import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/data/qf_api_service.dart';
import 'package:mubeen_quran_pure/data/translation_manager.dart';
import 'package:mubeen_quran_pure/models/quran_models.dart';

class FakeQfApiService extends QfApiService {
  FakeQfApiService({this.textsToReturn = const <String>[]});

  final List<String> textsToReturn;

  @override
  Future<List<String>> fetchSurahTranslation({
    required int resourceId,
    required int surahId,
  }) async {
    return textsToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranslationManager Validation Tests', () {
    test('getExpectedAyahCount returns accurate counts for Quran surahs', () {
      expect(getExpectedAyahCount(1), 7);
      expect(getExpectedAyahCount(2), 286);
      expect(getExpectedAyahCount(114), 6);
      expect(getExpectedAyahCount(0), 0);
      expect(getExpectedAyahCount(115), 0);
    });

    test(
      'downloadSurahTranslation rejects partial translation that does not match expected ayah count',
      () async {
        // Surah 1 (Fatiha) has 7 ayahs. Provide only 3.
        final FakeQfApiService fakeApi = FakeQfApiService(
          textsToReturn: <String>['Аят 1', 'Аят 2', 'Аят 3'],
        );
        final TranslationManager manager = TranslationManager(
          apiService: fakeApi,
        );

        final bool success = await manager.downloadSurahTranslation(
          translatorKey: 'en_sahih',
          surahId: 1,
        );

        // Must be rejected because 3 != 7!
        expect(success, isFalse);

        manager.dispose();
      },
    );

    test(
      'downloadSurahTranslation rejects translation containing empty ayahs',
      () async {
        // 7 ayahs for Fatiha, but one is empty string
        final FakeQfApiService fakeApi = FakeQfApiService(
          textsToReturn: <String>['1', '2', '   ', '4', '5', '6', '7'],
        );
        final TranslationManager manager = TranslationManager(
          apiService: fakeApi,
        );

        final bool success = await manager.downloadSurahTranslation(
          translatorKey: 'en_sahih',
          surahId: 1,
        );

        expect(success, isFalse);

        manager.dispose();
      },
    );
  });
}
