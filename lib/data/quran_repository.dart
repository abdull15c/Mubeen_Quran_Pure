import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/quran_models.dart';
import '../search/semantic_search.dart';

const String _databaseAsset = 'assets/db/quran.db.gz';
const String _databaseFileName = 'quran_pure_v2.db';
const String _databaseContentVersion = '2';
const int _databaseSchemaVersion = 2;
const Map<String, String> _expectedContentMetadata = <String, String>{
  'schema_version': '2',
  'content_scope': 'quran_only',
  'ayah_count': '6236',
};

class QuranRepository {
  QuranRepository({SemanticSearch? semanticSearch})
    : _semanticSearch = semanticSearch ?? AssetSemanticSearch();

  static Future<void>? _preparingDatabase;

  final SemanticSearch _semanticSearch;
  Database? _database;
  Future<void>? _opening;
  Future<void>? _closing;

  Future<void> open() {
    final Future<void>? pendingClose = _closing;
    if (pendingClose != null) {
      return pendingClose.then((_) => open());
    }

    final Database? database = _database;
    if (database != null && database.isOpen) {
      return Future<void>.value();
    }

    final Future<void>? pendingOpen = _opening;
    if (pendingOpen != null) {
      return pendingOpen;
    }

    late final Future<void> opening;
    opening = _openDatabase().whenComplete(() {
      if (identical(_opening, opening)) {
        _opening = null;
      }
    });
    _opening = opening;
    return opening;
  }

  Future<void> close() {
    final Future<void>? pendingClose = _closing;
    if (pendingClose != null) {
      return pendingClose;
    }

    late final Future<void> closing;
    closing = _closeDatabase().whenComplete(() {
      if (identical(_closing, closing)) {
        _closing = null;
      }
    });
    _closing = closing;
    return closing;
  }

  Future<void> _closeDatabase() async {
    final Future<void>? pendingOpen = _opening;
    if (pendingOpen != null) {
      try {
        await pendingOpen;
      } on Object {
        // A failed open leaves no database to close.
      }
    }

    final Database? database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
    await _semanticSearch.close();
  }

  Future<List<Surah>> getSurahs() async {
    final Database database = _db;
    final List<Map<String, Object?>> rows = await database.rawQuery('''
      SELECT
        id,
        name_arabic,
        name_translit,
        name_russian,
        revelation_place,
        ayah_count,
        revelation_order,
        bismillah_pre
      FROM surahs
      ORDER BY id ASC
    ''');
    return List<Surah>.unmodifiable(rows.map(Surah.fromMap));
  }

