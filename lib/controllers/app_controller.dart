import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_models.dart';

enum AppThemeStyle { parchment, oled, emerald, light }

enum ReaderMode { flow, mushaf }

/// Bundled Quran typefaces; see `lib/theme/quran_fonts.dart` for metrics.
enum QuranFont { hafs, hafsSmart, amiri }

class AppController extends ChangeNotifier {
  static const String _eyeCareEnabledKey = 'eye_care_enabled';
  static const String _themeStyleKey = 'theme_style';
  static const String _readerModeKey = 'reader_mode';
  static const String _translatorKeyKey = 'translator_key';
  static const String _showTranslationKey = 'show_translation';
  static const String _arabicFontSizeKey = 'arabic_font_size';
  static const String _translationFontSizeKey = 'translation_font_size';
  static const String _autoScrollLinesPerMinuteKey =
      'auto_scroll_lines_per_minute';
  static const String _lastLocationKey = 'last_location';
  static const String _lastSurahIdKey = 'last_surah_id';
  static const String _lastAyahNumberKey = 'last_ayah_number';
  static const String _lastPageKey = 'last_page';
  static const String _bookmarkedAyahIdsKey = 'bookmarked_ayah_ids';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _readerTipDismissedKey = 'reader_tip_dismissed';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _localeKey = 'ui_locale';
  static const String _arabicFontKey = 'arabic_font';

  /// Supported UI locales.
  static const List<String> supportedLocaleCodes = <String>[
    'ru',
    'en',
    'tg',
    'uz',
    'ky',
    'az',
  ];

  SharedPreferences? _preferences;
  Future<void>? _initialization;
  Future<void> _persistence = Future<void>.value();

  bool _initialized = false;
  bool _onboardingCompleted = false;
  bool _readerTipDismissed = false;
  bool _eyeCareEnabled = false;
  AppThemeStyle _themeStyle = AppThemeStyle.parchment;
  ReaderMode _readerMode = ReaderMode.flow;
  String _translatorKey = 'kuliev';
  bool _showTranslation = true;
  double _arabicFontSize = 34;
  double _translationFontSize = 17;
  double _autoScrollLinesPerMinute = 4;
  int _lastSurahId = 1;
  int _lastAyahNumber = 1;
  int _lastPage = 1;
  Set<int> _bookmarkedAyahIds = <int>{};
  List<String> _recentSearches = <String>[];
  String _localeCode = 'ru';
  QuranFont _arabicFont = QuranFont.hafs;
  bool _immersiveReading = false;

  bool get initialized => _initialized;
  QuranFont get arabicFont => _arabicFont;

  /// Focused reading: the reader hides its app bar, the bottom navigation and
  /// per-ayah actions until the user taps the text again. Not persisted.
  bool get immersiveReading => _immersiveReading;

  void setImmersiveReading(bool value) {
    if (_immersiveReading == value) return;
    _immersiveReading = value;
    notifyListeners();
  }

  void toggleImmersiveReading() => setImmersiveReading(!_immersiveReading);

  bool get onboardingCompleted => _onboardingCompleted;
  bool get readerTipDismissed => _readerTipDismissed;
  bool get eyeCareEnabled => _eyeCareEnabled;
  AppThemeStyle get themeStyle => _themeStyle;
  ReaderMode get readerMode => _readerMode;
  String get translatorKey => _translatorKey;
  bool get showTranslation => _showTranslation;
  double get arabicFontSize => _arabicFontSize;
  double get translationFontSize => _translationFontSize;
  double get autoScrollLinesPerMinute => _autoScrollLinesPerMinute;
  int get lastSurahId => _lastSurahId;
  int get lastAyahNumber => _lastAyahNumber;
  int get lastPage => _lastPage;
  Set<int> get bookmarkedAyahIds => Set<int>.unmodifiable(_bookmarkedAyahIds);
  List<String> get recentSearches => List<String>.unmodifiable(_recentSearches);
  String get localeCode => _localeCode;

  Future<void> initialize() =>
      _initialization ??= _persist((_) => _initialize()).whenComplete(() {
        if (!_initialized) {
          _initialized = true;
          notifyListeners();
        }
      });

