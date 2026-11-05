import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/data/quran_repository.dart';
import 'package:mubeen_quran_pure/search/semantic_search.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic search normalization matches indexed Quran forms', () {
    expect(normalizeArabicForSearch('ٱللَّهُ'), 'الله');
    expect(normalizeArabicForSearch('إِلَٰه'), 'الاه');
    expect(normalizeArabicForSearch('ٱهْدِنَا ٱلصِّرَٰطَ'), 'اهدنا الصراط');
    expect(normalizeArabicForSearch('عَلَىٰ'), 'عليا');
    expect(normalizeArabicForSearch('всё ещё'), 'все еще');
  });

  group('QuranRepository Unit Tests', () {
    late QuranRepository repository;
    late Directory supportDirectory;
    late _FakeQuranDatabasePlatform databasePlatform;

    setUp(() async {
      supportDirectory = await Directory.systemTemp.createTemp(
        'quran-repository-test-',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall call) async => switch (call.method) {
              'getApplicationSupportDirectory' ||
              'getApplicationCacheDirectory' => supportDirectory.path,
              final String method => throw UnsupportedError(
                'Unexpected path_provider call: $method',
              ),
            },
          );
      databasePlatform = _FakeQuranDatabasePlatform();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.tekartik.sqflite'),
            databasePlatform.handleMethodCall,
          );
      databaseFactoryOrNull ??= databaseFactorySqflitePlugin;
      repository = QuranRepository(
        semanticSearch: const _EmptySemanticSearch(),
      );
    });

    tearDown(() async {
      await repository.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.tekartik.sqflite'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      await supportDirectory.delete(recursive: true);
    });

    test('throws StateError when queries are executed before open()', () async {
      expect(() => repository.getSurahs(), throwsStateError);
      expect(() => repository.getSurah(1), throwsStateError);
      expect(() => repository.getAyahsForSurah(1, 'kuliev'), throwsStateError);
      expect(() => repository.getAyahsForPage(1), throwsStateError);
      expect(() => repository.getPageForSurah(1), throwsStateError);
      expect(() => repository.getFirstLocationForPage(1), throwsStateError);
      expect(() => repository.getFirstLocationForJuz(1), throwsStateError);
      expect(() => repository.getFirstLocationForHizb(1), throwsStateError);
      expect(() => repository.search('2:255'), throwsStateError);
      expect(() => repository.getTafsir(1, 1), throwsStateError);
      expect(() => repository.getWords(1, 1), throwsStateError);
      expect(() => repository.getAyahsByIds(<int>[1]), throwsStateError);
    });

    test('close() does not crash on an uninitialized repository', () async {
      await repository.close();
    });

    test('reuses an installed database with the expected revision', () async {
      final File installedDatabase = File(
        path.join(supportDirectory.path, 'quran_pure_v2.db'),
      );
      await installedDatabase.writeAsBytes(_sqliteHeader);
      databasePlatform.addDatabase(
        installedDatabase.path,
        userVersion: 2,
        metadata: _expectedMetadata,
      );

      await repository.open();

      expect(databasePlatform.openCount, equals(2));
      expect(await installedDatabase.readAsBytes(), equals(_sqliteHeader));
    });

    test('accepts the shipped revision metadata fallback', () async {
      final File installedDatabase = File(
        path.join(supportDirectory.path, 'quran_pure_v2.db'),
      );
      await installedDatabase.writeAsBytes(_sqliteHeader);
      databasePlatform.addDatabase(
        installedDatabase.path,
        userVersion: 2,
        metadata: <String, String>{
          'schema_version': '2',
          'content_scope': 'quran_only',
          'ayah_count': '6236',
        },
      );

      await repository.open();

      expect(databasePlatform.openCount, equals(2));
      expect(databasePlatform.installedAsset, isFalse);
    });

    test('reinstalls when the installed content revision is stale', () async {
      final File installedDatabase = File(
        path.join(supportDirectory.path, 'quran_pure_v2.db'),
      );
      await installedDatabase.writeAsBytes(_sqliteHeader);
      databasePlatform.addDatabase(
        installedDatabase.path,
        userVersion: 2,
        metadata: <String, String>{
          ..._expectedMetadata,
          'content_version': '1',
        },
      );

      await repository.open();

      expect(databasePlatform.openCount, equals(3));
      expect(databasePlatform.installedAsset, isTrue);
      expect(
        databasePlatform.databaseFor(installedDatabase.path).metadata,
        equals(_expectedMetadata),
      );
    });

    test('reinstalls when the installed user_version is stale', () async {
      final File installedDatabase = File(
        path.join(supportDirectory.path, 'quran_pure_v2.db'),
      );
      await installedDatabase.writeAsBytes(_sqliteHeader);
      databasePlatform.addDatabase(
        installedDatabase.path,
        userVersion: 1,
        metadata: _expectedMetadata,
      );

      await repository.open();

      expect(databasePlatform.openCount, equals(3));
      expect(databasePlatform.installedAsset, isTrue);
      expect(
        databasePlatform.databaseFor(installedDatabase.path).userVersion,
        equals(2),
      );
    });

    test('Arabic search query normalization matches built content', () async {
      final File installedDatabase = File(
        path.join(supportDirectory.path, 'quran_pure_v2.db'),
      );
      await installedDatabase.writeAsBytes(_sqliteHeader);
      databasePlatform.addDatabase(
        installedDatabase.path,
        userVersion: 2,
        metadata: _expectedMetadata,
      );
      await repository.open();

      await repository.search('آل إِمْرَان');

      expect(databasePlatform.lastSearchQuery, equals('"ال"* OR "امران"*'));
    });

    test(
      'multi-word search filters Russian stopwords like "в", "и", "на"',
      () async {
        final File installedDatabase = File(
          path.join(supportDirectory.path, 'quran_pure_v2.db'),
        );
        await installedDatabase.writeAsBytes(_sqliteHeader);
        databasePlatform.addDatabase(
          installedDatabase.path,
          userVersion: 2,
          metadata: _expectedMetadata,
        );
        await repository.open();

        await repository.search('деньги в долг');
        expect(
          databasePlatform.lastSearchQuery,
          equals('"деньги"* OR "долг"*'),
        );

        await repository.search('тяжело на душе');
        expect(
          databasePlatform.lastSearchQuery,
          equals('"тяжело"* OR "душе"*'),
        );
      },
    );

    test('invalid Quran reference does not fall through to FTS', () async {
      final File installedDatabase = File(
        path.join(supportDirectory.path, 'quran_pure_v2.db'),
      );
      await installedDatabase.writeAsBytes(_sqliteHeader);
      databasePlatform.addDatabase(
        installedDatabase.path,
        userVersion: 2,
        metadata: _expectedMetadata,
      );
      await repository.open();

      expect(await repository.search('2:999'), isEmpty);
      expect(databasePlatform.lastSearchQuery, isNull);
    });
  });
}

