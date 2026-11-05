import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../bookmarks/bookmark_controller.dart';
import '../bookmarks/bookmark_models.dart';
import '../controllers/app_controller.dart';
import '../data/quran_repository.dart';
import '../khatm/khatm_controller.dart';
import '../khatm/khatm_progress_card.dart';
import '../models/quran_models.dart';
import '../theme/app_theme.dart';

typedef OpenLocationCallback =
    void Function(ReaderLocation location, {ReaderMode? mode});

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({
    super.key,
    required this.controller,
    required this.repository,
    required this.khatmController,
    required this.bookmarkController,
    required this.onOpenLocation,
  });

  final AppController controller;
  final QuranRepository repository;
  final KhatmController khatmController;
  final BookmarkController bookmarkController;
  final OpenLocationCallback onOpenLocation;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late Future<List<Surah>> _surahs;
  int _navigationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _surahs = widget.repository.getSurahs();
  }

  @override
  void didUpdateWidget(NavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      ++_navigationGeneration;
      _surahs = widget.repository.getSurahs();
    }
  }

  @override
  void dispose() {
    ++_navigationGeneration;
    super.dispose();
  }

  void _openResolvedLocation(
    Future<ReaderLocation> Function() resolve, {
    ReaderMode? mode,
  }) {
    unawaited(_resolveAndOpen(resolve, mode: mode));
  }

  void _openLocation(ReaderLocation location, {ReaderMode? mode}) {
    if (!mounted) return;
    ++_navigationGeneration;
    widget.onOpenLocation(location, mode: mode);
  }

  Future<void> _resolveAndOpen(
    Future<ReaderLocation> Function() resolve, {
    ReaderMode? mode,
  }) async {
    final int generation = ++_navigationGeneration;
    try {
      final ReaderLocation location = await resolve();
      if (!mounted || generation != _navigationGeneration) return;
      widget.onOpenLocation(location, mode: mode);
    } on Object catch (error) {
      if (!mounted || generation != _navigationGeneration) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Не удалось открыть выбранное место.\n$error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.tabNavigation),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[
              Tab(text: l.navigationSurahs),
              Tab(text: l.navigationJuz),
              Tab(text: l.navigationHizb),
              Tab(text: l.quranPages),
              Tab(text: l.navigationBookmarks),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _SurahList(
              controller: widget.controller,
              khatmController: widget.khatmController,
              surahs: _surahs,
              onOpen: _openLocation,
              onOpenSurah: (Surah surah) {
                _openResolvedLocation(() async {
                  final int page = await widget.repository.getPageForSurah(
                    surah.id,
                  );
                  return ReaderLocation(
                    surahId: surah.id,
                    ayahNumber: 1,
                    page: page,
                  );
                }, mode: ReaderMode.flow);
              },
            ),
            _NumberGrid(
              count: 30,
              prefix: l.navigationJuz,
              onTap: (int value) {
                _openResolvedLocation(
                  () => widget.repository.getFirstLocationForJuz(value),
                );
              },
            ),
            _NumberGrid(
              count: 60,
              prefix: l.navigationHizb,
              onTap: (int value) {
                _openResolvedLocation(
                  () => widget.repository.getFirstLocationForHizb(value),
                );
              },
            ),
            _NumberGrid(
              count: 604,
              prefix: l.quranPages,
              compact: true,
              onTap: (int value) {
                _openResolvedLocation(
                  () => widget.repository.getFirstLocationForPage(value),
                  mode: ReaderMode.mushaf,
                );
              },
            ),
            _Bookmarks(
              controller: widget.controller,
              bookmarkController: widget.bookmarkController,
              repository: widget.repository,
              onOpen: _openLocation,
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({
    required this.controller,
    required this.khatmController,
    required this.surahs,
    required this.onOpen,
    required this.onOpenSurah,
  });

  final AppController controller;
  final KhatmController khatmController;
  final Future<List<Surah>> surahs;
  final OpenLocationCallback onOpen;
  final ValueChanged<Surah> onOpenSurah;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Surah>>(
      future: surahs,
      builder: (BuildContext context, AsyncSnapshot<List<Surah>> snapshot) {
        if (snapshot.hasError) {
          return _ErrorMessage(error: snapshot.error!);
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Загрузка списка сур',
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          itemCount: snapshot.data!.length + 2,
          separatorBuilder: (_, int index) => index <= 1
              ? const SizedBox(height: 10)
              : const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _ContinueReadingCard(
                controller: controller,
                onOpen: onOpen,
              );
            }
            if (index == 1) {
              return KhatmProgressCard(khatmController: khatmController);
            }
            final Surah surah = snapshot.data![index - 2];
            return Semantics(
              button: true,
              label:
                  'Открыть суру ${surah.id}, ${surah.nameRussian}, '
                  '${surah.ayahCount} аятов',
              excludeSemantics: true,
              onTap: () => onOpenSurah(surah),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                leading: _NumberMedallion(number: surah.id),
                title: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 2,
                  children: <Widget>[
                    Text(
                      surah.nameRussian,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      surah.nameArabic,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: context.quranType.arabicFamily,
                        fontSize: 25,
                        color: context.quranColors.gold,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${surah.ayahCount} аятов · ${surah.nameTranslit}',
                ),
                onTap: () => onOpenSurah(surah),
              ),
            );
          },
        );
      },
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.controller, required this.onOpen});

  final AppController controller;
  final OpenLocationCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        void openLastLocation() {
          onOpen(
            ReaderLocation(
              surahId: controller.lastSurahId,
              ayahNumber: controller.lastAyahNumber,
              page: controller.lastPage,
            ),
          );
        }

        return Semantics(
          button: true,
          label:
              'Продолжить чтение, сура ${controller.lastSurahId}, '
              'аят ${controller.lastAyahNumber}, страница '
              '${controller.lastPage}',
          excludeSemantics: true,
          onTap: openLastLocation,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.quranColors.gold.withValues(alpha: 0.14),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: context.quranColors.gold,
                  size: 28,
                ),
              ),
              title: const Text(
                'Продолжить чтение',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Сура ${controller.lastSurahId}, аят ${controller.lastAyahNumber} · стр. ${controller.lastPage}',
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.quranColors.gold,
              ),
              onTap: openLastLocation,
            ),
          ),
        );
      },
    );
  }
}

