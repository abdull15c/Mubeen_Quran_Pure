import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';

@immutable
final class QuranThemeColors extends ThemeExtension<QuranThemeColors> {
  const QuranThemeColors({
    required this.gold,
    required this.deepGreen,
    required this.paper,
    required this.ink,
    required this.muted,
    required this.ornament,
  });

  final Color gold;
  final Color deepGreen;
  final Color paper;
  final Color ink;
  final Color muted;
  final Color ornament;

  @override
  QuranThemeColors copyWith({
    Color? gold,
    Color? deepGreen,
    Color? paper,
    Color? ink,
    Color? muted,
    Color? ornament,
  }) {
    return QuranThemeColors(
      gold: gold ?? this.gold,
      deepGreen: deepGreen ?? this.deepGreen,
      paper: paper ?? this.paper,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      ornament: ornament ?? this.ornament,
    );
  }

  @override
  QuranThemeColors lerp(QuranThemeColors? other, double t) {
    if (other == null) return this;
    return QuranThemeColors(
      gold: Color.lerp(gold, other.gold, t)!,
      deepGreen: Color.lerp(deepGreen, other.deepGreen, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      ornament: Color.lerp(ornament, other.ornament, t)!,
    );
  }
}

ThemeData buildAppTheme(AppThemeStyle style) {
  final (Brightness brightness, QuranThemeColors colors) = switch (style) {
    AppThemeStyle.parchment => (
      Brightness.light,
      const QuranThemeColors(
        gold: Color(0xFFA77A2E),
        deepGreen: Color(0xFF163D35),
        paper: Color(0xFFF4EAD5),
        ink: Color(0xFF29231B),
        muted: Color(0xFF5E5242),
        ornament: Color(0xFFD9C59E),
      ),
    ),
    AppThemeStyle.oled => (
      Brightness.dark,
      const QuranThemeColors(
        gold: Color(0xFFD0AC62),
        deepGreen: Color(0xFF0F352E),
        paper: Color(0xFF000000),
        ink: Color(0xFFE9E2D5),
        muted: Color(0xFF9B958A),
        ornament: Color(0xFF312A20),
      ),
    ),
    AppThemeStyle.emerald => (
      Brightness.dark,
      const QuranThemeColors(
        gold: Color(0xFFD9B866),
        deepGreen: Color(0xFF082F28),
        paper: Color(0xFF0B3B32),
        ink: Color(0xFFF4EBD7),
        muted: Color(0xFFB5C3B8),
        ornament: Color(0xFF2C5B50),
      ),
    ),
    AppThemeStyle.light => (
      Brightness.light,
      const QuranThemeColors(
        gold: Color(0xFF9A742E),
        deepGreen: Color(0xFF18443A),
        paper: Color(0xFFFAF9F5),
        ink: Color(0xFF202421),
        muted: Color(0xFF525A56),
        ornament: Color(0xFFE6E1D5),
      ),
    ),
  };

  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: colors.deepGreen,
        brightness: brightness,
        surface: colors.paper,
      ).copyWith(
        primary: colors.deepGreen,
        onPrimary: colors.paper,
        secondary: colors.gold,
        onSecondary: colors.ink,
        surface: colors.paper,
        onSurface: colors.ink,
        outline: colors.ornament,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.paper,
    splashFactory: InkSparkle.splashFactory,
    extensions: <ThemeExtension<dynamic>>[colors],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.paper,
      foregroundColor: colors.ink,
      titleTextStyle: TextStyle(
        color: colors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      backgroundColor: colors.paper,
      indicatorColor: colors.gold.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? brightness == Brightness.dark
                    ? colors.gold
                    : colors.deepGreen
              : colors.muted,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colors.gold
              : colors.muted,
        );
      }),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Color.alphaBlend(
        colors.ornament.withValues(alpha: 0.18),
        colors.paper,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.ornament.withValues(alpha: 0.72)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.ornament.withValues(alpha: 0.65),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.ornament.withValues(alpha: 0.14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colors.gold, width: 1.2),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.paper,
      showDragHandle: true,
      dragHandleColor: colors.ornament,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}

extension QuranThemeContext on BuildContext {
  QuranThemeColors get quranColors =>
      Theme.of(this).extension<QuranThemeColors>()!;
}
