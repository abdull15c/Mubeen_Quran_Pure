import 'package:flutter/material.dart';

enum TajweedRuleType {
  madd6(
    title: 'Мадд Лазим (6 счетов)',
    nameArabic: 'مَدّ لَازِم',
    description:
        'Обязательное длинное тянущееся чтение на 6 счетов (около 1.5–2 сек) перед буквой с шаддой или сукуном.',
    color: Color(0xFF8E24AA), // Purple
    targetBeats: 6,
    targetDurationSec: 1.6,
  ),
  madd4(
    title: 'Мадд 4-5 счетов',
    nameArabic: 'مَدّ مُتَّصِل / مُنْفَصِل',
    description: 'Тянется на 4 или 5 счетов перед хамзой (около 1.0–1.3 сек).',
    color: Color(0xFFE91E63), // Pink / Magenta
    targetBeats: 4,
    targetDurationSec: 1.1,
  ),
  madd2(
    title: 'Мадд Таби‘и (2 счета)',
    nameArabic: 'مَدّ طَبِيعِي',
    description: 'Естественное удлинение гласной на 2 счета (около 0.5 сек).',
    color: Color(0xFF3949AB), // Indigo
    targetBeats: 2,
    targetDurationSec: 0.5,
  ),
  qalqalah(
    title: 'Калькаля (Отскок звука)',
    nameArabic: 'قَلْقَلَة',
    description:
        'Сотрясение / упругий отскок звука на буквах «ق ط ب ج د» с сукуном.',
    color: Color(0xFF0288D1), // Cyan / Blue
    targetBeats: 1,
    targetDurationSec: 0.3,
  ),
  ghunnah(
    title: 'Гунна (Носовой звук)',
    nameArabic: 'غُنَّة',
    description:
        'Задержка звука в носовой полости на 2 счета на буквах «نّ» и «مّ» с ташдидом.',
    color: Color(0xFFFB8C00), // Orange / Amber
    targetBeats: 2,
    targetDurationSec: 0.6,
  ),
  ikhfa(
    title: 'Ихфа (Сокрытие)',
    nameArabic: 'إِخْفَاء',
    description:
        'Сокрытие звука Нун сакина или танвина перед 15 буквами с легкой гунной на 2 счета.',
    color: Color(0xFF43A047), // Green
    targetBeats: 2,
    targetDurationSec: 0.6,
  ),
  idgham(
    title: 'Идгам (Слияние)',
    nameArabic: 'إِدْغَام',
    description: 'Вхождение/слияние звука Нун сакина в буквы «يرملون».',
    color: Color(0xFF00897B), // Teal
    targetBeats: 2,
    targetDurationSec: 0.6,
  ),
  iqlab(
    title: 'Икляб (Превращение в Мим)',
    nameArabic: 'إِقْلَاب',
    description:
        'Превращение Нун сакина в звук «Мим» перед буквой «Ба» (ب) с гунной.',
    color: Color(0xFF7CB342), // Light Green
    targetBeats: 2,
    targetDurationSec: 0.6,
  ),
  izhar(
    title: 'Изхар (Ясное чтение)',
    nameArabic: 'إِظْهَار',
    description:
        'Четкое и ясное произношение Нун сакина без гунны перед 6 гортанными буквами.',
    color: Color(0xFF546E7A), // Blue Grey
    targetBeats: 1,
    targetDurationSec: 0.3,
  );

  const TajweedRuleType({
    required this.title,
    required this.nameArabic,
    required this.description,
    required this.color,
    required this.targetBeats,
    required this.targetDurationSec,
  });

  final String title;
  final String nameArabic;
  final String description;
  final Color color;
  final int targetBeats;
  final double targetDurationSec;
}

final class TajweedRuleOccurrence {
  const TajweedRuleOccurrence({
    required this.rule,
    required this.letter,
    required this.wordIndex,
    required this.wordText,
    required this.explanation,
  });

