import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';

/// Font family used for translations and tafsir (PT Serif, SIL OFL).
const String kTranslationFontFamily = 'PTSerif';

/// Rendering parameters for one of the bundled Quran typefaces.
///
/// The three faces have very different vertical metrics, so the reader asks
/// the active spec for its line height instead of hardcoding one.
@immutable
final class QuranFontSpec {
  const QuranFontSpec({
    required this.font,
    required this.family,
    required this.lineHeight,
    required this.previewLabel,
  });

  final QuranFont font;

  /// `fontFamily` as declared in `pubspec.yaml`.
  final String family;

  /// Multiplier for [TextStyle.height] in the flow reader.
  final double lineHeight;

  /// Short Latin label used in the settings preview.
  final String previewLabel;
}

const Map<QuranFont, QuranFontSpec> kQuranFontSpecs = <QuranFont, QuranFontSpec>{
  QuranFont.hafs: QuranFontSpec(
    font: QuranFont.hafs,
    family: 'KFGQPCHafs',
    lineHeight: 1.8,
    previewLabel: 'KFGQPC Hafs',
  ),
  QuranFont.hafsSmart: QuranFontSpec(
    font: QuranFont.hafsSmart,
    family: 'KFGQPCHafsSmart',
    lineHeight: 1.75,
    previewLabel: 'Hafs Smart',
  ),
  QuranFont.amiri: QuranFontSpec(
    font: QuranFont.amiri,
    family: 'AmiriQuran',
    lineHeight: 1.95,
    previewLabel: 'Amiri Quran',
  ),
};

extension QuranFontSpecX on QuranFont {
  QuranFontSpec get spec => kQuranFontSpecs[this]!;
}

/// Theme extension carrying the active Quran typeface, so widgets can ask
/// `context.quranType.arabicFamily` instead of hardcoding a family name.
@immutable
final class QuranTypography extends ThemeExtension<QuranTypography> {
  const QuranTypography({
    required this.arabicFamily,
    required this.arabicLineHeight,
    this.translationFamily = kTranslationFontFamily,
  });

  factory QuranTypography.of(QuranFont font) {
    final QuranFontSpec spec = font.spec;
    return QuranTypography(
      arabicFamily: spec.family,
      arabicLineHeight: spec.lineHeight,
    );
  }

  final String arabicFamily;
  final double arabicLineHeight;
  final String translationFamily;

  @override
  QuranTypography copyWith({
    String? arabicFamily,
    double? arabicLineHeight,
    String? translationFamily,
  }) {
    return QuranTypography(
      arabicFamily: arabicFamily ?? this.arabicFamily,
      arabicLineHeight: arabicLineHeight ?? this.arabicLineHeight,
      translationFamily: translationFamily ?? this.translationFamily,
    );
  }

  @override
  QuranTypography lerp(QuranTypography? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}

extension QuranTypographyContext on BuildContext {
  QuranTypography get quranType =>
      Theme.of(this).extension<QuranTypography>() ??
      QuranTypography.of(QuranFont.hafs);
}
