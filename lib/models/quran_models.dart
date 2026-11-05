const Set<String> kBuiltInTranslatorKeys = <String>{'kuliev', 'abu_adel'};

/// All translator keys recognized by the app (built-in + API-downloaded).
Set<String> get kSupportedTranslatorKeys => <String>{
  ...kBuiltInTranslatorKeys,
  ...kApiTranslations.map((TranslationInfo t) => t.key),
};

/// Metadata for a single Quran translation.
final class TranslationInfo {
  const TranslationInfo({
    required this.key,
    required this.displayName,
    required this.languageCode,
    required this.languageLabel,
    required this.authorName,
    this.qfResourceId,
    this.isBuiltIn = false,
  });

  /// Internal key used in the database `translations.translator_key` column.
  final String key;

  /// Human-readable name shown in the UI.
  final String displayName;

  /// ISO 639-1 language code (e.g. 'ru', 'en', 'tg').
  final String languageCode;

  /// Label shown in the language group header.
  final String languageLabel;

  /// Author / translator name.
  final String authorName;

  /// Quran Foundation API resource ID. Null for built-in translations.
  final int? qfResourceId;

  /// Whether this translation is bundled in the app database.
  final bool isBuiltIn;
}

/// Built-in translations (already in the database).
const List<TranslationInfo> kBuiltInTranslations = <TranslationInfo>[
  TranslationInfo(
    key: 'kuliev',
    displayName: 'Эльмир Кулиев',
    languageCode: 'ru',
    languageLabel: 'Русский',
    authorName: 'Эльмир Кулиев',
    isBuiltIn: true,
  ),
  TranslationInfo(
    key: 'abu_adel',
    displayName: 'Абу Адель',
    languageCode: 'ru',
    languageLabel: 'Русский',
    authorName: 'Абу Адель',
    isBuiltIn: true,
  ),
];

/// API translations available for download from Quran Foundation.
const List<TranslationInfo> kApiTranslations = <TranslationInfo>[
  TranslationInfo(
    key: 'en_sahih',
    displayName: 'Saheeh International',
    languageCode: 'en',
    languageLabel: 'English',
    authorName: 'Saheeh International',
    qfResourceId: 20,
  ),
  TranslationInfo(
    key: 'tj_mirof',
    displayName: 'Хоҷа Мироф ва Хоҷа Мир',
    languageCode: 'tg',
    languageLabel: 'Тоҷикӣ',
    authorName: 'Khawaja Mirof & Khawaja Mir',
    qfResourceId: 139,
  ),
  TranslationInfo(
    key: 'uz_sodiq',
    displayName: 'Muhammad Sodiq Muhammad Yusuf',
    languageCode: 'uz',
    languageLabel: "O'zbekcha",
    authorName: 'Muhammad Sodiq Muhammad Yusuf',
    qfResourceId: 55,
  ),
  TranslationInfo(
    key: 'az_musayev',
    displayName: 'Alikhan Musayev',
    languageCode: 'az',
    languageLabel: 'Azərbaycan',
    authorName: 'Alikhan Musayev',
    qfResourceId: 75,
  ),
];

/// All available translations (built-in + API).
const List<TranslationInfo> kAllTranslations = <TranslationInfo>[
  ...kBuiltInTranslations,
  ...kApiTranslations,
];

/// Finds a [TranslationInfo] by its key, or null if not found.
TranslationInfo? findTranslation(String key) {
  for (final TranslationInfo t in kAllTranslations) {
    if (t.key == key) return t;
  }
  return null;
}

final class Surah {
  const Surah({
    required this.id,
    required this.nameArabic,
    required this.nameTranslit,
    required this.nameRussian,
    required this.revelationPlace,
    required this.ayahCount,
    required this.revelationOrder,
    required this.bismillahPre,
  });

  factory Surah.fromMap(Map<String, Object?> map) {
    return Surah(
      id: _readInt(map, 'id'),
      nameArabic: _readString(map, 'name_arabic'),
      nameTranslit: _readString(map, 'name_translit'),
      nameRussian: _readString(map, 'name_russian'),
      revelationPlace: _readString(map, 'revelation_place'),
      ayahCount: _readInt(map, 'ayah_count'),
      revelationOrder: _readInt(map, 'revelation_order'),
      bismillahPre: _readBool(map, 'bismillah_pre'),
    );
  }

  final int id;
  final String nameArabic;
  final String nameTranslit;
  final String nameRussian;
  final String revelationPlace;
  final int ayahCount;
  final int revelationOrder;
  final bool bismillahPre;
}

final class QuranAyah {
  factory QuranAyah({
    required int id,
    required int surah,
    required int number,
    required String text,
    required int juz,
    required int hizb,
    required int page,
    required bool sajda,
    required Map<String, String> translations,
  }) {
    return QuranAyah._(
      id: id,
      surah: surah,
      number: number,
      text: text,
      juz: juz,
      hizb: hizb,
      page: page,
      sajda: sajda,
      translations: Map<String, String>.unmodifiable(translations),
    );
  }

  factory QuranAyah.fromMap(
    Map<String, Object?> map, {
    Map<String, String> translations = const <String, String>{},
  }) {
    return QuranAyah(
      id: _readInt(map, 'id'),
      surah: _readInt(map, 'surah_id'),
      number: _readInt(map, 'number_in_surah'),
      text: _readString(map, 'text_uthmani'),
      juz: _readInt(map, 'juz'),
      hizb: _readInt(map, 'hizb'),
      page: _readInt(map, 'page'),
      sajda: _readBool(map, 'sajda'),
      translations: translations,
    );
  }