final class _EmptySemanticSearch implements SemanticSearch {
  const _EmptySemanticSearch();

  @override
  Future<List<SemanticHit>> search(String query, {int limit = 120}) async {
    return const <SemanticHit>[];
  }

  @override
  Future<void> close() async {}
}

const List<int> _sqliteHeader = <int>[
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

const Map<String, String> _expectedMetadata = <String, String>{
  'schema_version': '2',
  'content_version': '2',
  'content_scope': 'quran_only',
  'ayah_count': '6236',
};

final class _FakeQuranDatabasePlatform {
  final Map<String, _FakeDatabase> _databases = <String, _FakeDatabase>{};
  final Map<int, String> _pathsById = <int, String>{};
  var _nextId = 1;
  var openCount = 0;
  var installedAsset = false;
  String? lastSearchQuery;

  void addDatabase(
    String databasePath, {
    required int userVersion,
    required Map<String, String> metadata,
  }) {
    _databases[databasePath] = _FakeDatabase(
      userVersion: userVersion,
      metadata: Map<String, String>.from(metadata),
    );
  }

  _FakeDatabase databaseFor(String databasePath) => _databases[databasePath]!;

  Future<Object?> handleMethodCall(MethodCall call) async {
    final Map<Object?, Object?> arguments =
        call.arguments as Map<Object?, Object?>? ?? <Object?, Object?>{};
    switch (call.method) {
      case 'openDatabase':
        final String databasePath = arguments['path']! as String;
        openCount++;
        final _FakeDatabase? existingDatabase = _databases[databasePath];
        if (existingDatabase != null &&
            File(databasePath).lengthSync() > _sqliteHeader.length &&
            (existingDatabase.userVersion != 2 ||
                !_metadataMatches(existingDatabase.metadata))) {
          installedAsset = true;
          _databases[databasePath] = _FakeDatabase(
            userVersion: 2,
            metadata: Map<String, String>.from(_expectedMetadata),
          );
        }
        _databases.putIfAbsent(databasePath, () {
          installedAsset = true;
          return _FakeDatabase(
            userVersion: 2,
            metadata: Map<String, String>.from(_expectedMetadata),
          );
        });
        final int id = _nextId++;
        _pathsById[id] = databasePath;
        return <String, Object?>{'id': id};
      case 'query':
        final int id = arguments['id']! as int;
        final _FakeDatabase database = _databases[_pathsById[id]]!;
        final String sql = arguments['sql']! as String;
        if (sql.contains('FROM content_metadata')) {
          return <String, Object?>{
            'columns': <String>['key', 'value'],
            'rows': database.metadata.entries.map((
              MapEntry<String, String> entry,
            ) {
              return <Object?>[entry.key, entry.value];
            }).toList(),
          };
        }
        if (sql.trim() == 'PRAGMA user_version') {
          return <String, Object?>{
            'columns': <String>['user_version'],
            'rows': <List<Object?>>[
              <Object?>[database.userVersion],
            ],
          };
        }
        if (sql.contains('WHERE a.surah_id = ? AND a.number_in_surah = ?')) {
          return <String, Object?>{
            'columns': <String>[],
            'rows': <List<Object?>>[],
          };
        }
        if (sql.contains('FROM quran_search_fts')) {
          final List<Object?> queryArguments =
              (arguments['arguments'] as List<Object?>?) ?? <Object?>[];
          lastSearchQuery = queryArguments.first as String;
          return <String, Object?>{
            'columns': <String>[],
            'rows': <List<Object?>>[],
          };
        }
        throw UnsupportedError('Unexpected query: $sql');
      case 'closeDatabase':
        return null;
      default:
        throw UnsupportedError('Unexpected sqflite call: ${call.method}');
    }
  }

  bool _metadataMatches(Map<String, String> metadata) {
    final String? contentVersion =
        metadata['content_version'] ?? metadata['schema_version'];
    return contentVersion == '2' &&
        _expectedMetadata.entries.every(
          (MapEntry<String, String> entry) =>
              entry.key == 'content_version' ||
              metadata[entry.key] == entry.value,
        );
  }
}

final class _FakeDatabase {
  _FakeDatabase({required this.userVersion, required this.metadata});

  final int userVersion;
  final Map<String, String> metadata;
}
