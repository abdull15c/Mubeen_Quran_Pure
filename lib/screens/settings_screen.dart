import 'package:flutter/material.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../controllers/app_controller.dart';
import '../data/translation_manager.dart';
import '../models/quran_models.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'guide_screen.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.translationManager,
  });

  final AppController controller;
  final TranslationManager translationManager;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? child) {
          final AppLocalizations l = AppLocalizations.of(context)!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              _SectionTitle(l.uiLanguage),
              const SizedBox(height: 10),
              _LanguagePicker(controller: controller),
              const SizedBox(height: 24),
              _SectionTitle(l.sectionAppearance),
              const SizedBox(height: 10),
              _ThemePicker(controller: controller),
              const SizedBox(height: 24),
              _SectionTitle(l.sectionTranslation),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      title: Text(l.eyeCareFilter),
                      secondary: const Icon(Icons.nightlight_round),
                      value: controller.eyeCareEnabled,
                      onChanged: controller.setEyeCareEnabled,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(l.showTranslation),
                      subtitle: Text(l.showTranslationSubtitle),
                      value: controller.showTranslation,
                      onChanged: controller.setShowTranslation,
                    ),
                    const Divider(height: 1),
                    _TranslationPicker(
                      controller: controller,
                      translationManager: translationManager,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(l.sectionTextSize),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: controller.arabicFontSize,
                          height: 1.7,
                        ),
                      ),
                      _ValueLabel(
                        label: l.arabicTextSize,
                        value: '${controller.arabicFontSize.round()}',
                      ),
                      Slider(
                        min: 24,
                        max: 56,
                        divisions: 32,
                        value: controller.arabicFontSize,
                        onChanged: controller.setArabicFontSize,
                      ),
                      const Divider(),
                      _ValueLabel(
                        label: l.translationTextSize,
                        value: '${controller.translationFontSize.round()}',
                      ),
                      Slider(
                        min: 13,
                        max: 28,
                        divisions: 15,
                        value: controller.translationFontSize,
                        onChanged: controller.setTranslationFontSize,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(l.sectionHandsFreeReading),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    children: <Widget>[
                      _ValueLabel(
                        label: l.autoScrollSpeed,
                        value: l.autoScrollSpeedValue(
                          controller.autoScrollLinesPerMinute.toStringAsFixed(
                            0,
                          ),
                        ),
                      ),
                      Slider(
                        min: 1,
                        max: 12,
                        divisions: 11,
                        value: controller.autoScrollLinesPerMinute,
                        onChanged: controller.setAutoScrollLinesPerMinute,
                      ),
                      Text(l.autoScrollHint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const GuideScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.help_outline_rounded,
                          color: context.quranColors.gold,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l.guideTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.guideSubtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.quranColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => OnboardingScreen(
                          controller: controller,
                          isPreview: true,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.auto_stories_rounded,
                          color: context.quranColors.gold,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l.onboardingTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.onboardingSubtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.quranColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const AboutScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline_rounded,
                          color: context.quranColors.gold,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l.sourcesTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.sourcesSubtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.quranColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.shield_outlined,
                        color: context.quranColors.gold,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(l.privacyNote)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.controller});

  final AppController controller;

  static const List<(String, String)> _locales = <(String, String)>[
    ('ru', 'Русский'),
    ('en', 'English'),
    ('tg', 'Тоҷикӣ'),
    ('uz', "O'zbekcha"),
    ('ky', 'Кыргызча'),
    ('az', 'Azərbaycan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: RadioGroup<String>(
        groupValue: controller.localeCode,
        onChanged: (String? value) {
          if (value != null) controller.setLocale(value);
        },
        child: Column(
          children: <Widget>[
            for (final (String code, String label) in _locales)
              RadioListTile<String>(value: code, title: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _TranslationPicker extends StatelessWidget {
  const _TranslationPicker({
    required this.controller,
    required this.translationManager,
  });

  final AppController controller;
  final TranslationManager translationManager;

  @override
  Widget build(BuildContext context) {
    // Group translations by language.
    final Map<String, List<TranslationInfo>> groups =
        <String, List<TranslationInfo>>{};
    for (final TranslationInfo t in kAllTranslations) {
      groups.putIfAbsent(t.languageLabel, () => <TranslationInfo>[]).add(t);
    }

    return ListenableBuilder(
      listenable: translationManager,
      builder: (BuildContext context, _) {
        final List<Widget> tiles = <Widget>[];
        for (final MapEntry<String, List<TranslationInfo>> entry
            in groups.entries) {
          // Language group header.
          tiles.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                entry.key,
                style: TextStyle(
                  color: context.quranColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
          // Translation radio tiles.
          for (final TranslationInfo t in entry.value) {
            final bool selected = controller.translatorKey == t.key;
            final bool downloading = translationManager.isAnyDownloading(t.key);
            tiles.add(
              RadioListTile<String>(
                value: t.key,
                title: Text(t.displayName),
                subtitle: !t.isBuiltIn
                    ? Text(
                        downloading
                            ? AppLocalizations.of(context)!.downloading
                            : AppLocalizations.of(context)!.onlineTranslation,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: downloading
                              ? context.quranColors.gold
                              : context.quranColors.muted,
                        ),
                      )
                    : null,
                secondary: downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (!t.isBuiltIn && selected
                          ? Icon(
                              Icons.cloud_done_rounded,
                              size: 20,
                              color: context.quranColors.gold,
                            )
                          : null),
              ),
            );
          }
        }

        return RadioGroup<String>(
          groupValue: controller.translatorKey,
          onChanged: (String? value) {
            if (value != null) controller.setTranslatorKey(value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tiles,
          ),
        );
      },
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final List<(AppThemeStyle, String, Color)> themes =
        <(AppThemeStyle, String, Color)>[
          (AppThemeStyle.parchment, l.themeParchment, const Color(0xFFF4EAD5)),
          (AppThemeStyle.oled, l.themeOled, const Color(0xFF000000)),
          (AppThemeStyle.emerald, l.themeEmerald, const Color(0xFF0B3B32)),
          (AppThemeStyle.light, l.themeLight, const Color(0xFFFAF9F5)),
        ];
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final (AppThemeStyle style, String label, Color color) =
              themes[index];
          final bool selected = controller.themeStyle == style;
          return Semantics(
            selected: selected,
            button: true,
            label: l.themeLabel(label),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => controller.setThemeStyle(style),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 105,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? context.quranColors.gold
                        : context.quranColors.ornament,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0x40777777)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'الله',
                        style: TextStyle(
                          color: Color(0xFFB28A43),
                          fontFamily: 'AmiriQuran',
                          fontSize: 21,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.quranColors.gold,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1.25,
      ),
    );
  }
}

class _ValueLabel extends StatelessWidget {
  const _ValueLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(value, style: TextStyle(color: context.quranColors.gold)),
      ],
    );
  }
}
