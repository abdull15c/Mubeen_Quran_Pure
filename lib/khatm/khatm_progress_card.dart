import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubeen_quran_pure/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'khatm_controller.dart';
import 'khatm_models.dart';

class KhatmProgressCard extends StatelessWidget {
  const KhatmProgressCard({
    super.key,
    required this.khatmController,
    this.onOpenMushaf,
  });

  final KhatmController khatmController;
  final VoidCallback? onOpenMushaf;

  void _showCreatePlanDialog(BuildContext context) {
    int selectedDays = 30;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final AppLocalizations l = AppLocalizations.of(context)!;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: <Widget>[
                  const Icon(Icons.flag_rounded, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 10),
                  Text(l.khatmGoalTitle),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.khatmDaysQuestion,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <int>[15, 30, 60, 90].map((int days) {
                      final bool isSelected = selectedDays == days;
                      return ChoiceChip(
                        label: Text(l.daysCount(days)),
                        selected: isSelected,
                        selectedColor: context.quranColors.gold,
                        onSelected: (bool selected) {
                          if (selected) {
                            setModalState(() => selectedDays = days);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.quranColors.paper,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 20,
                          color: Color(0xFFD4AF37),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.dailyGoalPages((604 / selectedDays).ceil()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.quranColors.deepGreen,
                    foregroundColor: const Color(0xFFE3C47D),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact().ignore();
                    khatmController.createPlan(
                      targetDays: selectedDays,
                      title: l.khatmPlanTitle(selectedDays),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(l.startKhatm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: khatmController,
      builder: (BuildContext context, _) {
        if (!khatmController.hasActivePlan) {
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _showCreatePlanDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.quranColors.gold.withValues(alpha: 0.18),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: Color(0xFFD4AF37),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l.setKhatmGoal,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.calculateDailyNorm,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFFD4AF37),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final KhatmPlan plan = khatmController.plan!;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.quranColors.deepGreen,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: context.quranColors.gold.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.track_changes_rounded,
                    color: Color(0xFFE3C47D),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.title,
                      style: const TextStyle(
                        color: Color(0xFFEAE3D2),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFFE3C47D),
                      size: 18,
                    ),
                    onSelected: (String val) {
                      if (val == 'new') {
                        _showCreatePlanDialog(context);
                      } else if (val == 'delete') {
                        khatmController.deletePlan();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'new',
                            child: Text(l.editGoal),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(l.resetGoal),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  // Circular Progress Indicator
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          value: plan.progressPercentage,
                          strokeWidth: 6,
                          backgroundColor: const Color(0x33E3C47D),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFE3C47D),
                          ),
                        ),
                        Text(
                          '${plan.progressPercentInt}%',
                          style: const TextStyle(
                            color: Color(0xFFE3C47D),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l.khatmPagesRead(plan.completedCount),
                          style: const TextStyle(
                            color: Color(0xFFEAE3D2),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.khatmDailyNormRemain(
                            plan.dailyTargetPages,
                            plan.daysRemaining,
                          ),
                          style: const TextStyle(
                            color: Color(0xFFB5C3B8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
