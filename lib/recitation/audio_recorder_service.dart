import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records microphone audio to a WAV buffer for Whisper API transcription
/// and provides client-side Voice Activity Detection (VAD).
///
/// Uses the `record` package which supports Android and iOS.
/// Output format: PCM 16-bit, mono, 16 kHz – optimal for Whisper.
class AudioRecorderService extends ChangeNotifier {
  AudioRecorderService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  bool _isRecording = false;
  bool _isSpeaking = false;
  bool _disposed = false;
  double _currentAmplitude = -160.0;
  String? _currentPath;
  String? _errorMessage;

  StreamSubscription<Amplitude>? _amplitudeSub;
  DateTime? _lastSpeechTime;
  int _speechDurationMs = 0;
  int _recordGeneration = 0;

  // Maximum continuous segment length (25 seconds) to prevent unbounded recording
  static const int _maxSegmentDurationMs = 25000;

  Future<void>? _lock;

  /// Callback triggered when user stops speaking after reciting a segment
  /// (silence detected after active speech).
  VoidCallback? onSpeechPauseDetected;

  bool get isRecording => _isRecording;
  bool get isSpeaking => _isSpeaking;
  bool get isDisposed => _disposed;
  double get currentAmplitude => _currentAmplitude;
  String? get errorMessage => _errorMessage;

  /// Sequential execution lock to serialize operations on the audio recorder
  Future<T> _runLocked<T>(Future<T> Function() action) async {
    final Future<void>? previousLock = _lock;
    final Completer<void> completer = Completer<void>();
    _lock = completer.future;
    try {
      if (previousLock != null) {
        await previousLock;
      }
      return await action();
    } finally {
      completer.complete();
      if (identical(_lock, completer.future)) {
        _lock = null;
      }
    }
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Start recording audio from the device microphone.
  ///
  /// Serialized and idempotent: duplicate calls while recording are safely ignored.
  Future<bool> startRecording({bool enableVad = true}) async {
    return _runLocked(() async {
      if (_disposed) return false;
      if (_isRecording) {
        return true; // Already recording
      }
      final int gen = ++_recordGeneration;

      _errorMessage = null;

      try {
        final bool hasPermission = await _recorder.hasPermission();
        if (_disposed || gen != _recordGeneration) return false;

        if (!hasPermission) {
          _errorMessage = 'Нет разрешения на запись с микрофона.';
          _safeNotifyListeners();
          return false;
        }

        final Directory tempDir = await getTemporaryDirectory();
        if (_disposed || gen != _recordGeneration) return false;

        final String filePath = p.join(
          tempDir.path,
          'quran_recitation_${DateTime.now().millisecondsSinceEpoch}.wav',
        );

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: filePath,
        );

        if (_disposed || gen != _recordGeneration) {
          try {
            await _recorder.stop();
          } catch (_) {}
          _cleanupFile(filePath);
          return false;
        }

        _currentPath = filePath;
        _isRecording = true;
        _isSpeaking = false;
        _speechDurationMs = 0;
        _lastSpeechTime = null;

        if (enableVad) {
          _startVadMonitoring();
        }

        _safeNotifyListeners();
        return true;
      } catch (e) {
        _errorMessage = 'Ошибка записи: $e';
        _isRecording = false;
        if (_currentPath != null) {
          _cleanupFile(_currentPath);
          _currentPath = null;
        }
        _safeNotifyListeners();
        return false;
      }
    });
  }

