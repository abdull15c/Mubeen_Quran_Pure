import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'audio_recorder_service.dart';
import 'quran_speech_engine.dart';
import 'whisper_api_engine.dart';

class _PendingAudioChunk {
  _PendingAudioChunk({
    required this.bytes,
    required this.sessionToken,
    required this.ayahIndex,
    required this.expectedText,
    required this.onRecognized,
  });

  final Uint8List bytes;
  final int sessionToken;
  final int ayahIndex;
  final String? expectedText;
  final ValueChanged<SpeechResult> onRecognized;
}

/// Dedicated speech recognition service powered by the fine-tuned
/// Modal Whisper Large v3 Quran LoRA server.
///
/// Supports single-Ayah recitation and continuous live VAD streaming.
class SpeechRecitationService extends ChangeNotifier {
  SpeechRecitationService({
    WhisperApiEngine? whisperEngine,
    AudioRecorderService? recorder,
  }) : _whisperEngine = whisperEngine ?? WhisperApiEngine(),
       _recorder = recorder ?? AudioRecorderService();

  final WhisperApiEngine _whisperEngine;
  final AudioRecorderService _recorder;

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isRotating = false;
  bool _isContinuous = false;
  bool _disposed = false;
  double _soundLevel = 0.0;
  String _lastRecognizedText = '';
  SpeechResult? _lastSpeechResult;
  String? _errorMessage;
  String? _expectedAyahText;
  String _engineMode = 'idle'; // 'whisper' | 'idle'

  // Session & Ayah tracking
  int _sessionToken = 0;
  int _currentAyahIndex = 0;
  double _accumulatedDurationSec = 0.0;
  final List<WordTimestamp> _accumulatedContinuousWords = <WordTimestamp>[];

  // Bounded queue for handling live audio chunks when network is slow
  final Queue<_PendingAudioChunk> _chunkQueue = Queue<_PendingAudioChunk>();
  bool _isProcessingQueue = false;

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isContinuous => _isContinuous;
  bool get isSpeaking => _recorder.isSpeaking;
  double get soundLevel => _soundLevel;
  String get lastRecognizedText => _lastRecognizedText;
  SpeechResult? get lastSpeechResult => _lastSpeechResult;
  String? get errorMessage => _errorMessage;
  String get engineMode => _engineMode;
  bool get isWhisperAvailable => _whisperEngine.isAvailable;

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<bool> initialize() async {
    return true;
  }

  /// Update the expected Ayah text prompt during live continuous recitation.
  ///
  /// Increments the Ayah generation so late responses from the previous Ayah
  /// are cleanly discarded without interrupting the ongoing microphone session.
  void setExpectedAyahText(String text) {
    _expectedAyahText = text;
    _accumulatedContinuousWords.clear();
    _accumulatedDurationSec = 0.0;
    _currentAyahIndex++;
    _lastRecognizedText = '';
    _lastSpeechResult = null;
    _safeNotifyListeners();
  }

  /// Start single-pass listening for an Ayah recitation.
  Future<void> startListening({
    required ValueChanged<SpeechResult> onRecognized,
    String? expectedText,
    ValueChanged<double>? onSoundLevel,
  }) async {
    final int session = ++_sessionToken;
    _isContinuous = false;
    _currentAyahIndex++;
    _lastRecognizedText = '';
    _lastSpeechResult = null;
    _errorMessage = null;
    _expectedAyahText = expectedText;
    _chunkQueue.clear();

    final bool started = await _recorder.startRecording(enableVad: false);
    if (session != _sessionToken || _disposed) return;

    if (!started) {
      _errorMessage =
          _recorder.errorMessage ?? 'Не удалось получить доступ к микрофону.';
      _engineMode = 'idle';
      _safeNotifyListeners();
      return;
    }
    _engineMode = 'whisper';
    _isListening = true;
    _safeNotifyListeners();
  }

