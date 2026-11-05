"""
Modal Serverless Deployment for Quran Whisper ASR (Large v3 Turbo + LoRA support).

Deploys an OpenAI-compatible /v1/audio/transcriptions endpoint with
word-level timestamps and Tashkeel/Quranic prompt biasing.
"""

import io
import os
import secrets
import tempfile
from typing import List, Optional

from fastapi import Depends, FastAPI, File, Form, HTTPException, Request, Security, UploadFile
from fastapi.responses import JSONResponse, PlainTextResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import modal

MAX_AUDIO_BYTES = 10 * 1024 * 1024
MAX_PROMPT_CHARS = 4_000
WHISPER_MODEL = "deepdml/faster-whisper-large-v3-turbo-ct2"
WHISPER_MODEL_REVISION = "4df90f75321148c3a29a9e2351b7ddf8f5b115a8"

# ---------------------------------------------------------------------------
# 1. Container image with the CUDA 12 libraries required by CTranslate2
# ---------------------------------------------------------------------------
image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "faster-whisper==1.2.1",
        "huggingface-hub==1.30.0",
        "nvidia-cublas-cu12==12.9.1.4",
        "nvidia-cudnn-cu12==9.13.1.26",
        "fastapi[standard]>=0.115.0",
        "python-multipart>=0.0.31",
        "pydantic>=2.10.0",
    )
    .env(
        {
            "LD_LIBRARY_PATH": (
                "/usr/local/lib/python3.11/site-packages/nvidia/cublas/lib:"
                "/usr/local/lib/python3.11/site-packages/nvidia/cudnn/lib"
            )
        }
    )
)

app = modal.App("quran-whisper-service", image=image)

# ---------------------------------------------------------------------------
# 2. Serverless GPU Inference Class
# ---------------------------------------------------------------------------
@app.cls(
    gpu="L4",  # Fast modern GPU (~$0.0002/sec on demand, instant warm up)
    scaledown_window=60,  # Scale down to 0 replicas after 60s idle (0$ cost)
    timeout=120,
)
class QuranWhisperInference:
    @modal.enter()
    def load_model(self):
        """Loads and warms up the Whisper Large v3 Turbo engine."""
        from faster_whisper import WhisperModel
        from huggingface_hub import snapshot_download

        print("Loading Whisper Large v3 Turbo on cuda (float16)...")
        model_path = snapshot_download(
            repo_id=WHISPER_MODEL,
            revision=WHISPER_MODEL_REVISION,
        )
        self.model = WhisperModel(
            model_path,
            device="cuda",
            compute_type="float16",
            cpu_threads=4,
        )
        print("Whisper Model loaded successfully.")

    @modal.method()
    def transcribe_audio(
        self,
        audio_bytes: bytes,
        prompt: Optional[str] = None,
        language: str = "ar",
        temperature: float = 0.0,
    ) -> dict:
        """Transcribes audio with word-level timestamps and Tashkeel/Uthmani prompt biasing."""
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            tmp_file.write(audio_bytes)
            tmp_path = tmp_file.name

        try:
            segments, info = self.model.transcribe(
                tmp_path,
                language=language,
                initial_prompt=prompt,
                word_timestamps=True,
                temperature=temperature,
                beam_size=5,
                vad_filter=True,
                vad_parameters=dict(min_silence_duration_ms=500),
            )

            full_text_parts = []
            words_output = []

            for segment in segments:
                # Discard silence or noise segments
                if hasattr(segment, 'no_speech_prob') and segment.no_speech_prob > 0.6:
                    continue
                if hasattr(segment, 'avg_logprob') and segment.avg_logprob < -1.5:
                    continue

                full_text_parts.append(segment.text.strip())
                if segment.words:
                    for w in segment.words:
                        clean_word = w.word.strip()
                        prob = getattr(w, "probability", 1.0)
                        if clean_word and prob >= 0.2:
                            words_output.append({
                                "word": clean_word,
                                "start": round(w.start, 3),
                                "end": round(w.end, 3),
                                "probability": round(prob, 3),
                            })

            full_text = " ".join(full_text_parts).strip()

            return {
                "text": full_text,
                "language": info.language,
                "duration": round(info.duration, 2),
                "words": words_output,
            }
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)


# ---------------------------------------------------------------------------
# 3. FastAPI Web Application (/v1/audio/transcriptions)
# ---------------------------------------------------------------------------
web_app = FastAPI(title="Quran Whisper API", version="1.0.0")

auth_scheme = HTTPBearer(auto_error=False)

def verify_token(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(auth_scheme),
):
    expected_token = os.environ.get("MODAL_API_KEY")
    if not expected_token:
        raise HTTPException(status_code=503, detail="API authentication is not configured")
    if credentials is None or not secrets.compare_digest(
        credentials.credentials,
        expected_token,
    ):
        raise HTTPException(status_code=401, detail="Invalid authentication token")
    return credentials.credentials