class _NumberGrid extends StatelessWidget {
  const _NumberGrid({
    required this.count,
    required this.prefix,
    required this.onTap,
    this.compact = false,
  });

  final int count;
  final String prefix;
  final ValueChanged<int> onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 102 : 160,
        mainAxisExtent: compact ? 74 : 98,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (BuildContext context, int index) {
        final int value = index + 1;
        void openNumber() => onTap(value);
        return Semantics(
          button: true,
          label: '$prefix $value',
          excludeSemantics: true,
          onTap: openNumber,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: openNumber,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.quranColors.ornament),
                color: context.quranColors.ornament.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$value',
                      style: TextStyle(
                        color: context.quranColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 19 : 25,
                      ),
                    ),
                    if (!compact) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        prefix,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bookmarks extends StatefulWidget {
  const _Bookmarks({
    required this.controller,
    required this.bookmarkController,
    required this.repository,
    required this.onOpen,
  });

  final AppController controller;
  final BookmarkController bookmarkController;
  final QuranRepository repository;
  final OpenLocationCallback onOpen;

  @override
  State<_Bookmarks> createState() => _BookmarksState();
}

class _BookmarksState extends State<_Bookmarks> {
  late Set<int> _bookmarkIds;
  Future<List<QuranSearchResult>>? _bookmarks;
  String _selectedFolder = 'all';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    widget.bookmarkController.addListener(_handleBookmarkControllerChanged);
    _cacheBookmarks(widget.bookmarkController.entries.keys.toSet());
  }

