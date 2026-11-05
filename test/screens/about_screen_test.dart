import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';
import 'package:mubeen_quran_pure/screens/about_screen.dart';
import 'package:mubeen_quran_pure/theme/app_theme.dart';
import 'package:mubeen_quran_pure/controllers/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AboutScreen renders all sources including font, morphology and license button',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AppThemeStyle.parchment),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: const AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mubeen Quran Pure'), findsOneWidget);
      expect(find.textContaining('Amiri Quran'), findsOneWidget);
      expect(
        find.textContaining('Пословный разбор и морфология'),
        findsOneWidget,
      );
      expect(find.textContaining('EveryAyah'), findsWidgets);
      expect(find.textContaining('Quran.com'), findsWidgets);
      expect(find.textContaining('Whisper'), findsWidgets);
      expect(find.text('Лицензии открытого ПО'), findsOneWidget);
    },
  );
}