def verify_content_length(request: Request) -> None:
    raw_length = request.headers.get("content-length")
    if raw_length is None:
        raise HTTPException(status_code=411, detail="Length Required: Content-Length header is mandatory")
    try:
        content_length = int(raw_length)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid Content-Length") from exc
    # Multipart framing and text fields require a small allowance.
    if content_length > MAX_AUDIO_BYTES + 64 * 1024:
        raise HTTPException(status_code=413, detail="Request body is too large")

@web_app.post("/v1/audio/transcriptions")
@web_app.post("/audio/transcriptions")
async def transcriptions_endpoint(
    file: UploadFile = File(...),
    model: Optional[str] = Form("whisper-l-v3-turbo-quran-lora"),
    language: Optional[str] = Form("ar"),
    response_format: Optional[str] = Form("verbose_json"),
    prompt: Optional[str] = Form(None),
    temperature: Optional[float] = Form(0.0),
    token: str = Depends(verify_token),
    _: None = Depends(verify_content_length),
):
    """OpenAI-compatible speech-to-text API endpoint."""
    if file.content_type not in {"audio/wav", "audio/x-wav", "application/octet-stream"}:
        raise HTTPException(status_code=415, detail="Only WAV audio is accepted")
    if prompt is not None and len(prompt) > MAX_PROMPT_CHARS:
        raise HTTPException(status_code=400, detail="Prompt is too long")
    if language not in {None, "ar"}:
        raise HTTPException(status_code=400, detail="Only Arabic is supported")

    audio_bytes = await file.read(MAX_AUDIO_BYTES + 1)
    if not audio_bytes:
        return JSONResponse(
            status_code=400,
            content={"error": "Empty audio file received."},
        )
    if len(audio_bytes) > MAX_AUDIO_BYTES:
        return JSONResponse(
            status_code=413,
            content={"error": "Audio file too large. Maximum size is 10MB."},
        )
    if len(audio_bytes) < 44 or audio_bytes[:4] != b"RIFF" or audio_bytes[8:12] != b"WAVE":
        raise HTTPException(status_code=400, detail="Invalid WAV audio: missing RIFF/WAVE header")

    # Validate audio parameters by parsing RIFF chunks
    import struct
    try:
        offset = 12
        fmt_params = None
        data_size = None
        while offset + 8 <= len(audio_bytes):
            chunk_id = audio_bytes[offset:offset+4]
            chunk_size = struct.unpack_from("<I", audio_bytes, offset + 4)[0]
            if chunk_id == b"fmt " and chunk_size >= 16:
                fmt_params = struct.unpack_from("<HHIIHH", audio_bytes, offset + 8)
            elif chunk_id == b"data":
                data_size = chunk_size
            offset += 8 + chunk_size
            if chunk_size % 2 == 1:
                offset += 1

        if fmt_params is None:
            raise HTTPException(status_code=400, detail="Invalid WAV audio: missing fmt chunk")

        audio_format, num_channels, sample_rate, byte_rate, block_align, bits_per_sample = fmt_params
        if audio_format != 1:  # PCM format
            raise HTTPException(status_code=400, detail="Unsupported WAV format: only uncompressed PCM is supported")
        if num_channels not in {1, 2}:
            raise HTTPException(status_code=400, detail="Unsupported WAV channels: must be mono or stereo")
        if sample_rate < 8000 or sample_rate > 48000:
            raise HTTPException(status_code=400, detail=f"Unsupported sample rate: {sample_rate}Hz (expected 8kHz–48kHz)")
        if bits_per_sample not in {16, 24, 32}:
            raise HTTPException(status_code=400, detail="Unsupported bit depth: expected 16-bit PCM")

        bytes_per_sample = bits_per_sample // 8
        pcm_bytes = data_size if data_size is not None else (len(audio_bytes) - 44)
        duration_sec = pcm_bytes / (sample_rate * num_channels * bytes_per_sample)
        if duration_sec < 0.15:
            return JSONResponse(status_code=400, content={"error": "Audio recording too short (less than 0.15s)."})
        if duration_sec > 60.0:
            return JSONResponse(status_code=400, content={"error": "Audio recording too long (exceeds 60s limit)."})
    except (struct.error, IndexError):
        raise HTTPException(status_code=400, detail="Corrupt WAV header structure")

    inference_engine = QuranWhisperInference()
    result = await inference_engine.transcribe_audio.remote.aio(
        audio_bytes=audio_bytes,
        prompt=prompt,
        language=language or "ar",
        temperature=temperature or 0.0,
    )

    if response_format == "text":
        return PlainTextResponse(result["text"])

    return JSONResponse(content=result)


@app.function(
    image=image,
    scaledown_window=60,
    secrets=[modal.Secret.from_name("quran-api-secret")],
)
@modal.asgi_app()
def api():
    """Mounts the FastAPI application on Modal."""
    return web_app
