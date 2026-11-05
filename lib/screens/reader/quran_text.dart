import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Whether [token] consists only of Quranic annotation signs: waqf (pause)
/// marks, sajdah and rub-el-hizb signs, small high letters and harakat, with
/// no base Arabic letter. In the Tanzil Uthmani text these signs are usually
/// separated from the surrounding words by spaces.
bool isQuranMarkToken(String token) {
  if (token.isEmpty) return false;
  for (final int rune in token.runes) {
    final bool isMark =
        (rune >= 0x0610 && rune <= 0x061A) ||
        (rune >= 0x064B && rune <= 0x065F) ||
        rune == 0x0670 ||
        (rune >= 0x06D6 && rune <= 0x06ED) ||
        (rune >= 0x08D3 && rune <= 0x08FF);
    if (!isMark) return false;
  }
  return true;
}

/// Splits Uthmani [text] into whitespace-separated tokens and returns one
/// span per token.
///
/// Annotation-only tokens (see [isQuranMarkToken]) get [markStyle] and do not
/// count as words. Real words are numbered from zero in reading order, which
/// matches the word order of the Quran.com word-timing data used for karaoke
/// highlighting: the word at [activeWordIndex] gets [activeStyle] and every
/// earlier word gets [pastStyle].
List<InlineSpan> buildQuranTextSpans(
  String text, {
  required TextStyle markStyle,
  int? activeWordIndex,
  TextStyle? activeStyle,
  TextStyle? pastStyle,
}) {
  final List<String> tokens = text
      .split(RegExp(r'\s+'))
      .where((String token) => token.isNotEmpty)
      .toList(growable: false);
  final List<InlineSpan> spans = <InlineSpan>[];
  var wordIndex = 0;
  for (var index = 0; index < tokens.length; index++) {
    final String token = tokens[index];
    final bool isLast = index == tokens.length - 1;
    if (isQuranMarkToken(token)) {
      spans.add(TextSpan(text: token, style: markStyle));
    } else {
      TextStyle? style;
      if (activeWordIndex != null) {
        if (wordIndex == activeWordIndex) {
          style = activeStyle;
        } else if (wordIndex < activeWordIndex) {
          style = pastStyle;
        }
      }
      spans.add(TextSpan(text: token, style: style));
      wordIndex++;
    }
    if (!isLast) {
      spans.add(const TextSpan(text: ' '));
    }
  }
  return spans;
}

/// Number of real (non-annotation) words in Uthmani [text].
int countQuranWords(String text) {
  return text
      .split(RegExp(r'\s+'))
      .where((String token) => token.isNotEmpty && !isQuranMarkToken(token))
      .length;
}

/// One ayah laid out as a single justified right-to-left paragraph.
///
/// The paragraph keeps natural Arabic line breaking and word spacing, while
/// every word is still its own span so playback can highlight it.
class QuranAyahText extends StatelessWidget {
  const QuranAyahText({
    super.key,
    required this.text,
    required this.fontSize,
    this.activeWordIndex,
    this.height,
    this.textAlign = TextAlign.justify,
  });

  final String text;
  final double fontSize;
  final int? activeWordIndex;

  /// Line height multiplier; defaults to the active typeface's own value.
  final double? height;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final QuranThemeColors colors = context.quranColors;
    final QuranTypography type = context.quranType;
    return Text.rich(
      TextSpan(
        children: buildQuranTextSpans(
          text,
          markStyle: TextStyle(color: colors.gold.withValues(alpha: 0.78)),
          activeWordIndex: activeWordIndex,
          activeStyle: TextStyle(
            color: colors.gold,
            shadows: <Shadow>[
              Shadow(color: colors.gold.withValues(alpha: 0.45), blurRadius: 12),
            ],
          ),
          pastStyle: TextStyle(color: colors.ink.withValues(alpha: 0.55)),
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: type.arabicFamily,
        fontSize: fontSize,
        height: height ?? type.arabicLineHeight,
        color: colors.ink,
      ),
    );
  }
}
