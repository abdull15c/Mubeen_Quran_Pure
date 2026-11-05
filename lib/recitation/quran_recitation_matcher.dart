import 'dart:math' as math;

import 'quran_speech_engine.dart';
import 'tajweed_audio_analyzer.dart';
import 'tajweed_rule_detector.dart';

enum RecitationWordStatus { pending, active, correct, mismatch, hinted }

final class AyahWordToken {
  AyahWordToken({
    required this.index,
    required this.originalText,
    required this.normalizedText,
    this.alternateText,
    this.status = RecitationWordStatus.pending,
    this.mismatchHint,
    this.spokenWord,
    this.startSec,
    this.endSec,
    this.maddEval,
  });

  final int index;
  final String originalText;
  final String normalizedText;
  final String? alternateText;
  RecitationWordStatus status;
  String? mismatchHint;
  String? spokenWord;

  /// Word-level timing from Whisper (null when platform ASR is used).
  double? startSec;
  double? endSec;

  /// Madd duration evaluation from real voice timing (null when no Madd rule
  /// applies or when word timestamps are unavailable).
  MaddEvaluation? maddEval;

  void reset({bool isActive = false}) {
    status = isActive
        ? RecitationWordStatus.active
        : RecitationWordStatus.pending;
    mismatchHint = null;
    spokenWord = null;
    startSec = null;
    endSec = null;
    maddEval = null;
  }

  AyahWordToken copyWith({
    RecitationWordStatus? status,
    String? mismatchHint,
    String? spokenWord,
  }) {
    return AyahWordToken(
      index: index,
      originalText: originalText,
      normalizedText: normalizedText,
      alternateText: alternateText,
      status: status ?? this.status,
      mismatchHint: mismatchHint ?? this.mismatchHint,
      spokenWord: spokenWord ?? this.spokenWord,
      startSec: startSec,
      endSec: endSec,
      maddEval: maddEval,
    );
  }
}

final class _SpokenWordUnit {
  const _SpokenWordUnit({
    required this.normalizedText,
    required this.originalText,
    this.startSec,
    this.endSec,
  });

  final String normalizedText;
  final String originalText;
  final double? startSec;
  final double? endSec;
}