  Future<Surah> getSurah(int id) async {
    final Database database = _db;
    _requirePositive(id, 'id');
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
        SELECT
          id,
          name_arabic,
          name_translit,
          name_russian,
          revelation_place,
          ayah_count,
          revelation_order,
          bismillah_pre
        FROM surahs
        WHERE id = ?
        LIMIT 1
      ''',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      throw StateError('Surah $id was not found in the Quran database.');
    }
    return Surah.fromMap(rows.single);
  }

  Future<List<QuranAyah>> getAyahsForSurah(
    int surahId,
    String translatorKey,
  ) async {
    final Database database = _db;
    _requirePositive(surahId, 'surahId');
    _requireTranslatorKey(translatorKey);

    // For API translations the bundled DB has no data, so we skip the JOIN
    // and let the caller merge cached translations from TranslationManager.
    final String effectiveKey = kBuiltInTranslatorKeys.contains(translatorKey)
        ? translatorKey
        : '';

    return _getAyahs(
      database: database,
      where: 'a.surah_id = ?',
      whereArguments: <Object?>[surahId],
      preferredTranslatorKey: effectiveKey,
    );
  }

  Future<List<QuranAyah>> getAyahsForPage(int page) async {
    final Database database = _db;
    _requirePositive(page, 'page');
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
        SELECT
          id,
          surah_id,
          number_in_surah,
          text_uthmani,
          juz,
          hizb,
          page,
          sajda
        FROM ayahs
        WHERE page = ?
        ORDER BY surah_id ASC, number_in_surah ASC, id ASC
      ''',
      <Object?>[page],
    );
    return List<QuranAyah>.unmodifiable(
      rows.map((Map<String, Object?> row) => QuranAyah.fromMap(row)),
    );
  }

  Future<int> getPageForSurah(int surahId) async {
    final Database database = _db;
    _requirePositive(surahId, 'surahId');
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
        SELECT page
        FROM ayahs
        WHERE surah_id = ?
        ORDER BY number_in_surah ASC
        LIMIT 1
      ''',
      <Object?>[surahId],
    );
    if (rows.isEmpty) {
      throw StateError('Surah $surahId has no Quran page.');
    }
    return rows.single['page']! as int;
  }

  Future<ReaderLocation> getFirstLocationForJuz(int juz) async {
    final Database database = _db;
    _requirePositive(juz, 'juz');
    return _getFirstLocation(database: database, column: 'juz', value: juz);
  }

  Future<ReaderLocation> getFirstLocationForPage(int page) async {
    final Database database = _db;
    _requirePositive(page, 'page');
    return _getFirstLocation(database: database, column: 'page', value: page);
  }

  Future<ReaderLocation> getFirstLocationForHizb(int hizb) async {
    final Database database = _db;
    _requirePositive(hizb, 'hizb');
    return _getFirstLocation(database: database, column: 'hizb', value: hizb);
  }

  Future<List<QuranSearchResult>> search(
    String query, {
    String? translatorKey,
    int limit = 80,
  }) async {
    final Database database = _db;
    if (translatorKey != null) {
      _requireTranslatorKey(translatorKey);
    }
    if (limit <= 0) {
      throw RangeError.range(limit, 1, null, 'limit');
    }

    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const <QuranSearchResult>[];
    }

    final RegExpMatch? reference = RegExp(
      r'^(?:сура\s*)?(\d{1,3})(?:\s*[:.,\-\s]\s*|\s+аят\s*)(\d{1,3})$',
      caseSensitive: false,
    ).firstMatch(trimmedQuery);
    if (reference != null) {
      final int surahId = int.parse(reference.group(1)!);
      final int ayahNumber = int.parse(reference.group(2)!);
      if (surahId >= 1 && surahId <= 114) {
        final List<QuranSearchResult> refResults = await _getAyahByReference(
          database,
          surahId,
          ayahNumber,
        );
        if (refResults.isNotEmpty) {
          return refResults;
        }
      }
      return const <QuranSearchResult>[];
    }

    final String? matchQuery = _buildFtsPrefixQuery(
      normalizeArabicForSearch(trimmedQuery),
    );
    if (matchQuery == null || !_containsLetter(trimmedQuery)) {
      return const <QuranSearchResult>[];
    }

    final Future<List<SemanticHit>> semanticFuture =
        _containsCyrillic(trimmedQuery)
        ? _semanticSearch
              .search(trimmedQuery, limit: 120)
              .catchError((Object _) => const <SemanticHit>[])
        : Future<List<SemanticHit>>.value(const <SemanticHit>[]);
    final List<QuranSearchResult> lexicalResults = await _searchLexical(
      database,
      matchQuery,
      translatorKey: translatorKey,
      limit: 160,
    );
    final List<SemanticHit> semanticResults = await semanticFuture;
    if (semanticResults.isEmpty) {
      return List<QuranSearchResult>.unmodifiable(lexicalResults.take(limit));
    }

    final List<int> semanticIds = semanticResults
        .map((SemanticHit hit) => hit.ayahId)
        .toList(growable: false);
    final List<QuranSearchResult> semanticAyahs = await _getSearchAyahsByIds(
      database,
      semanticIds,
      translatorKey: translatorKey ?? 'kuliev',
    );
    return _fuseSearchResults(lexicalResults, semanticAyahs, limit: limit);
  }

  Future<List<QuranSearchResult>> _searchLexical(
    Database database,
    String matchQuery, {
    required String? translatorKey,
    required int limit,
  }) async {
    final List<String> queryTokens = _searchTokens(matchQuery);
    final String translationFilter;
    final List<Object?> filterArgsBase = <Object?>[];
    if (translatorKey == null) {
      translationFilter = '';
    } else {
      translationFilter = '''
        AND (
          quran_search_fts.kind <> 'translation'
          OR quran_search_fts.source_key = ?
        )
      ''';
      filterArgsBase.add(translatorKey);
    }

    final String baseSelect = '''
      SELECT
        a.id AS ayah_id,
        a.surah_id AS surah_id,
        a.number_in_surah AS ayah_number,
        s.name_russian AS surah_name_russian,
        s.name_arabic AS surah_name_arabic,
        a.text_uthmani AS arabic_text,
        quran_search_fts.text AS match_text,
        quran_search_fts.kind AS kind,
        quran_search_fts.source_key AS source_key,
        a.page AS page
      FROM quran_search_fts
      INNER JOIN surahs AS s
        ON s.id = CAST(quran_search_fts.surah_id AS INTEGER)
      INNER JOIN ayahs AS a
        ON a.surah_id = s.id
       AND a.number_in_surah = CASE
         WHEN quran_search_fts.ayah_number IS NULL
           OR CAST(quran_search_fts.ayah_number AS INTEGER) < 1 THEN 1
         ELSE CAST(quran_search_fts.ayah_number AS INTEGER)
       END
    ''';

    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    final Set<int> seenRowIds = <int>{};

    // If multi-token, prioritize exact AND matches first
    if (queryTokens.length > 1) {
      final String andFtsQuery = queryTokens
          .map((String t) => '"${t.replaceAll('"', '""')}"*')
          .join(' ');
      final List<Map<String, Object?>> andRows = await database.rawQuery(
        '''
        $baseSelect
        WHERE quran_search_fts MATCH ?
          $translationFilter
        LIMIT 200
      ''',
        <Object?>[andFtsQuery, ...filterArgsBase],
      );
      for (final Map<String, Object?> row in andRows) {
        final int id = (row['ayah_id'] as num).toInt();
        seenRowIds.add(id);
        rows.add(row);
      }
    }

    // Then retrieve candidate matches (up to 500) for Dart ranking
    final List<Map<String, Object?>> orRows = await database.rawQuery(
      '''
      $baseSelect
      WHERE quran_search_fts MATCH ?
        $translationFilter
      LIMIT 500
    ''',
      <Object?>[matchQuery, ...filterArgsBase],
    );

    for (final Map<String, Object?> row in orRows) {
      final int id = (row['ayah_id'] as num).toInt();
      if (!seenRowIds.contains(id)) {
        seenRowIds.add(id);
        rows.add(row);
      }
    }

    return compute(_rankLexicalCandidates, <String, Object>{
      'rows': rows,
      'queryTokens': queryTokens,
      'limit': limit,
    }, debugLabel: 'quran-search-lexical-rank');
  }

  Future<String?> getTafsir(int surah, int ayah) async {
    final Database database = _db;
    _requirePositive(surah, 'surah');
    _requirePositive(ayah, 'ayah');
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
        SELECT text
        FROM tafsir_saadi
        WHERE sura = ? AND aya = ?
        LIMIT 1
      ''',
      <Object?>[surah, ayah],
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.single['text'] as String?;
  }

  Future<List<QuranWord>> getWords(int surah, int ayah) async {
    final Database database = _db;
    _requirePositive(surah, 'surah');
    _requirePositive(ayah, 'ayah');
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
        SELECT
          word_order,
          text_arabic,
          text_russian,
          root_arabic,
          lemma,
          pos
        FROM quran_wbw
        WHERE sura = ? AND ayah = ?
        ORDER BY word_order ASC
      ''',
      <Object?>[surah, ayah],
    );
    return List<QuranWord>.unmodifiable(rows.map(QuranWord.fromMap));
  }

  Future<List<ThematicTopic>> getThematicTopics() async {
    final Database database = _db;
    final List<Map<String, Object?>> rows = await database.rawQuery('''
      SELECT
        tt.id,
        tt.category,
        tt.title,
        tt.description,
        tt.icon_name,
        tt.sort_order,
        COUNT(ta.id) AS ayah_count
      FROM thematic_topics AS tt
      LEFT JOIN thematic_ayahs AS ta ON tt.id = ta.topic_id
      GROUP BY tt.id
      ORDER BY tt.sort_order ASC
    ''');
    return List<ThematicTopic>.unmodifiable(rows.map(ThematicTopic.fromMap));
  }

  Future<List<ThematicAyahItem>> getThematicAyahs(
    String topicId, {
    String translatorKey = 'kuliev',
  }) async {
    final Database database = _db;
    _requireTranslatorKey(translatorKey);
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
      SELECT
        a.id AS id,
        a.surah_id AS surah_id,
        a.number_in_surah AS number_in_surah,
        a.text_uthmani AS text_uthmani,
        a.text_normalized AS text_normalized,
        a.juz AS juz,
        a.hizb AS hizb,
        a.page AS page,
        a.sajda AS sajda,
        t.text AS translation,
        ta.note AS thematic_note
      FROM thematic_ayahs AS ta
      INNER JOIN ayahs AS a
        ON a.surah_id = ta.surah_id
       AND a.number_in_surah = ta.ayah_number
      LEFT JOIN translations AS t
        ON t.ayah_id = a.id
       AND t.translator_key = ?
      WHERE ta.topic_id = ?
      ORDER BY ta.sort_order ASC
      ''',
      <Object?>[translatorKey, topicId],
    );
    return List<ThematicAyahItem>.unmodifiable(
      rows.map((Map<String, Object?> row) {
        final String? translationText = row['translation'] as String?;
        final QuranAyah ayah = QuranAyah.fromMap(
          row,
          translations: translationText != null
              ? <String, String>{translatorKey: translationText}
              : const <String, String>{},
        );
        final String? note = row['thematic_note'] as String?;
        return ThematicAyahItem(ayah: ayah, note: note);
      }),
    );
  }

  Future<List<QuranSearchResult>> getAyahsBySurahAndNumbers(
    List<({int surahId, int ayahNumber, String matchText, String sourceKey})>
    items,
  ) async {
    final Database database = _db;
    final List<QuranSearchResult> results = <QuranSearchResult>[];
    for (final item in items) {
      final List<Map<String, Object?>> rows = await database.rawQuery(
        '''
        SELECT
          a.id AS ayah_id,
          a.surah_id AS surah_id,
          a.number_in_surah AS ayah_number,
          s.name_russian AS surah_name_russian,
          s.name_arabic AS surah_name_arabic,
          a.text_uthmani AS arabic_text,
          ? AS match_text,
          'translation' AS kind,
          ? AS source_key,
          a.page AS page
        FROM ayahs AS a
        INNER JOIN surahs AS s ON s.id = a.surah_id
        WHERE a.surah_id = ? AND a.number_in_surah = ?
        LIMIT 1
        ''',
        <Object?>[
          item.matchText,
          item.sourceKey,
          item.surahId,
          item.ayahNumber,
        ],
      );
      if (rows.isNotEmpty) {
        results.add(QuranSearchResult.fromMap(rows.first));
      }
    }
    return results;
  }

  Future<List<QuranSearchResult>> getAyahsByIds(Iterable<int> ayahIds) async {
    final Database database = _db;
    final List<int> orderedIds = <int>[];
    final Set<int> seenIds = <int>{};
    for (final int id in ayahIds) {
      _requirePositive(id, 'ayahIds');
      if (seenIds.add(id)) {
        orderedIds.add(id);
      }
    }
    if (orderedIds.isEmpty) {
      return const <QuranSearchResult>[];
    }

    const int chunkSize = 900;
    final Map<int, QuranSearchResult> resultsById = <int, QuranSearchResult>{};
    for (var start = 0; start < orderedIds.length; start += chunkSize) {
      final int end = start + chunkSize < orderedIds.length
          ? start + chunkSize
          : orderedIds.length;
      final List<int> chunk = orderedIds.sublist(start, end);
      final String placeholders = List<String>.filled(
        chunk.length,
        '?',
      ).join(',');
      final List<Map<String, Object?>> rows = await database.rawQuery('''
          SELECT
            a.id AS ayah_id,
            a.surah_id AS surah_id,
            a.number_in_surah AS ayah_number,
            s.name_russian AS surah_name_russian,
            s.name_arabic AS surah_name_arabic,
            a.text_uthmani AS arabic_text,
            a.text_uthmani AS match_text,
            'ayah' AS kind,
            'uthmani' AS source_key,
            a.page AS page
          FROM ayahs AS a
          INNER JOIN surahs AS s ON s.id = a.surah_id
          WHERE a.id IN ($placeholders)
          ORDER BY a.id ASC
        ''', chunk);
      for (final Map<String, Object?> row in rows) {
        final QuranSearchResult result = QuranSearchResult.fromMap(row);
        resultsById[result.ayahId] = result;
      }
    }

    return List<QuranSearchResult>.unmodifiable(
      orderedIds
          .map((int id) => resultsById[id])
          .whereType<QuranSearchResult>(),
    );
  }

  Future<List<QuranSearchResult>> _getSearchAyahsByIds(
    Database database,
    List<int> orderedIds, {
    required String translatorKey,
  }) async {
    if (orderedIds.isEmpty) return const <QuranSearchResult>[];
    final Map<int, QuranSearchResult> resultsById = <int, QuranSearchResult>{};
    const int chunkSize = 900;
    for (var start = 0; start < orderedIds.length; start += chunkSize) {
      final int end = start + chunkSize < orderedIds.length
          ? start + chunkSize
          : orderedIds.length;
      final List<int> chunk = orderedIds.sublist(start, end);
      final String placeholders = List<String>.filled(
        chunk.length,
        '?',
      ).join(',');
      final List<Map<String, Object?>> rows = await database.rawQuery(
        '''
          SELECT
            a.id AS ayah_id,
            a.surah_id AS surah_id,
            a.number_in_surah AS ayah_number,
            s.name_russian AS surah_name_russian,
            s.name_arabic AS surah_name_arabic,
            a.text_uthmani AS arabic_text,
            COALESCE(t.text, a.text_uthmani) AS match_text,
            'semantic' AS kind,
            ? AS source_key,
            a.page AS page
          FROM ayahs AS a
          INNER JOIN surahs AS s ON s.id = a.surah_id
          LEFT JOIN translations AS t
            ON t.ayah_id = a.id
           AND t.translator_key = ?
          WHERE a.id IN ($placeholders)
        ''',
        <Object?>[translatorKey, translatorKey, ...chunk],
      );
      for (final Map<String, Object?> row in rows) {
        final QuranSearchResult result = QuranSearchResult.fromMap(row);
        resultsById[result.ayahId] = result;
      }
    }
    return List<QuranSearchResult>.unmodifiable(
      orderedIds
          .map((int id) => resultsById[id])
          .whereType<QuranSearchResult>(),
    );
  }

  Database get _db {
    final Database? database = _database;
    if (database == null || !database.isOpen) {
      throw StateError(
        'QuranRepository is not open. Call open() before querying it.',
      );
    }
    return database;
  }

  Future<Directory> _databaseDirectory() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      return getApplicationCacheDirectory();
    }
    return getApplicationSupportDirectory();
  }

  Future<void> _openDatabase() async {
    final Directory directory = await _databaseDirectory();
    final String databasePath = path.join(directory.path, _databaseFileName);
    final File databaseFile = File(databasePath);

    await _prepareDatabase(databaseFile);

    final Database database = await openDatabase(
      databasePath,
      readOnly: true,
      singleInstance: false,
    );
    try {
      if (!await _hasExpectedContent(database)) {
        throw StateError(
          'The installed Quran database has an unexpected content version.',
        );
      }
    } on Object {
      await database.close();
      rethrow;
    }
    _database = database;
  }

  Future<void> _prepareDatabase(File databaseFile) async {
    final Future<void>? pendingPreparation = _preparingDatabase;
    if (pendingPreparation != null) {
      return pendingPreparation;
    }

    late final Future<void> preparation;
    preparation = _installDatabaseIfNeeded(databaseFile).whenComplete(() {
      if (identical(_preparingDatabase, preparation)) {
        _preparingDatabase = null;
      }
    });
    _preparingDatabase = preparation;
    return preparation;
  }

  Future<void> _installDatabaseIfNeeded(File databaseFile) async {
    if (await _fileHasExpectedContent(databaseFile)) {
      return;
    }

    await _installDatabase(databaseFile);
    if (!await _fileHasExpectedContent(databaseFile)) {
      throw const FormatException(
        'The Quran database asset has an unexpected content version.',
      );
    }
  }

  Future<bool> _fileHasExpectedContent(File databaseFile) async {
    if (!await _hasSqliteHeader(databaseFile)) {
      return false;
    }

    Database? database;
    try {
      database = await openDatabase(
        databaseFile.path,
        readOnly: true,
        singleInstance: false,
      );
      return await _hasExpectedContent(database);
    } on Object {
      return false;
    } finally {
      if (database != null && database.isOpen) {
        await database.close();
      }
    }
  }

  Future<bool> _hasExpectedContent(Database database) async {
    try {
      final List<Map<String, Object?>> metadataRows = await database.rawQuery(
        '''
          SELECT key, value
          FROM content_metadata
        ''',
      );
      final Map<String, String> metadata = <String, String>{
        for (final Map<String, Object?> row in metadataRows)
          if (row['key'] is String && row['value'] is String)
            row['key']! as String: row['value']! as String,
      };
      final List<Map<String, Object?>> versionRows = await database.rawQuery(
        'PRAGMA user_version',
      );
      final Object? schemaVersion = versionRows.single['user_version'];
      final String? contentVersion =
          metadata['content_version'] ?? metadata['schema_version'];

      return schemaVersion == _databaseSchemaVersion &&
          contentVersion == _databaseContentVersion &&
          _expectedContentMetadata.entries.every(
            (MapEntry<String, String> entry) =>
                metadata[entry.key] == entry.value,
          );
    } on Object {
      return false;
    }
  }

  Future<void> _installDatabase(File destination) async {
    final ByteData assetData = await rootBundle.load(_databaseAsset);
    final Uint8List compressedBytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );
    final File compressed = File('${destination.path}.gz.tmp');
    final File temporary = File('${destination.path}.tmp');
    if (await compressed.exists()) {
      await compressed.delete();
    }
    if (await temporary.exists()) {
      await temporary.delete();
    }
    try {
      await compressed.writeAsBytes(compressedBytes, flush: true);
      await compute(_decodeGzipFile, (
        compressed.path,
        temporary.path,
      ), debugLabel: 'quran-database-gzip');
      if (!await _hasSqliteHeader(temporary)) {
        throw const FormatException(
          'The decompressed Quran asset is not a SQLite database.',
        );
      }
      if (await destination.exists()) {
        await destination.delete();
      }
      await temporary.rename(destination.path);
    } finally {
      if (await compressed.exists()) {
        await compressed.delete();
      }
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<List<QuranAyah>> _getAyahs({
    required Database database,
    required String where,
    required List<Object?> whereArguments,
    required String preferredTranslatorKey,
  }) async {
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
        SELECT
          a.id,
          a.surah_id,
          a.number_in_surah,
          a.text_uthmani,
          a.juz,
          a.hizb,
          a.page,
          a.sajda,
          t.translator_key,
          t.text AS translation_text
        FROM ayahs AS a
        LEFT JOIN translations AS t
          ON t.ayah_id = a.id
         AND t.translator_key IN (${kBuiltInTranslatorKeys.map((k) => "'$k'").join(',')})
        WHERE $where
        ORDER BY
          a.surah_id ASC,
          a.number_in_surah ASC,
          a.id ASC,
          CASE WHEN t.translator_key = ? THEN 0 ELSE 1 END ASC,
          t.translator_key ASC
      ''',
      <Object?>[...whereArguments, preferredTranslatorKey],
    );

    final Map<int, _AyahAccumulator> ayahs = <int, _AyahAccumulator>{};
    for (final Map<String, Object?> row in rows) {
      final int id = row['id']! as int;
      final _AyahAccumulator accumulator = ayahs.putIfAbsent(
        id,
        () => _AyahAccumulator(row),
      );
      final Object? translatorKey = row['translator_key'];
      final Object? translationText = row['translation_text'];
      if (translatorKey is String && translationText is String) {
        accumulator.translations[translatorKey] = translationText;
      }
    }

    return List<QuranAyah>.unmodifiable(
      ayahs.values.map((_AyahAccumulator value) => value.toModel()),
    );
  }

  Future<ReaderLocation> _getFirstLocation({
    required Database database,
    required String column,
    required int value,
  }) async {
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
        SELECT
          surah_id,
          number_in_surah AS ayah_number,
          page
        FROM ayahs
        WHERE $column = ?
        ORDER BY surah_id ASC, number_in_surah ASC, id ASC
        LIMIT 1
      ''',
      <Object?>[value],
    );
    if (rows.isEmpty) {
      throw StateError('No Quran location exists for $column $value.');
    }
    return ReaderLocation.fromMap(rows.single);
  }

  Future<List<QuranSearchResult>> _getAyahByReference(
    Database database,
    int surahId,
    int ayahNumber,
  ) async {
    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
        SELECT
          a.id AS ayah_id,
          a.surah_id AS surah_id,
          a.number_in_surah AS ayah_number,
          s.name_russian AS surah_name_russian,
          s.name_arabic AS surah_name_arabic,
          a.text_uthmani AS arabic_text,
          a.text_uthmani AS match_text,
          'ayah' AS kind,
          'uthmani' AS source_key,
          a.page AS page
        FROM ayahs AS a
        INNER JOIN surahs AS s ON s.id = a.surah_id
        WHERE a.surah_id = ? AND a.number_in_surah = ?
        LIMIT 1
      ''',
      <Object?>[surahId, ayahNumber],
    );
    return List<QuranSearchResult>.unmodifiable(
      rows.map(QuranSearchResult.fromMap),
    );
  }
}

final class _AyahAccumulator {
  _AyahAccumulator(this.row);

  final Map<String, Object?> row;
  final Map<String, String> translations = <String, String>{};

  QuranAyah toModel() {
    return QuranAyah.fromMap(row, translations: translations);
  }
}

void _decodeGzipFile((String, String) paths) {
  final InputFileStream input = InputFileStream(paths.$1);
  final OutputFileStream output = OutputFileStream(paths.$2);
  try {
    final bool decoded = const GZipDecoder().decodeStream(
      input,
      output,
      verify: true,
    );
    if (!decoded) {
      throw const FormatException('Unable to decode the Quran database asset.');
    }
  } finally {
    input.closeSync();
    output.closeSync();
  }
}

Future<bool> _hasSqliteHeader(File file) async {
  if (!await file.exists() || await file.length() < 16) {
    return false;
  }

  final RandomAccessFile reader = await file.open();
  try {
    return _bytesHaveSqliteHeader(await reader.read(16));
  } finally {
    await reader.close();
  }
}

bool _bytesHaveSqliteHeader(List<int> bytes) {
  const List<int> header = <int>[
    0x53,
    0x51,
    0x4c,
    0x69,
    0x74,
    0x65,
    0x20,
    0x66,
    0x6f,
    0x72,
    0x6d,
    0x61,
    0x74,
    0x20,
    0x33,
    0x00,
  ];
  if (bytes.length < header.length) {
    return false;
  }
  for (var index = 0; index < header.length; index++) {
    if (bytes[index] != header[index]) {
      return false;
    }
  }
  return true;
}

@visibleForTesting
String normalizeArabicForSearch(String value) {
  final String withAlif = value.replaceAll('\u0670', 'ا');
  final String withoutMarks = withAlif.replaceAll(
    RegExp(r'[\u0610-\u061a\u064b-\u065f\u06d6-\u06ed\u08d3-\u08ff]'),
    '',
  );
  const Map<String, String> replacements = <String, String>{
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ٱ': 'ا',
    'ى': 'ي',
    'ؤ': 'و',
    'ئ': 'ي',
    'ـ': '',
    'ё': 'е',
    'Ё': 'е',
  };
  final StringBuffer normalized = StringBuffer();
  for (final int rune in withoutMarks.runes) {
    final String character = String.fromCharCode(rune);
    normalized.write(replacements[character] ?? character);
  }
  return normalized.toString().trim().split(RegExp(r'\s+')).join(' ');
}

const Set<String> _stopwords = <String>{
  'в',
  'и',
  'к',
  'с',
  'у',
  'о',
  'а',
  'на',
  'по',
  'за',
  'из',
  'от',
  'до',
};

String? _buildFtsPrefixQuery(String query) {
  final List<String> rawTokens = RegExp(
    r'[\p{L}\p{M}\p{N}]+',
    unicode: true,
  ).allMatches(query).map((RegExpMatch match) => match.group(0)!).toList();

  List<String> tokens = rawTokens;
  if (rawTokens.length > 1) {
    final List<String> filtered = rawTokens
        .where((String token) => !_stopwords.contains(token.toLowerCase()))
        .toList();
    if (filtered.isNotEmpty) {
      tokens = filtered;
    }
  }

  final List<String> prefixTerms = tokens
      .where((String token) => token.length >= 2)
      .map((String token) => '"${token.replaceAll('"', '""')}"*')
      .toList(growable: false);
  if (prefixTerms.isEmpty) {
    return null;
  }
  return prefixTerms.join(' OR ');
}

List<String> _searchTokens(String matchQuery) {
  return RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true)
      .allMatches(matchQuery)
      .map((RegExpMatch match) => match.group(0)!.toLowerCase())
      .where(
        (String token) => token != 'or' && token != 'and' && token != 'not',
      )
      .toList(growable: false);
}

int _lexicalCoverage(String text, List<String> queryTokens) {
  final String normalized = normalizeArabicForSearch(text).toLowerCase();
  var score = 0;
  for (final String token in queryTokens) {
    if (normalized.contains(token)) score++;
  }
  return score;
}

bool _containsLetter(String value) {
  return RegExp(r'\p{L}', unicode: true).hasMatch(value);
}

bool _containsCyrillic(String value) {
  return RegExp(r'[А-Яа-яЁё]').hasMatch(value);
}

List<QuranSearchResult> _fuseSearchResults(
  List<QuranSearchResult> lexicalResults,
  List<QuranSearchResult> semanticResults, {
  required int limit,
}) {
  final Map<int, QuranSearchResult> resultsById = <int, QuranSearchResult>{};
  final Map<int, double> scores = <int, double>{};
  for (var index = 0; index < lexicalResults.length; index++) {
    final QuranSearchResult result = lexicalResults[index];
    resultsById[result.ayahId] = result;
    scores.update(
      result.ayahId,
      (double score) => score + 1 / (60 + index + 1),
      ifAbsent: () => 1 / (60 + index + 1),
    );
  }
  for (var index = 0; index < semanticResults.length; index++) {
    final QuranSearchResult result = semanticResults[index];
    resultsById.putIfAbsent(result.ayahId, () => result);
    scores.update(
      result.ayahId,
      (double score) => score + 0.85 / (60 + index + 1),
      ifAbsent: () => 0.85 / (60 + index + 1),
    );
  }
  final List<QuranSearchResult> fused = resultsById.values.toList()
    ..sort((QuranSearchResult left, QuranSearchResult right) {
      final int scoreOrder = scores[right.ayahId]!.compareTo(
        scores[left.ayahId]!,
      );
      if (scoreOrder != 0) return scoreOrder;
      return left.ayahId.compareTo(right.ayahId);
    });
  return List<QuranSearchResult>.unmodifiable(fused.take(limit));
}

void _requirePositive(int value, String name) {
  if (value <= 0) {
    throw RangeError.range(value, 1, null, name);
  }
}

void _requireTranslatorKey(String translatorKey) {
  if (!kSupportedTranslatorKeys.contains(translatorKey)) {
    throw ArgumentError.value(
      translatorKey,
      'translatorKey',
      'Unknown translator key.',
    );
  }
}

List<QuranSearchResult> _rankLexicalCandidates(Map<String, Object> args) {
  final List<Map<String, Object?>> rows =
      args['rows']! as List<Map<String, Object?>>;
  final List<String> queryTokens = args['queryTokens']! as List<String>;
  final int limit = args['limit']! as int;

  final Map<int, _LexicalCandidate> candidates = <int, _LexicalCandidate>{};
  for (final Map<String, Object?> row in rows) {
    final QuranSearchResult result = QuranSearchResult.fromMap(row);
    final int score = _lexicalCoverage(result.matchText, queryTokens);
    final _LexicalCandidate? current = candidates[result.ayahId];
    if (current == null || score > current.score) {
      candidates[result.ayahId] = _LexicalCandidate(result, score);
    }
  }
  final List<_LexicalCandidate> ranked = candidates.values.toList()
    ..sort((_LexicalCandidate left, _LexicalCandidate right) {
      final int scoreOrder = right.score.compareTo(left.score);
      return scoreOrder != 0
          ? scoreOrder
          : left.result.ayahId.compareTo(right.result.ayahId);
    });
  final int minimumCoverage = queryTokens.length <= 1 ? 1 : 2;
  return List<QuranSearchResult>.unmodifiable(
    ranked
        .where((_LexicalCandidate item) => item.score >= minimumCoverage)
        .take(limit)
        .map((_LexicalCandidate item) => item.result),
  );
}

final class _LexicalCandidate {
  const _LexicalCandidate(this.result, this.score);

  final QuranSearchResult result;
  final int score;
}
