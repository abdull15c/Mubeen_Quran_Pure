import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';

import '../../models/quran_models.dart';
import '../../theme/app_theme.dart';

/// Shared bottom sheet for picking an ayah number from a grid.
void showAyahPickerSheet({
  required BuildContext context,
  required Surah surah,
  required void Function(int ayahNumber) onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: context.quranColors.gold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.jumpToAyah,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.surahInfoLabel(
                          surah.id,
                          surah.nameRussian,
                          surah.ayahCount,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.quranColors.ink.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 64,
                  mainAxisExtent: 48,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: surah.ayahCount,
                itemBuilder: (BuildContext context, int index) {
                  final int ayahNum = index + 1;
                  return ActionChip(
                    label: Text(
                      '$ayahNum',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: context.quranColors.paper,
                    side: BorderSide(
                      color: context.quranColors.gold.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick().ignore();
                      Navigator.of(context).pop();
                      onSelected(ayahNum);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Generic bottom sheet used for tafsir and word analysis.
class StudySheet extends StatelessWidget {
  const StudySheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.loading,
    required this.error,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final bool loading;
  final Object? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final QuranThemeColors colors = context.quranColors;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 16, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.ink.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '${AppLocalizations.of(context)!.failedToLoadData}\n$error',
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                    child: child,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Error / empty state message with optional retry action.
class ReaderMessage extends StatelessWidget {
  const ReaderMessage({
    super.key,
    required this.icon,
    required this.message,
    this.details,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final Object? details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: context.quranColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (details != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '$details',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circled ayah number badge.
class AyahNumber extends StatelessWidget {
  const AyahNumber({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.quranColors.gold.withValues(alpha: 0.12),
        border: Border.all(
          color: context.quranColors.gold.withValues(alpha: 0.85),
          width: 1.2,
        ),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: context.quranColors.gold,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Badge shown when the ayah contains a sajda.
class SajdaBadge extends StatelessWidget {
  const SajdaBadge({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        '۩ ${AppLocalizations.of(context)!.sajda}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Auto-scroll FAB with speed controls.
class AutoScrollControl extends StatelessWidget {
  const AutoScrollControl({
    super.key,
    required this.running,
    required this.speed,
    required this.onToggle,
    required this.onSlower,
    required this.onFaster,
  });

  final bool running;
  final double speed;
  final VoidCallback onToggle;
  final VoidCallback onSlower;
  final VoidCallback onFaster;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black54,
      color: context.quranColors.deepGreen,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: context.quranColors.gold.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (running)
              IconButton(
                tooltip: AppLocalizations.of(context)!.slower,
                color: Colors.white70,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onSlower();
                },
                icon: const Icon(Icons.remove_rounded, size: 20),
              ),
            IconButton(
              tooltip: running
                  ? AppLocalizations.of(context)!.pause
                  : AppLocalizations.of(context)!.autoScroll,
              color: const Color(0xFFE3C47D),
              onPressed: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              icon: Icon(
                running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 26,
              ),
            ),
            if (running) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '${speed.round()} ${AppLocalizations.of(context)!.linesPerMinute(speed.round())}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.faster,
                color: Colors.white70,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onFaster();
                },
                icon: const Icon(Icons.add_rounded, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ornament line with juz label and page number.
class OrnamentLine extends StatelessWidget {
  const OrnamentLine({super.key, required this.label, this.juz});

  final String label;
  final int? juz;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (juz != null)
          Text(
            AppLocalizations.of(context)!.juz(juz!),
            style: TextStyle(
              color: context.quranColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        const Expanded(child: Divider(indent: 8, endIndent: 8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: TextStyle(
              color: context.quranColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(indent: 8, endIndent: 8)),
      ],
    );
  }
}

/// Label + value row used in word detail dialog.
class WordDetail extends StatelessWidget {
  const WordDetail({super.key, required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: context.quranColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value?.trim().isNotEmpty == true
                  ? value!
                  : AppLocalizations.of(context)!.notSpecified,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable word chip used in the word analysis sheet.
class WordChipCard extends StatelessWidget {
  const WordChipCard({super.key, required this.word, required this.onTap});

  final QuranWord word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final QuranThemeColors colors = context.quranColors;

    return Material(
      color: colors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.gold.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                word.textArabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 22,
                  height: 1.4,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                word.textRussian,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tip banner shown on first reader open.
class FirstTimeReaderTip extends StatelessWidget {
  const FirstTimeReaderTip({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: context.quranColors.gold.withValues(alpha: 0.12),
          border: Border.all(
            color: context.quranColors.gold.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.lightbulb_outline_rounded,
              color: context.quranColors.gold,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.readerTipTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l.readerTipBody,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: context.quranColors.ink.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.understood,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
