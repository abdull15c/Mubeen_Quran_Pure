import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/models/quran_models.dart';

void main() {
  group('Quran Models Unit Tests', () {
    test('Surah.fromMap parses valid map correctly', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 1,
        'name_arabic': 'الفاتحة',
        'name_translit': 'Al-Fatihah',
        'name_russian': 'Открывающая Коран',
        'revelation_place': 'meccan',
        'ayah_count': 7,
        'revelation_order': 5,
        'bismillah_pre': 1,
      };

      final Surah surah = Surah.fromMap(map);

      expect(surah.id, equals(1));
      expect(surah.nameArabic, equals('الفاتحة'));
      expect(surah.nameTranslit, equals('Al-Fatihah'));
      expect(surah.nameRussian, equals('Открывающая Коран'));
      expect(surah.revelationPlace, equals('meccan'));
      expect(surah.ayahCount, equals(7));
      expect(surah.revelationOrder, equals(5));
      expect(surah.bismillahPre, isTrue);
    });

    test(
      'Surah.fromMap throws FormatException when required key is missing or invalid',
      () {
        final Map<String, Object?> invalidMap = <String, Object?>{
          'id': 'not_an_int',
          'name_arabic': 'الفاتحة',
        };

        expect(() => Surah.fromMap(invalidMap), throwsFormatException);
      },
    );

    test('QuranAyah.fromMap parses valid map with translations', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 255,
        'surah_id': 2,
        'number_in_surah': 255,
        'text_uthmani': 'اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
        'juz': 3,
        'hizb': 5,
        'page': 42,
        'sajda': 0,
      };

      final Map<String, String> translations = <String, String>{
        'kuliev':
            'Аллах — нет божества, кроме Него, Живого, Поддерживающего жизнь.',
      };

      final QuranAyah ayah = QuranAyah.fromMap(map, translations: translations);

      expect(ayah.id, equals(255));
      expect(ayah.surah, equals(2));
      expect(ayah.number, equals(255));
      expect(
        ayah.text,
        equals('اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ'),
      );
      expect(ayah.juz, equals(3));
      expect(ayah.hizb, equals(5));
      expect(ayah.page, equals(42));
      expect(ayah.sajda, isFalse);
      expect(ayah.translations, equals(translations));
      expect(
        () => ayah.translations['kuliev'] = 'new text',
        throwsUnsupportedError,
      );
    });

    test('QuranWord.fromMap parses word and nullable fields', () {
      final Map<String, Object?> map = <String, Object?>{
        'word_order': 1,
        'text_arabic': 'بِسْمِ',
        'text_russian': 'С именем',
        'root_arabic': 'سمو',
        'lemma': 'اسم',
        'pos': 'N',
      };

      final QuranWord word = QuranWord.fromMap(map);

      expect(word.wordOrder, equals(1));
      expect(word.textArabic, equals('بِسْمِ'));
      expect(word.textRussian, equals('С именем'));
      expect(word.rootArabic, equals('سمو'));
      expect(word.lemma, equals('اسم'));
      expect(word.partOfSpeech, equals('N'));
    });

    test('ReaderLocation and QuranSearchResult map deserialization works', () {
      final ReaderLocation location = ReaderLocation.fromMap(<String, Object?>{
        'surah_id': 114,
        'ayah_number': 6,
        'page': 604,
      });
      expect(location.surahId, equals(114));
      expect(location.ayahNumber, equals(6));
      expect(location.page, equals(604));

      final QuranSearchResult searchResult =
          QuranSearchResult.fromMap(<String, Object?>{
            'ayah_id': 1,
            'surah_id': 1,
            'ayah_number': 1,
            'surah_name_russian': 'Аль-Фатиха',
            'surah_name_arabic': 'الفاتحة',
            'arabic_text': 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ',
            'match_text': 'بِسْمِ اللَّهِ',
            'kind': 'ayah',
            'source_key': 'uthmani',
            'page': 1,
          });
      expect(searchResult.ayahId, equals(1));
      expect(searchResult.surahNameRussian, equals('Аль-Фатиха'));
      expect(searchResult.kind, equals('ayah'));
    });

    test('ThematicTopic.fromMap parses valid map correctly', () {
      final ThematicTopic topic = ThematicTopic.fromMap(<String, Object?>{
        'id': 'comfort_peace',
        'category': 'Духовное состояние',
        'title': 'Утешение и покой',
        'description': 'Аяты при грусти и тревоге',
        'icon_name': 'spa_rounded',
        'sort_order': 1,
        'ayah_count': 8,
      });

      expect(topic.id, equals('comfort_peace'));
      expect(topic.category, equals('Духовное состояние'));
      expect(topic.title, equals('Утешение и покой'));
      expect(topic.description, equals('Аяты при грусти и тревоге'));
      expect(topic.iconName, equals('spa_rounded'));
      expect(topic.sortOrder, equals(1));
      expect(topic.ayahCount, equals(8));
    });

    test('Translation registry and findTranslation work correctly', () {
      expect(kBuiltInTranslations.length, equals(2));
      expect(kApiTranslations.length, equals(4));
      expect(kAllTranslations.length, equals(6));

      expect(kSupportedTranslatorKeys, contains('kuliev'));
      expect(kSupportedTranslatorKeys, contains('en_sahih'));
      expect(kSupportedTranslatorKeys, contains('tj_mirof'));
      expect(kSupportedTranslatorKeys, contains('uz_sodiq'));
      expect(kSupportedTranslatorKeys, contains('az_musayev'));

      final TranslationInfo? en = findTranslation('en_sahih');
      expect(en, isNotNull);
      expect(en!.languageCode, equals('en'));
      expect(en.qfResourceId, equals(20));
      expect(en.isBuiltIn, isFalse);

      final TranslationInfo? kuliev = findTranslation('kuliev');
      expect(kuliev, isNotNull);
      expect(kuliev!.isBuiltIn, isTrue);

      expect(findTranslation('non_existent'), isNull);
    });
  });
}