  final TajweedRuleType rule;
  final String letter;
  final int wordIndex;
  final String wordText;
  final String explanation;
}

class TajweedRuleDetector {
  static const Set<String> _qalqalahLetters = <String>{'ق', 'ط', 'ب', 'ج', 'د'};
  static const Set<String> _ikhfaLetters = <String>{
    'ت',
    'ث',
    'ج',
    'د',
    'ذ',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ف',
    'ق',
    'ك',
  };
  static const Set<String> _idghamLetters = <String>{
    'ي',
    'ر',
    'م',
    'ل',
    'و',
    'ن',
  };
  static const Set<String> _izharLetters = <String>{
    'ء',
    'ه',
    'ع',
    'ح',
    'غ',
    'خ',
  };

  static const String _maddSign = '\u0653'; // Maddah ~
  static const String _shaddah = '\u0651'; // Shaddah ّ
  static const String _sukun1 = '\u0652'; // Sukun ْ
  static const String _sukun2 = '\u06DF'; // Quranic sukun ۡ
  static const String _sukun3 = '\u06E1'; // Small high dotless head of khah
  static const String _smallMeem =
      '\u06E2'; // Small high meem isolated for Iqlab ۢ

  static bool _isDiacritic(String char) {
    if (char.isEmpty) return false;
    final int code = char.codeUnitAt(0);
    return (code >= 0x064B && code <= 0x065F) ||
        code == 0x0670 ||
        (code >= 0x06D6 && code <= 0x06ED) ||
        (code >= 0x08F0 && code <= 0x08FF);
  }

  static bool _hasMaddSign(String clean) {
    return clean.contains(_maddSign) ||
        clean.contains('آ') ||
        clean.contains('\u06E4');
  }

  /// Pattern-based detection: checks if maddah sign is followed by shaddah or sukun on next consonant
  static bool _isMaddLazimPattern(String clean) {
    for (var i = 0; i < clean.length; i++) {
      if (clean[i] == _maddSign || clean[i] == 'آ' || clean[i] == '\u06E4') {
        // Look ahead to check if the upcoming consonant has a shaddah or sukun
        for (var j = i + 1; j < clean.length; j++) {
          final String c = clean[j];
          if (c == _shaddah || c == _sukun1 || c == _sukun2 || c == _sukun3) {
            return true;
          }
          if (!_isDiacritic(c) && j > i + 1) {
            // Reached next next consonant without shaddah
            break;
          }
        }
      }
    }
    return false;
  }

  static bool _isLastConsonant(String clean, int index) {
    for (var k = index + 1; k < clean.length; k++) {
      if (!_isDiacritic(clean[k])) return false;
    }
    return true;
  }

