// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kirghiz Kyrgyz (`ky`).
class AppLocalizationsKy extends AppLocalizations {
  AppLocalizationsKy([String locale = 'ky']) : super(locale);

  @override
  String get appTitle => 'Мубийн Куран';

  @override
  String get appName => 'МУБИЙН';

  @override
  String get appSubtitle => 'КУРАН';

  @override
  String get tabRead => 'Окуу';

  @override
  String get tabNavigation => 'Навигация';

  @override
  String get tabSearch => 'Издөө';

  @override
  String get tabSettings => 'Жөндөөлөр';

  @override
  String get settingsTitle => 'Окуу жөндөөлөрү';

  @override
  String get sectionAppearance => 'Көрүнүш';

  @override
  String get sectionTranslation => 'Котормо';

  @override
  String get sectionTextSize => 'Тексттин өлчөмү';

  @override
  String get sectionHandsFreeReading => 'Автоматтык окуу';

  @override
  String get eyeCareFilter => 'Көз коргоо (Түнкү чыпка)';

  @override
  String get showTranslation => 'Котормону көрсөтүү';

  @override
  String get showTranslationSubtitle =>
      'Араб тексти ар дайым негизги бойдон калат';

  @override
  String get onlineTranslation => 'Онлайн котормо';

  @override
  String get downloading => 'Жүктөлүүдө...';

  @override
  String get arabicTextSize => 'Араб тексти';

  @override
  String get translationTextSize => 'Котормо';

  @override
  String get autoScrollSpeed => 'Авто-жылдыруу ылдамдыгы';

  @override
  String autoScrollSpeedValue(String value) {
    return '$value сап/мүн';
  }

  @override
  String get autoScrollHint =>
      'Вертикалдуу окуу режиминде баскыч менен авто-жылдырууну баштаңыз. Бир жолу басуу токтотот.';

  @override
  String get guideTitle => 'Колдонмо жана кеңештер';

  @override
  String get guideSubtitle => 'Жаңсоолор, авто-жылдыруу, тафсир жана издөө';

  @override
  String get onboardingTitle => 'Тиркеме жөнүндө';

  @override
  String get onboardingSubtitle => 'Эскертме аяты менен кириш экранын ачуу';

  @override
  String get sourcesTitle => 'Булактар жана атрибуция';

  @override
  String get sourcesSubtitle => 'Тексттер жана лицензиялар жөнүндө маалымат';

  @override
  String get privacyNote =>
      'Жалгыз Куран. Жарнамасыз, каттоосуз, лентасыз, окуу анализсиз жана бөтөн бөлүмдөрсүз. Жөндөөлөр жана кыстармалар түзмөктө сакталат.';

  @override
  String get themeParchment => 'Пергамент';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeEmerald => 'Зумурут';

  @override
  String get themeLight => 'Жарык';

  @override
  String themeLabel(String name) {
    return 'Тема $name';
  }

  @override
  String get jumpToAyah => 'Аятка өтүү';

  @override
  String get verticalReading => 'Вертикалдуу окуу';

  @override
  String get quranPages => 'Куран барактары';

  @override
  String surahInfoLabel(int id, String name, int count) {
    return 'Сүрө $id. $name ($count аят)';
  }

  @override
  String get meccan => 'Мекке';

  @override
  String get medinan => 'Мадина';

  @override
  String get listenSurah => 'Сүрөнү угуу';

  @override
  String get pause => 'Тыным';

  @override
  String get listenAyah => 'Аятты угуу';

  @override
  String get copyAyah => 'Аятты көчүрүү';

  @override
  String get wordAnalysis => 'Сөз боюнча талдоо';

  @override
  String get tafsirSaadi => 'Тафсир ас-Саади';

  @override
  String get recitationCheck => 'Кыраат текшерүү (Хифз)';

  @override
  String get addBookmark => 'Кыстарма кошуу';

  @override
  String get removeBookmark => 'Кыстарманы жок кылуу';

  @override
  String ayahCopied(int surah, int ayah) {
    return 'Аят $surah:$ayah көчүрүлдү';
  }

  @override
  String get copyFailed => 'Аятты көчүрүү мүмкүн болбоду.';

  @override
  String quranReference(int surah, int ayah) {
    return 'Куран ($surah:$ayah)';
  }

  @override
  String tafsirTitle(int surah, int ayah) {
    return 'Тафсир ас-Саади · $surah:$ayah';
  }

  @override
  String get tafsirSubtitle => 'Шейх Абдур-Рахман ас-Саадинин Куран тафсири';

  @override
  String get tafsirNotFound => 'Бул аят үчүн тафсир табылган жок.';

