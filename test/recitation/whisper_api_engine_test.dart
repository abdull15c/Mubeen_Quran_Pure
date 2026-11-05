import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/recitation/quran_recitation_matcher.dart';
import 'package:mubeen_quran_pure/recitation/quran_speech_engine.dart';
import 'package:mubeen_quran_pure/recitation/tajweed_audio_analyzer.dart';
import 'package:mubeen_quran_pure/recitation/tajweed_rule_detector.dart';
import 'package:mubeen_quran_pure/recitation/whisper_api_engine.dart';

void main() {
  group('WhisperApiEngine JSON parsing', () {
    test('parses valid verbose_json response with word timestamps', () {
      const String json = '''
      {
        "text": "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
        "words": [
          {"word": "بسم", "start": 0.12, "end": 0.48},
          {"word": "الله", "start": 0.52, "end": 0.85},
          {"word": "الرحمن", "start": 0.90, "end": 1.35},
          {"word": "الرحيم", "start": 1.40, "end": 1.82}
        ]
      }
      ''';

      final SpeechResult result = WhisperApiEngine.parseResponse(json);

      expect(result.fullText, 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ');
      expect(result.hasTimestamps, isTrue);
      expect(result.words.length, 4);
      expect(result.words[0].word, 'بسم');
      expect(result.words[0].startSec, 0.12);
      expect(result.words[0].endSec, 0.48);
      expect(result.words[0].durationSec, closeTo(0.36, 0.001));
      expect(result.words[3].word, 'الرحيم');
    });

    test('parses response without words array gracefully', () {
      const String json = '{"text": "بسم الله الرحمن الرحيم"}';

      final SpeechResult result = WhisperApiEngine.parseResponse(json);

      expect(result.fullText, 'بسم الله الرحمن الرحيم');
      expect(result.hasTimestamps, isFalse);
      expect(result.words, isEmpty);
    });

    test('handles empty text response', () {
      const String json = '{"text": "", "words": []}';

      final SpeechResult result = WhisperApiEngine.parseResponse(json);

      expect(result.fullText, isEmpty);
      expect(result.words, isEmpty);
    });

    test('skips malformed word entries', () {
      const String json = '''
      {
        "text": "الحمد لله",
        "words": [
          {"word": "الحمد", "start": 0.1, "end": 0.5},
          {"word": null, "start": 0.6, "end": 0.9},
          {"start": 1.0, "end": 1.3},
          {"word": "لله", "start": 1.0, "end": 1.4}
        ]
      }
      ''';

      final SpeechResult result = WhisperApiEngine.parseResponse(json);

      expect(result.words.length, 2);
      expect(result.words[0].word, 'الحمد');
      expect(result.words[1].word, 'لله');
    });

    test('throws FormatException on invalid JSON structure', () {
      expect(
        () => WhisperApiEngine.parseResponse('"just a string"'),
        throwsFormatException,
      );
    });
  });

  group('WhisperApiEngine availability', () {
    test('isAvailable is false without a build-time API key', () {
      final WhisperApiEngine engine = WhisperApiEngine();
      expect(engine.isAvailable, isFalse);
    });

    test('isAvailable is false when API key is empty', () {
      final WhisperApiEngine engine = WhisperApiEngine(apiKey: '');
      expect(engine.isAvailable, isFalse);
    });

    test('isAvailable is true when API key is provided', () {
      final WhisperApiEngine engine = WhisperApiEngine(apiKey: 'modal-key');
      expect(engine.isAvailable, isTrue);
    });

    test('recognize returns empty result when not available', () async {
      final WhisperApiEngine engine = WhisperApiEngine(apiKey: '');
      final SpeechResult result = await engine.recognize(Uint8List(100));
      expect(result.fullText, isEmpty);
      expect(result.confidence, 0);
    });

    test(
      'cancelAll increments cancellation epoch and aborts recognize immediately',
      () async {
        final WhisperApiEngine engine = WhisperApiEngine(
          apiKey: 'test-key',
          baseUrl: 'https://fake.url',
        );

        // Trigger recognize and immediately cancel
        final Future<SpeechResult> future = engine.recognize(Uint8List(50));
        engine.cancelAll();
        final SpeechResult result = await future;

        expect(result.fullText, isEmpty);
        expect(result.confidence, 0);
        await engine.dispose();
      },
    );
  });

  group('evaluateWithTimestamps pipeline', () {
    test('evaluates spoken text with timestamps and detects Madd timing', () {
      // Simulate an Ayah with Madd Lazim: الضَّآلِّينَ
      const String ayahText =
          'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّآلِّينَ';
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        ayahText,
      );
      final Map<int, List<TajweedRuleOccurrence>> tajweedRules =
          TajweedRuleDetector.analyzeAyah(ayahText);

      // Simulate a Whisper response with word timestamps
      final SpeechResult speechResult = SpeechResult(
        fullText: 'صراط الذين انعمت عليهم غير المغضوب عليهم ولا الضالين',
        words: <WordTimestamp>[
          const WordTimestamp(word: 'صراط', startSec: 0.1, endSec: 0.5),
          const WordTimestamp(word: 'الذين', startSec: 0.55, endSec: 0.9),
          const WordTimestamp(word: 'انعمت', startSec: 0.95, endSec: 1.3),
          const WordTimestamp(word: 'عليهم', startSec: 1.35, endSec: 1.7),
          const WordTimestamp(word: 'غير', startSec: 1.75, endSec: 2.0),
          const WordTimestamp(word: 'المغضوب', startSec: 2.05, endSec: 2.6),
          const WordTimestamp(word: 'عليهم', startSec: 2.65, endSec: 3.0),
          const WordTimestamp(word: 'ولا', startSec: 3.05, endSec: 3.3),
          const WordTimestamp(word: 'الضالين', startSec: 3.35, endSec: 5.0),
        ],
      );

      final RecitationResult result =
          QuranRecitationMatcher.evaluateWithTimestamps(
            tokens: tokens,
            speechResult: speechResult,
            tajweedRules: tajweedRules,
          );

      expect(result.isCompleted, isTrue);
      expect(result.correctCount, greaterThan(0));

      // Check that timestamps were recorded on tokens
      final AyahWordToken firstToken = tokens.first;
      expect(firstToken.startSec, isNotNull);
      expect(firstToken.endSec, isNotNull);
    });

    test('falls back to text-only evaluation when no timestamps', () {
      const String ayahText = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        ayahText,
      );
      final Map<int, List<TajweedRuleOccurrence>> tajweedRules =
          TajweedRuleDetector.analyzeAyah(ayahText);

      const SpeechResult speechResult = SpeechResult(
        fullText: 'الحمد لله رب العالمين',
        // No word timestamps (platform ASR fallback)
      );

      final RecitationResult result =
          QuranRecitationMatcher.evaluateWithTimestamps(
            tokens: tokens,
            speechResult: speechResult,
            tajweedRules: tajweedRules,
          );

      expect(result.isCompleted, isTrue);
      expect(result.correctCount, 4);
      // No Madd evaluation without timestamps
      expect(tokens.first.maddEval, isNull);
    });

    test('does not complete timestamped recitation with skipped words', () {
      const String ayahText = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';
      final List<AyahWordToken> tokens = QuranRecitationMatcher.tokenizeAyah(
        ayahText,
      );

      const SpeechResult speechResult = SpeechResult(
        fullText: 'لله رب العالمين',
        words: <WordTimestamp>[
          WordTimestamp(word: 'لله', startSec: 0.1, endSec: 0.4),
          WordTimestamp(word: 'رب', startSec: 0.5, endSec: 0.7),
          WordTimestamp(word: 'العالمين', startSec: 0.8, endSec: 1.3),
        ],
      );

      final RecitationResult result =
          QuranRecitationMatcher.evaluateWithTimestamps(
            tokens: tokens,
            speechResult: speechResult,
            tajweedRules: const <int, List<TajweedRuleOccurrence>>{},
          );

      expect(tokens.first.status, RecitationWordStatus.mismatch);
      expect(result.isCompleted, isFalse);
    });

    test('MaddEvaluation provides neutral educational guidance', () {
      final MaddEvaluation eval = TajweedAudioAnalyzer.evaluateMadd(
        rule: TajweedRuleType.madd6,
        actualDurationSec: 1.65,
      );
      expect(eval.quality, MaddQuality.informational);
      expect(eval.message, contains('Правило'));
      expect(eval.message, contains('Длительность слова'));
    });
  });
}
