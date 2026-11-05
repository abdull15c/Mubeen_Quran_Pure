import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/quran_models.dart';
import 'qf_api_service.dart';

/// Manages downloading, caching, and deleting API-sourced Quran translations.
///
/// Downloaded translations are stored in a separate writable SQLite database
/// so that the read-only bundled Quran database remains untouched.
class TranslationManager extends ChangeNotifier {
  TranslationManager({QfApiService? apiService})
    : _apiService = apiService ?? QfApiService();

  static const String _dbFileName = 'translations_cache.db';

  final QfApiService _apiService;
  Database? _database;
  Future<void>? _opening;

  /// Keys of surahs currently being downloaded.  UI can check this to show
  /// a progress indicator.
  final Set<String> _downloading = <String>{};

  /// Returns a download key (translator + surah) if a download is in progress.
  bool isDownloading(String translatorKey, int surahId) =>
      _downloading.contains('$translatorKey:$surahId');

  /// Whether any download is in progress for the given translator.
  bool isAnyDownloading(String translatorKey) =>
      _downloading.any((String key) => key.startsWith('$translatorKey:'));

  // ---------------------------------------------------------------------------
  // Database lifecycle
  // ---------------------------------------------------------------------------

  Future<Database> _open() async {
    final Database? db = _database;
    if (db != null && db.isOpen) return db;

    if (_opening != null) {
      await _opening;
      return _database!;
    }

    late final Future<void> opening;
    opening = _initDatabase().whenComplete(() {
      if (identical(_opening, opening)) _opening = null;
    });
    _opening = opening;
    await opening;
    return _database!;
  }

