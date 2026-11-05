import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tg.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ky'),
    Locale('ru'),
    Locale('tg'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Mubeen Quran Pure'**
  String get appTitle;

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'MUBEEN'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'QURAN PURE'**
  String get appSubtitle;

  /// No description provided for @tabRead.
  ///
  /// In ru, this message translates to:
  /// **'Читать'**
  String get tabRead;

  /// No description provided for @tabNavigation.
  ///
  /// In ru, this message translates to:
  /// **'Навигация'**
  String get tabNavigation;

  /// No description provided for @tabSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get tabSearch;

  /// No description provided for @tabSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get tabSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки чтения'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get sectionAppearance;

  /// No description provided for @sectionTranslation.
  ///
  /// In ru, this message translates to:
  /// **'Перевод смыслов'**
  String get sectionTranslation;

  /// No description provided for @sectionTextSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер текста'**
  String get sectionTextSize;

  /// No description provided for @sectionHandsFreeReading.
  ///
  /// In ru, this message translates to:
  /// **'Чтение без рук'**
  String get sectionHandsFreeReading;

  /// No description provided for @eyeCareFilter.
  ///
  /// In ru, this message translates to:
  /// **'Защита глаз (Ночной фильтр)'**
  String get eyeCareFilter;

  /// No description provided for @showTranslation.
  ///
  /// In ru, this message translates to:
  /// **'Показывать перевод'**
  String get showTranslation;

  /// No description provided for @showTranslationSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Арабский текст всегда остаётся главным'**
  String get showTranslationSubtitle;

  /// No description provided for @onlineTranslation.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн-перевод'**
  String get onlineTranslation;

  /// No description provided for @downloading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get downloading;

  /// No description provided for @arabicTextSize.
  ///
  /// In ru, this message translates to:
  /// **'Арабский текст'**
  String get arabicTextSize;

  /// No description provided for @translationTextSize.
  ///
  /// In ru, this message translates to:
  /// **'Русский перевод'**
  String get translationTextSize;

  /// No description provided for @autoScrollSpeed.
  ///
  /// In ru, this message translates to:
  /// **'Скорость автопрокрутки'**
  String get autoScrollSpeed;

  /// No description provided for @autoScrollSpeedValue.
  ///
  /// In ru, this message translates to:
  /// **'{value} строк/мин'**
  String autoScrollSpeedValue(String value);

  /// No description provided for @autoScrollHint.
  ///
  /// In ru, this message translates to:
  /// **'Запустите автопрокрутку кнопкой в режиме вертикального чтения. Одно касание ставит её на паузу.'**
  String get autoScrollHint;

  /// No description provided for @guideTitle.
  ///
  /// In ru, this message translates to:
  /// **'Руководство и подсказки'**
  String get guideTitle;

  /// No description provided for @guideSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Жесты, автопрокрутка, тафсир и поиск'**
  String get guideSubtitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In ru, this message translates to:
  /// **'О приложении и напоминание'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Открыть вводный экран с аятом-назиданием'**
  String get onboardingSubtitle;

  /// No description provided for @sourcesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Источники и атрибуция'**
  String get sourcesTitle;

  /// No description provided for @sourcesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Информация о текстах и лицензиях'**
  String get sourcesSubtitle;

  /// No description provided for @privacyNote.
  ///
  /// In ru, this message translates to:
  /// **'Только Коран. Без рекламы, регистрации, ленты, аналитики чтения и посторонних разделов. Настройки и закладки хранятся на устройстве.'**
  String get privacyNote;

  /// No description provided for @themeParchment.
  ///
  /// In ru, this message translates to:
  /// **'Пергамент'**
  String get themeParchment;

  /// No description provided for @themeOled.
  ///
  /// In ru, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @themeEmerald.
  ///
  /// In ru, this message translates to:
  /// **'Изумруд'**
  String get themeEmerald;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Тема {name}'**
  String themeLabel(String name);

  /// No description provided for @jumpToAyah.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к аяту'**
  String get jumpToAyah;

  /// No description provided for @verticalReading.
  ///
  /// In ru, this message translates to:
  /// **'Вертикальное чтение'**
  String get verticalReading;

  /// No description provided for @quranPages.
  ///
  /// In ru, this message translates to:
  /// **'Страницы Корана'**
  String get quranPages;

  /// No description provided for @surahInfoLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сура {id}. {name} ({count} аятов)'**
  String surahInfoLabel(int id, String name, int count);

  /// No description provided for @meccan.
  ///
  /// In ru, this message translates to:
  /// **'Мекканская'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In ru, this message translates to:
  /// **'Мединская'**
  String get medinan;

  /// No description provided for @listenSurah.
  ///
  /// In ru, this message translates to:
  /// **'Слушать суру'**
  String get listenSurah;

  /// No description provided for @pause.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get pause;

  /// No description provided for @listenAyah.
  ///
  /// In ru, this message translates to:
  /// **'Слушать аят'**
  String get listenAyah;

  /// No description provided for @copyAyah.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать аят'**
  String get copyAyah;

  /// No description provided for @wordAnalysis.
  ///
  /// In ru, this message translates to:
  /// **'Пословный разбор'**
  String get wordAnalysis;

  /// No description provided for @tafsirSaadi.
  ///
  /// In ru, this message translates to:
  /// **'Тафсир ас-Саади'**
  String get tafsirSaadi;

  /// No description provided for @recitationCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверить чтение (Хифз)'**
  String get recitationCheck;

  /// No description provided for @addBookmark.
  ///
  /// In ru, this message translates to:
  /// **'Добавить закладку (зажмите для выбора папки)'**
  String get addBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In ru, this message translates to:
  /// **'Удалить закладку (зажмите для выбора папки)'**
  String get removeBookmark;

  /// No description provided for @ayahCopied.
  ///
  /// In ru, this message translates to:
  /// **'Аят {surah}:{ayah} скопирован'**
  String ayahCopied(int surah, int ayah);

  /// No description provided for @copyFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скопировать аят.'**
  String get copyFailed;

  /// No description provided for @quranReference.
  ///
  /// In ru, this message translates to:
  /// **'Коран ({surah}:{ayah})'**
  String quranReference(int surah, int ayah);

  /// No description provided for @tafsirTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тафсир ас-Саади · {surah}:{ayah}'**
  String tafsirTitle(int surah, int ayah);

  /// No description provided for @tafsirSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Толкование Священного Корана шейха Абдур-Рахмана ас-Саади'**
  String get tafsirSubtitle;

  /// No description provided for @tafsirNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Тафсир для этого аята не найден.'**
  String get tafsirNotFound;

  /// No description provided for @wordAnalysisTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пословный разбор · {surah}:{ayah}'**
  String wordAnalysisTitle(int surah, int ayah);

  /// No description provided for @wordAnalysisSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на слово для подробной грамматики и корня'**
  String get wordAnalysisSubtitle;

  /// No description provided for @wordAnalysisNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Пословный разбор не найден.'**
  String get wordAnalysisNotFound;

  /// No description provided for @wordTranslation.
  ///
  /// In ru, this message translates to:
  /// **'Перевод'**
  String get wordTranslation;

  /// No description provided for @wordRoot.
  ///
  /// In ru, this message translates to:
  /// **'Корень'**
  String get wordRoot;

  /// No description provided for @wordLemma.
  ///
  /// In ru, this message translates to:
  /// **'Лемма'**
  String get wordLemma;

  /// No description provided for @wordPartOfSpeech.
  ///
  /// In ru, this message translates to:
  /// **'Часть речи'**
  String get wordPartOfSpeech;

  /// No description provided for @notSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Не указано'**
  String get notSpecified;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @sajda.
  ///
  /// In ru, this message translates to:
  /// **'Сажда'**
  String get sajda;

  /// No description provided for @juz.
  ///
  /// In ru, this message translates to:
  /// **'Джуз {number}'**
  String juz(int number);

  /// No description provided for @autoScroll.
  ///
  /// In ru, this message translates to:
  /// **'Автопрокрутка'**
  String get autoScroll;

  /// No description provided for @slower.
  ///
  /// In ru, this message translates to:
  /// **'Медленнее'**
  String get slower;

  /// No description provided for @faster.
  ///
  /// In ru, this message translates to:
  /// **'Быстрее'**
  String get faster;

  /// No description provided for @linesPerMinute.
  ///
  /// In ru, this message translates to:
  /// **'{value} стр/м'**
  String linesPerMinute(int value);

  /// No description provided for @readerTipTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подсказка для чтения'**
  String get readerTipTitle;

  /// No description provided for @readerTipBody.
  ///
  /// In ru, this message translates to:
  /// **'Нажимайте иконки возле каждого аята для пословного разбора, тафсира ас-Саади и закладок.'**
  String get readerTipBody;

  /// No description provided for @understood.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get understood;

  /// No description provided for @failedToOpenSurah.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть суру.'**
  String get failedToOpenSurah;

  /// No description provided for @noAyahsInSurah.
  ///
  /// In ru, this message translates to:
  /// **'В этой суре нет аятов.'**
  String get noAyahsInSurah;

  /// No description provided for @failedToLoadPage.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить страницу {page}.'**
  String failedToLoadPage(int page);

  /// No description provided for @noAyahsOnPage.
  ///
  /// In ru, this message translates to:
  /// **'На странице {page} нет аятов.'**
  String noAyahsOnPage(int page);

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @failedToLoadData.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные.'**
  String get failedToLoadData;

  /// No description provided for @pageOfTotal.
  ///
  /// In ru, this message translates to:
  /// **'Страница {page} из 604'**
  String pageOfTotal(int page);

  /// No description provided for @textLayout.
  ///
  /// In ru, this message translates to:
  /// **'Текстовая вёрстка'**
  String get textLayout;

  /// No description provided for @failedToOpenQuran.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть Коран'**
  String get failedToOpenQuran;

  /// No description provided for @checkStorageAndRestart.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте свободное место на устройстве и перезапустите приложение.'**
  String get checkStorageAndRestart;

  /// No description provided for @navigationSurahs.
  ///
  /// In ru, this message translates to:
  /// **'Суры'**
  String get navigationSurahs;

  /// No description provided for @navigationJuz.
  ///
  /// In ru, this message translates to:
  /// **'Джузы'**
  String get navigationJuz;

  /// No description provided for @navigationHizb.
  ///
  /// In ru, this message translates to:
  /// **'Хизбы'**
  String get navigationHizb;

  /// No description provided for @navigationBookmarks.
  ///
  /// In ru, this message translates to:
  /// **'Закладки'**
  String get navigationBookmarks;

  /// No description provided for @searchInQuran.
  ///
  /// In ru, this message translates to:
  /// **'Поиск в Коране'**
  String get searchInQuran;

  /// No description provided for @searchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по тексту, переводу или номеру аята'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get noResults;

  /// No description provided for @recentSearches.
  ///
  /// In ru, this message translates to:
  /// **'Недавние запросы'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In ru, this message translates to:
  /// **'Очистить все'**
  String get clearAll;

  /// No description provided for @uiLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык интерфейса'**
  String get uiLanguage;

  /// No description provided for @languageRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTajik.
  ///
  /// In ru, this message translates to:
  /// **'Тоҷикӣ'**
  String get languageTajik;

  /// No description provided for @languageUzbek.
  ///
  /// In ru, this message translates to:
  /// **'Oʻzbekcha'**
  String get languageUzbek;

  /// No description provided for @languageKyrgyz.
  ///
  /// In ru, this message translates to:
  /// **'Кыргызча'**
  String get languageKyrgyz;

  /// No description provided for @languageAzerbaijani.
  ///
  /// In ru, this message translates to:
  /// **'Azərbaycan'**
  String get languageAzerbaijani;

  /// No description provided for @aboutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Источники и атрибуция'**
  String get aboutTitle;

  /// No description provided for @aboutAppDescription.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатное приложение для чтения Священного Корана без рекламы и сбора данных.'**
  String get aboutAppDescription;

  /// No description provided for @aboutDataSources.
  ///
  /// In ru, this message translates to:
  /// **'ИСТОЧНИКИ ДАННЫХ'**
  String get aboutDataSources;

  /// No description provided for @sourceUthmaniTitle.
  ///
  /// In ru, this message translates to:
  /// **'Арабский текст Корана (Uthmani)'**
  String get sourceUthmaniTitle;

  /// No description provided for @sourceUthmaniDesc.
  ///
  /// In ru, this message translates to:
  /// **'Предоставлен проектом Tanzil.net. Используется на условиях лицензии Tanzil Quran License. Проект Tanzil предоставляет выверенный и аутентичный текст Священного Корана.'**
  String get sourceUthmaniDesc;

  /// No description provided for @sourceKulievTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перевод смыслов (Эльмир Кулиев)'**
  String get sourceKulievTitle;

  /// No description provided for @sourceKulievDesc.
  ///
  /// In ru, this message translates to:
  /// **'Распространяется свободно. Текст перевода смыслов предоставлен для некоммерческого использования и бесплатного распространения.'**
  String get sourceKulievDesc;

  /// No description provided for @sourceAbuAdelTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перевод смыслов (Абу Адель)'**
  String get sourceAbuAdelTitle;

  /// No description provided for @sourceAbuAdelDesc.
  ///
  /// In ru, this message translates to:
  /// **'Распространяется свободно. Текст перевода смыслов предоставлен для некоммерческого использования и бесплатного распространения.'**
  String get sourceAbuAdelDesc;

  /// No description provided for @sourceTafsirTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тафсир (Абдур-Рахман ас-Саади)'**
  String get sourceTafsirTitle;

  /// No description provided for @sourceTafsirDesc.
  ///
  /// In ru, this message translates to:
  /// **'Толкование Священного Корана. Текст распространяется свободно в образовательных и некоммерческих целях.'**
  String get sourceTafsirDesc;

  /// No description provided for @sourceFontTitle.
  ///
  /// In ru, this message translates to:
  /// **'Шрифт (Amiri Quran)'**
  String get sourceFontTitle;

  /// No description provided for @sourceFontDesc.
  ///
  /// In ru, this message translates to:
  /// **'Используется открытый арабский шрифт Amiri под лицензией SIL Open Font License (OFL).'**
  String get sourceFontDesc;

  /// No description provided for @sourceMorphologyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пословный разбор и морфология'**
  String get sourceMorphologyTitle;

  /// No description provided for @sourceMorphologyDesc.
  ///
  /// In ru, this message translates to:
  /// **'Арабская грамматика и пословные значения: Quranic Arabic Corpus (corpus.quran.com, автор Kais Dukes) под лицензией GNU GPL.'**
  String get sourceMorphologyDesc;

  /// No description provided for @sourceAudioTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аудио чтецов (EveryAyah)'**
  String get sourceAudioTitle;

  /// No description provided for @sourceAudioDesc.
  ///
  /// In ru, this message translates to:
  /// **'Записи чтения Корана загружаются по сети с everyayah.com. Права на записи принадлежат чтецам и издателям; приложение не содержит аудио в комплекте и использует его только для прослушивания.'**
  String get sourceAudioDesc;

  /// No description provided for @sourceOnlineApiTitle.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн-переводы и тайминги слов (Quran.com)'**
  String get sourceOnlineApiTitle;

  /// No description provided for @sourceOnlineApiDesc.
  ///
  /// In ru, this message translates to:
  /// **'Дополнительные переводы (Saheeh International, таджикский, узбекский, азербайджанский) и пословные тайминги чтецов загружаются через открытый API Quran.com / Quran Foundation и кэшируются на устройстве.'**
  String get sourceOnlineApiDesc;

  /// No description provided for @sourceSpeechTitle.
  ///
  /// In ru, this message translates to:
  /// **'Распознавание речи (Whisper)'**
  String get sourceSpeechTitle;

  /// No description provided for @sourceSpeechDesc.
  ///
  /// In ru, this message translates to:
  /// **'Тренажёр чтения отправляет запись на сервер с моделью OpenAI Whisper (лицензия MIT), размещённый на Modal. Запись удаляется сразу после обработки.'**
  String get sourceSpeechDesc;

  /// No description provided for @sectionArabicFont.
  ///
  /// In ru, this message translates to:
  /// **'Арабский шрифт'**
  String get sectionArabicFont;

  /// No description provided for @fontHafs.
  ///
  /// In ru, this message translates to:
  /// **'Усмани Хафс (мединский мусхаф)'**
  String get fontHafs;

  /// No description provided for @fontHafsSmart.
  ///
  /// In ru, this message translates to:
  /// **'Хафс Smart (для экрана)'**
  String get fontHafsSmart;

  /// No description provided for @fontAmiri.
  ///
  /// In ru, this message translates to:
  /// **'Amiri Quran (классический насх)'**
  String get fontAmiri;

  /// No description provided for @sourceFontKfgqpcTitle.
  ///
  /// In ru, this message translates to:
  /// **'Шрифты KFGQPC Хафс'**
  String get sourceFontKfgqpcTitle;

  /// No description provided for @sourceFontKfgqpcDesc.
  ///
  /// In ru, this message translates to:
  /// **'Шрифты «KFGQPC HAFS Uthmanic Script» и «KFGQPC Hafs Smart» Комплекса имени Короля Фахда по изданию Корана (Медина). Лицензия разрешает бесплатное использование, копирование и распространение без изменений; текст лицензии включён в приложение.'**
  String get sourceFontKfgqpcDesc;

  /// No description provided for @sourceFontSerifTitle.
  ///
  /// In ru, this message translates to:
  /// **'Шрифт перевода (PT Serif)'**
  String get sourceFontSerifTitle;

  /// No description provided for @sourceFontSerifDesc.
  ///
  /// In ru, this message translates to:
  /// **'Переводы и тафсир набраны шрифтом PT Serif компании ParaType под лицензией SIL Open Font License.'**
  String get sourceFontSerifDesc;

  /// No description provided for @viewLicenses.
  ///
  /// In ru, this message translates to:
  /// **'Лицензии открытого ПО'**
  String get viewLicenses;

  /// No description provided for @skip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get next;

  /// No description provided for @startReading.
  ///
  /// In ru, this message translates to:
  /// **'Бисмилля, начать чтение'**
  String get startReading;

  /// No description provided for @reminderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание верующим'**
  String get reminderTitle;

  /// No description provided for @reminderAyah.
  ///
  /// In ru, this message translates to:
  /// **'«Это — благословенное Писание, которое Мы ниспослали тебе, дабы они размышляли над его аятами и дабы обладающие разумом внимали назиданию.»'**
  String get reminderAyah;

  /// No description provided for @reminderRef.
  ///
  /// In ru, this message translates to:
  /// **'Сура 38 «Сад», аят 29'**
  String get reminderRef;

  /// No description provided for @purityStatement.
  ///
  /// In ru, this message translates to:
  /// **'Только Книга Аллаха. Без рекламы, лент, сбора данных и отвлекающих факторов. Работает офлайн (кроме голосовой проверки чтения).'**
  String get purityStatement;

  /// No description provided for @readingModesTitle.
  ///
  /// In ru, this message translates to:
  /// **'РЕЖИМЫ ЧТЕНИЯ'**
  String get readingModesTitle;

  /// No description provided for @readingModesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите привычный способ чтения'**
  String get readingModesSubtitle;

  /// No description provided for @flowModeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Плавный свиток (Flow)'**
  String get flowModeTitle;

  /// No description provided for @flowModeBadge.
  ///
  /// In ru, this message translates to:
  /// **'Построчный режим'**
  String get flowModeBadge;

  /// No description provided for @flowModeDesc.
  ///
  /// In ru, this message translates to:
  /// **'Удобно для ежедневного вдумчивого чтения. Включает плавную автопрокрутку без рук, пословный разбор арабских корней и тафсир ас-Саади.'**
  String get flowModeDesc;

  /// No description provided for @mushafModeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Классический Мусхаф (604 стр.)'**
  String get mushafModeTitle;

  /// No description provided for @mushafModeBadge.
  ///
  /// In ru, this message translates to:
  /// **'Страничный режим'**
  String get mushafModeBadge;

  /// No description provided for @mushafModeDesc.
  ///
  /// In ru, this message translates to:
  /// **'Традиционная вёрстка страницы в страницу (Мединский мусхаф). Идеально подходит для заучивания (хифз) и повторения.'**
  String get mushafModeDesc;

  /// No description provided for @featuresTitle.
  ///
  /// In ru, this message translates to:
  /// **'ВОЗМОЖНОСТИ'**
  String get featuresTitle;

  /// No description provided for @featuresSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Всё для вашего удобства'**
  String get featuresSubtitle;

  /// No description provided for @themesFeatureTitle.
  ///
  /// In ru, this message translates to:
  /// **'4 благородные темы и ночной фильтр'**
  String get themesFeatureTitle;

  /// No description provided for @themesFeatureBadge.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get themesFeatureBadge;

  /// No description provided for @themesFeatureDesc.
  ///
  /// In ru, this message translates to:
  /// **'Пергамент, Изумруд, глубокий OLED и Светлая тема с бережным янтарным фильтром для защиты глаз в темноте.'**
  String get themesFeatureDesc;

  /// No description provided for @searchFeatureTitle.
  ///
  /// In ru, this message translates to:
  /// **'Умный поиск по всей Книге'**
  String get searchFeatureTitle;

  /// No description provided for @searchFeatureBadge.
  ///
  /// In ru, this message translates to:
  /// **'Мгновенный поиск'**
  String get searchFeatureBadge;

  /// No description provided for @searchFeatureDesc.
  ///
  /// In ru, this message translates to:
  /// **'Ищите по арабскому тексту (с огласовками и без), переводам, названиям сур или точным ссылкам (например, 2:255).'**
  String get searchFeatureDesc;

  /// No description provided for @khatmGoalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Цель чтения (Хатм)'**
  String get khatmGoalTitle;

  /// No description provided for @khatmDaysQuestion.
  ///
  /// In ru, this message translates to:
  /// **'За сколько дней вы планируете прочитать весь Коран (604 страницы)?'**
  String get khatmDaysQuestion;

  /// No description provided for @daysCount.
  ///
  /// In ru, this message translates to:
  /// **'{days} дней'**
  String daysCount(int days);

  /// No description provided for @dailyGoalPages.
  ///
  /// In ru, this message translates to:
  /// **'Цель: {pages} стр. в день'**
  String dailyGoalPages(int pages);

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @startKhatm.
  ///
  /// In ru, this message translates to:
  /// **'Начать Хатм'**
  String get startKhatm;

  /// No description provided for @khatmPlanTitle.
  ///
  /// In ru, this message translates to:
  /// **'Хатм за {days} дней'**
  String khatmPlanTitle(int days);

  /// No description provided for @setKhatmGoal.
  ///
  /// In ru, this message translates to:
  /// **'Поставить цель чтения (Хатм)'**
  String get setKhatmGoal;

  /// No description provided for @calculateDailyNorm.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитайте ежедневную норму страниц'**
  String get calculateDailyNorm;

  /// No description provided for @editGoal.
  ///
  /// In ru, this message translates to:
  /// **'Изменить цель'**
  String get editGoal;

  /// No description provided for @resetGoal.
  ///
  /// In ru, this message translates to:
  /// **'Завершить / сбросить'**
  String get resetGoal;

  /// No description provided for @khatmPagesRead.
  ///
  /// In ru, this message translates to:
  /// **'Прочитано {completed} из 604 стр.'**
  String khatmPagesRead(int completed);

  /// No description provided for @khatmDailyNormRemain.
  ///
  /// In ru, this message translates to:
  /// **'Норма: {daily} стр./день · Осталось: {remaining} дн.'**
  String khatmDailyNormRemain(int daily, int remaining);

  /// No description provided for @bookmarkTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закладка: Сура {surah}:{ayah}'**
  String bookmarkTitle(int surah, int ayah);

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @folderCollection.
  ///
  /// In ru, this message translates to:
  /// **'Папка / Коллекция:'**
  String get folderCollection;

  /// No description provided for @personalNote.
  ///
  /// In ru, this message translates to:
  /// **'Личная заметка (необязательно):'**
  String get personalNote;

  /// No description provided for @personalNoteHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Заучить на этой неделе...'**
  String get personalNoteHint;

  /// No description provided for @saveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get saveChanges;

  /// No description provided for @addToBookmarks.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в закладки'**
  String get addToBookmarks;

  /// No description provided for @selectReciter.
  ///
  /// In ru, this message translates to:
  /// **'Выберите чтеца (Тилява)'**
  String get selectReciter;

  /// No description provided for @playbackSpeed.
  ///
  /// In ru, this message translates to:
  /// **'Скорость воспроизведения'**
  String get playbackSpeed;

  /// No description provided for @downloadSurahOffline.
  ///
  /// In ru, this message translates to:
  /// **'Скачать суру для офлайн чтения'**
  String get downloadSurahOffline;

  /// No description provided for @speed.
  ///
  /// In ru, this message translates to:
  /// **'Скорость'**
  String get speed;

  /// No description provided for @repeatOn.
  ///
  /// In ru, this message translates to:
  /// **'Повтор аята включен'**
  String get repeatOn;

  /// No description provided for @repeatOff.
  ///
  /// In ru, this message translates to:
  /// **'Повтор аята выключен'**
  String get repeatOff;

  /// No description provided for @closePlayer.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть плеер'**
  String get closePlayer;

  /// No description provided for @prevAyah.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий аят'**
  String get prevAyah;

  /// No description provided for @nextAyah.
  ///
  /// In ru, this message translates to:
  /// **'Следующий аят'**
  String get nextAyah;

  /// No description provided for @ayahNumber.
  ///
  /// In ru, this message translates to:
  /// **'Аят {number}'**
  String ayahNumber(int number);

  /// No description provided for @hifzTrainerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверка чтения (Хифз)'**
  String get hifzTrainerTitle;

  /// No description provided for @hifzAyahInfo.
  ///
  /// In ru, this message translates to:
  /// **'Сура {surahId}. {surahName} · Аят {ayahNum}'**
  String hifzAyahInfo(int surahId, String surahName, int ayahNum);

  /// No description provided for @tajweedRules.
  ///
  /// In ru, this message translates to:
  /// **'Правила Таджвида этого аята'**
  String get tajweedRules;

  /// No description provided for @byMemory.
  ///
  /// In ru, this message translates to:
  /// **'По памяти'**
  String get byMemory;

  /// No description provided for @withText.
  ///
  /// In ru, this message translates to:
  /// **'С текстом'**
  String get withText;

  /// No description provided for @continuousMode.
  ///
  /// In ru, this message translates to:
  /// **'Сплошное чтение'**
  String get continuousMode;

  /// No description provided for @oneAyahMode.
  ///
  /// In ru, this message translates to:
  /// **'Один аят'**
  String get oneAyahMode;

  /// No description provided for @continuousModeDesc.
  ///
  /// In ru, this message translates to:
  /// **'Авто-переход к следующему аяту'**
  String get continuousModeDesc;

  /// No description provided for @listenToAyah.
  ///
  /// In ru, this message translates to:
  /// **'Послушать аят'**
  String get listenToAyah;

  /// No description provided for @perfectReading.
  ///
  /// In ru, this message translates to:
  /// **'МашаАллах! Аят прочитан'**
  String get perfectReading;

  /// No description provided for @readingAccuracy.
  ///
  /// In ru, this message translates to:
  /// **'Точность: {accuracy}% ({correct}/{total} слов)'**
  String readingAccuracy(int accuracy, int correct, int total);

  /// No description provided for @aiListening.
  ///
  /// In ru, this message translates to:
  /// **'Слышу: \"{text}\"'**
  String aiListening(String text);

  /// No description provided for @startOver.
  ///
  /// In ru, this message translates to:
  /// **'Начать заново'**
  String get startOver;

  /// No description provided for @stopListening.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get stopListening;

  /// No description provided for @startListening.
  ///
  /// In ru, this message translates to:
  /// **'Читать'**
  String get startListening;

  /// No description provided for @readingInstructions.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на микрофон и начните читать аят на арабском'**
  String get readingInstructions;

  /// No description provided for @listeningInProgress.
  ///
  /// In ru, this message translates to:
  /// **'Слушаю вас...'**
  String get listeningInProgress;

  /// No description provided for @processingAudio.
  ///
  /// In ru, this message translates to:
  /// **'Обработка...'**
  String get processingAudio;

  /// No description provided for @micError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка микрофона. Убедитесь, что дано разрешение.'**
  String get micError;

  /// No description provided for @recitationDisclaimerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Важное предупреждение'**
  String get recitationDisclaimerTitle;

  /// No description provided for @recitationDisclaimerBody.
  ///
  /// In ru, this message translates to:
  /// **'Автоматическая проверка чтения может ошибаться и не гарантирует 100% точность. Используйте её только как вспомогательный инструмент. Она не заменяет обучение и проверку чтения у квалифицированного шейха, кари или преподавателя таджвида. Не изучайте произношение, опираясь только на результат приложения. Для распознавания ваша аудиозапись будет отправлена на внешний сервер.'**
  String get recitationDisclaimerBody;

  /// No description provided for @recitationDisclaimerAccept.
  ///
  /// In ru, this message translates to:
  /// **'Понимаю, продолжить'**
  String get recitationDisclaimerAccept;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'az',
    'en',
    'ky',
    'ru',
    'tg',
    'uz',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
    case 'tg':
      return AppLocalizationsTg();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
