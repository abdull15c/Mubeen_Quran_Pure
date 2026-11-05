import 'dart:convert';
import 'package:flutter/material.dart';

final class BookmarkFolder {
  const BookmarkFolder({
    required this.id,
    required this.name,
    required this.iconName,
    this.colorValue = 0xFFD4AF37,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorValue;

  IconData get icon {
    switch (iconName) {
      case 'brain':
        return Icons.psychology_rounded;
      case 'dua':
        return Icons.volunteer_activism_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'favorite':
      default:
        return Icons.bookmark_rounded;
    }
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'name': name,
    'icon_name': iconName,
    'color_value': colorValue,
  };

  factory BookmarkFolder.fromMap(Map<String, Object?> map) => BookmarkFolder(
    id: (map['id'] as String?) ?? 'folder',
    name: (map['name'] as String?) ?? 'Папка',
    iconName: (map['icon_name'] as String?) ?? 'favorite',
    colorValue: (map['color_value'] as int?) ?? 0xFFD4AF37,
  );
}

final class BookmarkEntry {
  const BookmarkEntry({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.folderId,
    this.note,
    required this.createdAt,
  });

  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String folderId;
  final String? note;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'ayah_id': ayahId,
    'surah_id': surahId,
    'ayah_number': ayahNumber,
    'folder_id': folderId,
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };

  factory BookmarkEntry.fromMap(Map<String, Object?> map) => BookmarkEntry(
    ayahId: (map['ayah_id'] as int?) ?? 1,
    surahId: (map['surah_id'] as int?) ?? 1,
    ayahNumber: (map['ayah_number'] as int?) ?? 1,
    folderId: (map['folder_id'] as String?) ?? 'favorites',
    note: map['note'] as String?,
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
}

const List<BookmarkFolder> kDefaultBookmarkFolders = <BookmarkFolder>[
  BookmarkFolder(
    id: 'favorites',
    name: 'Избранное',
    iconName: 'favorite',
    colorValue: 0xFFD4AF37,
  ),
  BookmarkFolder(
    id: 'hifz',
    name: 'На заучивание',
    iconName: 'brain',
    colorValue: 0xFF4CAF50,
  ),
  BookmarkFolder(
    id: 'duas',
    name: 'Дуа из Корана',
    iconName: 'dua',
    colorValue: 0xFF2196F3,
  ),
  BookmarkFolder(
    id: 'friday',
    name: 'Для пятницы',
    iconName: 'mosque',
    colorValue: 0xFF9C27B0,
  ),
];
