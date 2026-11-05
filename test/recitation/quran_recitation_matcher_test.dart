import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/recitation/quran_recitation_matcher.dart';
import 'package:mubeen_quran_pure/recitation/quran_speech_engine.dart';

void main() {
  group('QuranRecitationMatcher Tests', () {
    test(
      'Normalizes Arabic text correctly with diacritics removal and normalization',
      () {
        const String input = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
        final String normalized = QuranRecitationMatcher.normalizeArabic(input);
        expect(normalized, 'بسم الله الرحمن الرحيم');
      },
    );

    test('Glues isolated single-character Arabic prefixes correctly', () {
      final List<String> raw = <String>['و', 'بالحق', 'ف', 'استقم', 'ل', 'لله'];
      final List<String> glued = QuranRecitationMatcher.glueSpokenWords(raw);

      expect(glued.length, 3);
      expect(glued[0], 'وبالحق');
      expect(glued[1], 'فاستقم');
      expect(glued[2], 'للله');
    });

    test('Tokenizes Ayah correctly', () {
      const String input = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ۝١';
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        input,
      );

      expect(tokens.length, 4);
      expect(tokens[0].normalizedText, 'بسم');
      expect(tokens[1].normalizedText, 'الله');
      expect(tokens[2].normalizedText, 'الرحمن');
      expect(tokens[3].normalizedText, 'الرحيم');
    });

    test(
      'Evaluates spoken text and accurately matches correct words with prefix gluing',
      () {
        const String input = 'وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ';
        final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
          input,
        );

        // User speaks with isolated particles 'و تواصوا ب الحق'
        final RecitationResult result =
            QuranRecitationMatcher.evaluateSpokenText(
              tokens: tokens,
              recognizedArabicSpeech: 'و تواصوا ب الحق',
            );

        expect(tokens[0].status, RecitationWordStatus.correct);
        expect(tokens[1].status, RecitationWordStatus.correct);
        expect(result.correctCount, 2);
      },
    );

    test(
      'Detects Mahraj phonetic confusion when similar letters are swapped',
      () {
        const String input = 'إِيَّاكَ نَعْبُدُ';
        final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
          input,
        );

        // User confuses 'ع' with Hamza 'ء' -> 'نئبد' or 'نعبد'
        final RecitationResult result =
            QuranRecitationMatcher.evaluateSpokenText(
              tokens: tokens,
              recognizedArabicSpeech: 'إياك نءبد',
            );

        expect(tokens[0].status, RecitationWordStatus.correct);
        expect(tokens[1].status, RecitationWordStatus.mismatch);
        expect(tokens[1].mismatchHint, contains('‘Айн'));
        expect(result.correctCount, 1);
        expect(result.mistakeCount, 1);
        expect(result.isCompleted, isFalse);
      },
    );

    test('Does not complete an Ayah from arbitrary wrong words', () {
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        'الحمد لله رب العالمين',
      );

      final RecitationResult result = QuranRecitationMatcher.evaluateSpokenText(
        tokens: tokens,
        recognizedArabicSpeech: 'كتاب مسجد نور سلام',
      );

      expect(result.correctCount, 0);
      expect(result.isCompleted, isFalse);
      expect(tokens.first.status, RecitationWordStatus.mismatch);
    });

    test('Does not complete an Ayah when a word was skipped', () {
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        'الحمد لله رب العالمين',
      );

      final RecitationResult result = QuranRecitationMatcher.evaluateSpokenText(
        tokens: tokens,
        recognizedArabicSpeech: 'لله رب العالمين',
      );

      expect(tokens.first.status, RecitationWordStatus.mismatch);
      expect(result.correctCount, 3);
      expect(result.isCompleted, isFalse);
    });

    test('Evaluates complete Ayah recitation', () {
      const String input = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        input,
      );

      final RecitationResult result = QuranRecitationMatcher.evaluateSpokenText(
        tokens: tokens,
        recognizedArabicSpeech: 'الحمد لله رب العالمين',
      );

      expect(result.correctCount, 4);
      expect(result.isCompleted, true);
      expect(result.accuracy, 1.0);
      expect(result.scorePercentage, 100);
    });

    test(
      'قلوب and كلوب are rejected as Mahraj error in both text and timestamps',
      () {
        final List<AyahWordToken> tokensText =
            QuranRecitationMatcher.tokenizeAyah('قلوب');
        final RecitationResult resultText =
            QuranRecitationMatcher.evaluateSpokenText(
              tokens: tokensText,
              recognizedArabicSpeech: 'كلوب',
            );
        expect(tokensText.first.status, RecitationWordStatus.mismatch);
        expect(tokensText.first.mismatchHint, contains('Коф'));
        expect(resultText.correctCount, 0);

        final List<AyahWordToken> tokensTime =
            QuranRecitationMatcher.tokenizeAyah('قلوب');
        final RecitationResult resultTime =
            QuranRecitationMatcher.evaluateWithTimestamps(
              tokens: tokensTime,
              speechResult: const SpeechResult(
                fullText: 'كلوب',
                words: <WordTimestamp>[
                  WordTimestamp(word: 'كلوب', startSec: 0.1, endSec: 0.6),
                ],
              ),
              tajweedRules: const {},
            );
        expect(tokensTime.first.status, RecitationWordStatus.mismatch);
        expect(tokensTime.first.mismatchHint, contains('Коф'));
        expect(resultTime.correctCount, 0);
      },
    );

    test('Completely wrong attempt does not return 100% accuracy', () {
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        'الحمد لله رب العالمين',
      );
      final RecitationResult result = QuranRecitationMatcher.evaluateSpokenText(
        tokens: tokens,
        recognizedArabicSpeech: 'باطل شمس قمر',
      );
      expect(result.correctCount, 0);
      expect(result.accuracy, 0.0);
      expect(result.scorePercentage, 0);
      expect(result.isCompleted, isFalse);
    });

    test(
      'Stop signs between words do not shift timestamps of adjacent words',
      () {
        final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
          'الحمد لله',
        );
        final RecitationResult result =
            QuranRecitationMatcher.evaluateWithTimestamps(
              tokens: tokens,
              speechResult: const SpeechResult(
                fullText: 'الحمد ۚ لله',
                words: <WordTimestamp>[
                  WordTimestamp(word: 'الحمد', startSec: 0.2, endSec: 0.7),
                  WordTimestamp(
                    word: 'ۚ',
                    startSec: 0.8,
                    endSec: 0.85,
                  ), // stop sign
                  WordTimestamp(word: 'لله', startSec: 0.9, endSec: 1.4),
                ],
              ),
              tajweedRules: const {},
            );

        expect(result.correctCount, 2);
        expect(tokens[0].status, RecitationWordStatus.correct);
        expect(tokens[0].startSec, 0.2);
        expect(tokens[0].endSec, 0.7);
        expect(tokens[1].status, RecitationWordStatus.correct);
        expect(tokens[1].startSec, 0.9);
        expect(tokens[1].endSec, 1.4);
      },
    );

    test('Uthmani dagger alif and tatweel normalize to standard forms', () {
      // مَٰلِكِ in Uthmani text has dagger alif (\u0670). Spoken Arabic & ASR produces مالك.
      const String uthmaniMalik = 'مَٰلِكِ يَوْمِ الدِّينِ';
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        uthmaniMalik,
      );

      expect(tokens[0].normalizedText, equals('ملك'));
      expect(tokens[0].alternateText, equals('مالك'));

      final RecitationResult result = QuranRecitationMatcher.evaluateSpokenText(
        tokens: tokens,
        recognizedArabicSpeech: 'مالك يوم الدين',
      );

      expect(tokens[0].status, equals(RecitationWordStatus.correct));
      expect(result.correctCount, 3);
      expect(result.isCompleted, isTrue);

      // Tatweel removal:
      expect(
        QuranRecitationMatcher.normalizeArabic('الـرحـمن'),
        equals('الرحمن'),
      );
    });

    test('New attempt cleans up old tokens state completely', () {
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        'الحمد',
      );
      QuranRecitationMatcher.evaluateSpokenText(
        tokens: tokens,
        recognizedArabicSpeech: 'خطأ',
      );
      expect(tokens.first.status, RecitationWordStatus.mismatch);

      // Now user repeats correctly
      final RecitationResult secondAttempt =
          QuranRecitationMatcher.evaluateSpokenText(
            tokens: tokens,
            recognizedArabicSpeech: 'الحمد',
          );
      expect(tokens.first.status, RecitationWordStatus.correct);
      expect(tokens.first.mismatchHint, isNull);
      expect(secondAttempt.correctCount, 1);
      expect(secondAttempt.isCompleted, isTrue);
    });
  });
}