  @override
  void didUpdateWidget(_Bookmarks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.bookmarkController != widget.bookmarkController) {
      oldWidget.bookmarkController.removeListener(
        _handleBookmarkControllerChanged,
      );
      widget.bookmarkController.addListener(_handleBookmarkControllerChanged);
    }
    final Set<int> ids = widget.bookmarkController.entries.keys.toSet();
    if (oldWidget.repository != widget.repository ||
        !setEquals(ids, _bookmarkIds)) {
      _cacheBookmarks(ids);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    widget.bookmarkController.removeListener(_handleBookmarkControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handleBookmarkControllerChanged() {
    final Set<int> ids = widget.bookmarkController.entries.keys.toSet();
    if (!setEquals(ids, _bookmarkIds)) {
      if (mounted) {
        setState(() => _cacheBookmarks(ids));
      }
    } else {
      if (mounted) setState(() {});
    }
  }

  void _cacheBookmarks(Set<int> ids) {
    _bookmarkIds = Set<int>.unmodifiable(ids);
    _bookmarks = ids.isEmpty
        ? null
        : widget.repository.getAyahsByIds(_bookmarkIds);
  }

  @override
  Widget build(BuildContext context) {
    if (_bookmarkIds.isEmpty) {
      return const _EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'Закладок пока нет',
        message: 'Добавьте закладку возле нужного аята во время чтения.',
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: const Text('Все закладки'),
                  selected: _selectedFolder == 'all',
                  selectedColor: context.quranColors.gold,
                  onSelected: (_) => setState(() => _selectedFolder = 'all'),
                ),
              ),
              ...widget.bookmarkController.folders.map((BookmarkFolder folder) {
                final bool isSel = _selectedFolder == folder.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(folder.icon, size: 14),
                    label: Text(folder.name),
                    selected: isSel,
                    selectedColor: context.quranColors.gold,
                    onSelected: (_) =>
                        setState(() => _selectedFolder = folder.id),
                  ),
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<QuranSearchResult>>(
            future: _bookmarks,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<QuranSearchResult>> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return _ErrorMessage(error: snapshot.error!);
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Загрузка закладок',
                      ),
                    );
                  }

                  final List<QuranSearchResult> allList = snapshot.data!;
                  final List<QuranSearchResult> filtered =
                      _selectedFolder == 'all'
                      ? allList
                      : allList.where((QuranSearchResult res) {
                          final BookmarkEntry? entry = widget.bookmarkController
                              .getEntry(res.ayahId);
                          return entry?.folderId == _selectedFolder;
                        }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('В этой папке нет закладок.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final QuranSearchResult result = filtered[index];
                      final BookmarkEntry? entry = widget.bookmarkController
                          .getEntry(result.ayahId);
                      final BookmarkFolder? folder = entry != null
                          ? widget.bookmarkController.folders.firstWhere(
                              (BookmarkFolder f) => f.id == entry.folderId,
                              orElse: () => kDefaultBookmarkFolders.first,
                            )
                          : null;

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${result.surahNameRussian} · ${result.surahId}:${result.ayahNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (folder != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.quranColors.gold.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        folder.icon,
                                        size: 12,
                                        color: context.quranColors.gold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        folder.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.quranColors.gold,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  result.arabicText,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: context.quranType.arabicFamily,
                                    fontSize: 23,
                                    height: 1.7,
                                  ),
                                ),
                              ),
                              if (entry?.note != null &&
                                  entry!.note!.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.quranColors.paper,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '📝 ${entry.note!}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: 'Удалить закладку',
                            onPressed: () {
                              HapticFeedback.lightImpact().ignore();
                              widget.bookmarkController.removeBookmark(
                                result.ayahId,
                              );
                            },
                            icon: const Icon(Icons.bookmark_remove_rounded),
                          ),
                          onTap: () => widget.onOpen(
                            ReaderLocation(
                              surahId: result.surahId,
                              ayahNumber: result.ayahNumber,
                              page: result.page,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
          ),
        ),
      ],
    );
  }
}

class _NumberMedallion extends StatelessWidget {
  const _NumberMedallion({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.quranColors.gold),
        color: context.quranColors.gold.withValues(alpha: 0.08),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: context.quranColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $message',
      excludeSemantics: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 48, color: context.quranColors.gold),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Не удалось загрузить данные Корана.\n$error'),
        ),
      ),
    );
  }
}