  Future<void> _initialize() async {
    try {
      final SharedPreferences preferences = _preferences ??=
          await SharedPreferences.getInstance();

      final Object? savedEyeCare = preferences.get(_eyeCareEnabledKey);
      _eyeCareEnabled = savedEyeCare is bool ? savedEyeCare : false;

      final Object? savedOnboarding = preferences.get(_onboardingCompletedKey);
      _onboardingCompleted = savedOnboarding is bool ? savedOnboarding : false;

      final Object? savedReaderTip = preferences.get(_readerTipDismissedKey);
      _readerTipDismissed = savedReaderTip is bool ? savedReaderTip : false;

      _themeStyle = _readEnum(
        preferences.get(_themeStyleKey),
        AppThemeStyle.values,
        AppThemeStyle.parchment,
      );
      _readerMode = _readEnum(
        preferences.get(_readerModeKey),
        ReaderMode.values,
        ReaderMode.flow,
      );
      _arabicFont = _readEnum(
        preferences.get(_arabicFontKey),
        QuranFont.values,
        QuranFont.hafs,
      );

      final Object? savedTranslatorKey = preferences.get(_translatorKeyKey);
      _translatorKey =
          savedTranslatorKey is String &&
              kSupportedTranslatorKeys.contains(savedTranslatorKey)
          ? savedTranslatorKey
          : 'kuliev';

      final Object? savedShowTranslation = preferences.get(_showTranslationKey);
      _showTranslation = savedShowTranslation is bool
          ? savedShowTranslation
          : true;
      _arabicFontSize = _readClampedDouble(
        preferences.get(_arabicFontSizeKey),
        24,
        56,
        34,
      );
      _translationFontSize = _readClampedDouble(
        preferences.get(_translationFontSizeKey),
        13,
        28,
        17,
      );
      _autoScrollLinesPerMinute = _readClampedDouble(
        preferences.get(_autoScrollLinesPerMinuteKey),
        1,
        12,
        4,
      );
      final Object? savedLocationValue = preferences.get(_lastLocationKey);
      final _SavedLocation? savedLocation = _readLocation(savedLocationValue);
      final bool hasLegacyLocation =
          preferences.containsKey(_lastSurahIdKey) ||
          preferences.containsKey(_lastAyahNumberKey) ||
          preferences.containsKey(_lastPageKey);
      final _SavedLocation location =
          savedLocation ??
          _SavedLocation(
            surahId: _readIntInRange(
              preferences.get(_lastSurahIdKey),
              1,
              114,
              1,
            ),
            ayahNumber: _readPositiveInt(
              preferences.get(_lastAyahNumberKey),
              1,
            ),
            page: _readIntInRange(preferences.get(_lastPageKey), 1, 604, 1),
          );
      _lastSurahId = location.surahId;
      _lastAyahNumber = location.ayahNumber;
      _lastPage = location.page;
      _bookmarkedAyahIds = _readBookmarks(
        preferences.getStringList(_bookmarkedAyahIdsKey) ??
            preferences.get(_bookmarkedAyahIdsKey),
      );
      _recentSearches = _readStringList(
        preferences.getStringList(_recentSearchesKey) ??
            preferences.get(_recentSearchesKey),
      );

      final Object? savedLocale = preferences.get(_localeKey);
      _localeCode =
          savedLocale is String && supportedLocaleCodes.contains(savedLocale)
          ? savedLocale
          : 'ru';

      if (hasLegacyLocation ||
          (savedLocationValue != null && savedLocation == null)) {
        await _saveLocationRecord(preferences, location);
      }
    } catch (_) {
      // Keep usable defaults when local storage is temporarily unavailable.
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    await _initialization;
    if (_onboardingCompleted) return;
    _onboardingCompleted = true;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setBool(_onboardingCompletedKey, true),
    );
  }

