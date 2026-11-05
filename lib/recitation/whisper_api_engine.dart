import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'quran_speech_engine.dart';

/// Exception thrown when Whisper API encounters a non-recoverable error.
class WhisperApiException implements Exception {
  const WhisperApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Dedicated Quran Whisper Large v3 Turbo speech engine via Modal cloud.
///
/// Default configuration connects directly to the high-performance Modal
/// deployment with fine-tuned weights and word timestamps.
///
/// Can be overridden at build time via `--dart-define`:
/// ```powershell
/// flutter build apk --dart-define=WHISPER_API_URL=https://... --dart-define=WHISPER_API_KEY=...
/// ```
class WhisperApiEngine implements QuranSpeechEngine {
  WhisperApiEngine({String? apiKey, String? baseUrl, String? model})
    : _apiKey =
          apiKey ??
          const String.fromEnvironment('WHISPER_API_KEY', defaultValue: ''),
      _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'WHISPER_API_URL',
            defaultValue:
                'https://abdulla552t--quran-whisper-service-api.modal.run/v1',
          ),
      _model =
          model ??
          const String.fromEnvironment(
            'WHISPER_MODEL',
            defaultValue: 'whisper-large-v3-turbo',
          );

  final String _apiKey;
  final String _baseUrl;
  final String _model;

  static const Duration _overallTimeout = Duration(seconds: 30);
  static const int _maxResponseBodyBytes = 1024 * 1024; // 1 MB limit
  static const int _maxRetries = 1;

  final Set<HttpClient> _activeClients = <HttpClient>{};
  bool _disposed = false;
  int _cancellationEpoch = 0;

  @override
  bool get isAvailable => _apiKey.isNotEmpty && _baseUrl.isNotEmpty;

  /// Отменяет все активные сетевые запросы распознавания и предотвращает retry.
  void cancelAll() {
    _cancellationEpoch++;
    for (final HttpClient client in _activeClients.toList()) {
      client.close(force: true);
    }
    _activeClients.clear();
  }

  /// Отправляет пустой пинг на сервер для "прогрева" (Cold Start) контейнера Modal.
  Future<void> preWarm() async {
    if (!isAvailable || _disposed) return;
    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    _activeClients.add(client);
    try {
      final HttpClientRequest request = await client.openUrl(
        'HEAD',
        Uri.parse('$_baseUrl/audio/transcriptions'),
      );
      request.headers.set('Authorization', 'Bearer $_apiKey');
      await request.close();
    } catch (_) {
      // Ignore ping errors
    } finally {
      client.close(force: true);
      _activeClients.remove(client);
    }
  }

