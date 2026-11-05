import 'dart:convert';
import 'dart:io';

import '../models/quran_models.dart';

/// HTTP client for the Quran Foundation public API (api.qurancdn.com).
///
/// No OAuth2 is required — the translations endpoint is publicly accessible.
class QfApiService {
  QfApiService();

  static const String _baseUrl = 'https://api.qurancdn.com/api/qdc';
  static const String _quranComUrl = 'https://api.quran.com/api/v4';
  static const Duration _timeout = Duration(seconds: 15);

  HttpClient? _httpClient;

  HttpClient get _client =>
      _httpClient ??= HttpClient()..connectionTimeout = _timeout;

  /// Fetches all ayah translations for a given [surahId] using the QF
  /// [resourceId]. Returns a list of plain-text translations ordered by ayah
  /// number (1-based, matching surah ayah order).
  ///
  /// HTML footnote markup (`<sup>`) is stripped from the returned text.
  Future<List<String>> fetchSurahTranslation({
    required int resourceId,
    required int surahId,
  }) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/quran/translations/$resourceId'
      '?chapter_number=$surahId&per_page=300',
    );

    final HttpClientRequest request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final HttpClientResponse response = await request.close().timeout(_timeout);
    if (response.statusCode != 200) {
      await response.drain<void>();
      throw HttpException(
        'QF API returned ${response.statusCode} for '
        'resource $resourceId, surah $surahId.',
        uri: uri,
      );
    }

    final String body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_timeout);
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Unexpected QF API response format.');
    }

    final Object? translationsRaw = decoded['translations'];
    if (translationsRaw is! List) {
      throw const FormatException(
        'QF API response missing "translations" array.',
      );
    }

    return List<String>.unmodifiable(
      translationsRaw.map((Object? item) {
        if (item is! Map<String, Object?>) return '';
        final Object? text = item['text'];
        return text is String ? _stripHtml(text) : '';
      }),
    );
  }

  /// Fetches translations for a specific ayah range within a surah.
  /// Useful for Mushaf page mode where only a subset of ayahs is displayed.
  Future<Map<int, String>> fetchAyahTranslations({
    required int resourceId,
    required int surahId,
    required int fromAyah,
    required int toAyah,
  }) async {
    // The QF API doesn't support per-ayah filtering, so we fetch the whole
    // surah and pick the requested range.
    final List<String> all = await fetchSurahTranslation(
      resourceId: resourceId,
      surahId: surahId,
    );
    final Map<int, String> result = <int, String>{};
    for (int ayah = fromAyah; ayah <= toAyah && ayah <= all.length; ayah++) {
      result[ayah] = all[ayah - 1];
    }
    return result;
  }

  /// Fetches word-by-word timestamps for a specific surah and reciter.
  /// Returns a map of Ayah Number -> List of [WordTiming], representing the
  /// start and end time (in milliseconds) for each word in the ayah.
  Future<Map<int, List<WordTiming>>> fetchWordTimestamps({
    required int surahId,
    required int quranComReciterId,
  }) async {
    final Map<int, List<WordTiming>> result = <int, List<WordTiming>>{};
    int page = 1;

    while (true) {
      final Uri uri = Uri.parse(
        '$_quranComUrl/verses/by_chapter/$surahId'
        '?words=true&audio=$quranComReciterId&per_page=100&page=$page',
      );

      final HttpClientRequest request = await _client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final HttpClientResponse response = await request.close().timeout(
        _timeout,
      );
      if (response.statusCode != 200) {
        await response.drain<void>();
        throw HttpException(
          'Quran.com API returned ${response.statusCode} for '
          'surah $surahId, reciter $quranComReciterId.',
          uri: uri,
        );
      }

      final String body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException(
          'Unexpected Quran.com API response format.',
        );
      }

      final Object? versesRaw = decoded['verses'];
      if (versesRaw is! List || versesRaw.isEmpty) break;

      for (final Object? verseRow in versesRaw) {
        if (verseRow is! Map<String, Object?>) continue;

        final Object? ayahNum = verseRow['verse_number'];
        final Object? audioData = verseRow['audio'];
        final Object? wordsData = verseRow['words'];

        if (ayahNum is! int ||
            audioData is! Map<String, Object?> ||
            wordsData is! List) {
          continue;
        }

        final Object? segments = audioData['segments'];
        if (segments is! List) continue;

        // Extract actual words (skip end-of-ayah markers)
        final List<Map<String, Object?>> wordsOnly = wordsData
            .whereType<Map<String, Object?>>()
            .where((Map<String, Object?> w) => w['char_type_name'] == 'word')
            .toList();

        // Map segments by their word position to ensure exact 1-to-1 association
        final Map<int, WordTiming> segmentMap = <int, WordTiming>{};
        for (final Object? segRaw in segments) {
          if (segRaw is List && segRaw.length >= 4) {
            final int? segPos = segRaw[0] is num
                ? (segRaw[0] as num).toInt()
                : int.tryParse(segRaw[0].toString());
            final int startMs = segRaw[2] is num
                ? (segRaw[2] as num).toInt()
                : int.tryParse(segRaw[2].toString()) ?? 0;
            final int endMs = segRaw[3] is num
                ? (segRaw[3] as num).toInt()
                : int.tryParse(segRaw[3].toString()) ?? 0;
            if (segPos != null) {
              segmentMap[segPos] = WordTiming(startMs: startMs, endMs: endMs);
            }
          }
        }

        final List<WordTiming> timings = <WordTiming>[];

        for (int i = 0; i < wordsOnly.length; i++) {
          final Map<String, Object?> wordObj = wordsOnly[i];
          final int? position = wordObj['position'] is num
              ? (wordObj['position'] as num).toInt()
              : int.tryParse(wordObj['position']?.toString() ?? '');

          final WordTiming? timing =
              (position != null ? segmentMap[position] : null) ??
              segmentMap[i + 1] ??
              segmentMap[i];

          timings.add(timing ?? const WordTiming(startMs: 0, endMs: 0));
        }

        result[ayahNum] = timings;
      }

      final Object? pagination = decoded['pagination'];
      if (pagination is Map<String, Object?>) {
        final Object? currentPage = pagination['current_page'];
        final Object? totalPages = pagination['total_pages'];
        if (currentPage is int &&
            totalPages is int &&
            currentPage < totalPages) {
          page++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return result;
  }

  /// Returns the list of available translations from the QF API.
  /// This is mainly useful for discovery; the app uses a hardcoded registry.
  Future<List<Map<String, Object?>>> fetchAvailableTranslations() async {
    final Uri uri = Uri.parse('$_baseUrl/resources/translations');

    final HttpClientRequest request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final HttpClientResponse response = await request.close().timeout(_timeout);
    if (response.statusCode != 200) {
      await response.drain<void>();
      throw HttpException(
        'QF API returned ${response.statusCode} for translations list.',
        uri: uri,
      );
    }

    final String body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_timeout);
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Unexpected QF API response format.');
    }

    final Object? translations = decoded['translations'];
    if (translations is! List) {
      throw const FormatException(
        'QF API response missing "translations" array.',
      );
    }

    return List<Map<String, Object?>>.from(
      translations.whereType<Map<String, Object?>>(),
    );
  }

  /// Releases the underlying HTTP client.
  void dispose() {
    _httpClient?.close(force: true);
    _httpClient = null;
  }

  /// Strips HTML tags (e.g. `<sup foot_note=...>1</sup>`) from API text.
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<sup[^>]*>[^<]*</sup>'), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