  Future<void> _initDatabase() async {
    final String documentsDir = (await getApplicationSupportDirectory()).path;
    final String dbPath = path.join(documentsDir, _dbFileName);

    _database = await openDatabase(
      dbPath,
      version: 2,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_word_timings (
              reciter_id     INTEGER NOT NULL,
              surah_id       INTEGER NOT NULL,
              ayah_number    INTEGER NOT NULL,
              word_index     INTEGER NOT NULL,
              start_ms       INTEGER NOT NULL,
              end_ms         INTEGER NOT NULL,
              PRIMARY KEY (reciter_id, surah_id, ayah_number, word_index)
            )
          ''');
        }
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cached_translations (
            translator_key TEXT NOT NULL,
            surah_id       INTEGER NOT NULL,
            ayah_number    INTEGER NOT NULL,
            text           TEXT NOT NULL,
            PRIMARY KEY (translator_key, surah_id, ayah_number)
          )
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_cached_translations_key_surah
            ON cached_translations (translator_key, surah_id)
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cached_word_timings (
            reciter_id     INTEGER NOT NULL,
            surah_id       INTEGER NOT NULL,
            ayah_number    INTEGER NOT NULL,
            word_index     INTEGER NOT NULL,
            start_ms       INTEGER NOT NULL,
            end_ms         INTEGER NOT NULL,
            PRIMARY KEY (reciter_id, surah_id, ayah_number, word_index)
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    _apiService.dispose();
    if (_opening != null) {
      try {
        await _opening;
      } catch (_) {}
    }
    final Database? db = _database;
    _database = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Download
  // ---------------------------------------------------------------------------

  /// Downloads translation for a single surah and stores it in the cache DB.
  /// Validates that all expected ayahs are returned and writes transactionally.
  /// Returns `true` on success, `false` on failure.
  Future<bool> downloadSurahTranslation({
    required String translatorKey,
    required int surahId,
    int? expectedAyahs,
  }) async {
    final int expectedCount = expectedAyahs ?? getExpectedAyahCount(surahId);
    final String downloadKey = '$translatorKey:$surahId';
    if (_downloading.contains(downloadKey)) return false;

    final TranslationInfo? info = findTranslation(translatorKey);
    if (info == null || info.qfResourceId == null) return false;

    _downloading.add(downloadKey);
    notifyListeners();

    try {
      final List<String> texts = await _apiService.fetchSurahTranslation(
        resourceId: info.qfResourceId!,
        surahId: surahId,
      );

      if (texts.isEmpty ||
          (expectedCount > 0 && texts.length != expectedCount)) {
        debugPrint(
          'TranslationManager: validation failed for $translatorKey surah $surahId: '
          'got ${texts.length} ayahs, expected $expectedCount',
        );
        return false;
      }

      for (final String text in texts) {
        if (text.trim().isEmpty) {
          debugPrint(
            'TranslationManager: empty ayah found in translation for surah $surahId',
          );
          return false;
        }
      }

      final Database db = await _open();
      await db.transaction((Transaction txn) async {
        final Batch batch = txn.batch();
        for (int i = 0; i < texts.length; i++) {
          batch.insert('cached_translations', <String, Object>{
            'translator_key': translatorKey,
            'surah_id': surahId,
            'ayah_number': i + 1,
            'text': texts[i],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
      return true;
    } on Object catch (error) {
      debugPrint(
        'TranslationManager: failed to download '
        '$translatorKey surah $surahId: $error',
      );
      return false;
    } finally {
      _downloading.remove(downloadKey);
      notifyListeners();
    }
  }

  /// Downloads the entire translation (all 114 surahs) sequentially.
  /// Calls [onProgress] with (completed, total) after each surah.
  Future<bool> downloadFullTranslation({
    required String translatorKey,
    void Function(int completed, int total)? onProgress,
  }) async {
    for (int surah = 1; surah <= 114; surah++) {
      final bool ok = await downloadSurahTranslation(
        translatorKey: translatorKey,
        surahId: surah,
      );
      if (!ok) return false;
      onProgress?.call(surah, 114);
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns cached translations for [surahId] keyed by ayah number,
  /// or an empty map if nothing is cached.
  Future<Map<int, String>> getCachedTranslations({
    required String translatorKey,
    required int surahId,
  }) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        'cached_translations',
        columns: <String>['ayah_number', 'text'],
        where: 'translator_key = ? AND surah_id = ?',
        whereArgs: <Object>[translatorKey, surahId],
        orderBy: 'ayah_number ASC',
      );
      return <int, String>{
        for (final Map<String, Object?> row in rows)
          row['ayah_number']! as int: row['text']! as String,
      };
    } on Object {
      return const <int, String>{};
    }
  }

  /// Whether all ayahs for a surah have been cached for a given translator.
  Future<bool> isSurahCached({
    required String translatorKey,
    required int surahId,
    int? expectedAyahs,
  }) async {
    try {
      final int expected = expectedAyahs ?? getExpectedAyahCount(surahId);
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM cached_translations '
        'WHERE translator_key = ? AND surah_id = ?',
        <Object>[translatorKey, surahId],
      );
      final int count = (rows.first['cnt']! as int);
      return expected > 0 ? count >= expected : count > 0;
    } on Object {
      return false;
    }
  }

  /// Returns the number of surahs cached for a given translator.
  Future<int> cachedSurahCount(String translatorKey) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT COUNT(DISTINCT surah_id) AS cnt FROM cached_translations '
        'WHERE translator_key = ?',
        <Object>[translatorKey],
      );
      return rows.first['cnt']! as int;
    } on Object {
      return 0;
    }
  }

  /// Searches cached translations for matching ayahs.
  Future<List<({int surahId, int ayahNumber, String text})>>
  searchCachedTranslations({
    required String translatorKey,
    required String query,
    int limit = 50,
  }) async {
    final String cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.rawQuery(
        '''
        SELECT surah_id, ayah_number, text
        FROM cached_translations
        WHERE translator_key = ? AND text LIKE ?
        LIMIT ?
        ''',
        <Object>[translatorKey, '%$cleanQuery%', limit],
      );
      return rows
          .map(
            (Map<String, Object?> r) => (
              surahId: r['surah_id']! as int,
              ayahNumber: r['ayah_number']! as int,
              text: r['text']! as String,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Word Timings
  // ---------------------------------------------------------------------------

  /// Fetches and caches word timestamps for a specific surah and reciter.
  Future<Map<int, List<WordTiming>>> getOrFetchWordTimings({
    required int surahId,
    required int quranComReciterId,
  }) async {
    final Map<int, List<WordTiming>> cached = await _getCachedWordTimings(
      surahId: surahId,
      reciterId: quranComReciterId,
    );

    if (cached.isNotEmpty) {
      return cached;
    }

    try {
      final Map<int, List<WordTiming>> fetched = await _apiService
          .fetchWordTimestamps(
            surahId: surahId,
            quranComReciterId: quranComReciterId,
          );

      if (fetched.isNotEmpty) {
        await _saveWordTimings(surahId, quranComReciterId, fetched);
      }
      return fetched;
    } on Object catch (error) {
      debugPrint('TranslationManager: failed to fetch timings: $error');
      return const <int, List<WordTiming>>{};
    }
  }

  Future<Map<int, List<WordTiming>>> _getCachedWordTimings({
    required int surahId,
    required int reciterId,
  }) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        'cached_word_timings',
        where: 'reciter_id = ? AND surah_id = ?',
        whereArgs: <Object>[reciterId, surahId],
        orderBy: 'ayah_number ASC, word_index ASC',
      );

      final Map<int, List<WordTiming>> result = <int, List<WordTiming>>{};
      for (final Map<String, Object?> row in rows) {
        final int ayahNum = row['ayah_number']! as int;
        final int startMs = row['start_ms']! as int;
        final int endMs = row['end_ms']! as int;

        result
            .putIfAbsent(ayahNum, () => <WordTiming>[])
            .add(WordTiming(startMs: startMs, endMs: endMs));
      }
      return result;
    } on Object {
      return const <int, List<WordTiming>>{};
    }
  }

  Future<void> _saveWordTimings(
    int surahId,
    int reciterId,
    Map<int, List<WordTiming>> timings,
  ) async {
    try {
      final Database db = await _open();
      final Batch batch = db.batch();

      for (final MapEntry<int, List<WordTiming>> entry in timings.entries) {
        final int ayahNum = entry.key;
        final List<WordTiming> words = entry.value;

        for (int i = 0; i < words.length; i++) {
          final WordTiming t = words[i];
          batch.insert('cached_word_timings', <String, Object>{
            'reciter_id': reciterId,
            'surah_id': surahId,
            'ayah_number': ayahNum,
            'word_index': i,
            'start_ms': t.startMs,
            'end_ms': t.endMs,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: true);
    } on Object catch (error) {
      debugPrint('TranslationManager: failed to save timings: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  /// Deletes all cached ayahs for a given translator.
  Future<void> deleteTranslation(String translatorKey) async {
    try {
      final Database db = await _open();
      await db.delete(
        'cached_translations',
        where: 'translator_key = ?',
        whereArgs: <Object>[translatorKey],
      );
      notifyListeners();
    } on Object catch (error) {
      debugPrint('TranslationManager: failed to delete $translatorKey: $error');
    }
  }

  /// Deletes all cached translations.
  Future<void> deleteAll() async {
    try {
      final Database db = await _open();
      await db.delete('cached_translations');
      notifyListeners();
    } on Object catch (error) {
      debugPrint('TranslationManager: failed to delete all: $error');
    }
  }
}