  @override
  Future<SpeechResult> recognize(
    Uint8List audioWav, {
    String? expectedText,
  }) async {
    if (!isAvailable || audioWav.isEmpty || _disposed) {
      return const SpeechResult(fullText: '', confidence: 0);
    }

    final int epoch = _cancellationEpoch;
    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      if (_disposed || epoch != _cancellationEpoch) {
        return const SpeechResult(fullText: '', confidence: 0);
      }
      try {
        final SpeechResult result = await _send(
          audioWav,
          expectedText: expectedText,
        );
        if (_disposed || epoch != _cancellationEpoch) {
          return const SpeechResult(fullText: '', confidence: 0);
        }
        return result;
      } on WhisperApiException catch (error) {
        // Do not retry 4xx errors (auth, client, payload too large)
        lastError = error;
        break;
      } on Object catch (error) {
        lastError = error;
        if (_disposed || epoch != _cancellationEpoch) {
          return const SpeechResult(fullText: '', confidence: 0);
        }
        if (attempt < _maxRetries) {
          await Future<void>.delayed(
            Duration(milliseconds: 400 * (attempt + 1)),
          );
          if (_disposed || epoch != _cancellationEpoch) {
            return const SpeechResult(fullText: '', confidence: 0);
          }
        }
      }
    }
    if (_disposed || epoch != _cancellationEpoch) {
      return const SpeechResult(fullText: '', confidence: 0);
    }
    debugPrint('WhisperApiEngine: transcription failed – $lastError');
    if (lastError is WhisperApiException) {
      throw lastError;
    }
    return const SpeechResult(fullText: '', confidence: 0);
  }

  Future<SpeechResult> _send(Uint8List audioWav, {String? expectedText}) async {
    final Uri uri = Uri.parse('$_baseUrl/audio/transcriptions');

    final String boundary =
        '----DartBoundary${DateTime.now().millisecondsSinceEpoch}';
    final List<int> body = _buildMultipartBody(
      boundary: boundary,
      audioWav: audioWav,
      expectedText: expectedText,
    );

    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    _activeClients.add(client);

    try {
      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $_apiKey');
      request.headers.set(
        'Content-Type',
        'multipart/form-data; boundary=$boundary',
      );
      request.headers.set('Content-Length', body.length.toString());
      request.add(body);

      final HttpClientResponse response = await request.close().timeout(
        _overallTimeout,
      );

      if (response.statusCode != 200) {
        final String errorBody = await _readLimitedBody(response);
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw WhisperApiException(
            'Ошибка авторизации на сервере Whisper (${response.statusCode}). Проверьте API ключ.',
            statusCode: response.statusCode,
          );
        }
        if (response.statusCode == 413) {
          throw const WhisperApiException(
            'Аудиозапись слишком велика для обработки (413).',
            statusCode: 413,
          );
        }
        if (response.statusCode == 429) {
          throw const WhisperApiException(
            'Превышен лимит запросов к серверу (429). Повторите позже.',
            statusCode: 429,
          );
        }
        throw WhisperApiException(
          'Ошибка сервера Whisper (${response.statusCode}): $errorBody',
          statusCode: response.statusCode,
        );
      }

      final String responseBody = await _readLimitedBody(response);
      return _parseResponse(responseBody);
    } finally {
      client.close(force: true);
      _activeClients.remove(client);
    }
  }

  Future<String> _readLimitedBody(HttpClientResponse response) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    int readBytes = 0;

    await for (final List<int> chunk in response.timeout(_overallTimeout)) {
      readBytes += chunk.length;
      if (readBytes > _maxResponseBodyBytes) {
        throw const WhisperApiException(
          'Ответ сервера Whisper превысил допустимый размер (1 МБ).',
        );
      }
      builder.add(chunk);
    }

    return utf8.decode(builder.takeBytes(), allowMalformed: true);
  }

  List<int> _buildMultipartBody({
    required String boundary,
    required Uint8List audioWav,
    String? expectedText,
  }) {
    final StringBuffer header = StringBuffer();

    void addField(String name, String value) {
      header.write('--$boundary\r\n');
      header.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
      header.write('$value\r\n');
    }

    addField('model', _model);
    addField('language', 'ar');
    addField('response_format', 'verbose_json');
    addField('timestamp_granularities[]', 'word');
    addField('temperature', '0.0');

    // Use a neutral Quranic recitation style hint instead of biasing the model
    // with the exact target sentence, preventing hallucinations on silence/noise.
    const String neutralPrompt = 'القرآن الكريم، ترتيل وتجويد';
    addField('prompt', neutralPrompt);

    // Field: file (WAV audio)
    header.write('--$boundary\r\n');
    header.write(
      'Content-Disposition: form-data; name="file"; filename="recitation.wav"\r\n',
    );
    header.write('Content-Type: audio/wav\r\n\r\n');

    final List<int> headerBytes = utf8.encode(header.toString());
    final List<int> footerBytes = utf8.encode('\r\n--$boundary--\r\n');

    return <int>[...headerBytes, ...audioWav, ...footerBytes];
  }

  static SpeechResult _parseResponse(String jsonBody) {
    final Object? decoded = jsonDecode(jsonBody);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Whisper API returned invalid JSON.');
    }

    final String fullText = (decoded['text'] as String?)?.trim() ?? '';
    final List<WordTimestamp> words = <WordTimestamp>[];
    double totalProb = 0.0;
    int probCount = 0;

    final Object? wordsRaw = decoded['words'];
    if (wordsRaw is List) {
      for (final Object? item in wordsRaw) {
        if (item is Map<String, Object?>) {
          final String? word = item['word'] as String?;
          final num? start = item['start'] as num?;
          final num? end = item['end'] as num?;
          final num? prob = item['probability'] as num?;

          if (word != null && word.isNotEmpty && start != null && end != null) {
            words.add(
              WordTimestamp(
                word: word.trim(),
                startSec: start.toDouble(),
                endSec: end.toDouble(),
              ),
            );
            if (prob != null) {
              totalProb += prob.toDouble();
              probCount++;
            }
          }
        }
      }
    }

    final double calculatedConfidence = probCount > 0
        ? (totalProb / probCount).clamp(0.0, 1.0)
        : 0.95;

    return SpeechResult(
      fullText: fullText,
      words: List<WordTimestamp>.unmodifiable(words),
      confidence: calculatedConfidence,
    );
  }

  /// Exposed for unit testing.
  @visibleForTesting
  static SpeechResult parseResponse(String jsonBody) =>
      _parseResponse(jsonBody);

  @override
  Future<void> dispose() async {
    _disposed = true;
    cancelAll();
  }
}
