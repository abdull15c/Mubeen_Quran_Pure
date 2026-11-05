import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/bookmarks/bookmark_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookmarkController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'Corrupted entry JSON item does not wipe other valid bookmarks',
      () async {
        final List<Map<String, Object?>> validAndCorruptList = [
          {
            'ayah_id': 1,
            'surah_id': 1,
            'ayah_number': 1,
            'folder_id': 'favorites',
            'created_at': DateTime(2026, 1, 1).toIso8601String(),
          },
          {
            'ayah_id': 'invalid_id', // corrupt type
            'surah_id': 1,
          },
          {
            'ayah_id': 255,
            'surah_id': 2,
            'ayah_number': 255,
            'folder_id': 'hifz',
            'created_at': DateTime(2026, 1, 2).toIso8601String(),
          },
        ];

        SharedPreferences.setMockInitialValues(<String, Object>{
          'mubeen_bookmarks_entries_v1': jsonEncode(validAndCorruptList),
        });

        final BookmarkController controller = BookmarkController();
        await controller.ensureInitialized();

        expect(controller.isBookmarked(1), isTrue);
        expect(controller.isBookmarked(255), isTrue);
        expect(controller.entries.length, 2);
      },
    );

    test('Migrates legacy bookmarked_ayah_ids seamlessly', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bookmarked_ayah_ids': <String>['7', '42'],
        'mubeen_bookmarks': <String>['42', '100'],
      });

      final BookmarkController controller = BookmarkController();
      await controller.ensureInitialized();

      expect(controller.isBookmarked(7), isTrue);
      expect(controller.isBookmarked(42), isTrue);
      expect(controller.isBookmarked(100), isTrue);
      expect(controller.entries.length, 3);
    });

    test('Concurrent toggle operations do not lose state', () async {
      final BookmarkController controller = BookmarkController();
      await controller.ensureInitialized();

      await Future.wait([
        controller.saveBookmark(ayahId: 10, surahId: 1, ayahNumber: 10),
        controller.saveBookmark(ayahId: 20, surahId: 2, ayahNumber: 20),
        controller.saveBookmark(ayahId: 30, surahId: 2, ayahNumber: 30),
      ]);

      expect(controller.isBookmarked(10), isTrue);
      expect(controller.isBookmarked(20), isTrue);
      expect(controller.isBookmarked(30), isTrue);
      expect(controller.entries.length, 3);

      await controller.toggleBookmark(ayahId: 20, surahId: 2, ayahNumber: 20);
      expect(controller.isBookmarked(20), isFalse);
      expect(controller.isBookmarked(10), isTrue);
      expect(controller.isBookmarked(30), isTrue);
    });
  });
}