  @override
  String wordAnalysisTitle(int surah, int ayah) {
    return 'Сөз талдоосу · $surah:$ayah';
  }

  @override
  String get wordAnalysisSubtitle =>
      'Деталдуу грамматика жана тамыр үчүн сөздү басыңыз';

  @override
  String get wordAnalysisNotFound => 'Сөз талдоосу табылган жок.';

  @override
  String get wordTranslation => 'Котормо';

  @override
  String get wordRoot => 'Тамыр';

  @override
  String get wordLemma => 'Лемма';

  @override
  String get wordPartOfSpeech => 'Сөз түрү';

  @override
  String get notSpecified => 'Көрсөтүлгөн эмес';

  @override
  String get close => 'Жабуу';

  @override
  String get sajda => 'Сажда';

  @override
  String juz(int number) {
    return 'Жүз $number';
  }

  @override
  String get autoScroll => 'Авто-жылдыруу';

  @override
  String get slower => 'Жайыраак';

  @override
  String get faster => 'Тезирээк';

  @override
  String linesPerMinute(int value) {
    return '$value с/м';
  }

  @override
  String get readerTipTitle => 'Окуу кеңеши';

  @override
  String get readerTipBody =>
      'Сөз талдоосу, тафсир жана кыстармалар үчүн ар бир аяттын жанындагы сүрөтчөлөрдү басыңыз.';

  @override
  String get understood => 'Түшүнүктүү';

  @override
  String get failedToOpenSurah => 'Сүрөнү ачуу мүмкүн болбоду.';

  @override
  String get noAyahsInSurah => 'Бул сүрөдө аят жок.';

  @override
  String failedToLoadPage(int page) {
    return '$page-баракты жүктөө мүмкүн болбоду.';
  }

  @override
  String noAyahsOnPage(int page) {
    return '$page-баракта аят жок.';
  }

  @override
  String get retry => 'Кайра аракет';

  @override
  String get failedToLoadData => 'Маалыматтарды жүктөө мүмкүн болбоду.';

  @override
  String pageOfTotal(int page) {
    return 'Барак $page / 604';
  }

  @override
  String get textLayout => 'Текст жайгашуусу';

  @override
  String get failedToOpenQuran => 'Куранды ачуу мүмкүн болбоду';

  @override
  String get checkStorageAndRestart =>
      'Түзмөктөгү бош орунду текшериңиз жана тиркемени кайра иштетиңиз.';

  @override
  String get navigationSurahs => 'Сүрөлөр';

  @override
  String get navigationJuz => 'Жүздөр';

  @override
  String get navigationHizb => 'Хизбдар';

  @override
  String get navigationBookmarks => 'Кыстармалар';

  @override
  String get searchInQuran => 'Курандан издөө';

  @override
  String get searchHint => 'Текст, котормо же аят номери боюнча издөө';

  @override
  String get noResults => 'Эч нерсе табылган жок';

  @override
  String get recentSearches => 'Акыркы издөөлөр';

  @override
  String get clearAll => 'Баарын тазалоо';

  @override
  String get uiLanguage => 'Интерфейс тили';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTajik => 'Тоҷикӣ';

  @override
  String get languageUzbek => 'Oʻzbekcha';

  @override
  String get languageKyrgyz => 'Кыргызча';

  @override
  String get languageAzerbaijani => 'Azərbaycan';

  @override
  String get aboutTitle => 'Булактар жана авторлор';

  @override
  String get aboutAppDescription =>
      'Ыйык Куранды жарнамасыз жана маалымат чогултуусуз окуу үчүн акысыз тиркеме.';

  @override
  String get aboutDataSources => 'МААЛЫМАТ БУЛАКТАРЫ';

  @override
  String get sourceUthmaniTitle => 'Курандын арабча тексти (Uthmani)';

  @override
  String get sourceUthmaniDesc =>
      'Tanzil.net долбоору тарабынан сунушталган. Ыйык Курандын такталган тексти.';

  @override
  String get sourceKulievTitle => 'Маанилердин котормосу (Элмир Кулиев)';

  @override
  String get sourceKulievDesc =>
      'Коммерциялык эмес максатта акысыз таркатылат.';

  @override
  String get sourceAbuAdelTitle => 'Маанилердин котормосу (Абу Адел)';

  @override
  String get sourceAbuAdelDesc =>
      'Коммерциялык эмес максатта акысыз таркатылат.';

  @override
  String get sourceTafsirTitle => 'Тафсир (Абдур-Рахман ас-Саади)';

  @override
  String get sourceTafsirDesc =>
      'Ыйык Курандын түшүндүрмөсү акысыз таркатылат.';

