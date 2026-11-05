import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../../controllers/app_controller.dart';
import '../../data/quran_repository.dart';
import '../../models/quran_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/islamic_ornament_painters.dart';
import 'quran_text.dart';
import 'reader_utils.dart';
import 'reader_widgets.dart';

class MushafReader extends StatefulWidget {
  const MushafReader({
    super.key,
    required this.controller,
    required this.repository,
    required this.initialPage,
    required this.onPageChanged,
    required this.onLocationChanged,
  });

  final AppController controller;
  final QuranRepository repository;
  final int initialPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ReaderLocation> onLocationChanged;

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialPage.clamp(1, 604) - 1,
  );
  late int _currentPage = widget.initialPage.clamp(1, 604);
  late Future<List<Surah>> _surahs = widget.repository.getSurahs();
  Timer? _pageSaveDebounce;
  int? _pendingPage;
  bool _savingPage = false;

  late double _lastArabicFontSize = widget.controller.arabicFontSize;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSettingsChanged);
  }

  @override
  void didUpdateWidget(covariant MushafReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onSettingsChanged);
      widget.controller.addListener(_onSettingsChanged);
      _lastArabicFontSize = widget.controller.arabicFontSize;
    }
    if (oldWidget.repository != widget.repository) {
      setState(() => _surahs = widget.repository.getSurahs());
    }
    final int requestedPage = widget.initialPage.clamp(1, 604);
    if (oldWidget.initialPage != widget.initialPage &&
        requestedPage != _currentPage &&
        _pageController.hasClients) {
      _pageController.jumpToPage(requestedPage - 1);
    }
  }

  void _onSettingsChanged() {
    if (_lastArabicFontSize != widget.controller.arabicFontSize) {
      _lastArabicFontSize = widget.controller.arabicFontSize;
      if (mounted) setState(() {});
    }
  }

  void _pageChanged(int index) {
    final int page = index + 1;
    unawaited(safeHapticFeedback(HapticFeedback.lightImpact));
    setState(() => _currentPage = page);
    widget.onPageChanged(page);
    _pageSaveDebounce?.cancel();
    _pageSaveDebounce = Timer(
      const Duration(milliseconds: 240),
      () => _queuePageSave(page),
    );
  }

  void _queuePageSave(int page) {
    _pendingPage = page;
    if (!_savingPage) unawaited(_savePendingPages());
  }

  Future<void> _savePendingPages() async {
    _savingPage = true;
    try {
      while (mounted && _pendingPage != null) {
        final int page = _pendingPage!;
        _pendingPage = null;
        try {
          final List<QuranAyah> ayahs = await widget.repository.getAyahsForPage(
            page,
          );
          if (!mounted || page != _currentPage || ayahs.isEmpty) continue;
          final QuranAyah first = ayahs.first;
          final ReaderLocation location = ReaderLocation(
            surahId: first.surah,
            ayahNumber: first.number,
            page: page,
          );
          await widget.controller.saveLocation(
            surahId: first.surah,
            ayahNumber: first.number,
            page: page,
          );
          if (mounted && page == _currentPage) {
            widget.onLocationChanged(location);
          }
        } on Object {
          // The page itself reports load errors and remains swipeable.
        }
      }
    } finally {
      _savingPage = false;
      if (mounted && _pendingPage != null) {
        unawaited(_savePendingPages());
      }
    }
  }

  void _reloadSurahs() {
    setState(() => _surahs = widget.repository.getSurahs());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSettingsChanged);
    _pageSaveDebounce?.cancel();
    _pendingPage = null;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
          child: Row(
            children: <Widget>[
              Text(l.pageOfTotal(_currentPage)),
              const Spacer(),
              Text(
                l.textLayout,
                style: TextStyle(color: context.quranColors.gold, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 604,
              onPageChanged: _pageChanged,
              itemBuilder: (BuildContext context, int index) {
                return _MushafPage(
                  key: ValueKey<int>(index + 1),
                  page: index + 1,
                  controller: widget.controller,
                  repository: widget.repository,
                  surahs: _surahs,
                  onReloadSurahs: _reloadSurahs,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MushafPage extends StatefulWidget {
  const _MushafPage({
    super.key,
    required this.page,
    required this.controller,
    required this.repository,
    required this.surahs,
    required this.onReloadSurahs,
  });

  final int page;
  final AppController controller;
  final QuranRepository repository;
  final Future<List<Surah>> surahs;
  final VoidCallback onReloadSurahs;

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  late Future<(List<QuranAyah>, List<Surah>)> _content = _loadContent();

  @override
  void didUpdateWidget(covariant _MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page ||
        oldWidget.repository != widget.repository ||
        oldWidget.surahs != widget.surahs) {
      setState(() {
        _content = _loadContent();
      });
    }
  }

  Future<(List<QuranAyah>, List<Surah>)> _loadContent() async {
    final List<Object> values = await Future.wait<Object>(<Future<Object>>[
      widget.repository.getAyahsForPage(widget.page),
      widget.surahs,
    ]);
    return (values[0] as List<QuranAyah>, values[1] as List<Surah>);
  }

  void _reload() {
    widget.onReloadSurahs();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<QuranAyah>, List<Surah>)>(
      future: _content,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<(List<QuranAyah>, List<Surah>)> snapshot,
          ) {
            if (snapshot.hasError) {
              return ReaderMessage(
                icon: Icons.error_outline_rounded,
                message: AppLocalizations.of(
                  context,
                )!.failedToLoadPage(widget.page),
                details: snapshot.error,
                onRetry: _reload,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<QuranAyah> ayahs = snapshot.data!.$1;
            if (ayahs.isEmpty) {
              return ReaderMessage(
                icon: Icons.menu_book_outlined,
                message: AppLocalizations.of(
                  context,
                )!.noAyahsOnPage(widget.page),
                onRetry: _reload,
              );
            }
            final Map<int, Surah> surahs = <int, Surah>{
              for (final Surah surah in snapshot.data!.$2) surah.id: surah,
            };
            return Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 14),
              child: MushafPageBorder(
                goldColor: context.quranColors.gold,
                backgroundColor: context.quranColors.paper,
                child: Column(
                  children: <Widget>[
                    OrnamentLine(label: '${widget.page}', juz: ayahs.first.juz),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: widget.controller.toggleImmersiveReading,
                        child: SingleChildScrollView(
                          child: _MushafPageContent(
                            ayahs: ayahs,
                            surahs: surahs,
                            fontSize: widget.controller.arabicFontSize * 0.78,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}

class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent({
    required this.ayahs,
    required this.surahs,
    required this.fontSize,
  });

  final List<QuranAyah> ayahs;
  final Map<int, Surah> surahs;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final List<Widget> sections = <Widget>[];
    int? currentSurah;
    final List<InlineSpan> ayahSpans = <InlineSpan>[];

    void flushAyahs() {
      if (ayahSpans.isEmpty) return;
      sections.add(
        Text.rich(
          TextSpan(children: List<InlineSpan>.of(ayahSpans)),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontFamily: context.quranType.arabicFamily,
            fontSize: fontSize,
            height: context.quranType.arabicLineHeight + 0.1,
            color: context.quranColors.ink,
          ),
        ),
      );
      ayahSpans.clear();
    }

    for (final QuranAyah ayah in ayahs) {
      if (currentSurah != ayah.surah) {
        flushAyahs();
        currentSurah = ayah.surah;
        if (ayah.number == 1) {
          final Surah? surah = surahs[ayah.surah];
          sections.add(
            _MushafSurahHeading(
              surahId: ayah.surah,
              surahName: surah?.nameArabic,
              showBismillah: surah?.bismillahPre == true,
            ),
          );
        }
      }
      ayahSpans.addAll(<InlineSpan>[
        ...buildQuranTextSpans(
          ayah.text,
          markStyle: TextStyle(
            color: context.quranColors.gold.withValues(alpha: 0.78),
          ),
        ),
        const TextSpan(text: ' '),
        TextSpan(
          text: '۝${toArabicDigits(ayah.number)} ',
          style: TextStyle(
            color: context.quranColors.gold,
            fontSize: fontSize * 0.9,
          ),
        ),
      ]);
    }
    flushAyahs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

class _MushafSurahHeading extends StatelessWidget {
  const _MushafSurahHeading({
    required this.surahId,
    required this.surahName,
    required this.showBismillah,
  });

  final int surahId;
  final String? surahName;
  final bool showBismillah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 6),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.quranColors.deepGreen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.quranColors.gold.withValues(alpha: 0.7),
                width: 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              surahName?.trim().isNotEmpty == true
                  ? surahName!
                  : 'سورة $surahId',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE3C47D),
                fontFamily: context.quranType.arabicFamily,
                fontSize: 24,
                height: 1.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (showBismillah)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(
                bismillah,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.quranColors.ink,
                  fontFamily: context.quranType.arabicFamily,
                  fontSize: 21,
                  height: 1.7,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
