import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../../audio/quran_audio_models.dart';
import '../../audio/quran_audio_service.dart';
import '../../bookmarks/bookmark_controller.dart';
import '../../bookmarks/bookmark_dialog.dart';
import '../../controllers/app_controller.dart';
import '../../data/quran_repository.dart';
import '../../data/translation_manager.dart';
import '../../models/quran_models.dart';
import '../../theme/app_theme.dart';
import '../recitation_trainer_sheet.dart';
import 'quran_text.dart';
import 'reader_widgets.dart';

class AyahCard extends StatelessWidget {
  const AyahCard({
    super.key,
    required this.ayah,
    required this.surah,
    required this.controller,
    required this.repository,
    required this.audioService,
    required this.translationManager,
    required this.bookmarkController,
    required this.totalAyahsInSurah,
  });

  final QuranAyah ayah;
  final Surah surah;
  final AppController controller;
  final QuranRepository repository;
  final QuranAudioService audioService;
  final TranslationManager translationManager;
  final BookmarkController bookmarkController;
  final int totalAyahsInSurah;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        audioService,
        bookmarkController,
      ]),
      builder: (BuildContext context, _) {
        final bool isCurrentAyah = audioService.isAyahActive(
          ayah.surah,
          ayah.number,
        );
        final bool isPlayingThisAyah = isCurrentAyah && audioService.isPlaying;
        final String? translation = ayah.translations[controller.translatorKey];
        final bool bookmarked = bookmarkController.isBookmarked(ayah.id);

        final List<Widget> actions = <Widget>[
          IconButton(
            tooltip: isPlayingThisAyah ? l.pause : l.listenAyah,
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              HapticFeedback.lightImpact().ignore();
              if (isPlayingThisAyah) {
                audioService.pause();
              } else if (isCurrentAyah) {
                audioService.resume();
              } else {
                audioService.playAyah(
                  ayah.surah,
                  ayah.number,
                  totalAyahsInSurah: totalAyahsInSurah,
                );
                final Reciter requestedReciter = audioService.currentReciter;
                final int? apiReciterId = requestedReciter.quranComReciterId;
                if (apiReciterId != null) {
                  final Map<int, List<WordTiming>> timings =
                      await translationManager.getOrFetchWordTimings(
                        surahId: ayah.surah,
                        quranComReciterId: apiReciterId,
                      );
                  if (audioService.isAyahActive(ayah.surah, ayah.number) &&
                      audioService.currentReciter == requestedReciter) {
                    audioService.karaoke.setTimings(timings[ayah.number]);
                  }
                } else {
                  audioService.karaoke.clear();
                }
              }
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isPlayingThisAyah
                    ? (audioService.isBuffering
                          ? Icons.hourglass_top_rounded
                          : Icons.pause_circle_filled_rounded)
                    : Icons.play_circle_outline_rounded,
                key: ValueKey<bool>(isPlayingThisAyah),
                size: 20,
                color: isCurrentAyah ? context.quranColors.gold : null,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: () {
              HapticFeedback.mediumImpact().ignore();
              BookmarkEditorSheet.show(
                context,
                ayah: ayah,
                surah: surah,
                bookmarkController: bookmarkController,
              );
            },
            child: IconButton(
              tooltip: bookmarked ? l.removeBookmark : l.addBookmark,
              visualDensity: VisualDensity.compact,
              onPressed: () {
                HapticFeedback.lightImpact().ignore();
                bookmarkController.toggleBookmark(
                  ayahId: ayah.id,
                  surahId: ayah.surah,
                  ayahNumber: ayah.number,
                );
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  key: ValueKey<bool>(bookmarked),
                  color: bookmarked ? context.quranColors.gold : null,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: () => _showMoreActions(context, translation),
            icon: const Icon(Icons.more_horiz_rounded, size: 22),
          ),
        ];
        final bool immersive = controller.immersiveReading;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isCurrentAyah
                ? Border.all(color: context.quranColors.gold, width: 1.5)
                : null,
            boxShadow: isCurrentAyah
                ? <BoxShadow>[
                    BoxShadow(
                      color: context.quranColors.gold.withValues(alpha: 0.18),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 12, 17, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final Widget identity = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              AyahNumber(number: ayah.number),
                              const SizedBox(width: 9),
                              Text(
                                '${ayah.surah}:${ayah.number}',
                                style: TextStyle(
                                  color: context.quranColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (ayah.sajda) ...<Widget>[
                                const SizedBox(width: 8),
                                SajdaBadge(color: context.quranColors.gold),
                              ],
                            ],
                          );
                          if (immersive) {
                            return identity;
                          }
                          if (constraints.maxWidth < 330) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                identity,
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Wrap(spacing: 2, children: actions),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: <Widget>[
                              identity,
                              const Spacer(),
                              ...actions,
                            ],
                          );
                        },
                  ),
                  const SizedBox(height: 7),
                  ListenableBuilder(
                    listenable: audioService.karaoke,
                    builder: (BuildContext context, _) {
                      final int? activeWordIdx = isPlayingThisAyah
                          ? audioService.karaoke.activeWordIndex
                          : null;
                      return QuranAyahText(
                        text: ayah.text,
                        fontSize: controller.arabicFontSize,
                        activeWordIndex: activeWordIdx,
                      );
                    },
                  ),
                  if (controller.showTranslation &&
                      translation != null) ...<Widget>[
                    const Divider(height: 26),
                    SelectableText(
                      translation,
                      style: TextStyle(
                        fontFamily: context.quranType.translationFamily,
                        fontSize: controller.translationFontSize,
                        height: 1.55,
                        color: context.quranColors.ink.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Secondary actions live in a sheet so the card itself stays quiet: only
  /// play, bookmark and this menu are shown inline.
  Future<void> _showMoreActions(
    BuildContext context,
    String? translation,
  ) async {
    HapticFeedback.selectionClick().ignore();
    final AppLocalizations l = AppLocalizations.of(context)!;
    final QuranThemeColors colors = context.quranColors;
    final _AyahAction? action = await showModalBottomSheet<_AyahAction>(
      context: context,
      builder: (BuildContext sheetContext) {
        Widget tile(IconData icon, String label, _AyahAction value) {
          return ListTile(
            leading: Icon(icon, color: colors.gold),
            title: Text(label),
            onTap: () => Navigator.of(sheetContext).pop(value),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: <Widget>[
                    AyahNumber(number: ayah.number),
                    const SizedBox(width: 10),
                    Text(
                      '${surah.nameRussian} · ${ayah.surah}:${ayah.number}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              tile(Icons.notes_rounded, l.tafsirSaadi, _AyahAction.tafsir),
              tile(Icons.translate_rounded, l.wordAnalysis, _AyahAction.words),
              tile(
                Icons.mic_none_rounded,
                l.recitationCheck,
                _AyahAction.recite,
              ),
              tile(Icons.copy_rounded, l.copyAyah, _AyahAction.copy),
              tile(
                Icons.bookmark_add_outlined,
                l.addToBookmarks,
                _AyahAction.bookmarkEditor,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _AyahAction.tafsir:
        await _showTafsir(context);
      case _AyahAction.words:
        await _showWords(context);
      case _AyahAction.recite:
        await RecitationTrainerSheet.show(
          context,
          surah: surah,
          ayah: ayah,
          audioService: audioService,
        );
      case _AyahAction.copy:
        await _copyAyah(context, translation);
      case _AyahAction.bookmarkEditor:
        await BookmarkEditorSheet.show(
          context,
          ayah: ayah,
          surah: surah,
          bookmarkController: bookmarkController,
        );
    }
  }

  Future<void> _copyAyah(BuildContext context, String? translation) async {
    final AppLocalizations? l = AppLocalizations.of(context);
    final StringBuffer buffer = StringBuffer()
      ..writeln(ayah.text)
      ..writeln();
    if (controller.showTranslation && translation != null) {
      buffer
        ..writeln(translation)
        ..writeln();
    }
    buffer.write(
      l?.quranReference(ayah.surah, ayah.number) ??
          'Quran (${ayah.surah}:${ayah.number})',
    );

    try {
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.copyFailed ??
                'Не удалось скопировать аят.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.ayahCopied(ayah.surah, ayah.number) ??
              'Аят ${ayah.surah}:${ayah.number} скопирован',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showTafsir(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final AppLocalizations l = AppLocalizations.of(context)!;
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<String?>(
            future: repository.getTafsir(ayah.surah, ayah.number),
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              final String? tafsir = snapshot.data?.trim();
              return StudySheet(
                title: l.tafsirTitle(ayah.surah, ayah.number),
                subtitle: l.tafsirSubtitle,
                loading: snapshot.connectionState != ConnectionState.done,
                error: snapshot.error,
                child: tafsir == null || tafsir.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(l.tafsirNotFound),
                        ),
                      )
                    : SelectableText(
                        tafsir,
                        style: TextStyle(
                          fontFamily: context.quranType.translationFamily,
                          fontSize: 16.5,
                          height: 1.68,
                          letterSpacing: 0.15,
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showWords(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final AppLocalizations l = AppLocalizations.of(context)!;
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<List<QuranWord>>(
            future: repository.getWords(ayah.surah, ayah.number),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<QuranWord>> snapshot,
                ) {
                  final List<QuranWord>? words = snapshot.data;
                  return StudySheet(
                    title: l.wordAnalysisTitle(ayah.surah, ayah.number),
                    subtitle: l.wordAnalysisSubtitle,
                    loading: snapshot.connectionState != ConnectionState.done,
                    error: snapshot.error,
                    child: words == null || words.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(l.wordAnalysisNotFound),
                            ),
                          )
                        : Directionality(
                            textDirection: TextDirection.rtl,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              alignment: WrapAlignment.start,
                              children: words
                                  .map(
                                    (QuranWord word) => WordChipCard(
                                      word: word,
                                      onTap: () =>
                                          _showWordDetails(context, word),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  );
                },
          ),
        );
      },
    );
  }

  void _showWordDetails(BuildContext context, QuranWord word) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations l = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: context.quranColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              word.textArabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: context.quranType.arabicFamily,
                fontSize: 34,
                height: 1.3,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              WordDetail(label: l.wordTranslation, value: word.textRussian),
              WordDetail(label: l.wordRoot, value: word.rootArabic),
              WordDetail(label: l.wordLemma, value: word.lemma),
              WordDetail(label: l.wordPartOfSpeech, value: word.partOfSpeech),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }
}

enum _AyahAction { tafsir, words, recite, copy, bookmarkEditor }
