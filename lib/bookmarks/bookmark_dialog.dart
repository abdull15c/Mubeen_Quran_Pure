import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';
import '../models/quran_models.dart';
import '../theme/app_theme.dart';
import 'bookmark_controller.dart';
import 'bookmark_models.dart';

class BookmarkEditorSheet extends StatefulWidget {
  const BookmarkEditorSheet({
    super.key,
    required this.ayah,
    required this.surah,
    required this.bookmarkController,
  });

  final QuranAyah ayah;
  final Surah surah;
  final BookmarkController bookmarkController;

  static Future<void> show(
    BuildContext context, {
    required QuranAyah ayah,
    required Surah surah,
    required BookmarkController bookmarkController,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BookmarkEditorSheet(
          ayah: ayah,
          surah: surah,
          bookmarkController: bookmarkController,
        );
      },
    );
  }

  @override
  State<BookmarkEditorSheet> createState() => _BookmarkEditorSheetState();
}

class _BookmarkEditorSheetState extends State<BookmarkEditorSheet> {
  late String _selectedFolderId;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final BookmarkEntry? existing = widget.bookmarkController.getEntry(
      widget.ayah.id,
    );
    _selectedFolderId = existing?.folderId ?? 'favorites';
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact().ignore();
    widget.bookmarkController.saveBookmark(
      ayahId: widget.ayah.id,
      surahId: widget.ayah.surah,
      ayahNumber: widget.ayah.number,
      folderId: _selectedFolderId,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );
    Navigator.of(context).pop();
  }

  void _remove() {
    HapticFeedback.lightImpact().ignore();
    widget.bookmarkController.removeBookmark(widget.ayah.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool isBookmarked = widget.bookmarkController.isBookmarked(
      widget.ayah.id,
    );

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.quranColors.gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.bookmark_add_rounded,
                    color: Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.bookmarkTitle(widget.surah.id, widget.ayah.number),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isBookmarked)
                    IconButton(
                      tooltip: l.delete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: _remove,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l.folderCollection,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.bookmarkController.folders.map((
                  BookmarkFolder folder,
                ) {
                  final bool isSelected = _selectedFolderId == folder.id;
                  return ChoiceChip(
                    avatar: Icon(folder.icon, size: 16),
                    label: Text(folder.name),
                    selected: isSelected,
                    selectedColor: context.quranColors.gold,
                    onSelected: (bool sel) {
                      if (sel) setState(() => _selectedFolderId = folder.id);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                l.personalNote,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(hintText: l.personalNoteHint),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: context.quranColors.deepGreen,
                  foregroundColor: const Color(0xFFE3C47D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(isBookmarked ? l.saveChanges : l.addToBookmarks),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
