import 'package:flutter/material.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.controller,
    this.isPreview = false,
  });

  final AppController controller;
  final bool isPreview;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _complete() {
    if (widget.isPreview) {
      Navigator.of(context).pop();
    } else {
      widget.controller.completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final QuranThemeColors colors = context.quranColors;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.gold.withValues(alpha: 0.14),
                          border: Border.all(
                            color: colors.gold.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: colors.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'MUBEEN',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                              color: colors.ink,
                            ),
                          ),
                          Text(
                            'QURAN PURE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: colors.gold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _complete,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.muted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      widget.isPreview
                          ? l.close
                          : _currentPage == _pageCount - 1
                          ? ''
                          : l.skip,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: <Widget>[
                  _ReminderSlide(colors: colors),
                  _ModesSlide(colors: colors),
                  _FeaturesSlide(colors: colors),
                ],
              ),
            ),

            // Bottom Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Animated Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(_pageCount, (int index) {
                      final bool isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isSelected ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.gold
                              : colors.ornament.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.deepGreen,
                        foregroundColor: const Color(0xFFF4EAD5),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: colors.gold.withValues(alpha: 0.65),
                            width: 1.2,
                          ),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            _currentPage == _pageCount - 1
                                ? l.startReading
                                : l.next,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pageCount - 1
                                ? Icons.auto_stories_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                            color: colors.gold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Slide 1: Quranic Reminder & Philosophy
class _ReminderSlide extends StatelessWidget {
  const _ReminderSlide({required this.colors});

  final QuranThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          // Quranic Medallion
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.gold.withValues(alpha: 0.12),
              border: Border.all(color: colors.gold, width: 1.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.gold.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 34,
              color: colors.gold,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            l.reminderTitle,
            style: TextStyle(
              color: colors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 14),

          // Quranic Verse Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: colors.ornament.withValues(alpha: 0.18),
              border: Border.all(
                color: colors.ornament.withValues(alpha: 0.8),
                width: 1.2,
              ),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  'كِتَـٰبٌ أَنزَلْنَـٰهُ إِلَيْكَ مُبَـٰرَكٌۭ لِّيَدَّبَّرُوٓا۟ ءَايَـٰتِهِۦ وَلِيَتَذَكَّرَ أُو۟لُوا۟ ٱلْأَلْبَـٰبِ',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: context.quranType.arabicFamily,
                    fontSize: 23,
                    height: 1.9,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  color: colors.gold.withValues(alpha: 0.35),
                  thickness: 0.8,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 10),
                Text(
                  l.reminderAyah,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                    color: colors.ink.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.reminderRef,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Purity Statement Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: colors.deepGreen.withValues(alpha: 0.08),
              border: Border.all(
                color: colors.deepGreen.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.shield_outlined, size: 24, color: colors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.purityStatement,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: colors.ink.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Slide 2: Reading Modes (Flow & Mushaf)
class _ModesSlide extends StatelessWidget {
  const _ModesSlide({required this.colors});

  final QuranThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 6),
          Text(
            l.readingModesTitle,
            style: TextStyle(
              color: colors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.readingModesSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 16),

          // Mode 1: Vertical Flow
          _FeatureCard(
            colors: colors,
            icon: Icons.view_agenda_rounded,
            badge: l.flowModeBadge,
            title: l.flowModeTitle,
            description: l.flowModeDesc,
          ),
          const SizedBox(height: 12),

          // Mode 2: Traditional Mushaf
          _FeatureCard(
            colors: colors,
            icon: Icons.auto_stories_rounded,
            badge: l.mushafModeBadge,
            title: l.mushafModeTitle,
            description: l.mushafModeDesc,
          ),
        ],
      ),
    );
  }
}

// Slide 3: Customization & Search
class _FeaturesSlide extends StatelessWidget {
  const _FeaturesSlide({required this.colors});

  final QuranThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 6),
          Text(
            l.featuresTitle,
            style: TextStyle(
              color: colors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.featuresSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 16),

          _FeatureCard(
            colors: colors,
            icon: Icons.palette_outlined,
            badge: l.themesFeatureBadge,
            title: l.themesFeatureTitle,
            description: l.themesFeatureDesc,
          ),
          const SizedBox(height: 12),

          _FeatureCard(
            colors: colors,
            icon: Icons.search_rounded,
            badge: l.searchFeatureBadge,
            title: l.searchFeatureTitle,
            description: l.searchFeatureDesc,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.colors,
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
  });

  final QuranThemeColors colors;
  final IconData icon;
  final String badge;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.ornament.withValues(alpha: 0.16),
        border: Border.all(
          color: colors.ornament.withValues(alpha: 0.7),
          width: 1.1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.gold.withValues(alpha: 0.14),
              border: Border.all(
                color: colors.gold.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 22, color: colors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: colors.gold.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    badge.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: colors.ink.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