  @override
  String get sourceFontTitle => 'Арип (Amiri Quran)';

  @override
  String get sourceFontDesc =>
      'SIL OFL лицензиясы менен ачык арабча Amiri ариби.';

  @override
  String get sourceMorphologyTitle => 'Сөзмө-сөз морфология';

  @override
  String get sourceMorphologyDesc =>
      'Араб грамматикасы жана сөзмө-сөз маанилери: Quranic Arabic Corpus (corpus.quran.com, автору Kais Dukes) GNU GPL лицензиясы менен.';

  @override
  String get sourceAudioTitle => 'Карылардын аудиосу (EveryAyah)';

  @override
  String get sourceAudioDesc =>
      'Куран окуу жазуулары everyayah.com сайтынан жүктөлөт. Укуктар карыларга жана басмаканаларга таандык; тиркеме аудиону өзү менен камтыбайт жана аны угуу үчүн гана колдонот.';

  @override
  String get sourceOnlineApiTitle =>
      'Онлайн котормолор жана сөз убактысы (Quran.com)';

  @override
  String get sourceOnlineApiDesc =>
      'Кошумча котормолор (Saheeh International, тажик, өзбек, азербайжан) жана карылардын сөзмө-сөз убакыт белгилери ачык Quran.com / Quran Foundation API аркылуу жүктөлүп, түзмөктө сакталат.';

  @override
  String get sourceSpeechTitle => 'Кепти таануу (Whisper)';

  @override
  String get sourceSpeechDesc =>
      'Окуу машыктыргычы жазууңузду Modal\'да жайгашкан OpenAI Whisper (MIT лицензиясы) моделдүү серверге жөнөтөт. Жазуу иштетилгенден кийин дароо өчүрүлөт.';

  @override
  String get viewLicenses => 'Ачык булактуу программалык лицензиялар';

  @override
  String get skip => 'Өткөрүп жиберүү';

  @override
  String get next => 'Кийинки';

  @override
  String get startReading => 'Бисмиллах, окууну баштоо';

  @override
  String get reminderTitle => 'Ыймандууларга эскертүү';

  @override
  String get reminderAyah =>
      '«Бул – аяттары тууралуу ой жүгүртүп, акыл ээлери эске алуулары үчүн Биз сага түшүргөн берекелүү Китеп.»';

  @override
  String get reminderRef => '38-сүрө «Сад», 29-аят';

  @override
  String get purityStatement =>
      'Жалгыз Аллахтын Китеби. Жарнамасыз жана алаксытуучу нерселерсиз. Офлайн иштейт (үндү текшерүү функциясынан тышкары).';

  @override
  String get readingModesTitle => 'ОКУУ РЕЖИМДЕРИ';

  @override
  String get readingModesSubtitle => 'Өзүңүзгө ыңгайлуу окуу ыкмасын тандаңыз';

  @override
  String get flowModeTitle => 'Ырааттуу түрмөк (Flow)';

  @override
  String get flowModeBadge => 'Сапма-сап режим';

  @override
  String get flowModeDesc =>
      'Күнүмдүк ойлонуп окуу үчүн ыңгайлуу. Авто-жылдыруу жана сөздүк талдоону камтыйт.';

  @override
  String get mushafModeTitle => 'Классикалык Мусхаф (604 бет)';

  @override
  String get mushafModeBadge => 'Барактык режим';

  @override
  String get mushafModeDesc =>
      'Медина мусхафынын баракма-барак форматы. Жаттоо (хифз) үчүн эң сонун.';

  @override
  String get featuresTitle => 'МҮМКҮНЧҮЛҮКТӨР';

  @override
  String get featuresSubtitle => 'Баары сиздин ыңгайыңыз үчүн';

  @override
  String get themesFeatureTitle => '4 тема жана түнкү чыпка';

  @override
  String get themesFeatureBadge => 'Көрүнүш';

  @override
  String get themesFeatureDesc =>
      'Пергамент, Зумурут, OLED жана Жарык темалары көз коргоочу чыпкасы менен.';

  @override
  String get searchFeatureTitle => 'Китеп боюнча акылдуу издөө';

  @override
  String get searchFeatureBadge => 'Ыкчам издөө';

  @override
  String get searchFeatureDesc =>
      'Арабча текст, котормолор же аят номерлери (мисалы, 2:255) боюнча издеңиз.';

  @override
  String get khatmGoalTitle => 'Окуу максаты (Хатм)';

  @override
  String get khatmDaysQuestion =>
      'Куранды (604 бет) канча күндө толук окуп бүтүүнү пландайсыз?';

  @override
  String daysCount(int days) {
    return '$days күн';
  }