  Future<void> dismissReaderTip() async {
    await _initialization;
    if (_readerTipDismissed) return;
    _readerTipDismissed = true;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setBool(_readerTipDismissedKey, true),
    );
  }

  Future<void> setEyeCareEnabled(bool value) async {
    await _initialization;
    if (_eyeCareEnabled == value) return;
    _eyeCareEnabled = value;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setBool(_eyeCareEnabledKey, value),
    );
  }

  Future<void> setThemeStyle(AppThemeStyle value) async {
    await _initialization;
    if (_themeStyle == value) {
      return;
    }
    _themeStyle = value;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setString(_themeStyleKey, value.name),
    );
  }

  Future<void> setArabicFont(QuranFont value) async {
    await _initialization;
    if (_arabicFont == value) {
      return;
    }
    _arabicFont = value;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setString(_arabicFontKey, value.name),
    );
  }

  Future<void> setReaderMode(ReaderMode value) async {
    await _initialization;
    if (_readerMode == value) {
      return;
    }
    _readerMode = value;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setString(_readerModeKey, value.name),
    );
  }

  Future<void> setTranslatorKey(String value) async {
    await _initialization;
    if (!kSupportedTranslatorKeys.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Unsupported translator key');
    }
    if (_translatorKey == value) {
      return;
    }
    _translatorKey = value;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setString(_translatorKeyKey, value),
    );
  }

  Future<void> setShowTranslation(bool value) async {
    await _initialization;
    if (_showTranslation == value) {
      return;
    }
    _showTranslation = value;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setBool(_showTranslationKey, value),
    );
  }

  Future<void> setArabicFontSize(num value) async {
    await _initialization;
    final double clampedValue = _clampFinite(value, 24, 56);
    if (_arabicFontSize == clampedValue) {
      return;
    }
    _arabicFontSize = clampedValue;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setDouble(_arabicFontSizeKey, clampedValue),
    );
  }

  Future<void> setTranslationFontSize(num value) async {
    await _initialization;
    final double clampedValue = _clampFinite(value, 13, 28);
    if (_translationFontSize == clampedValue) {
      return;
    }
    _translationFontSize = clampedValue;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setDouble(_translationFontSizeKey, clampedValue),
    );
  }

  Future<void> setAutoScrollLinesPerMinute(num value) async {
    await _initialization;
    final double clampedValue = _clampFinite(value, 1, 12);
    if (_autoScrollLinesPerMinute == clampedValue) {
      return;
    }
    _autoScrollLinesPerMinute = clampedValue;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setDouble(_autoScrollLinesPerMinuteKey, clampedValue),
    );
  }

  Future<void> saveLocation({
    required int surahId,
    required int ayahNumber,
    required int page,
  }) async {
    await _initialization;
    RangeError.checkValueInInterval(surahId, 1, 114, 'surahId');
    RangeError.checkValueInInterval(ayahNumber, 1, 286, 'ayahNumber');
    RangeError.checkValueInInterval(page, 1, 604, 'page');

    if (_lastSurahId == surahId &&
        _lastAyahNumber == ayahNumber &&
        _lastPage == page) {
      return;
    }

    _lastSurahId = surahId;
    _lastAyahNumber = ayahNumber;
    _lastPage = page;
    notifyListeners();

    await _persist(
      (SharedPreferences preferences) => _saveLocationRecord(
        preferences,
        _SavedLocation(surahId: surahId, ayahNumber: ayahNumber, page: page),
      ),
    );
  }

  Future<void> toggleBookmark(int ayahId) async {
    await _initialization;
    RangeError.checkValueInInterval(ayahId, 1, 6236, 'ayahId');
    if (!_bookmarkedAyahIds.remove(ayahId)) {
      _bookmarkedAyahIds.add(ayahId);
    }
    notifyListeners();

    final List<String> savedIds = (_bookmarkedAyahIds.toList()..sort())
        .map((int id) => id.toString())
        .toList();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setStringList(_bookmarkedAyahIdsKey, savedIds),
    );
  }

  Future<void> addRecentSearch(String rawQuery) async {
    await _initialization;
    final String query = rawQuery.trim();
    if (query.isEmpty) return;

    final List<String> updated = <String>[
      query,
      ..._recentSearches.where(
        (String item) => item.toLowerCase() != query.toLowerCase(),
      ),
    ];
    if (updated.length > 8) {
      updated.removeRange(8, updated.length);
    }
    _recentSearches = updated;
    notifyListeners();

    await _persist(
      (SharedPreferences preferences) =>
          preferences.setStringList(_recentSearchesKey, _recentSearches),
    );
  }

  Future<void> removeRecentSearch(String query) async {
    await _initialization;
    final String trimmed = query.trim().toLowerCase();
    final List<String> updated = _recentSearches
        .where((String item) => item.toLowerCase() != trimmed)
        .toList();
    if (updated.length == _recentSearches.length) return;
    _recentSearches = updated;
    notifyListeners();

    await _persist(
      (SharedPreferences preferences) =>
          preferences.setStringList(_recentSearchesKey, _recentSearches),
    );
  }

  Future<void> clearRecentSearches() async {
    await _initialization;
    if (_recentSearches.isEmpty) return;
    _recentSearches = <String>[];
    notifyListeners();

    await _persist(
      (SharedPreferences preferences) => preferences.remove(_recentSearchesKey),
    );
  }

  bool isBookmarked(int ayahId) => _bookmarkedAyahIds.contains(ayahId);

  Future<void> setLocale(String code) async {
    await _initialization;
    if (!supportedLocaleCodes.contains(code)) {
      throw ArgumentError.value(code, 'code', 'Unsupported locale');
    }
    if (_localeCode == code) return;
    _localeCode = code;
    notifyListeners();
    await _persist(
      (SharedPreferences preferences) =>
          preferences.setString(_localeKey, code),
    );
  }

  Future<void> _persist(
    Future<Object?> Function(SharedPreferences preferences) operation,
  ) {
    final Future<void> persistence = _persistence.then((_) async {
      try {
        final SharedPreferences preferences = _preferences ??=
            await SharedPreferences.getInstance();
        await operation(preferences);
      } catch (_) {
        // In-memory settings remain available if persistence fails.
      }
    });
    _persistence = persistence;
    return persistence;
  }

  static Future<void> _saveLocationRecord(
    SharedPreferences preferences,
    _SavedLocation location,
  ) async {
    final bool saved = await preferences.setString(
      _lastLocationKey,
      jsonEncode(<String, int>{
        'surah_id': location.surahId,
        'ayah_number': location.ayahNumber,
        'page': location.page,
      }),
    );
    if (!saved) {
      return;
    }
    await preferences.remove(_lastSurahIdKey);
    await preferences.remove(_lastAyahNumberKey);
    await preferences.remove(_lastPageKey);
  }

  static T _readEnum<T extends Enum>(
    Object? savedValue,
    List<T> values,
    T fallback,
  ) {
    if (savedValue is String) {
      for (final T value in values) {
        if (value.name == savedValue) {
          return value;
        }
      }
    }
    return fallback;
  }

  static double _readClampedDouble(
    Object? savedValue,
    double minimum,
    double maximum,
    double fallback,
  ) {
    if (savedValue is! num || !savedValue.isFinite) {
      return fallback;
    }
    return savedValue.toDouble().clamp(minimum, maximum).toDouble();
  }

  static int _readIntInRange(
    Object? savedValue,
    int minimum,
    int maximum,
    int fallback,
  ) {
    if (savedValue is int && savedValue >= minimum && savedValue <= maximum) {
      return savedValue;
    }
    return fallback;
  }

  static int _readPositiveInt(Object? savedValue, int fallback) {
    if (savedValue is int && savedValue > 0) {
      return savedValue;
    }
    return fallback;
  }

  static _SavedLocation? _readLocation(Object? savedValue) {
    if (savedValue is! String) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(savedValue);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      final Object? surahId = decoded['surah_id'];
      final Object? ayahNumber = decoded['ayah_number'];
      final Object? page = decoded['page'];
      if (surahId is! int ||
          surahId < 1 ||
          surahId > 114 ||
          ayahNumber is! int ||
          ayahNumber < 1 ||
          page is! int ||
          page < 1 ||
          page > 604) {
        return null;
      }
      return _SavedLocation(
        surahId: surahId,
        ayahNumber: ayahNumber,
        page: page,
      );
    } on FormatException {
      return null;
    }
  }

  static Set<int> _readBookmarks(Object? savedValue) {
    if (savedValue is! List) {
      return <int>{};
    }

    return savedValue
        .map(
          (dynamic item) => item is int ? item : int.tryParse(item.toString()),
        )
        .whereType<int>()
        .where((int id) => id >= 1 && id <= 6236)
        .toSet();
  }

  static List<String> _readStringList(Object? savedValue) {
    if (savedValue is! List) {
      return <String>[];
    }
    return savedValue
        .map((dynamic item) => item?.toString().trim())
        .whereType<String>()
        .where((String item) => item.isNotEmpty)
        .take(8)
        .toList();
  }

  static double _clampFinite(num value, double minimum, double maximum) {
    final double doubleValue = value.toDouble();
    if (!doubleValue.isFinite) {
      throw ArgumentError.value(value, 'value', 'Must be finite');
    }
    return doubleValue.clamp(minimum, maximum).toDouble();
  }
}

final class _SavedLocation {
  const _SavedLocation({
    required this.surahId,
    required this.ayahNumber,
    required this.page,
  });

  final int surahId;
  final int ayahNumber;
  final int page;
}
