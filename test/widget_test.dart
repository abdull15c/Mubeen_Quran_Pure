import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/app.dart';
import 'package:mubeen_quran_pure/controllers/app_controller.dart';
import 'package:mubeen_quran_pure/data/quran_repository.dart';

void main() {
  testWidgets('startup error is presented without unrelated navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MubeenQuranApp(
        controller: AppController(),
        repository: QuranRepository(),
        startupError: 'database unavailable',
      ),
    );

    expect(find.text('Не удалось открыть Коран'), findsOneWidget);
    expect(find.textContaining('database unavailable'), findsOneWidget);
    expect(find.text('Хадисы'), findsNothing);
    expect(find.text('Азкары'), findsNothing);
  });
}