  @override
  String dailyGoalPages(int pages) {
    return 'Максат: күнүнө $pages бет';
  }

  @override
  String get cancel => 'Жокко чыгаруу';

  @override
  String get startKhatm => 'Хатмды баштоо';

  @override
  String khatmPlanTitle(int days) {
    return '$days күндүк Хатм';
  }

  @override
  String get setKhatmGoal => 'Окуу максатын коюу (Хатм)';

  @override
  String get calculateDailyNorm => 'Күнүмдүк бет өлчөмүн эсептеңиз';

  @override
  String get editGoal => 'Максатты өзгөртүү';

  @override
  String get resetGoal => 'Аяктоо / тазалоо';

  @override
  String khatmPagesRead(int completed) {
    return '604 беттен $completed бет окулду';
  }

  @override
  String khatmDailyNormRemain(int daily, int remaining) {
    return 'Өлчөм: күнүнө $daily бет · Калды: $remaining күн';
  }

  @override
  String bookmarkTitle(int surah, int ayah) {
    return 'Кыстарма: $surah-сүрө, $ayah-аят';
  }

  @override
  String get delete => 'Жок кылуу';

  @override
  String get folderCollection => 'Папка / Жыйнак:';

  @override
  String get personalNote => 'Жеке эскертүү (милдеттүү эмес):';

  @override
  String get personalNoteHint => 'Мисалы: Бул жумада жаттоо...';

  @override
  String get saveChanges => 'Өзгөртүүлөрдү сактоо';

  @override
  String get addToBookmarks => 'Кыстармаларга кошуу';

  @override
  String get selectReciter => 'Карыны тандоо (Тилават)';

  @override
  String get playbackSpeed => 'Ойнотуу ылдамдыгы';

  @override
  String get downloadSurahOffline => 'Офлайн окуу үчүн сүрөнү жүктөө';

  @override
  String get speed => 'Ылдамдык';

  @override
  String get repeatOn => 'Аят кайталоо күйгүзүлдү';

  @override
  String get repeatOff => 'Аят кайталоо өчүрүлдү';

  @override
  String get closePlayer => 'Плейерди жабуу';

  @override
  String get prevAyah => 'Мурунку аят';

  @override
  String get nextAyah => 'Кийинки аят';

  @override
  String ayahNumber(int number) {
    return '$number-аят';
  }

  @override
  String get hifzTrainerTitle => 'Кыраат текшерүү (Хифз)';

  @override
  String hifzAyahInfo(int surahId, String surahName, int ayahNum) {
    return 'Сүрө $surahId. $surahName · Аят $ayahNum';
  }

  @override
  String get tajweedRules => 'Бул аяттын тажвид эрежелери';

  @override
  String get byMemory => 'Жаттан';

  @override
  String get withText => 'Текст менен';

  @override
  String get continuousMode => 'Үзгүлтүксүз';

  @override
  String get oneAyahMode => 'Бир аят';

  @override
  String get continuousModeDesc => 'Кийинки аятка автоматтык өтүү';

  @override
  String get listenToAyah => 'Аятты угуу';

  @override
  String get perfectReading => 'МашаАллах! Аят туура окулду';

  @override
  String readingAccuracy(int accuracy, int correct, int total) {
    return 'Тактык: $accuracy% ($correct/$total сөз)';
  }

  @override
  String aiListening(String text) {
    return 'Угуп жатам: \"$text\"';
  }

  @override
  String get startOver => 'Кайра баштоо';

  @override
  String get stopListening => 'Токтотуу';

  @override
  String get startListening => 'Окуу';

  @override
  String get readingInstructions => 'Микрофонду басып, арабча окуп баштаңыз';

  @override
  String get listeningInProgress => 'Угуп жатам...';

  @override
  String get processingAudio => 'Иштетилүүдө...';

  @override
  String get micError => 'Микрофон катасы. Уруксат берилгенин текшериңиз.';

  @override
  String get recitationDisclaimerTitle => 'Маанилүү эскертүү';

  @override
  String get recitationDisclaimerBody =>
      'Кыраатты автоматтык текшерүү ката кетириши мүмкүн жана 100% тактыкка кепилдик бербейт. Аны жардамчы курал катары гана колдонуңуз. Ал квалификациялуу шейхтен, карыдан же тажвид мугалиминен билим алууну жана кыраатты текшертүүнү алмаштырбайт. Айтылышты колдонмонун жыйынтыгына гана таянып үйрөнбөңүз. Таануу үчүн үн жаздырууңуз тышкы серверге жөнөтүлөт.';

  @override
  String get recitationDisclaimerAccept => 'Түшүндүм, улантуу';
}