  const QuranAyah._({
    required this.id,
    required this.surah,
    required this.number,
    required this.text,
    required this.juz,
    required this.hizb,
    required this.page,
    required this.sajda,
    required this.translations,
  });

  final int id;
  final int surah;
  final int number;
  final String text;
  final int juz;
  final int hizb;
  final int page;
  final bool sajda;
  final Map<String, String> translations;
}

final class QuranWord {
  const QuranWord({
    required this.wordOrder,
    required this.textArabic,
    required this.textRussian,
    required this.rootArabic,
    required this.lemma,
    required this.partOfSpeech,
  });

  factory QuranWord.fromMap(Map<String, Object?> map) {
    return QuranWord(
      wordOrder: _readInt(map, 'word_order'),
      textArabic: _readString(map, 'text_arabic'),
      textRussian: _readString(map, 'text_russian'),
      rootArabic: _readNullableString(map, 'root_arabic'),
      lemma: _readNullableString(map, 'lemma'),
      partOfSpeech: _readNullableString(map, 'pos'),
    );
  }

  final int wordOrder;
  final String textArabic;
  final String textRussian;
  final String? rootArabic;
  final String? lemma;
  final String? partOfSpeech;
}

final class ReaderLocation {
  const ReaderLocation({
    required this.surahId,
    required this.ayahNumber,
    required this.page,
  });

  factory ReaderLocation.fromMap(Map<String, Object?> map) {
    return ReaderLocation(
      surahId: _readInt(map, 'surah_id'),
      ayahNumber: _readInt(map, 'ayah_number'),
      page: _readInt(map, 'page'),
    );
  }

  final int surahId;
  final int ayahNumber;
  final int page;
}

final class QuranSearchResult {
  const QuranSearchResult({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.surahNameRussian,
    required this.surahNameArabic,
    required this.arabicText,
    required this.matchText,
    required this.kind,
    required this.sourceKey,
    required this.page,
  });

  factory QuranSearchResult.fromMap(Map<String, Object?> map) {
    return QuranSearchResult(
      ayahId: _readInt(map, 'ayah_id'),
      surahId: _readInt(map, 'surah_id'),
      ayahNumber: _readInt(map, 'ayah_number'),
      surahNameRussian: _readString(map, 'surah_name_russian'),
      surahNameArabic: _readString(map, 'surah_name_arabic'),
      arabicText: _readString(map, 'arabic_text'),
      matchText: _readString(map, 'match_text'),
      kind: _readString(map, 'kind'),
      sourceKey: _readString(map, 'source_key'),
      page: _readInt(map, 'page'),
    );
  }

  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String surahNameRussian;
  final String surahNameArabic;
  final String arabicText;
  final String matchText;
  final String kind;
  final String sourceKey;
  final int page;
}

final class ThematicTopic {
  const ThematicTopic({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.iconName,
    required this.sortOrder,
    this.ayahCount = 0,
  });

  factory ThematicTopic.fromMap(Map<String, Object?> map) {
    return ThematicTopic(
      id: _readString(map, 'id'),
      category: _readString(map, 'category'),
      title: _readString(map, 'title'),
      description: _readString(map, 'description'),
      iconName: _readString(map, 'icon_name'),
      sortOrder: _readInt(map, 'sort_order'),
      ayahCount: map.containsKey('ayah_count')
          ? _readInt(map, 'ayah_count')
          : 0,
    );
  }

  final String id;
  final String category;
  final String title;
  final String description;
  final String iconName;
  final int sortOrder;
  final int ayahCount;
}

final class ThematicAyahItem {
  const ThematicAyahItem({required this.ayah, this.note});

  final QuranAyah ayah;
  final String? note;
}

final class WordTiming {
  const WordTiming({required this.startMs, required this.endMs});
  final int startMs;
  final int endMs;
}

/// Standard ayah counts for all 114 Surahs of the Quran.
const List<int> kSurahAyahCounts = <int>[
  7,
  286,
  200,
  176,
  120,
  165,
  206,
  75,
  129,
  109,
  123,
  111,
  43,
  52,
  99,
  128,
  111,
  110,
  98,
  135,
  112,
  78,
  118,
  64,
  77,
  227,
  93,
  88,
  69,
  60,
  34,
  30,
  73,
  54,
  45,
  83,
  182,
  88,
  75,
  85,
  54,
  53,
  89,
  59,
  37,
  35,
  38,
  29,
  18,
  45,
  60,
  49,
  62,
  55,
  78,
  96,
  29,
  22,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  28,
  28,
  20,
  56,
  40,
  31,
  50,
  40,
  46,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  30,
  20,
  15,
  21,
  11,
  8,
  8,
  19,
  5,
  8,
  8,
  11,
  11,
  8,
  3,
  9,
  5,
  4,
  7,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];

int getExpectedAyahCount(int surahId) {
  if (surahId >= 1 && surahId <= 114) {
    return kSurahAyahCounts[surahId - 1];
  }
  return 0;
}

int _readInt(Map<String, Object?> map, String key) {
  final Object? value = map[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('Expected an integer in column "$key", got $value.');
}

String _readString(Map<String, Object?> map, String key) {
  final Object? value = map[key];
  if (value is String) {
    return value;
  }
  throw FormatException('Expected text in column "$key", got $value.');
}

String? _readNullableString(Map<String, Object?> map, String key) {
  final Object? value = map[key];
  if (value == null || value is String) {
    return value as String?;
  }
  throw FormatException('Expected text or null in column "$key", got $value.');
}

bool _readBool(Map<String, Object?> map, String key) {
  final Object? value = map[key];
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  throw FormatException(
    'Expected a boolean integer in column "$key", got $value.',
  );
}
