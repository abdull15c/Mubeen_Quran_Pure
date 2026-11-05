import 'package:flutter/material.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import 'controllers/app_controller.dart';
import 'data/quran_repository.dart';
import 'data/translation_manager.dart';
import 'screens/onboarding_screen.dart';
import 'screens/quran_home_screen.dart';
import 'theme/app_theme.dart';

class MubeenQuranApp extends StatefulWidget {
  const MubeenQuranApp({
    super.key,
    required this.controller,
    required this.repository,
    this.startupError,
  });

  final AppController controller;
  final QuranRepository repository;
  final Object? startupError;

  @override
  State<MubeenQuranApp> createState() => _MubeenQuranAppState();
}

class _MubeenQuranAppState extends State<MubeenQuranApp> {
  late final TranslationManager _translationManager = TranslationManager();

  @override
  void dispose() {
    widget.repository.close().ignore();
    _translationManager.close().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final Widget home;
        if (widget.startupError != null) {
          home = StartupErrorScreen(error: widget.startupError!);
        } else if (!widget.controller.onboardingCompleted) {
          home = OnboardingScreen(controller: widget.controller);
        } else {
          home = QuranHomeScreen(
            controller: widget.controller,
            repository: widget.repository,
            translationManager: _translationManager,
          );
        }

        return MaterialApp(
          title: 'Mubeen Quran Pure',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(
            widget.controller.themeStyle,
            arabicFont: widget.controller.arabicFont,
          ),
          locale: Locale(widget.controller.localeCode),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: home,
          builder: (BuildContext context, Widget? navigator) {
            final Widget child = navigator ?? const SizedBox.shrink();
            if (!widget.controller.eyeCareEnabled) {
              return child;
            }
            return ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0x33FFB300),
                BlendMode.darken,
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.menu_book_rounded, size: 54),
                        const SizedBox(height: 20),
                        Text(
                          'Не удалось открыть Коран',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Проверьте свободное место на устройстве и перезапустите приложение.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
