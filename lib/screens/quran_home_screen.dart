import 'package:flutter/material.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../audio/quran_audio_service.dart';
import '../controllers/app_controller.dart';
import '../data/quran_repository.dart';
import '../data/translation_manager.dart';
import '../models/quran_models.dart';
import '../khatm/khatm_controller.dart';
import '../bookmarks/bookmark_controller.dart';
import 'navigation_screen.dart';
import 'reader_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({
    super.key,
    required this.controller,
    required this.repository,
    required this.translationManager,
  });

  final AppController controller;
  final QuranRepository repository;
  final TranslationManager translationManager;

  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen> {
  final GlobalKey<ReaderScreenState> _readerKey =
      GlobalKey<ReaderScreenState>();
  late final QuranAudioService _audioService;
  late final KhatmController _khatmController;
  late final BookmarkController _bookmarkController;
  int _selectedIndex = 0;
  int _openGeneration = 0;

  @override
  void initState() {
    super.initState();
    _audioService = QuranAudioService(repository: widget.repository);
    _khatmController = KhatmController();
    _bookmarkController = BookmarkController();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _khatmController.dispose();
    _bookmarkController.dispose();
    super.dispose();
  }

  void _openLocation(ReaderLocation location, {ReaderMode? mode}) {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final int generation = ++_openGeneration;
    setState(() => _selectedIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _openGeneration) return;
      _readerKey.currentState?.openLocation(location, mode: mode);
    });
  }

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    ++_openGeneration;
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Безопасное получение локализации
    final AppLocalizations? l = AppLocalizations.of(context);

    final List<Widget> screens = <Widget>[
      ReaderScreen(
        key: _readerKey,
        controller: widget.controller,
        repository: widget.repository,
        audioService: _audioService,
        translationManager: widget.translationManager,
        khatmController: _khatmController,
        bookmarkController: _bookmarkController,
        isActive: _selectedIndex == 0,
      ),
      NavigationScreen(
        controller: widget.controller,
        repository: widget.repository,
        khatmController: _khatmController,
        bookmarkController: _bookmarkController,
        onOpenLocation: _openLocation,
      ),
      SearchScreen(
        controller: widget.controller,
        repository: widget.repository,
        translationManager: widget.translationManager,
        onOpenLocation: _openLocation,
      ),
      SettingsScreen(
        controller: widget.controller,
        translationManager: widget.translationManager,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories_rounded),
            label: l?.tabRead ?? 'Читать',
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: l?.tabNavigation ?? 'Навигация',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            label: l?.tabSearch ?? 'Поиск',
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_rounded),
            label: l?.tabSettings ?? 'Настройки',
          ),
        ],
      ),
    );
  }
}
