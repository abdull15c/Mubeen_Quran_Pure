import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/bookmarks/bookmark_models.dart';

void main() {
  group('Bookmark Models Tests', () {
    test(
      'BookmarkEntry serializes and deserializes correctly with notes and folders',
      () {
        final BookmarkEntry entry = BookmarkEntry(
          ayahId: 255,
          surahId: 2,
          ayahNumber: 255,
          folderId: 'hifz',
          note: 'Аят аль-Курси - заучить с таджвидом',
          createdAt: DateTime(2026, 8, 29),
        );

        final Map<String, Object?> map = entry.toMap();
        final BookmarkEntry fromMap = BookmarkEntry.fromMap(map);

        expect(fromMap.ayahId, 255);
        expect(fromMap.surahId, 2);
        expect(fromMap.folderId, 'hifz');
        expect(fromMap.note, 'Аят аль-Курси - заучить с таджвидом');
      },
    );

    test('Default bookmark folders contain essential categories', () {
      expect(kDefaultBookmarkFolders.length, 4);
      final List<String> ids = kDefaultBookmarkFolders
          .map((BookmarkFolder f) => f.id)
          .toList();
      expect(ids, contains('favorites'));
      expect(ids, contains('hifz'));
      expect(ids, contains('duas'));
      expect(ids, contains('friday'));
    });
  });
}