  void _startVadMonitoring() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((Amplitude amp) {
          if (_disposed || !_isRecording) return;
          _currentAmplitude = amp.current;

          const double speechThreshold = -45.0; // dBFS
          const double silenceThreshold = -50.0; // dBFS

          if (amp.current > speechThreshold) {
            _isSpeaking = true;
            _lastSpeechTime = DateTime.now();
            _speechDurationMs += 100;
            _safeNotifyListeners();

            // Enforce maximum segment limit to prevent huge memory buffers
            if (_speechDurationMs >= _maxSegmentDurationMs) {
              _isSpeaking = false;
              _speechDurationMs = 0;
              _lastSpeechTime = null;
              _safeNotifyListeners();
              onSpeechPauseDetected?.call();
            }
          } else if (_isSpeaking && amp.current <= silenceThreshold) {
            final DateTime now = DateTime.now();
            final int silenceMs = _lastSpeechTime != null
                ? now.difference(_lastSpeechTime!).inMilliseconds
                : 0;

            if (silenceMs >= 450 && _speechDurationMs >= 600) {
              _isSpeaking = false;
              _speechDurationMs = 0;
              _lastSpeechTime = null;
              _safeNotifyListeners();
              onSpeechPauseDetected?.call();
            }
          }
        });
  }

  /// Rotates recording seamlessly: stops current recording, immediately starts
  /// next recording, and returns the bytes of the completed segment.
  Future<Uint8List?> rotateRecording() async {
    return _runLocked(() async {
      if (!_isRecording || _disposed) return null;

      String? finishedPath;
      try {
        finishedPath = await _recorder.stop();
      } catch (e) {
        debugPrint('AudioRecorder: error stopping segment in rotate: $e');
        _isRecording = false;
        _errorMessage = 'Ошибка остановки сегмента: $e';
        _safeNotifyListeners();
        return null;
      }

      if (!_isRecording || _disposed) {
        _cleanupFile(finishedPath);
        return null;
      }

      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String nextPath = p.join(
          tempDir.path,
          'quran_recitation_${DateTime.now().millisecondsSinceEpoch}.wav',
        );

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: nextPath,
        );

        _currentPath = nextPath;
        _isSpeaking = false;
        _speechDurationMs = 0;
        _lastSpeechTime = null;
      } catch (e) {
        debugPrint('AudioRecorder: error starting next segment in rotate: $e');
        _isRecording = false;
        _errorMessage = 'Ошибка перезапуска записи: $e';
        _cleanupFile(finishedPath);
        _safeNotifyListeners();
        return null;
      }

      if (finishedPath != null) {
        return _readFileAndCleanup(finishedPath);
      }
      return null;
    });
  }

  /// Stop the current recording and return the raw WAV bytes.
  Future<Uint8List?> stopRecording() async {
    return _runLocked(() async {
      if (!_isRecording || _disposed) return null;

      try {
        _amplitudeSub?.cancel();
        _amplitudeSub = null;

        final String? path = await _recorder.stop();
        _isRecording = false;
        _isSpeaking = false;
        _safeNotifyListeners();

        final String? filePath = path ?? _currentPath;
        _currentPath = null;
        if (filePath == null) return null;

        return _readFileAndCleanup(filePath);
      } catch (e) {
        _errorMessage = 'Ошибка остановки записи: $e';
        _isRecording = false;
        _currentPath = null;
        _safeNotifyListeners();
        return null;
      }
    });
  }

  /// Cancel a recording in progress without producing output.
  Future<void> cancelRecording() async {
    _recordGeneration++;
    return _runLocked(() async {
      _amplitudeSub?.cancel();
      _amplitudeSub = null;
      try {
        await _recorder.stop();
      } catch (_) {}

      _isRecording = false;
      _isSpeaking = false;
      if (_currentPath != null) {
        _cleanupFile(_currentPath);
        _currentPath = null;
      }
      _safeNotifyListeners();
    });
  }

  Uint8List? _readFileAndCleanup(String path) {
    final File file = File(path);
    if (!file.existsSync()) return null;

    try {
      final Uint8List rawBytes = file.readAsBytesSync();
      if (rawBytes.isEmpty) return null;

      if (rawBytes.length > 4 && rawBytes[0] == 0x52 && rawBytes[1] == 0x49) {
        return rawBytes;
      }
      return _addWavHeader(rawBytes, 16000, 1, 16);
    } catch (e) {
      debugPrint('AudioRecorder: Error reading audio file $path: $e');
      return null;
    } finally {
      _cleanupFile(path);
    }
  }

  void _cleanupFile(String? path) {
    if (path == null) return;
    try {
      final File file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  /// Adds standard 44-byte WAV header to raw PCM audio data.
  Uint8List _addWavHeader(
    Uint8List pcmBytes,
    int sampleRate,
    int channels,
    int bitRate,
  ) {
    final int byteRate = ((sampleRate * channels * bitRate) / 8).round();
    final int size = pcmBytes.length;
    final int fileSize = size + 36;

    final Uint8List header = Uint8List(44);
    final ByteData bd = ByteData.view(header.buffer);

    // RIFF header
    bd.setUint8(0, 0x52);
    bd.setUint8(1, 0x49);
    bd.setUint8(2, 0x46);
    bd.setUint8(3, 0x46); // 'RIFF'
    bd.setUint32(4, fileSize, Endian.little);
    bd.setUint8(8, 0x57);
    bd.setUint8(9, 0x41);
    bd.setUint8(10, 0x56);
    bd.setUint8(11, 0x45); // 'WAVE'

    // fmt chunk
    bd.setUint8(12, 0x66);
    bd.setUint8(13, 0x6d);
    bd.setUint8(14, 0x74);
    bd.setUint8(15, 0x20); // 'fmt '
    bd.setUint32(16, 16, Endian.little); // chunk size
    bd.setUint16(20, 1, Endian.little); // PCM
    bd.setUint16(22, channels, Endian.little); // channels
    bd.setUint32(24, sampleRate, Endian.little); // sample rate
    bd.setUint32(28, byteRate, Endian.little); // byte rate
    bd.setUint16(32, (channels * bitRate ~/ 8), Endian.little); // block align
    bd.setUint16(34, bitRate, Endian.little); // bits per sample

    // data chunk
    bd.setUint8(36, 0x64);
    bd.setUint8(37, 0x61);
    bd.setUint8(38, 0x74);
    bd.setUint8(39, 0x61); // 'data'
    bd.setUint32(40, size, Endian.little);

    final BytesBuilder builder = BytesBuilder(copy: false)
      ..add(header)
      ..add(pcmBytes);
    return builder.toBytes();
  }

  @override
  void dispose() {
    _disposed = true;
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    onSpeechPauseDetected = null;
    _recorder.dispose();
    if (_currentPath != null) {
      _cleanupFile(_currentPath);
      _currentPath = null;
    }
    super.dispose();
  }
}
