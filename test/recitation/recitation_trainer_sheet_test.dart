import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:mubeen_quran_pure/audio/quran_audio_service.dart';
import 'package:mubeen_quran_pure/controllers/app_controller.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';
import 'package:mubeen_quran_pure/models/quran_models.dart';
import 'package:mubeen_quran_pure/screens/recitation_trainer_sheet.dart';
import 'package:mubeen_quran_pure/theme/app_theme.dart';

import '../audio/quran_audio_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  JustAudioPlatform.instance = FakeJustAudioPlatform();

  const Surah testSurah = Surah(
    id: 1,
    nameArabic: 'الفاتحة',
    nameTranslit: 'Al-Fatihah',
    nameRussian: 'Открывающая',
    revelationPlace: 'meccan',
    ayahCount: 7,
    revelationOrder: 5,
    bismillahPre: false,
  );

  final QuranAyah testAyah = QuranAyah(
    id: 1,
    surah: 1,
    number: 1,
    text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
    page: 1,
    juz: 1,
    hizb: 1,
    sajda: false,
    translations: const <String, String>{},
  );

  final ThemeData testTheme = buildAppTheme(AppThemeStyle.parchment);

  group('RecitationTrainerSheet Widget Tests', () {
    late QuranAudioService audioService;
    late FakeQuranRepository repository;

    setUp(() {
      repository = FakeQuranRepository();
      audioService = QuranAudioService(repository: repository);
    });

    tearDown(() {
      audioService.dispose();
    });

    testWidgets('Renders Ayah tokens and start over resets state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Scaffold(
            body: RecitationTrainerSheet(
              surah: testSurah,
              ayah: testAyah,
              audioService: audioService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that Arabic tokens are rendered
      expect(find.text('بِسْمِ'), findsOneWidget);
      expect(find.text('ٱللَّهِ'), findsOneWidget);
      expect(find.text('ٱلرَّحْمَٰنِ'), findsOneWidget);
      expect(find.text('ٱلرَّحِيمِ'), findsOneWidget);

      // Find Start Over (replay) button and tap it
      final Finder replayBtn = find.byIcon(Icons.replay_rounded);
      expect(replayBtn, findsOneWidget);
      await tester.tap(replayBtn);
      await tester.pumpAndSettle();

      // Tokens should still be displayed
      expect(find.text('بِسْمِ'), findsOneWidget);
    });

    testWidgets('Tapping mic when Whisper is unavailable shows warning', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Scaffold(
            body: RecitationTrainerSheet(
              surah: testSurah,
              ayah: testAyah,
              audioService: audioService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder micBtn = find.byIcon(Icons.mic_none_rounded);
      expect(micBtn, findsOneWidget);

      await tester.tap(micBtn);
      await tester.pumpAndSettle();

      // SnackBar with warning must be displayed
      expect(
        find.textContaining('Сервер распознавания речи не настроен'),
        findsOneWidget,
      );
    });
  });
}
