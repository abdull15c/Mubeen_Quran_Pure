import 'dart:typed_data';

/// A single word recognized by the speech engine with precise timing.
final class WordTimestamp {
  const WordTimestamp({
    required this.word,
    required this.startSec,
    required this.endSec,
  });

  final String word;
  final double startSec;
  final double endSec;

  double get durationSec => endSec - startSec;

  @override
  String toString() =>
      'WordTimestamp("$word", ${startSec.toStringAsFixed(2)}–${endSec.toStringAsFixed(2)}s)';
}

/// The result of a speech recognition pass.
final class SpeechResult {
  const SpeechResult({
    required this.fullText,
    this.words = const <WordTimestamp>[],
    this.confidence = 1.0,
  });

  /// The full recognized text.
  final String fullText;

  /// Per-word timestamps (empty when the platform ASR fallback is used).
  final List<WordTimestamp> words;

  /// Overall confidence score (0.0–1.0).
  final double confidence;

  /// Whether word-level timing data is available.
  bool get hasTimestamps => words.isNotEmpty;

  @override
  String toString() =>
      'SpeechResult("$fullText", ${words.length} words, confidence=$confidence)';
}

/// A swappable speech recognition backend.
///
/// Two implementations exist:
///  * [WhisperApiEngine] – sends audio to the Whisper API and returns
///    word-level timestamps.
///  * [PlatformSpeechEngine] – uses the on-device [speech_to_text] plugin
///    as an offline fallback (no word timestamps).
abstract interface class QuranSpeechEngine {
  /// Recognize Arabic speech from a WAV audio buffer.
  ///
  /// [audioWav] must be a valid WAV file encoded as PCM 16-bit mono 16 kHz.
  /// [expectedText] is an optional Uthmani hint that may improve accuracy.
  Future<SpeechResult> recognize(Uint8List audioWav, {String? expectedText});

  /// Whether this engine is ready to accept audio.
  bool get isAvailable;

  /// Release resources held by this engine.
  Future<void> dispose();
}
