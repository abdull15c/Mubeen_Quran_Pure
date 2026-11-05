import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/controllers/app_controller.dart';
import 'package:mubeen_quran_pure/screens/reader/quran_text.dart';
import 'package:mubeen_quran_pure/theme/app_theme.dart';

void main() {
  const TextStyle markStyle = TextStyle(color: Colors.amber);
  const TextStyle activeStyle = TextStyle(color: Colors.red);
  const TextStyle pastStyle = TextStyle(color: Colors.grey);

  group('isQuranMarkToken', () {
    test('recognizes standalone waqf and sajdah signs', () {
      expect(isQuranMarkToken('ۛ'), isTrue); // small high three dots
      expect(isQuranMarkToken('ۖ'), isTrue); // sla
      expect(isQuranMarkToken('۩'), isTrue); // sajdah
      expect(isQuranMarkToken('۞'), isTrue); // rub el hizb
    });

    test('rejects words even when they carry harakat', () {
      expect(isQuranMarkToken('ٱلْحَمْدُ'), isFalse);
      expect(isQuranMarkToken('لَا'), isFalse);
      expect(isQuranMarkToken(''), isFalse);
    });
  });

  group('buildQuranTextSpans', () {
    // 2:2 begins "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى" where ۛ is a
    // standalone pause sign that must not count as a word.
    const String text = 'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى';

    test('numbers words without counting pause signs', () {
      expect(countQuranWords(text), 6);
      final List<InlineSpan> spans = buildQuranTextSpans(
        text,
        markStyle: markStyle,
        activeWordIndex: 4, // فِيهِ, the word right after the first sign
        activeStyle: activeStyle,
        pastStyle: pastStyle,
      );
      final List<TextSpan> words = spans
          .whereType<TextSpan>()
          .where((TextSpan span) => span.text != ' ')
          .toList();
      expect(words.length, 8);
      expect(words[4].text, 'ۛ');
      expect(words[4].style, same(markStyle));
      expect(words[5].text, 'فِيهِ');
      expect(words[5].style, same(activeStyle));
      expect(words[3].style, same(pastStyle));
      expect(words[7].style, isNull);
    });

    test('joins tokens with single spaces and no trailing space', () {
      final List<InlineSpan> spans = buildQuranTextSpans(
        '  أ  ب ',
        markStyle: markStyle,
      );
      expect(
        spans.map((InlineSpan span) => (span as TextSpan).text).join(),
        'أ ب',
      );
    });
  });

  testWidgets('QuranAyahText lays out as one justified paragraph', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AppThemeStyle.parchment),
        home: const Scaffold(
          body: QuranAyahText(text: 'بِسْمِ ٱللَّهِ', fontSize: 30),
        ),
      ),
    );
    final RichText richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.textAlign, TextAlign.justify);
    expect(richText.textDirection, TextDirection.rtl);
  });
}
