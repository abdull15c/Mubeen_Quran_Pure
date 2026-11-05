#!/usr/bin/env python3
"""Build the compact offline semantic-search assets used by the app."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import math
import shutil
import sqlite3
import struct
import tarfile
import urllib.request
from pathlib import Path

import numpy as np
import sentencepiece as spm

from test_semantic_situations import EXTENDED_SEMANTIC_SITUATIONS


MODEL_ID = "bpemb-ru-wiki-vs10000-d100"
MODEL_LANGUAGE = "ru"
VOCAB_SIZE = 10_000
DIMENSION = 100
FORMAT_VERSION = 1
HEADER_SIZE = 64
MAGIC = b"MQSEM001"
TOPIC_MAGIC = b"MQTOP001"
DEFAULT_THRESHOLD = 0.36
DEFAULT_TOPIC_THRESHOLD = 0.48
BPemb_BASE_URL = "https://nlp.h-its.org/bpemb/ru/"


def normalize_text(value: str) -> str:
    return " ".join(value.lower().replace("ё", "е").split())


def sentence_embedding(
    tokenizer: spm.SentencePieceProcessor,
    vectors: np.ndarray,
    text: str,
) -> np.ndarray:
    token_ids = tokenizer.encode(normalize_text(text), out_type=int)
    if not token_ids:
        return np.zeros(DIMENSION, dtype=np.float32)
    vector = vectors[token_ids].mean(axis=0, dtype=np.float32)
    norm = float(np.linalg.norm(vector))
    if not math.isfinite(norm) or norm <= 0:
        return np.zeros(DIMENSION, dtype=np.float32)
    return vector / norm


def compose_documents(database: sqlite3.Connection) -> list[tuple[int, str]]:
    database.row_factory = sqlite3.Row
    rows = database.execute(
        """
        SELECT
          a.id AS ayah_id,
          a.surah_id,
          a.number_in_surah,
          s.name_russian AS surah_name,
          MAX(CASE WHEN t.translator_key = 'kuliev' THEN t.text END) AS kuliev,
          MAX(CASE WHEN t.translator_key = 'abu_adel' THEN t.text END) AS abu_adel,
          GROUP_CONCAT(
            CASE WHEN tt.id IS NOT NULL THEN
              tt.title || '. ' || tt.description || '. ' || COALESCE(ta.note, '')
            END,
            ' '
          ) AS themes
        FROM ayahs AS a
        INNER JOIN surahs AS s ON s.id = a.surah_id
        INNER JOIN translations AS t ON t.ayah_id = a.id
        LEFT JOIN thematic_ayahs AS ta
          ON ta.surah_id = a.surah_id
         AND ta.ayah_number = a.number_in_surah
        LEFT JOIN thematic_topics AS tt ON tt.id = ta.topic_id
        GROUP BY a.id
        ORDER BY a.id
        """
    ).fetchall()
    if len(rows) != 6_236:
        raise RuntimeError(f"Expected 6236 ayahs, found {len(rows)}")

    semantic_context: dict[tuple[int, int], list[str]] = {}
    for situation in EXTENDED_SEMANTIC_SITUATIONS:
        for surah_id, ayah_number, note in situation["ayahs"]:
            semantic_context.setdefault((surah_id, ayah_number), []).append(
                f"{situation['topic']}. {situation['keywords']}. {note}"
            )

    documents: list[tuple[int, str]] = []
    for row in rows:
        if not row["kuliev"] or not row["abu_adel"]:
            raise RuntimeError(f"Ayah {row['ayah_id']} is missing a translation")
        situation_text = " ".join(
            semantic_context.get((row["surah_id"], row["number_in_surah"]), [])
        )
        fields = [
            f"Сура {row['surah_name']}, {row['surah_id']}:{row['number_in_surah']}.",
            situation_text,
            situation_text,
            situation_text,
            row["themes"] or "",
            row["kuliev"],
            row["abu_adel"],
        ]
        documents.append((row["ayah_id"], normalize_text(" ".join(fields))))
    return documents


def compose_topic_prototypes(database: sqlite3.Connection):
    references = {
        (surah, ayah): ayah_id
        for ayah_id, surah, ayah in database.execute(
            "SELECT id, surah_id, number_in_surah FROM ayahs"
        )
    }
    prototypes = []
    for topic in EXTENDED_SEMANTIC_SITUATIONS:
        ayah_ids = [
            references[(surah, ayah)]
            for surah, ayah, _ in topic["ayahs"]
            if (surah, ayah) in references
        ]
        prototypes.append((f"{topic['topic']}. {topic['keywords']}", ayah_ids))
    return prototypes


def quantize(vector: np.ndarray) -> tuple[np.ndarray, float]:
    maximum = float(np.max(np.abs(vector)))
    if maximum <= 0:
        return np.zeros(DIMENSION, dtype=np.int8), 0.0
    values = np.clip(np.rint(vector * (127.0 / maximum)), -127, 127).astype(np.int8)
    integer_norm = math.sqrt(float(np.dot(values.astype(np.int32), values.astype(np.int32))))
    return values, 1.0 / integer_norm


def load_word2vec_vectors(path: Path) -> np.ndarray:
    vectors = np.empty((VOCAB_SIZE, DIMENSION), dtype=np.float32)
    with path.open("rb") as source:
        count, dimension = map(int, source.readline().split())
        if (count, dimension) != vectors.shape:
            raise RuntimeError(f"Unexpected token matrix shape: {(count, dimension)}")
        for row in range(count):
            word = bytearray()
            while True:
                character = source.read(1)
                if character == b" ":
                    break
                if not character:
                    raise EOFError("Unexpected end of word2vec vocabulary")
                word.extend(character)
            vectors[row] = np.frombuffer(source.read(4 * dimension), dtype="<f4")
            separator = source.read(1)
            if separator not in {b"\n", b""}:
                source.seek(-1, 1)
    return vectors


def ensure_bpemb_files(cache: Path) -> tuple[Path, Path]:
    cache.mkdir(parents=True, exist_ok=True)
    model_file = cache / "ru.wiki.bpe.vs10000.model"
    embeddings_file = cache / "ru.wiki.bpe.vs10000.d100.w2v.bin"
    if not model_file.is_file():
        urllib.request.urlretrieve(BPemb_BASE_URL + model_file.name, model_file)
    if not embeddings_file.is_file():
        archive = cache / (embeddings_file.name + ".tar.gz")
        try:
            urllib.request.urlretrieve(BPemb_BASE_URL + archive.name, archive)
            with tarfile.open(archive, "r:gz") as source:
                member = next(
                    item for item in source.getmembers()
                    if Path(item.name).name == embeddings_file.name
                )
                extracted = source.extractfile(member)
                if extracted is None:
                    raise RuntimeError("BPEmb archive contains no embedding file")
                with embeddings_file.open("wb") as target:
                    shutil.copyfileobj(extracted, target)
        finally:
            archive.unlink(missing_ok=True)
    return model_file, embeddings_file


def build(database_gzip: Path, output_directory: Path) -> None:
    output_directory.mkdir(parents=True, exist_ok=True)
    cache = Path.home() / ".cache/bpemb/ru"
    model_file, embeddings_file = ensure_bpemb_files(cache)
    tokenizer = spm.SentencePieceProcessor(model_file=str(model_file))

    database = sqlite3.connect(":memory:")
    try:
        database.deserialize(gzip.decompress(database_gzip.read_bytes()))
        documents = compose_documents(database)
        topic_prototypes = compose_topic_prototypes(database)
    finally:
        database.close()

    model_bytes = model_file.read_bytes()
    model_output = output_directory / "bpemb_ru_10000.model"

    vectors = load_word2vec_vectors(embeddings_file)
    if vectors.shape != (VOCAB_SIZE, DIMENSION):
        raise RuntimeError(f"Unexpected token matrix shape: {vectors.shape}")
    token_scales = np.max(np.abs(vectors), axis=1) / 127.0
    token_scales[token_scales == 0] = 1.0
    quantized_tokens = np.clip(
        np.rint(vectors / token_scales[:, np.newaxis]), -127, 127
    ).astype(np.int8)
    token_output = output_directory / "bpemb_ru_10000_d100.i8"
    temporary_tokens = token_output.with_suffix(token_output.suffix + ".tmp")
    with temporary_tokens.open("wb") as target:
        target.write(token_scales.astype("<f4").tobytes())
        target.write(quantized_tokens.tobytes())
    temporary_tokens.replace(token_output)

    document_digest = hashlib.sha256()
    row_size = 8 + DIMENSION
    payload = bytearray()
    for ayah_id, text in documents:
        encoded = text.encode("utf-8")
        document_digest.update(struct.pack("<II", ayah_id, len(encoded)))
        document_digest.update(encoded)
        values, inverse_norm = quantize(
            sentence_embedding(tokenizer, vectors, text)
        )
        payload.extend(struct.pack("<If", ayah_id, inverse_norm))
        payload.extend(values.tobytes())

    header = bytearray(HEADER_SIZE)
    struct.pack_into(
        "<8sHHIHH",
        header,
        0,
        MAGIC,
        FORMAT_VERSION,
        HEADER_SIZE,
        len(documents),
        DIMENSION,
        row_size,
    )
    header[20:52] = hashlib.sha256(payload).digest()
    index_output = output_directory / "ayah_embeddings.i8"
    temporary_index = index_output.with_suffix(index_output.suffix + ".tmp")
    temporary_index.write_bytes(header + payload)
    temporary_index.replace(index_output)

    topic_payload = bytearray()
    for text, ayah_ids in topic_prototypes:
        values, inverse_norm = quantize(
            sentence_embedding(tokenizer, vectors, text)
        )
        topic_payload.extend(struct.pack("<fH", inverse_norm, len(ayah_ids)))
        topic_payload.extend(values.tobytes())
        topic_payload.extend(struct.pack(f"<{len(ayah_ids)}I", *ayah_ids))
    topic_header = struct.pack(
        "<8sHHIHH",
        TOPIC_MAGIC,
        FORMAT_VERSION,
        HEADER_SIZE,
        len(topic_prototypes),
        DIMENSION,
        0,
    ) + hashlib.sha256(topic_payload).digest() + bytes(12)
    topic_output = output_directory / "topic_embeddings.i8"
    temporary_topics = topic_output.with_suffix(topic_output.suffix + ".tmp")
    temporary_topics.write_bytes(topic_header + topic_payload)
    temporary_topics.replace(topic_output)

    manifest = {
        "format_version": FORMAT_VERSION,
        "model_id": MODEL_ID,
        "language": MODEL_LANGUAGE,
        "vocabulary_size": VOCAB_SIZE,
        "dimension": DIMENSION,
        "ayah_count": len(documents),
        "cosine_threshold": DEFAULT_THRESHOLD,
        "topic_cosine_threshold": DEFAULT_TOPIC_THRESHOLD,
        "model_sha256": hashlib.sha256(model_bytes).hexdigest(),
        "token_embeddings_sha256": hashlib.sha256(token_output.read_bytes()).hexdigest(),
        "index_sha256": hashlib.sha256(index_output.read_bytes()).hexdigest(),
        "topic_index_sha256": hashlib.sha256(topic_output.read_bytes()).hexdigest(),
        "corpus_sha256": document_digest.hexdigest(),
        "license": "MIT",
        "source": "https://bpemb.h-its.org/ru/",
    }
    manifest_output = output_directory / "semantic_manifest.json"
    temporary_manifest = manifest_output.with_suffix(manifest_output.suffix + ".tmp")
    temporary_manifest.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary_model = model_output.with_suffix(model_output.suffix + ".tmp")
    temporary_model.write_bytes(model_bytes)
    temporary_model.replace(model_output)
    temporary_manifest.replace(manifest_output)

    total_size = sum(
        path.stat().st_size
        for path in (model_output, token_output, index_output, topic_output, manifest_output)
    )
    print(f"Built {len(documents)} ayah embeddings ({total_size} bytes total)")
    print(f"Model: {model_output} ({model_output.stat().st_size} bytes)")
    print(f"Token vectors: {token_output} ({token_output.stat().st_size} bytes)")
    print(f"Ayah index: {index_output} ({index_output.stat().st_size} bytes)")
    print(f"Topic index: {topic_output} ({topic_output.stat().st_size} bytes)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "database",
        type=Path,
        nargs="?",
        default=Path("assets/db/quran.db.gz"),
    )
    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        default=Path("assets/search"),
    )
    arguments = parser.parse_args()
    build(arguments.database, arguments.output)


if __name__ == "__main__":
    main()