  /// Analyzes a single Arabic word with tashkeel and detects active Tajweed rules.
  static List<TajweedRuleOccurrence> analyzeWord(
    String wordWithTashkeel,
    int wordIndex,
  ) {
    final List<TajweedRuleOccurrence> rules = <TajweedRuleOccurrence>[];
    final String clean = wordWithTashkeel.trim();
    if (clean.isEmpty) return rules;

    // 1. Check for Madd (Pattern-based: 6 beats vs 4 beats)
    if (_hasMaddSign(clean)) {
      if (_isMaddLazimPattern(clean) ||
          clean.contains('الضَّآلِّينَ') ||
          clean.contains('الْحَآقَّةُ') ||
          clean.contains('الطَّآمَّةُ')) {
        rules.add(
          TajweedRuleOccurrence(
            rule: TajweedRuleType.madd6,
            letter: '~ (мадд)',
            wordIndex: wordIndex,
            wordText: clean,
            explanation:
                'Мадд Лазим — тяните звук ровно на 6 счетов (1.5–2 сек) перед шаддой/сукуном.',
          ),
        );
      } else {
        rules.add(
          TajweedRuleOccurrence(
            rule: TajweedRuleType.madd4,
            letter: '~ (мадд)',
            wordIndex: wordIndex,
            wordText: clean,
            explanation:
                'Мадд 4-5 счетов — тяните звук перед хамзой (около 1.1 сек).',
          ),
        );
      }
    }

    // 2. Check for Ghunnah (نّ or مّ with Shaddah)
    for (var i = 0; i < clean.length; i++) {
      final String char = clean[i];
      if (char == 'ن' || char == 'م') {
        bool hasShaddah = false;
        for (var j = i + 1; j < clean.length; j++) {
          final String c = clean[j];
          if (c == _shaddah) {
            hasShaddah = true;
            break;
          }
          if (!_isDiacritic(c)) break;
        }

        if (hasShaddah) {
          rules.add(
            TajweedRuleOccurrence(
              rule: TajweedRuleType.ghunnah,
              letter: '$char$_shaddah',
              wordIndex: wordIndex,
              wordText: clean,
              explanation:
                  'Гунна — задержите носовой звук на букве «$char» с ташдидом на 2 счета.',
            ),
          );
        }
      }
    }

    // 3. Check for Qalqalah (ق ط ب ج د with sukun or at end)
    for (var i = 0; i < clean.length; i++) {
      final String char = clean[i];
      if (_qalqalahLetters.contains(char)) {
        bool hasSukun = false;
        for (var j = i + 1; j < clean.length; j++) {
          final String next = clean[j];
          if (next == _sukun1 || next == _sukun2 || next == _sukun3) {
            hasSukun = true;
            break;
          }
          if (!_isDiacritic(next)) break;
        }
        if (!hasSukun && _isLastConsonant(clean, i)) {
          hasSukun = true;
        }

        if (hasSukun) {
          rules.add(
            TajweedRuleOccurrence(
              rule: TajweedRuleType.qalqalah,
              letter: char,
              wordIndex: wordIndex,
              wordText: clean,
              explanation:
                  'Калькаля на букве «$char» — сделайте упругий, четкий отскок звука.',
            ),
          );
        }
      }
    }

    // 4. Check for Iqlab inside word (small meem ۢ)
    if (clean.contains(_smallMeem)) {
      rules.add(
        TajweedRuleOccurrence(
          rule: TajweedRuleType.iqlab,
          letter: 'نۢ',
          wordIndex: wordIndex,
          wordText: clean,
          explanation:
              'Икляб — звук Нун превращается в чистый звук «Мим» с гунной перед буквой Ба.',
        ),
      );
    }

    // 5. Check for internal Ikhfa (Nun sakina followed by Ikhfa consonant)
    for (var i = 0; i < clean.length - 1; i++) {
      if (clean[i] == 'ن') {
        bool isVowelled = false;
        String nextConsonant = '';

        for (var j = i + 1; j < clean.length; j++) {
          final String nextChar = clean[j];
          if (_isDiacritic(nextChar)) {
            if (nextChar == '\u064E' || // Fatha
                nextChar == '\u064F' || // Damma
                nextChar == '\u0650' || // Kasra
                nextChar == '\u0651' || // Shaddah
                nextChar == '\u064B' || // Fathatan
                nextChar == '\u064C' || // Dammatan
                nextChar == '\u064D') {
              // Kasratan
              isVowelled = true;
              break;
            }
          } else {
            nextConsonant = nextChar;
            break;
          }
        }

        if (!isVowelled &&
            nextConsonant.isNotEmpty &&
            _ikhfaLetters.contains(nextConsonant)) {
          rules.add(
            TajweedRuleOccurrence(
              rule: TajweedRuleType.ikhfa,
              letter: 'ن ($nextConsonant)',
              wordIndex: wordIndex,
              wordText: clean,
              explanation:
                  'Ихфа — скройте звук Нун перед буквой «$nextConsonant» с легкой гунной на 2 счета.',
            ),
          );
        }
      }
    }

    return rules;
  }

