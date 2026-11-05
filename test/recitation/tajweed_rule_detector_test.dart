import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/recitation/tajweed_audio_analyzer.dart';
import 'package:mubeen_quran_pure/recitation/tajweed_rule_detector.dart';

void main() {
  group('TajweedRuleDetector & AudioAnalyzer Tests', () {
    test('Detects Madd Lazim (6 beats) via pattern detection', () {
      const String word = 'الضَّآلِّينَ';
      final List<TajweedRuleOccurrence> rules = TajweedRuleDetector.analyzeWord(
        word,
        0,
      );

      expect(rules.isNotEmpty, true);
      expect(
        rules.any((TajweedRuleOccurrence r) => r.rule == TajweedRuleType.madd6),
        true,
      );
    });

    test('Detects Qalqalah on letters with sukun', () {
      const String word = 'الْفَلَقِ';
      final List<TajweedRuleOccurrence> rules = TajweedRuleDetector.analyzeWord(
        word,
        0,
      );

      expect(rules.isNotEmpty, true);
      expect(
        rules.any(
          (TajweedRuleOccurrence r) => r.rule == TajweedRuleType.qalqalah,
        ),
        true,
      );
    });

    test('Detects Ghunnah on Noon and Meem with Shaddah', () {
      const String word = 'إِنَّ';
      final List<TajweedRuleOccurrence> rules = TajweedRuleDetector.analyzeWord(
        word,
        0,
      );

      expect(rules.isNotEmpty, true);
      expect(
        rules.any(
          (TajweedRuleOccurrence r) => r.rule == TajweedRuleType.ghunnah,
        ),
        true,
      );
    });

    test('Detects Ikhfa and Idgham across word boundaries in an Ayah', () {
      // 'مِن قَبْلِ' (Ikhfa on Nun before Qaf)
      const String ayah = 'مِن قَبْلِكَ وَمَن يَقُولُ';
      final Map<int, List<TajweedRuleOccurrence>> rules =
          TajweedRuleDetector.analyzeAyah(ayah);

      expect(rules.isNotEmpty, true);
      // Word 0 'من' followed by 'قبل' -> Ikhfa
      final List<TajweedRuleOccurrence>? word0Rules = rules[0];
      expect(
        word0Rules?.any(
          (TajweedRuleOccurrence r) => r.rule == TajweedRuleType.ikhfa,
        ),
        true,
      );
    });

    test('Does NOT flag vowelled Nun with fatha/kasra as Nun Sakina', () {
      // 'الْعَالَمِينَ الرَّحْمَٰنِ' - العالمين ends with vowelled Nun (fatha نَ).
      // It should NOT trigger Idgham on next word (الرحمن starts with R)!
      const String fatihaSegment = 'الْعَالَمِينَ الرَّحْمَٰنِ';
      final Map<int, List<TajweedRuleOccurrence>> rules =
          TajweedRuleDetector.analyzeAyah(fatihaSegment);

      final List<TajweedRuleOccurrence>? word0Rules = rules[0];
      expect(
        word0Rules?.any(
              (TajweedRuleOccurrence r) => r.rule == TajweedRuleType.idgham,
            ) ??
            false,
        isFalse,
      );

      // 'عَنِيدٍ' has vowelled Nun with kasra - should NOT trigger internal Ikhfa
      final List<TajweedRuleOccurrence> anidRules =
          TajweedRuleDetector.analyzeWord('عَنِيدٍ', 0);
      expect(
        anidRules.any(
          (TajweedRuleOccurrence r) => r.rule == TajweedRuleType.ikhfa,
        ),
        isFalse,
      );

      // 'الْإِنسَانَ' has unvowelled Nun followed by Sin -> SHOULD trigger internal Ikhfa
      final List<TajweedRuleOccurrence> insanRules =
          TajweedRuleDetector.analyzeWord('الْإِنسَانَ', 0);
      expect(
        insanRules.any(
          (TajweedRuleOccurrence r) => r.rule == TajweedRuleType.ikhfa,
        ),
        isTrue,
      );
    });

    test('Evaluates Madd duration neutrally without dogmatic claims', () {
      final MaddEvaluation eval = TajweedAudioAnalyzer.evaluateMadd(
        rule: TajweedRuleType.madd4,
        actualDurationSec: 1.1,
      );
      expect(eval.quality, MaddQuality.informational);
      expect(eval.message, contains('Правило'));
      expect(eval.message, contains('Длительность слова'));
    });
  });
}