  /// Start continuous recitation mode with live VAD (Voice Activity Detection).
  ///
  /// The microphone remains active continuously across multiple Ayahs.
  /// When the user pauses, segments are rotated and queued for Whisper.
  Future<void> startContinuousRecitation({
    required ValueChanged<SpeechResult> onChunkRecognized,
    String? expectedText,
  }) async {
    final int session = ++_sessionToken;
    _isContinuous = true;
    _currentAyahIndex++;
    _lastRecognizedText = '';
    _lastSpeechResult = null;
    _errorMessage = null;
    _expectedAyahText = expectedText;
    _accumulatedContinuousWords.clear();
    _accumulatedDurationSec = 0.0;
    _chunkQueue.clear();

    _recorder.onSpeechPauseDetected = () async {
      if (!_isListening || !_isContinuous || _isRotating || _disposed) return;
      if (session != _sessionToken) return;

      _isRotating = true;
      final int activeSession = _sessionToken;
      final int activeAyahIndex = _currentAyahIndex;
      final String? activeExpected = _expectedAyahText;

      try {
        final Uint8List? chunk = await _recorder.rotateRecording();
        if (activeSession != _sessionToken || !_isListening || !_isContinuous) {
          return;
        }

        if (chunk != null && chunk.isNotEmpty) {
          // Bounded queue: limit backlog to 3 pending chunks to prevent latency runaway
          if (_chunkQueue.length >= 3) {
            _chunkQueue.removeFirst(); // Drop oldest backlog
            _errorMessage = 'Медленное соединение, обработка с задержкой...';
            _safeNotifyListeners();
          }

          _chunkQueue.add(
            _PendingAudioChunk(
              bytes: chunk,
              sessionToken: activeSession,
              ayahIndex: activeAyahIndex,
              expectedText: activeExpected,
              onRecognized: onChunkRecognized,
            ),
          );

          _processChunkQueue();
        }
      } catch (e) {
        debugPrint('Continuous recitation pause rotate error: $e');
      } finally {
        _isRotating = false;
      }
    };

    final bool started = await _recorder.startRecording(enableVad: true);
    if (session != _sessionToken || _disposed) return;

    if (!started) {
      _errorMessage =
          _recorder.errorMessage ?? 'Не удалось включить непрерывный режим.';
      _engineMode = 'idle';
      _isContinuous = false;
      _safeNotifyListeners();
      return;
    }
    _engineMode = 'whisper';
    _isListening = true;
    _safeNotifyListeners();
  }

  Future<void> _processChunkQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    _isProcessing = true;
    _safeNotifyListeners();