  /// Analyzes an entire Ayah and detects both intra-word and inter-word rules (Ikhfa, Idgham, Izhar).
  static Map<int, List<TajweedRuleOccurrence>> analyzeAyah(String ayahText) {
    final List<String> words = ayahText
        .replaceAll(RegExp(r'[۝۞\d]'), '')
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();

    final Map<int, List<TajweedRuleOccurrence>> resultMap =
        <int, List<TajweedRuleOccurrence>>{};

    for (var i = 0; i < words.length; i++) {
      final String word = words[i];
      final List<TajweedRuleOccurrence> occurrences = analyzeWord(word, i);

      // Check boundary rules with next word (Nun Sakina / Tanween at end of word)
      if (i + 1 < words.length) {
        final String nextWord = words[i + 1];
        final String firstConsonant = _getFirstConsonant(nextWord);

        if (_endsWithNunSakinaOrTanween(word) && firstConsonant.isNotEmpty) {
          if (_ikhfaLetters.contains(firstConsonant)) {
            occurrences.add(
              TajweedRuleOccurrence(
                rule: TajweedRuleType.ikhfa,
                letter: 'ن ($firstConsonant)',
                wordIndex: i,
                wordText: word,
                explanation:
                    'Ихфа на стыке слов — скрывайте Нун перед буквой «$firstConsonant» с гунной.',
              ),
            );
          } else if (_idghamLetters.contains(firstConsonant)) {
            occurrences.add(
              TajweedRuleOccurrence(
                rule: TajweedRuleType.idgham,
                letter: 'ن ($firstConsonant)',
                wordIndex: i,
                wordText: word,
                explanation:
                    'Идгам на стыке слов — звук Нун сливается с буквой «$firstConsonant».',
              ),
            );
          } else if (_izharLetters.contains(firstConsonant)) {
            occurrences.add(
              TajweedRuleOccurrence(
                rule: TajweedRuleType.izhar,
                letter: 'ن ($firstConsonant)',
                wordIndex: i,
                wordText: word,
                explanation:
                    'Изхар — произносите Нун четко и ясно перед гортанной буквой «$firstConsonant».',
              ),
            );
          }
        }
      }

      if (occurrences.isNotEmpty) {
        resultMap[i] = occurrences;
      }
    }

    return resultMap;
  }

  static bool _endsWithNunSakinaOrTanween(String word) {
    if (word.isEmpty) return false;

    // 1. Check if the word ends with Tanween (ً , ٌ , ٍ )
    // In Arabic, Tanween occurs on or before final Alif/stop marks
    for (var i = word.length - 1; i >= 0; i--) {
      final String c = word[i];
      if (c == '\u064B' || c == '\u064C' || c == '\u064D') {
        return true;
      }
      if (!_isDiacritic(c) && c != 'ا' && c != 'ى' && c != 'ء') {
        break;
      }
    }

    // 2. Check if the last consonant is a Nun Sakina
    int lastConsonantIdx = -1;
    for (var i = word.length - 1; i >= 0; i--) {
      final String c = word[i];
      if (!_isDiacritic(c)) {
        lastConsonantIdx = i;
        break;
      }
    }

    if (lastConsonantIdx == -1 || word[lastConsonantIdx] != 'ن') {
      return false;
    }

    // Check all diacritics attached to this final Nun
    bool hasVowel = false;
    for (var i = lastConsonantIdx + 1; i < word.length; i++) {
      final String c = word[i];
      if (!_isDiacritic(c)) break;
      if (c == '\u064E' || // Fatha
          c == '\u064F' || // Damma
          c == '\u0650' || // Kasra
          c == '\u0651' || // Shaddah
          c == '\u0670') {
        // Dagger alif
        hasVowel = true;
        break;
      }
    }

    // A vowelled Nun (e.g. 'الْعَالَمِينَ' with fatha) is NOT Nun Sakina
    return !hasVowel;
  }

  static String _getFirstConsonant(String word) {
    for (var i = 0; i < word.length; i++) {
      final String c = word[i];
      if (!_isDiacritic(c) && c != 'ٱ' && c != 'ا') {
        return c;
      }
    }
    return '';
  }
}
