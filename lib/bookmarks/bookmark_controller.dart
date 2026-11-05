import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bookmark_models.dart';

class BookmarkController extends ChangeNotifier {
  BookmarkController() {
    _initFuture = _load();
  }

  static const String _entriesStorageKey = 'mubeen_bookmarks_entries_v1';
  static const String _customFoldersKey = 'mubeen_bookmarks_folders_v1';
  static const String _legacyBookmarksKey = 'mubeen_bookmarks';
  static const String _legacyAyahIdsKey = 'bookmarked_ayah_ids';

  late final Future<void> _initFuture;
  final Map<int, BookmarkEntry> _entries = <int, BookmarkEntry>{};
  final List<BookmarkFolder> _folders = List<BookmarkFolder>.from(
    kDefaultBookmarkFolders,
  );
  bool _initialized = false;
  Future<void>? _persistLock;

  Map<int, BookmarkEntry> get entries =>
      Map<int, BookmarkEntry>.unmodifiable(_entries);
  List<BookmarkFolder> get folders =>
      List<BookmarkFolder>.unmodifiable(_folders);
  bool get initialized => _initialized;

  Future<void> ensureInitialized() => _initFuture;

  bool isBookmarked(int ayahId) => _entries.containsKey(ayahId);

  BookmarkEntry? getEntry(int ayahId) => _entries[ayahId];

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. Safely load custom folders without clearing on initial failure
      final String? foldersJson = prefs.getString(_customFoldersKey);
      if (foldersJson != null && foldersJson.isNotEmpty) {
        try {
          final Object? decoded = jsonDecode(foldersJson);
          if (decoded is List) {
            final List<BookmarkFolder> loadedFolders = <BookmarkFolder>[];
            for (final dynamic m in decoded) {
              if (m is Map<String, Object?>) {
                try {
                  loadedFolders.add(BookmarkFolder.fromMap(m));
                } catch (e) {
                  debugPrint('BookmarkController: skipping invalid folder: $e');
                }
              }
            }
            if (loadedFolders.isNotEmpty) {
              _folders.clear();
              _folders.addAll(loadedFolders);
            }
          }
        } catch (e) {
          debugPrint('BookmarkController: error decoding folders JSON: $e');
        }
      }

      // 2. Safely load entries into an isolated temporary map
      final Map<int, BookmarkEntry> loadedEntries = <int, BookmarkEntry>{};
      final String? entriesJson = prefs.getString(_entriesStorageKey);
      if (entriesJson != null && entriesJson.isNotEmpty) {
        try {
          final Object? decoded = jsonDecode(entriesJson);
          if (decoded is List) {
            for (final dynamic item in decoded) {
              if (item is Map<String, Object?>) {
                try {
                  final BookmarkEntry entry = BookmarkEntry.fromMap(item);
                  loadedEntries[entry.ayahId] = entry;
                } catch (e) {
                  debugPrint('BookmarkController: skipping invalid entry: $e');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('BookmarkController: error decoding entries JSON: $e');
        }
      }

      // 3. Fallback and Migration: scan legacy keys without data loss
      final List<String>? legacyList1 = prefs.getStringList(
        _legacyBookmarksKey,
      );
      final List<String>? legacyList2 =
          prefs.getStringList(_legacyAyahIdsKey) ??
          (prefs.get(_legacyAyahIdsKey) is List
              ? (prefs.get(_legacyAyahIdsKey) as List)
                    .map((dynamic e) => e.toString())
                    .toList()
              : null);

      final Set<String> legacyIds = <String>{...?legacyList1, ...?legacyList2};

      for (final String idStr in legacyIds) {
        final int? id = int.tryParse(idStr);
        if (id != null &&
            id >= 1 &&
            id <= 6236 &&
            !loadedEntries.containsKey(id)) {
          loadedEntries[id] = BookmarkEntry(
            ayahId: id,
            surahId: 1,
            ayahNumber: 1,
            folderId: 'favorites',
            createdAt: DateTime.now(),
          );
        }
      }

      _entries.clear();
      _entries.addAll(loadedEntries);
    } catch (e) {
      debugPrint('BookmarkController: error during _load: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> saveBookmark({
    required int ayahId,
    required int surahId,
    required int ayahNumber,
    String folderId = 'favorites',
    String? note,
  }) async {
    await _initFuture;
    _entries[ayahId] = BookmarkEntry(
      ayahId: ayahId,
      surahId: surahId,
      ayahNumber: ayahNumber,
      folderId: folderId,
      note: note,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> removeBookmark(int ayahId) async {
    await _initFuture;
    _entries.remove(ayahId);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleBookmark({
    required int ayahId,
    required int surahId,
    required int ayahNumber,
    String folderId = 'favorites',
    String? note,
  }) async {
    await _initFuture;
    if (_entries.containsKey(ayahId)) {
      await removeBookmark(ayahId);
    } else {
      await saveBookmark(
        ayahId: ayahId,
        surahId: surahId,
        ayahNumber: ayahNumber,
        folderId: folderId,
        note: note,
      );
    }
  }

  Future<void> createFolder({
    required String name,
    required String iconName,
    int colorValue = 0xFFD4AF37,
  }) async {
    await _initFuture;
    final BookmarkFolder folder = BookmarkFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      iconName: iconName,
      colorValue: colorValue,
    );
    _folders.add(folder);
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, Object?>> maps = _folders
          .map((BookmarkFolder f) => f.toMap())
          .toList();
      await prefs.setString(_customFoldersKey, jsonEncode(maps));
    } catch (e) {
      debugPrint('BookmarkController: error creating folder: $e');
    }
  }

  /// Serialized write lock to prevent race conditions during rapid bookmark toggling.
  Future<void> _persist() async {
    final Future<void>? previous = _persistLock;
    final Completer<void> completer = Completer<void>();
    _persistLock = completer.future;
    try {
      if (previous != null) {
        await previous;
      }
      await _persistInternal();
    } finally {
      completer.complete();
      if (identical(_persistLock, completer.future)) {
        _persistLock = null;
      }
    }
  }

  Future<void> _persistInternal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, Object?>> maps = _entries.values
          .map((BookmarkEntry e) => e.toMap())
          .toList();
      await prefs.setString(_entriesStorageKey, jsonEncode(maps));

      final List<String> legacyIds = (_entries.keys.toList()..sort())
          .map((int id) => id.toString())
          .toList();
      await prefs.setStringList(_legacyBookmarksKey, legacyIds);
      await prefs.setStringList(_legacyAyahIdsKey, legacyIds);
    } catch (e) {
      debugPrint('BookmarkController: error in _persistInternal: $e');
    }
  }
}
