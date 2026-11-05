import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/controllers/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppController Unit Tests', () {
    late AppController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      controller = AppController();
      await controller.initialize();
    });

    test('initializes with default values', () {
      expect(controller.initialized, isTrue);
      expect(controller.onboardingCompleted, isFalse);
      expect(controller.readerTipDismissed, isFalse);
      expect(controller.themeStyle, equals(AppThemeStyle.parchment));
      expect(controller.readerMode, equals(ReaderMode.flow));
      expect(controller.translatorKey, equals('kuliev'));
      expect(controller.showTranslation, isTrue);
      expect(controller.arabicFontSize, equals(34.0));
      expect(controller.translationFontSize, equals(17.0));
      expect(controller.autoScrollLinesPerMinute, equals(4.0));
      expect(controller.lastSurahId, equals(1));
      expect(controller.lastAyahNumber, equals(1));
      expect(controller.lastPage, equals(1));
      expect(controller.bookmarkedAyahIds, isEmpty);
    });

    test('completeOnboarding updates state and persists', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.completeOnboarding();
      expect(controller.onboardingCompleted, isTrue);
      expect(notifications, equals(1));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);

      // Calling again is a no-op and does not notify
      await controller.completeOnboarding();
      expect(notifications, equals(1));
    });

    test('dismissReaderTip updates state and persists', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.dismissReaderTip();
      expect(controller.readerTipDismissed, isTrue);
      expect(notifications, equals(1));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reader_tip_dismissed'), isTrue);

      // Calling again is a no-op and does not notify
      await controller.dismissReaderTip();
      expect(notifications, equals(1));
    });

    test('theme style can be updated and persisted', () async {
      await controller.setThemeStyle(AppThemeStyle.oled);
      expect(controller.themeStyle, equals(AppThemeStyle.oled));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_style'), equals('oled'));
    });

    test('arabic font defaults to Hafs and persists a change', () async {
      expect(controller.arabicFont, equals(QuranFont.hafs));

      await controller.setArabicFont(QuranFont.amiri);
      expect(controller.arabicFont, equals(QuranFont.amiri));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('arabic_font'), equals('amiri'));

      SharedPreferences.setMockInitialValues(<String, Object>{
        'arabic_font': 'hafsSmart',
      });
      final AppController restored = AppController();
      await restored.initialize();
      expect(restored.arabicFont, equals(QuranFont.hafsSmart));

      SharedPreferences.setMockInitialValues(<String, Object>{
        'arabic_font': 'comic-sans',
      });
      final AppController fallback = AppController();
      await fallback.initialize();
      expect(fallback.arabicFont, equals(QuranFont.hafs));
    });

    test('reader mode can be updated and persisted', () async {
      await controller.setReaderMode(ReaderMode.mushaf);
      expect(controller.readerMode, equals(ReaderMode.mushaf));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('reader_mode'), equals('mushaf'));
    });

    test(
      'translator key supports kuliev and abu_adel, throws on invalid key',
      () async {
        await controller.setTranslatorKey('abu_adel');
        expect(controller.translatorKey, equals('abu_adel'));

        expect(
          () => controller.setTranslatorKey('invalid_key'),
          throwsArgumentError,
        );
      },
    );

    test('show translation toggle updates state and storage', () async {
      await controller.setShowTranslation(false);
      expect(controller.showTranslation, isFalse);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('show_translation'), isFalse);
    });

    test('arabic font size clamps to 24..56 range', () async {
      await controller.setArabicFontSize(10);
      expect(controller.arabicFontSize, equals(24.0));

      await controller.setArabicFontSize(100);
      expect(controller.arabicFontSize, equals(56.0));

      await controller.setArabicFontSize(40);
      expect(controller.arabicFontSize, equals(40.0));

      expect(
        () => controller.setArabicFontSize(double.nan),
        throwsArgumentError,
      );
    });

    test('translation font size clamps to 13..28 range', () async {
      await controller.setTranslationFontSize(5);
      expect(controller.translationFontSize, equals(13.0));

      await controller.setTranslationFontSize(50);
      expect(controller.translationFontSize, equals(28.0));

      await controller.setTranslationFontSize(20);
      expect(controller.translationFontSize, equals(20.0));
    });

    test('auto scroll lines per minute clamps to 1..12 range', () async {
      await controller.setAutoScrollLinesPerMinute(0);
      expect(controller.autoScrollLinesPerMinute, equals(1.0));

      await controller.setAutoScrollLinesPerMinute(20);
      expect(controller.autoScrollLinesPerMinute, equals(12.0));

      await controller.setAutoScrollLinesPerMinute(6);
      expect(controller.autoScrollLinesPerMinute, equals(6.0));
    });

    test('saveLocation validates, notifies, and persists one record', () async {
      expect(
        () => controller.saveLocation(surahId: 0, ayahNumber: 1, page: 1),
        throwsRangeError,
      );
      expect(
        () => controller.saveLocation(surahId: 115, ayahNumber: 1, page: 1),
        throwsRangeError,
      );
      expect(
        () => controller.saveLocation(surahId: 1, ayahNumber: 0, page: 1),
        throwsRangeError,
      );
      expect(
        () => controller.saveLocation(surahId: 1, ayahNumber: 287, page: 1),
        throwsRangeError,
      );
      expect(
        () => controller.saveLocation(surahId: 1, ayahNumber: 1, page: 0),
        throwsRangeError,
      );
      expect(
        () => controller.saveLocation(surahId: 1, ayahNumber: 1, page: 605),
        throwsRangeError,
      );

      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.saveLocation(surahId: 2, ayahNumber: 255, page: 42);
      expect(controller.lastSurahId, equals(2));
      expect(controller.lastAyahNumber, equals(255));
      expect(controller.lastPage, equals(42));
      expect(notifications, equals(1));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString('last_location')!),
        equals(<String, int>{'surah_id': 2, 'ayah_number': 255, 'page': 42}),
      );
      expect(prefs.containsKey('last_surah_id'), isFalse);
      expect(prefs.containsKey('last_ayah_number'), isFalse);
      expect(prefs.containsKey('last_page'), isFalse);
    });

    test('migrates legacy location keys to one record', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'last_surah_id': 18,
        'last_ayah_number': 10,
        'last_page': 293,
      });

      final AppController migratedController = AppController();
      await migratedController.initialize();

      expect(migratedController.lastSurahId, equals(18));
      expect(migratedController.lastAyahNumber, equals(10));
      expect(migratedController.lastPage, equals(293));
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString('last_location')!),
        equals(<String, int>{'surah_id': 18, 'ayah_number': 10, 'page': 293}),
      );
      expect(prefs.containsKey('last_surah_id'), isFalse);
      expect(prefs.containsKey('last_ayah_number'), isFalse);
      expect(prefs.containsKey('last_page'), isFalse);
    });

    test('concurrent location saves persist in call order', () async {
      await Future.wait(<Future<void>>[
        controller.saveLocation(surahId: 1, ayahNumber: 1, page: 1),
        controller.saveLocation(surahId: 2, ayahNumber: 255, page: 42),
      ]);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString('last_location')!),
        equals(<String, int>{'surah_id': 2, 'ayah_number': 255, 'page': 42}),
      );
      expect(controller.lastSurahId, equals(2));
      expect(controller.lastAyahNumber, equals(255));
      expect(controller.lastPage, equals(42));
    });

    test('initialization and updates persist in call order', () async {
      final AppController freshController = AppController();
      final Future<void> init = freshController.initialize();
      final Future<void> save = freshController.saveLocation(
        surahId: 114,
        ayahNumber: 6,
        page: 604,
      );
      await Future.wait(<Future<void>>[init, save]);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString('last_location')!),
        equals(<String, int>{'surah_id': 114, 'ayah_number': 6, 'page': 604}),
      );
      expect(freshController.lastSurahId, equals(114));
    });

    test('toggleBookmark manages bookmarks set and validates input', () async {
      expect(() => controller.toggleBookmark(0), throwsRangeError);
      expect(() => controller.toggleBookmark(6237), throwsRangeError);

      expect(controller.isBookmarked(255), isFalse);
      await controller.toggleBookmark(255);
      expect(controller.isBookmarked(255), isTrue);
      expect(controller.bookmarkedAyahIds, contains(255));

      await controller.toggleBookmark(100);
      expect(controller.bookmarkedAyahIds, equals(<int>{100, 255}));

      await controller.toggleBookmark(255);
      expect(controller.isBookmarked(255), isFalse);
      expect(controller.bookmarkedAyahIds, equals(<int>{100}));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('bookmarked_ayah_ids'),
        equals(<String>['100']),
      );
    });

    test(
      'recovers gracefully from saved corrupt SharedPreferences values',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'theme_style': 'invalid_theme',
          'reader_mode': 'invalid_mode',
          'translator_key': 'invalid_key',
          'show_translation': 'not_a_bool',
          'arabic_font_size': 'not_a_number',
          'translation_font_size': double.infinity,
          'auto_scroll_lines_per_minute': -5,
          'last_surah_id': 999,
          'last_ayah_number': -10,
          'last_page': 0,
          'bookmarked_ayah_ids': <String>['invalid', '-5', '42'],
          'onboarding_completed': 'not_a_bool',
          'reader_tip_dismissed': 'not_a_bool',
        });

        final AppController fallbackController = AppController();
        await fallbackController.initialize();

        expect(fallbackController.onboardingCompleted, isFalse);
        expect(fallbackController.readerTipDismissed, isFalse);
        expect(fallbackController.themeStyle, equals(AppThemeStyle.parchment));
        expect(fallbackController.readerMode, equals(ReaderMode.flow));
        expect(fallbackController.translatorKey, equals('kuliev'));
        expect(fallbackController.showTranslation, isTrue);
        expect(fallbackController.arabicFontSize, equals(34.0));
        expect(fallbackController.translationFontSize, equals(17.0));
        expect(fallbackController.autoScrollLinesPerMinute, equals(1.0));
        expect(fallbackController.lastSurahId, equals(1));
        expect(fallbackController.lastAyahNumber, equals(1));
        expect(fallbackController.lastPage, equals(1));
        expect(fallbackController.bookmarkedAyahIds, equals(<int>{42}));
      },
    );

    test(
      'bookmarks survive platform-decoded List<Object?> and filter out-of-range IDs',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'bookmarked_ayah_ids': <Object?>['42', '9999', '-1'],
        });

        final AppController testController = AppController();
        await testController.initialize();

        expect(testController.bookmarkedAyahIds, equals(<int>{42}));
      },
    );

    test(
      'recent searches can be added, deduplicated, limited, and cleared',
      () async {
        expect(controller.recentSearches, isEmpty);

        await controller.addRecentSearch('Рай');
        await controller.addRecentSearch('Терпение');
        expect(controller.recentSearches, equals(<String>['Терпение', 'Рай']));

        // Deduplication (case-insensitive) moves query to the top:
        await controller.addRecentSearch('рай');
        expect(controller.recentSearches, equals(<String>['рай', 'Терпение']));

        // Empty queries are ignored:
        await controller.addRecentSearch('   ');
        expect(controller.recentSearches.length, equals(2));

        // Limit to 8 items:
        for (var i = 1; i <= 10; i++) {
          await controller.addRecentSearch('Запрос $i');
        }
        expect(controller.recentSearches.length, equals(8));
        expect(controller.recentSearches.first, equals('Запрос 10'));

        // Remove specific search:
        await controller.removeRecentSearch('Запрос 10');
        expect(controller.recentSearches.contains('Запрос 10'), isFalse);
        expect(controller.recentSearches.length, equals(7));

        // Clear all:
        await controller.clearRecentSearches();
        expect(controller.recentSearches, isEmpty);
      },
    );
  });
}
