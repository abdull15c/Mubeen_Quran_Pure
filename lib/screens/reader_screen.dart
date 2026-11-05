import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../audio/quran_audio_service.dart';
import '../bookmarks/bookmark_controller.dart';
import '../controllers/app_controller.dart';
import '../data/quran_repository.dart';
import '../data/translation_manager.dart';
import '../khatm/khatm_controller.dart';
import '../models/quran_models.dart';
import 'reader/flow_reader.dart';
import 'reader/mushaf_reader.dart';
import 'reader/reader_utils.dart';

export 'reader/ayah_card.dart' show AyahCard;
export 'reader/flow_reader.dart' show FlowReader, FlowReaderState;
export 'reader/mushaf_reader.dart' show MushafReader;
export 'reader/reader_widgets.dart';
export 'reader/surah_header.dart' show SurahHeader;

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.controller,
    required this.repository,
    required this.audioService,
    required this.translationManager,
    required this.khatmController,
    required this.bookmarkController,
    required this.isActive,
  });

  final AppController controller;
  final QuranRepository repository;
  final QuranAudioService audioService;
  final TranslationManager translationManager;
  final KhatmController khatmController;
  final BookmarkController bookmarkController;
  final bool isActive;

  @override
  State<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  late ReaderMode _mode = widget.controller.readerMode;
  late int _surahId = widget.controller.lastSurahId;
  late int _targetAyah = widget.controller.lastAyahNumber;
  late int _page = widget.controller.lastPage;
  late AppLifecycleState _lifecycleState;
  bool _platformStateEnabled = false;
  Future<void> _platformUpdate = Future<void>.value();
  final GlobalKey<FlowReaderState> _flowReaderKey =
      GlobalKey<FlowReaderState>();
  Timer? _khatmDwellTimer;
  int? _pendingDwellPage;

  bool get _isReaderInteractive =>
      widget.isActive && _lifecycleState == AppLifecycleState.resumed;

  void _onPageDwellForKhatm(int page) {
    if (page < 1 || page > 604) return;
    if (_pendingDwellPage == page && _khatmDwellTimer?.isActive == true) {
      return;
    }
    _khatmDwellTimer?.cancel();
    _pendingDwellPage = page;
    _khatmDwellTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      if (_pendingDwellPage == page && _isReaderInteractive) {
        widget.khatmController.recordPageRead(page);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final WidgetsBinding binding = WidgetsBinding.instance;
    _lifecycleState = binding.lifecycleState ?? AppLifecycleState.resumed;
    binding.addObserver(this);
    _onPageDwellForKhatm(_page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPlatformState();
    });
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncPlatformState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lifecycleState == state) return;
    setState(() => _lifecycleState = state);
    _syncPlatformState();
  }

  void _syncPlatformState() {
    final bool shouldEnable = _isReaderInteractive;
    if (!shouldEnable) {
      _flowReaderKey.currentState?.stopAutoScroll();
    }
    if (!supportsMobilePlatformControls) return;
    if (_platformStateEnabled == shouldEnable) return;
    _platformStateEnabled = shouldEnable;
    _platformUpdate = _platformUpdate.then(
      (_) => _setPlatformState(shouldEnable),
    );
  }

  Future<void> _setPlatformState(bool enabled) async {
    final List<Future<void>> operations = <Future<void>>[
      ignorePlatformError(enabled ? WakelockPlus.enable : WakelockPlus.disable),
    ];
    if (supportsSystemUiControl) {
      operations.add(
        ignorePlatformError(
          () => SystemChrome.setEnabledSystemUIMode(
            enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
          ),
        ),
      );
    }
    await Future.wait<void>(operations);
  }

  @override
  void dispose() {
    _khatmDwellTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_platformStateEnabled && supportsMobilePlatformControls) {
      _platformStateEnabled = false;
      _platformUpdate = _platformUpdate.then((_) => _setPlatformState(false));
    }
    super.dispose();
  }

  void openLocation(ReaderLocation location, {ReaderMode? mode}) {
    final ReaderMode nextMode = mode ?? widget.controller.readerMode;
    if (_mode == ReaderMode.flow && nextMode != ReaderMode.flow) {
      _flowReaderKey.currentState?.stopAutoScroll();
    }
    setState(() {
      _mode = nextMode;
      _surahId = location.surahId;
      _targetAyah = location.ayahNumber;
      _page = location.page.clamp(1, 604);
    });
    widget.controller.setReaderMode(_mode);
  }

  Future<void> _setMode(ReaderMode mode) async {
    if (_mode == mode) return;
    if (_mode == ReaderMode.flow) {
      _flowReaderKey.currentState?.stopAutoScroll();
    }
    if (mode == ReaderMode.flow && _mode == ReaderMode.mushaf) {
      try {
        final ReaderLocation loc = await widget.repository
            .getFirstLocationForPage(_page);
        if (!mounted) return;
        _surahId = loc.surahId;
        _targetAyah = loc.ayahNumber;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _mode = mode);
    widget.controller.setReaderMode(mode);
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l) {
    return AppBar(
      titleSpacing: 16,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('MUBEEN', style: TextStyle(fontSize: 16, letterSpacing: 2.4)),
          Text('QURAN PURE', style: TextStyle(fontSize: 9, letterSpacing: 2.8)),
        ],
      ),
      actions: <Widget>[
        if (_mode == ReaderMode.flow)
          IconButton(
            tooltip: l.jumpToAyah,
            icon: const Icon(Icons.tag_rounded, size: 22),
            onPressed: () => _flowReaderKey.currentState?.showAyahPicker(),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SegmentedButton<ReaderMode>(
            showSelectedIcon: false,
            segments: <ButtonSegment<ReaderMode>>[
              ButtonSegment<ReaderMode>(
                value: ReaderMode.flow,
                icon: const Icon(Icons.view_agenda_outlined, size: 18),
                tooltip: l.verticalReading,
              ),
              ButtonSegment<ReaderMode>(
                value: ReaderMode.mushaf,
                icon: const Icon(Icons.auto_stories_outlined, size: 18),
                tooltip: l.quranPages,
              ),
            ],
            selected: <ReaderMode>{_mode},
            onSelectionChanged: (Set<ReaderMode> selected) {
              _setMode(selected.single);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool immersive = widget.controller.immersiveReading;
    final Widget reader = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _mode == ReaderMode.flow
          ? FlowReader(
              key: _flowReaderKey,
              controller: widget.controller,
              repository: widget.repository,
              audioService: widget.audioService,
              translationManager: widget.translationManager,
              bookmarkController: widget.bookmarkController,
              surahId: _surahId,
              targetAyah: _targetAyah,
              onLocationChanged: (ReaderLocation location) {
                _page = location.page;
                _onPageDwellForKhatm(location.page);
              },
            )
          : MushafReader(
              key: ValueKey<int>(_page),
              controller: widget.controller,
              repository: widget.repository,
              initialPage: _page,
              onPageChanged: (int page) {
                _page = page;
                _onPageDwellForKhatm(page);
              },
              onLocationChanged: (ReaderLocation location) {
                _surahId = location.surahId;
                _targetAyah = location.ayahNumber;
                _page = location.page;
                _onPageDwellForKhatm(location.page);
              },
            ),
    );
    // Focused reading hides the app bar; a tap on the text brings it back
    // (see FlowReader and MushafReader). The widget tree keeps the same shape
    // in both states so the readers keep their scroll position.
    return Scaffold(
      appBar: immersive ? null : _buildAppBar(l),
      body: SafeArea(top: immersive, bottom: false, child: reader),
    );
  }
}