    try {
      while (_chunkQueue.isNotEmpty && _isListening && !_disposed) {
        final _PendingAudioChunk item = _chunkQueue.removeFirst();

        // Check if session or ayah was cancelled/switched
        if (item.sessionToken != _sessionToken) continue;
        if (item.ayahIndex != _currentAyahIndex) {
          // Audio belongs to a previous Ayah, discard cleanly
          continue;
        }

        SpeechResult result;
        try {
          result = await _whisperEngine.recognize(
            item.bytes,
            expectedText: item.expectedText,
          );
        } catch (e) {
          debugPrint('Whisper chunk recognition error: $e');
          _errorMessage = e.toString();
          _safeNotifyListeners();
          continue;
        }

        if (item.sessionToken != _sessionToken || !_isListening || _disposed) {
          return;
        }
        if (item.ayahIndex != _currentAyahIndex) {
          // Discard if user already advanced to next ayah
          continue;
        }

        if (result.fullText.isNotEmpty) {
          final double currentOffset = _accumulatedDurationSec;
          double chunkDuration = 0.0;

          if (result.words.isNotEmpty) {
            for (final WordTimestamp w in result.words) {
              final WordTimestamp offsetWord = WordTimestamp(
                word: w.word,
                startSec: w.startSec + currentOffset,
                endSec: w.endSec + currentOffset,
              );
              _accumulatedContinuousWords.add(offsetWord);
            }
            chunkDuration = result.words.last.endSec;
          } else {
            // If words array is empty, preserve words from fullText so subsequent chunks concatenate cleanly
            final List<String> textWords = result.fullText
                .split(RegExp(r'\s+'))
                .where((String s) => s.isNotEmpty)
                .toList();
            chunkDuration = item.bytes.length / 32000.0;
            final double wordDuration = textWords.isNotEmpty
                ? chunkDuration / textWords.length
                : chunkDuration;
            for (var i = 0; i < textWords.length; i++) {
              _accumulatedContinuousWords.add(
                WordTimestamp(
                  word: textWords[i],
                  startSec: currentOffset + (i * wordDuration),
                  endSec: currentOffset + ((i + 1) * wordDuration),
                ),
              );
            }
          }
          _accumulatedDurationSec += chunkDuration;

          final String combinedText = _accumulatedContinuousWords.isNotEmpty
              ? _accumulatedContinuousWords
                    .map((WordTimestamp w) => w.word)
                    .join(' ')
              : result.fullText;

          final SpeechResult aggregatedResult = SpeechResult(
            fullText: combinedText,
            words: List<WordTimestamp>.unmodifiable(
              _accumulatedContinuousWords,
            ),
            confidence: result.confidence,
          );

          _lastRecognizedText = aggregatedResult.fullText;
          _lastSpeechResult = aggregatedResult;
          item.onRecognized(aggregatedResult);
          _safeNotifyListeners();
        }
      }
    } finally {
      _isProcessingQueue = false;
      _isProcessing = false;
      _safeNotifyListeners();
    }
  }

  /// Stop listening and process the recorded audio with Modal Whisper API.
  Future<void> stopListening({
    ValueChanged<SpeechResult>? onResult,
    String? expectedText,
  }) async {
    if (!_isListening && !_recorder.isRecording) {
      _isProcessing = false;
      _soundLevel = 0.0;
      _safeNotifyListeners();
      return;
    }

    final int session = ++_sessionToken;
    _isContinuous = false;
    _recorder.onSpeechPauseDetected = null;
    _chunkQueue.clear();

    _isListening = false;
    _isProcessing = true;
    _safeNotifyListeners();

    try {
      final Uint8List? audioBytes = await _recorder.stopRecording();
      if (session != _sessionToken || _disposed) return;

      if (audioBytes != null && audioBytes.isNotEmpty) {
        final SpeechResult result = await _whisperEngine.recognize(
          audioBytes,
          expectedText: expectedText ?? _expectedAyahText,
        );
        if (session != _sessionToken || _disposed) return;

        if (result.fullText.isNotEmpty) {
          _lastRecognizedText = result.fullText;
          _lastSpeechResult = result;
          onResult?.call(result);
        } else {
          _errorMessage =
              'Не удалось распознать речь. Попробуйте прочитать еще раз.';
        }
      } else {
        _errorMessage = 'Запись слишком короткая.';
      }
    } catch (e) {
      if (session == _sessionToken && !_disposed) {
        _errorMessage = e.toString();
        debugPrint('Whisper error: $e');
      }
    } finally {
      if (!_disposed) {
        _isProcessing = false;
        _soundLevel = 0.0;
        _safeNotifyListeners();
      }
    }
  }

  /// Cancel listening immediately, aborting active HTTP requests.
  Future<void> cancelListening() async {
    ++_sessionToken;
    _isContinuous = false;
    _recorder.onSpeechPauseDetected = null;
    _chunkQueue.clear();
    _whisperEngine.cancelAll();

    await _recorder.cancelRecording();
    _isListening = false;
    _isProcessing = false;
    _isRotating = false;
    _soundLevel = 0.0;
    _engineMode = 'idle';
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_sessionToken;
    _recorder.onSpeechPauseDetected = null;
    _chunkQueue.clear();
    _whisperEngine.cancelAll();
    _recorder.dispose();
    _whisperEngine.dispose();
    super.dispose();
  }
}
