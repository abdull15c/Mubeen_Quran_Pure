import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../../audio/quran_audio_player_widget.dart';
import '../../audio/quran_audio_service.dart';
import '../../bookmarks/bookmark_controller.dart';
import '../../controllers/app_controller.dart';
import '../../data/quran_repository.dart';
import '../../data/translation_manager.dart';
import '../../models/quran_models.dart';
import 'ayah_card.dart';
import 'reader_widgets.dart';
import 'surah_header.dart';

class FlowReader extends StatefulWidget {
  const FlowReader({
    super.key,
    required this.controller,
    required this.repository,
    required this.audioService,
    required this.translationManager,
    required this.bookmarkController,
    required this.surahId,
    required this.targetAyah,
    required this.onLocationChanged,
  });

  final AppController controller;
  final QuranRepository repository;
  final QuranAudioService audioService;
  final TranslationManager translationManager;
  final BookmarkController bookmarkController;
  final int surahId;
  final int targetAyah;
  final ValueChanged<ReaderLocation> onLocationChanged;

  @override
  State<FlowReader> createState() => FlowReaderState();
}

class FlowReaderState extends State<FlowReader>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = <int, GlobalKey>{};
  Ticker? _autoScrollTicker;
  Duration _lastTickerElapsed = Duration.zero;
  bool _autoScrolling = false;
  int _lastSavedAyah = -1;
  int _loadGeneration = 0;
  int _jumpGeneration = 0;
  late Future<(Surah, List<QuranAyah>)> _content;
  late double _lastArabicFontSize = widget.controller.arabicFontSize;
  late double _lastTranslationFontSize = widget.controller.translationFontSize;
  late bool _lastShowTranslation = widget.controller.showTranslation;
  late String _lastTranslatorKey = widget.controller.translatorKey;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSettingsChanged);
    widget.audioService.addListener(_onAudioChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant FlowReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onSettingsChanged);
      widget.controller.addListener(_onSettingsChanged);
      _rememberLayoutSettings();
    }
    if (oldWidget.audioService != widget.audioService) {
      oldWidget.audioService.removeListener(_onAudioChanged);
      widget.audioService.addListener(_onAudioChanged);
    }
    if (oldWidget.surahId != widget.surahId ||
        oldWidget.repository != widget.repository) {
      _load();
    } else if (oldWidget.targetAyah != widget.targetAyah) {
      _scheduleTargetJump();
    }
  }

  void _onAudioChanged() {
    if (!mounted) return;
    final int? playingSurah = widget.audioService.currentSurahId;
    final int? playingAyah = widget.audioService.currentAyahNumber;
    if (playingSurah == widget.surahId &&
        playingAyah != null &&
        widget.audioService.isPlaying) {
      _content.then((val) {
        if (mounted && widget.audioService.currentAyahNumber == playingAyah) {
          _jumpToAyahNumber(playingAyah, val.$2);
        }
      }, onError: (_) {});
    }
  }

  void _load() {
    final int generation = ++_loadGeneration;
    _jumpGeneration++;
    _ayahKeys.clear();
    _content = _loadContent();
    if (mounted) setState(() {});
    _lastSavedAyah = -1;
    _content.then((value) {
      if (!mounted || generation != _loadGeneration) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _loadGeneration) {
          unawaited(_jumpToTarget(value.$2));
        }
      });
    }, onError: (_) {});
  }

  Future<(Surah, List<QuranAyah>)> _loadContent() async {
    final String translatorKey = widget.controller.translatorKey;
    final List<Object> values = await Future.wait<Object>(<Future<Object>>[
      widget.repository.getSurah(widget.surahId),
      widget.repository.getAyahsForSurah(widget.surahId, translatorKey),
    ]);
    final Surah surah = values[0] as Surah;
    List<QuranAyah> ayahs = values[1] as List<QuranAyah>;

    // For API translations, merge cached data or trigger a lazy download.
    if (!kBuiltInTranslatorKeys.contains(translatorKey)) {
      final bool isFullyCached = await widget.translationManager.isSurahCached(
        translatorKey: translatorKey,
        surahId: widget.surahId,
        expectedAyahs: ayahs.length,
      );

      Map<int, String> cached = await widget.translationManager
          .getCachedTranslations(
            translatorKey: translatorKey,
            surahId: widget.surahId,
          );

      // If not fully cached yet, download and retry.
      if (!isFullyCached) {
        await widget.translationManager.downloadSurahTranslation(
          translatorKey: translatorKey,
          surahId: widget.surahId,
          expectedAyahs: ayahs.length,
        );
        cached = await widget.translationManager.getCachedTranslations(
          translatorKey: translatorKey,
          surahId: widget.surahId,
        );
      }

      // Merge translations into ayahs.
      if (cached.isNotEmpty) {
        ayahs = List<QuranAyah>.unmodifiable(
          ayahs.map((QuranAyah ayah) {
            final String? text = cached[ayah.number];
            if (text == null) return ayah;
            return QuranAyah(
              id: ayah.id,
              surah: ayah.surah,
              number: ayah.number,
              text: ayah.text,
              juz: ayah.juz,
              hizb: ayah.hizb,
              page: ayah.page,
              sajda: ayah.sajda,
              translations: <String, String>{
                ...ayah.translations,
                translatorKey: text,
              },
            );
          }),
        );
      }
    }

    return (surah, ayahs);
  }

  void _onSettingsChanged() {
    final bool layoutChanged =
        _lastArabicFontSize != widget.controller.arabicFontSize ||
        _lastTranslationFontSize != widget.controller.translationFontSize ||
        _lastShowTranslation != widget.controller.showTranslation ||
        _lastTranslatorKey != widget.controller.translatorKey;
    final (int, double)? anchor = layoutChanged ? _captureAnchor() : null;

    if (_lastTranslatorKey != widget.controller.translatorKey) {
      _load();
    }

    _rememberLayoutSettings();
    if (!mounted) return;
    setState(() {});
    if (anchor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restoreAnchor(anchor);
      });
    }
  }

  void _rememberLayoutSettings() {
    _lastArabicFontSize = widget.controller.arabicFontSize;
    _lastTranslationFontSize = widget.controller.translationFontSize;
    _lastShowTranslation = widget.controller.showTranslation;
    _lastTranslatorKey = widget.controller.translatorKey;
  }

  (int, double)? _captureAnchor() {
    if (!_scrollController.hasClients) return null;
    final double viewportTop = _viewportTop;
    int? nearestAyah;
    var nearestDistance = double.infinity;
    double? nearestTop;
    for (final MapEntry<int, GlobalKey> entry in _ayahKeys.entries) {
      final RenderObject? object = entry.value.currentContext
          ?.findRenderObject();
      if (object is! RenderBox || !object.attached) continue;
      final double top = object.localToGlobal(Offset.zero).dy;
      final double bottom = top + object.size.height;
      final double distance = bottom >= viewportTop
          ? (top - viewportTop).abs()
          : viewportTop - bottom + object.size.height;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestAyah = entry.key;
        nearestTop = top;
      }
    }
    if (nearestAyah == null || nearestTop == null) return null;
    return (nearestAyah, nearestTop);
  }

  void _restoreAnchor((int, double) anchor) {
    if (!_scrollController.hasClients) return;
    final RenderObject? object = _ayahKeys[anchor.$1]?.currentContext
        ?.findRenderObject();
    if (object is! RenderBox || !object.attached) return;
    final double newTop = object.localToGlobal(Offset.zero).dy;
    final double targetOffset = (_scrollController.offset + newTop - anchor.$2)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    if ((targetOffset - _scrollController.offset).abs() > 0.5) {
      _scrollController.jumpTo(targetOffset);
    }
  }

  Future<void> _jumpToTarget(List<QuranAyah> ayahs) async {
    await _jumpToAyahNumber(widget.targetAyah, ayahs);
  }

  void _scheduleTargetJump() {
    final Future<(Surah, List<QuranAyah>)> content = _content;
    content.then((value) {
      if (!mounted || !identical(content, _content)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(content, _content)) {
          unawaited(_jumpToTarget(value.$2));
        }
      });
    }, onError: (_) {});
  }

  Future<void> _jumpToAyahNumber(
    int targetNumber,
    List<QuranAyah> ayahs,
  ) async {
    if (ayahs.isEmpty || !_scrollController.hasClients) return;
    final int generation = ++_jumpGeneration;
    final int target = targetNumber.clamp(1, ayahs.length);
    if (target == 1) {
      _scrollController.jumpTo(0);
      return;
    }

    if (await _ensureAyahVisible(target, generation)) return;
    if (!mounted || generation != _jumpGeneration) return;

    // Phase one gets the lazily built sliver close enough to measure children.
    final double fraction = (target - 1) / (ayahs.length - 1);
    _jumpToOffset(_scrollController.position.maxScrollExtent * fraction);

    // Phase two uses actual laid-out cards to correct the estimate, then
    // ensureVisible supplies the exact final alignment.
    for (var attempt = 0; attempt < 6; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || generation != _jumpGeneration) return;
      if (await _ensureAyahVisible(target, generation)) return;
      if (!mounted || generation != _jumpGeneration) return;
      final List<(int, double, double)> measured = _measuredAyahs();
      if (measured.isEmpty) continue;
      measured.sort((first, second) => first.$1.compareTo(second.$1));
      final (int, double, double) nearest = measured.reduce((first, second) {
        return (first.$1 - target).abs() <= (second.$1 - target).abs()
            ? first
            : second;
      });
      final double itemExtent = measured.length > 1
          ? ((measured.last.$2 - measured.first.$2) /
                    (measured.last.$1 - measured.first.$1))
                .abs()
          : nearest.$3 + 10;
      _jumpToOffset(
        _scrollController.offset + (target - nearest.$1) * itemExtent,
      );
    }
  }

  Future<bool> _ensureAyahVisible(int target, int generation) async {
    final BuildContext? targetContext = _ayahKeys[target]?.currentContext;
    if (targetContext == null) return false;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.08,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    return mounted && generation == _jumpGeneration;
  }

  List<(int, double, double)> _measuredAyahs() {
    final List<(int, double, double)> measured = <(int, double, double)>[];
    for (final MapEntry<int, GlobalKey> entry in _ayahKeys.entries) {
      final RenderObject? object = entry.value.currentContext
          ?.findRenderObject();
      if (object is RenderBox && object.attached) {
        measured.add((
          entry.key,
          object.localToGlobal(Offset.zero).dy,
          object.size.height,
        ));
      }
    }
    return measured;
  }

  void _jumpToOffset(double offset) {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
    );
  }

  void _toggleAutoScroll() {
    if (_autoScrolling) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (!_scrollController.hasClients) return;
    _stopAutoScroll();
    setState(() => _autoScrolling = true);
    _lastTickerElapsed = Duration.zero;
    _autoScrollTicker = createTicker((Duration elapsed) {
      if (!_scrollController.hasClients || !_autoScrolling) {
        _stopAutoScroll();
        return;
      }
      final double deltaSeconds = _lastTickerElapsed == Duration.zero
          ? 0.016
          : (elapsed - _lastTickerElapsed).inMicroseconds / 1000000.0;
      _lastTickerElapsed = elapsed;

      final double clampedDelta = deltaSeconds.clamp(0.0, 0.05);
      final double estimatedLineHeight =
          widget.controller.arabicFontSize * 1.95;
      final double pixelsPerSecond =
          widget.controller.autoScrollLinesPerMinute * estimatedLineHeight / 60;
      final double next =
          _scrollController.offset + (pixelsPerSecond * clampedDelta);

      if (next >= _scrollController.position.maxScrollExtent) {
        _stopAutoScroll();
        return;
      }
      _scrollController.jumpTo(next);
    });
    _autoScrollTicker?.start();
  }

  void stopAutoScroll() => _stopAutoScroll();

  void _stopAutoScroll() {
    _autoScrollTicker?.stop();
    _autoScrollTicker?.dispose();
    _autoScrollTicker = null;
    if (!_autoScrolling) return;
    if (mounted) {
      setState(() => _autoScrolling = false);
    } else {
      _autoScrolling = false;
    }
  }

  void showAyahPicker() {
    _content.then((value) {
      if (!mounted) return;
      showAyahPickerSheet(
        context: context,
        surah: value.$1,
        onSelected: (int ayahNum) => _jumpToAyahNumber(ayahNum, value.$2),
      );
    }, onError: (_) {});
  }

  bool _handleScroll(ScrollNotification notification, List<QuranAyah> ayahs) {
    if (notification is ScrollEndNotification && ayahs.isNotEmpty) {
      QuranAyah ayah = ayahs.first;
      var nearestDistance = double.infinity;
      for (final QuranAyah candidate in ayahs) {
        final BuildContext? context =
            _ayahKeys[candidate.number]?.currentContext;
        final RenderObject? object = context?.findRenderObject();
        if (object is! RenderBox || !object.attached) continue;
        final double distance =
            (object.localToGlobal(Offset.zero).dy - _viewportTop).abs();
        if (distance < nearestDistance) {
          nearestDistance = distance;
          ayah = candidate;
        }
      }
      if (_lastSavedAyah != ayah.number) {
        _lastSavedAyah = ayah.number;
        final ReaderLocation location = ReaderLocation(
          surahId: ayah.surah,
          ayahNumber: ayah.number,
          page: ayah.page,
        );
        unawaited(
          widget.controller.saveLocation(
            surahId: ayah.surah,
            ayahNumber: ayah.number,
            page: ayah.page,
          ),
        );
        widget.onLocationChanged(location);
      }
    }
    return false;
  }

  double get _viewportTop {
    final RenderObject? object = _scrollController
        .position
        .context
        .notificationContext
        ?.findRenderObject();
    return object is RenderBox && object.attached
        ? object.localToGlobal(Offset.zero).dy
        : 0;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSettingsChanged);
    widget.audioService.removeListener(_onAudioChanged);
    _autoScrollTicker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return FutureBuilder<(Surah, List<QuranAyah>)>(
      future: _content,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<(Surah, List<QuranAyah>)> snapshot,
          ) {
            if (snapshot.hasError) {
              return ReaderMessage(
                icon: Icons.error_outline_rounded,
                message: l.failedToOpenSurah,
                details: snapshot.error,
                onRetry: _load,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final Surah surah = snapshot.data!.$1;
            final List<QuranAyah> ayahs = snapshot.data!.$2;
            if (ayahs.isEmpty) {
              return ReaderMessage(
                icon: Icons.menu_book_outlined,
                message: l.noAyahsInSurah,
                onRetry: _load,
              );
            }
            return Stack(
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _autoScrolling ? _toggleAutoScroll : null,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) =>
                        _handleScroll(notification, ayahs),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: SurahHeader(
                            surah: surah,
                            audioService: widget.audioService,
                            onJumpToAyah: (int ayahNum) =>
                                _jumpToAyahNumber(ayahNum, ayahs),
                          ),
                        ),
                        if (!widget.controller.readerTipDismissed)
                          SliverToBoxAdapter(
                            child: FirstTimeReaderTip(
                              onDismiss: widget.controller.dismissReaderTip,
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
                          sliver: SliverList.separated(
                            itemCount: ayahs.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (BuildContext context, int index) {
                              final QuranAyah ayah = ayahs[index];
                              return AyahCard(
                                key: _ayahKeys.putIfAbsent(
                                  ayah.number,
                                  GlobalKey.new,
                                ),
                                ayah: ayah,
                                surah: surah,
                                controller: widget.controller,
                                repository: widget.repository,
                                audioService: widget.audioService,
                                translationManager: widget.translationManager,
                                bookmarkController: widget.bookmarkController,
                                totalAyahsInSurah: surah.ayahCount,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 80,
                  child: AutoScrollControl(
                    running: _autoScrolling,
                    speed: widget.controller.autoScrollLinesPerMinute,
                    onToggle: _toggleAutoScroll,
                    onSlower: () =>
                        widget.controller.setAutoScrollLinesPerMinute(
                          widget.controller.autoScrollLinesPerMinute - 1,
                        ),
                    onFaster: () =>
                        widget.controller.setAutoScrollLinesPerMinute(
                          widget.controller.autoScrollLinesPerMinute + 1,
                        ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: QuranAudioMiniPlayer(
                    audioService: widget.audioService,
                    currentSurah: surah,
                  ),
                ),
              ],
            );
          },
    );
  }
}