class QuranRecitationMatcher {
  /// Regular expression to match Arabic diacritics (harakat), Quranic stop marks, etc.
  static final RegExp _tashkeelRegex = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0610-\u061A\u08F0-\u08FF]',
  );

  /// Known Arabic single-letter prefixes (conjunctions/prepositions) that STT engines might split.
  static const Set<String> _singlePrefixes = <String>{
    'و',
    'ف',
    'ب',
    'ل',
    'ك',
    'ال',
  };

  /// Common Mahraj (articulation) confusion pairs with educational tips.
  static const Map<String, (String, String)> _mahrajTips =
      <String, (String, String)>{
        'ع': (
          'ء',
          'Обратите внимание на гортанный звук «‘Айн» (ع) — не путайте с «Хамзой» (ء).',
        ),
        'ح': (
          'ه',
          'Звук «Ха» (ح) образуется в средней части гортани — мягче, чем «Ха» (ه).',
        ),
        'ص': (
          'س',
          'Буква «Сод» (ص) — твердая эмфатическая, в отличие от мягкой «Син» (س).',
        ),
        'ط': (
          'ت',
          'Буква «То» (ط) — твердая эмфатическая, не смягчайте до «Та» (ت).',
        ),
        'ض': ('д', 'Буква «Дод» (ض) образуется краем языка о коренные зубы.'),
        'ق': (
          'ك',
          'Буква «Коф» (ق) образуется в самой глубине языка — глубже, чем «Кяф» (ك).',
        ),
        'غ': (
          'خ',
          'Буква «Гойн» (غ) — звонкий гортанный звук, не путайте с глухой «Хо» (خ).',
        ),
        'ذ': ('з', 'Буква «Заль» (ذ) — межзубная, кончик языка между зубами.'),
        'ث': ('с', 'Буква «Са» (ث) — межзубная, кончик языка между зубами.'),
        'ظ': ('з', 'Буква «Зо» (ظ) — твердая эмфатическая межзубная.'),
      };

  /// Cleans and normalizes Arabic text for phonetic matching.
  static String normalizeArabic(String text) {
    if (text.isEmpty) return '';

    // Remove Tatweel / Kashida (U+0640)
    String cleaned = text.replaceAll('\u0640', '');

    cleaned = cleaned.replaceAll(_tashkeelRegex, '');

    // Normalize Alif forms (إ, أ, آ, ٱ -> ا)
    cleaned = cleaned.replaceAll(RegExp(r'[إأآٱ]'), 'ا');

    // Normalize Alif Maqsura (ى -> ي)
    cleaned = cleaned.replaceAll('ى', 'ي');

    // Normalize Taa Marbuta (ة -> ه)
    cleaned = cleaned.replaceAll('ة', 'ه');

    // Normalize Hamza forms
    cleaned = cleaned.replaceAll(RegExp(r'[ؤئ]'), 'ء');

    // Strip punctuation, symbols, Quranic ornaments and digits
    cleaned = cleaned.replaceAll(
      RegExp(r'[۝۞\d\u0660-\u0669\u06F0-\u06F9\s\p{P}]+', unicode: true),
      ' ',
    );

    return cleaned.trim();
  }

  /// Glues isolated single-character prefixes (e.g. 'و' 'بالحق' -> 'وبالحق')
  static List<String> glueSpokenWords(List<String> rawTokens) {
    final List<String> glued = <String>[];
    for (var i = 0; i < rawTokens.length; i++) {
      final String token = rawTokens[i].trim();
      if (token.isEmpty) continue;

      if (_singlePrefixes.contains(token) && i + 1 < rawTokens.length) {
        final String next = rawTokens[i + 1].trim();
        glued.add('$token$next');
        i++;
      } else {
        glued.add(token);
      }
    }
    return glued;
  }

  /// Glues units while correctly combining start and end timestamps.
  static List<_SpokenWordUnit> _glueSpokenUnits(List<_SpokenWordUnit> raw) {
    final List<_SpokenWordUnit> glued = <_SpokenWordUnit>[];
    for (var i = 0; i < raw.length; i++) {
      final _SpokenWordUnit current = raw[i];
      if (_singlePrefixes.contains(current.normalizedText) &&
          i + 1 < raw.length) {
        final _SpokenWordUnit next = raw[i + 1];
        final String mergedNorm =
            '${current.normalizedText}${next.normalizedText}';
        final String mergedOrig =
            '${current.originalText} ${next.originalText}';

        double? mergedStart;
        double? mergedEnd;
        if (current.startSec != null && next.startSec != null) {
          mergedStart = math.min(current.startSec!, next.startSec!);
        } else {
          mergedStart = current.startSec ?? next.startSec;
        }

        if (current.endSec != null && next.endSec != null) {
          mergedEnd = math.max(current.endSec!, next.endSec!);
        } else {
          mergedEnd = next.endSec ?? current.endSec;
        }

        glued.add(
          _SpokenWordUnit(
            normalizedText: mergedNorm,
            originalText: mergedOrig,
            startSec: mergedStart,
            endSec: mergedEnd,
          ),
        );
        i++;
      } else {
        glued.add(current);
      }
    }
    return glued;
  }

  /// Splits an Ayah's full Arabic text into structured word tokens.
  static List<AyahWordToken> tokenizeAyah(String ayahUthmaniText) {
    final List<String> rawWords = ayahUthmaniText
        .replaceAll(
          RegExp(r'[۝۞\d\u0660-\u0669\u06F0-\u06F9]', unicode: true),
          '',
        )
        .split(RegExp(r'\s+'))
        .where((String w) => w.trim().isNotEmpty)
        .toList();

    final List<AyahWordToken> tokens = <AyahWordToken>[];
    for (var i = 0; i < rawWords.length; i++) {
      final String raw = rawWords[i].trim();
      final String norm = normalizeArabic(raw);
      String? alt;
      if (raw.contains('\u0670')) {
        final String withAlif = normalizeArabic(raw.replaceAll('\u0670', 'ا'));
        if (withAlif != norm) {
          alt = withAlif;
        }
      }
      if (norm.isNotEmpty) {
        tokens.add(
          AyahWordToken(
            index: tokens.length,
            originalText: raw,
            normalizedText: norm,
            alternateText: alt,
            status: tokens.isEmpty
                ? RecitationWordStatus.active
                : RecitationWordStatus.pending,
          ),
        );
      }
    }
    return tokens;
  }

  /// Resets all word tokens to clean initial state.
  static void resetTokens(List<AyahWordToken> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      tokens[i].reset(isActive: i == 0);
    }
  }

  /// Evaluates recognized spoken text against the list of Ayah tokens with Mahraj detection.
  static RecitationResult evaluateSpokenText({
    required List<AyahWordToken> tokens,
    required String recognizedArabicSpeech,
  }) {
    if (tokens.isEmpty) {
      return const RecitationResult(
        completedWords: 0,
        totalWords: 0,
        correctCount: 0,
        mistakeCount: 0,
        isCompleted: true,
      );
    }

    final List<String> rawWords = recognizedArabicSpeech
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();

    final List<_SpokenWordUnit> rawUnits = <_SpokenWordUnit>[];
    for (final String raw in rawWords) {
      final String norm = normalizeArabic(raw);
      if (norm.isNotEmpty) {
        rawUnits.add(_SpokenWordUnit(normalizedText: norm, originalText: raw));
      }
    }

    return _evaluateInternal(tokens: tokens, rawSpokenUnits: rawUnits);
  }

  /// Evaluates spoken text from a Whisper [SpeechResult] with word-level timestamps.
  /// Uses the EXACT same matching logic and thresholds as [evaluateSpokenText].
  static RecitationResult evaluateWithTimestamps({
    required List<AyahWordToken> tokens,
    required SpeechResult speechResult,
    required Map<int, List<TajweedRuleOccurrence>> tajweedRules,
  }) {
    if (!speechResult.hasTimestamps) {
      return evaluateSpokenText(
        tokens: tokens,
        recognizedArabicSpeech: speechResult.fullText,
      );
    }

    if (tokens.isEmpty) {
      return const RecitationResult(
        completedWords: 0,
        totalWords: 0,
        correctCount: 0,
        mistakeCount: 0,
        isCompleted: true,
      );
    }

    final List<_SpokenWordUnit> rawUnits = <_SpokenWordUnit>[];
    for (final WordTimestamp wt in speechResult.words) {
      final String norm = normalizeArabic(wt.word);
      if (norm.isNotEmpty) {
        double? start = wt.startSec;
        double? end = wt.endSec;
        if (!start.isFinite || !end.isFinite || start < 0 || end < start) {
          start = null;
          end = null;
        }

        rawUnits.add(
          _SpokenWordUnit(
            normalizedText: norm,
            originalText: wt.word,
            startSec: start,
            endSec: end,
          ),
        );
      }
    }

    return _evaluateInternal(
      tokens: tokens,
      rawSpokenUnits: rawUnits,
      tajweedRules: tajweedRules,
    );
  }

  /// Unified core matching engine.
  static RecitationResult _evaluateInternal({
    required List<AyahWordToken> tokens,
    required List<_SpokenWordUnit> rawSpokenUnits,
    Map<int, List<TajweedRuleOccurrence>>? tajweedRules,
  }) {
    if (tokens.isEmpty) {
      return const RecitationResult(
        completedWords: 0,
        totalWords: 0,
        correctCount: 0,
        mistakeCount: 0,
        isCompleted: true,
      );
    }

    // Reset tokens before re-evaluating to prevent stale states across passes
    resetTokens(tokens);

    final List<_SpokenWordUnit> spokenWords = _glueSpokenUnits(rawSpokenUnits);

    var tokenIdx = 0;
    var correctCount = 0;
    var mistakeCount = 0;

    for (final _SpokenWordUnit spoken in spokenWords) {
      if (tokenIdx >= tokens.length) break;

      final AyahWordToken current = tokens[tokenIdx];
      double sim = similarity(
        spoken.normalizedText,
        current.normalizedText,
      );
      if (current.alternateText != null) {
        final double altSim = similarity(
          spoken.normalizedText,
          current.alternateText!,
        );
        if (altSim > sim) {
          sim = altSim;
        }
      }
      final String? mahrajTip = _detectMahrajTip(
        current.normalizedText,
        spoken.normalizedText,
      );

      // High confidence match: exact or very close with NO Mahraj confusion
      if (sim == 1.0 || (sim >= 0.85 && mahrajTip == null)) {
        current.status = RecitationWordStatus.correct;
        current.mismatchHint = null;
        current.spokenWord = spoken.normalizedText;
        current.startSec = spoken.startSec;
        current.endSec = spoken.endSec;
        if (tajweedRules != null) {
          _evaluateMaddForToken(current, tajweedRules);
        }
        correctCount++;
        tokenIdx++;
      } else {
        // Lookahead check: did user skip current word and recite next?
        bool matchedLookahead = false;
        if (tokenIdx + 1 < tokens.length) {
          final AyahWordToken next = tokens[tokenIdx + 1];
          double nextSim = similarity(
            spoken.normalizedText,
            next.normalizedText,
          );
          if (next.alternateText != null) {
            final double altSim = similarity(
              spoken.normalizedText,
              next.alternateText!,
            );
            if (altSim > nextSim) {
              nextSim = altSim;
            }
          }
          final String? nextMahraj = _detectMahrajTip(
            next.normalizedText,
            spoken.normalizedText,
          );

          if (nextSim == 1.0 || (nextSim >= 0.85 && nextMahraj == null)) {
            // Current was skipped / wrong
            current.status = RecitationWordStatus.mismatch;
            current.mismatchHint =
                mahrajTip ?? 'Слово пропущено или прочитано неточно';
            current.spokenWord = null;
            mistakeCount++;

            // Next is matched
            next.status = RecitationWordStatus.correct;
            next.mismatchHint = null;
            next.spokenWord = spoken.normalizedText;
            next.startSec = spoken.startSec;
            next.endSec = spoken.endSec;
            if (tajweedRules != null) {
              _evaluateMaddForToken(next, tajweedRules);
            }
            correctCount++;
            tokenIdx += 2;
            matchedLookahead = true;
          }
        }

        if (!matchedLookahead) {
          // If similarity is moderate and not a blatant mahraj swap, ask user to repeat
          if (sim >= 0.70 && mahrajTip == null) {
            current.status = RecitationWordStatus.hinted;
            current.mismatchHint =
                'Неуверенное распознавание. Повторите слово чётче.';
          } else {
            current.status = RecitationWordStatus.mismatch;
            current.mismatchHint =
                mahrajTip ?? 'Проверьте произношение этого слова';
          }
          current.spokenWord = spoken.normalizedText;
          mistakeCount++;
          // Do not advance tokenIdx so user can retry or self-correct this word
        }
      }
    }

    // Set active status on next expected word
    if (tokenIdx < tokens.length) {
      if (tokens[tokenIdx].status == RecitationWordStatus.pending) {
        tokens[tokenIdx].status = RecitationWordStatus.active;
      }
      for (var i = tokenIdx + 1; i < tokens.length; i++) {
        if (tokens[i].status != RecitationWordStatus.hinted) {
          tokens[i].status = RecitationWordStatus.pending;
          tokens[i].mismatchHint = null;
        }
      }
    }

    final bool isFinished = tokens.every(
      (AyahWordToken token) => token.status == RecitationWordStatus.correct,
    );

    return RecitationResult(
      completedWords: tokenIdx,
      totalWords: tokens.length,
      correctCount: correctCount,
      mistakeCount: mistakeCount,
      isCompleted: isFinished,
    );
  }

  /// Detects if the difference between expected and spoken is caused by a typical Mahraj error.
  static String? _detectMahrajTip(String expected, String spoken) {
    for (final MapEntry<String, (String, String)> entry
        in _mahrajTips.entries) {
      final String letter = entry.key;
      final (String confusedWith, String tip) = entry.value;

      if (expected.contains(letter) &&
          (spoken.contains(confusedWith) || !spoken.contains(letter))) {
        return tip;
      }
    }
    return null;
  }

  /// Calculates string similarity (1.0 = exact match, 0.0 = completely different).
  static double similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final int dist = _levenshtein(a, b);
    final int maxLen = math.max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return (maxLen - dist) / maxLen;
  }

  /// Checks if the token has a Madd rule and provides educational duration feedback.
  static void _evaluateMaddForToken(
    AyahWordToken token,
    Map<int, List<TajweedRuleOccurrence>> tajweedRules,
  ) {
    if (token.startSec == null || token.endSec == null) return;
    final List<TajweedRuleOccurrence>? rules = tajweedRules[token.index];
    if (rules == null) return;

    for (final TajweedRuleOccurrence rule in rules) {
      if (rule.rule == TajweedRuleType.madd6 ||
          rule.rule == TajweedRuleType.madd4 ||
          rule.rule == TajweedRuleType.madd2) {
        token.maddEval = TajweedAudioAnalyzer.evaluateMadd(
          rule: rule.rule,
          actualDurationSec: token.endSec! - token.startSec!,
        );
        break;
      }
    }
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final List<int> v0 = List<int>.generate(t.length + 1, (int i) => i);
    final List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < t.length; j++) {
        final int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (var j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }
}

final class RecitationResult {
  const RecitationResult({
    required this.completedWords,
    required this.totalWords,
    required this.correctCount,
    required this.mistakeCount,
    required this.isCompleted,
  });

  final int completedWords;
  final int totalWords;
  final int correctCount;
  final int mistakeCount;
  final bool isCompleted;

  /// Accuracy of spoken words (correct / total attempts).
  /// Returns 0.0 when 0 words have been completed (NOT 1.0).
  double get accuracy {
    final int attempts = correctCount + mistakeCount;
    if (attempts == 0) return 0.0;
    return (correctCount / attempts).clamp(0.0, 1.0);
  }

  /// Score percentage (0 to 100). Returns null if no attempts have been made yet.
  int? get scorePercentage {
    final int attempts = correctCount + mistakeCount;
    if (attempts == 0) return null;
    return (accuracy * 100).round();
  }

  /// Ayah completion progress (0.0 to 1.0).
  double get progress {
    if (totalWords == 0) return 1.0;
    return (completedWords / totalWords).clamp(0.0, 1.0);
  }

  int get progressPercentage => (progress * 100).round();
}
