import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/theme/islamic_ornament_painters.dart';

void main() {
  group('Islamic Ornament Tests', () {
    test('Arabic digits conversion works accurately', () {
      expect(AyahEndOrnament.toArabicDigits(1), '١');
      expect(AyahEndOrnament.toArabicDigits(7), '٧');
      expect(AyahEndOrnament.toArabicDigits(255), '٢٥٥');
    });

    testWidgets('SurahOrnamentFrame renders without layout error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SurahOrnamentFrame(child: Text('سورة الفاتحة'))),
        ),
      );

      expect(find.text('سورة الفاتحة'), findsOneWidget);
    });

    testWidgets('MushafPageBorder renders child accurately', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MushafPageBorder(
              goldColor: Color(0xFFD4AF37),
              backgroundColor: Color(0xFFF4EAD5),
              child: Text('صفحة 1'),
            ),
          ),
        ),
      );

      expect(find.text('صفحة 1'), findsOneWidget);
    });
  });
}
