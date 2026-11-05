import 'tajweed_rule_detector.dart';

enum MaddQuality { informational, perfect, underExtended, overExtended }

final class MaddEvaluation {
  const MaddEvaluation({
    required this.rule,
    required this.targetSec,
    required this.actualSec,
    this.quality = MaddQuality.informational,
    required this.message,
  });

  final TajweedRuleType rule;
  final double targetSec;
  final double actualSec;
  final MaddQuality quality;
  final String message;
}

class TajweedAudioAnalyzer {
  /// Provides educational feedback on words with Madd rules.
  /// Does not make categorical acoustic claims based solely on whole-word duration.
  static MaddEvaluation evaluateMadd({
    required TajweedRuleType rule,
    required double actualDurationSec,
  }) {
    final double target = rule.targetDurationSec;
    final int beats = rule.targetBeats;

    return MaddEvaluation(
      rule: rule,
      targetSec: target,
      actualSec: actualDurationSec,
      quality: MaddQuality.informational,
      message:
          'Правило: ${rule.title} (~$beats счёта). Длительность слова: ${actualDurationSec.toStringAsFixed(1)} сек.',
    );
  }
}
