// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tajik (`tg`).
class AppLocalizationsTg extends AppLocalizations {
  AppLocalizationsTg([String locale = 'tg']) : super(locale);

  @override
  String get appTitle => 'Мубийн Қуръони Покиза';

  @override
  String get appName => 'МУБИЙН';

  @override
  String get appSubtitle => 'ҚУРЪОНИ ПОКИЗА';

  @override
  String get tabRead => 'Хондан';

  @override
  String get tabNavigation => 'Навигатсия';

  @override
  String get tabSearch => 'Ҷустуҷӯ';

  @override
  String get tabSettings => 'Танзимот';

  @override
  String get settingsTitle => 'Танзимоти хондан';

  @override
  String get sectionAppearance => 'Намуд';

  @override
  String get sectionTranslation => 'Тарҷума';

  @override
  String get sectionTextSize => 'Андозаи матн';

  @override
  String get sectionHandsFreeReading => 'Хондани худкор';

  @override
  String get eyeCareFilter => 'Ҳифзи чашм (Филтри шабона)';

  @override
  String get showTranslation => 'Нишон додани тарҷума';

  @override
  String get showTranslationSubtitle => 'Матни арабӣ ҳамеша асосӣ боқӣ мемонад';

  @override
  String get onlineTranslation => 'Тарҷумаи онлайн';

  @override
  String get downloading => 'Зеркашӣ...';

  @override
  String get arabicTextSize => 'Матни арабӣ';

  @override
  String get translationTextSize => 'Тарҷума';

  @override
  String get autoScrollSpeed => 'Суръати худҷунбонӣ';

  @override
  String autoScrollSpeedValue(String value) {
    return '$value сатр/дақ';
  }

  @override
  String get autoScrollHint =>
      'Худҷунбониро бо тугмаи дар режими хондани амудӣ оғоз кунед. Як зарба онро боздоранд.';

  @override
  String get guideTitle => 'Роҳнамо ва маслиҳатҳо';

  @override
  String get guideSubtitle => 'Имоҳо, худҷунбонӣ, тафсир ва ҷустуҷӯ';

  @override
  String get onboardingTitle => 'Дар бораи барнома';

  @override
  String get onboardingSubtitle => 'Кушодани экрани муқаддимавӣ бо ояти ёдовар';

  @override
  String get sourcesTitle => 'Манбаъҳо ва атрибутсия';

  @override
  String get sourcesSubtitle => 'Маълумот дар бораи матнҳо ва литсензияҳо';

  @override
  String get privacyNote =>
      'Танҳо Қуръон. Бе таблиғот, бақайдгирӣ, лента, таҳлили хондан ва бахшҳои бегона. Танзимот ва хатбаракҳо дар дастгоҳ нигоҳ дошта мешаванд.';

  @override
  String get themeParchment => 'Пергамент';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeEmerald => 'Зумуррад';

  @override
  String get themeLight => 'Равшан';

  @override
  String themeLabel(String name) {
    return 'Мавзӯъ $name';
  }

  @override
  String get jumpToAyah => 'Гузаштан ба оят';

  @override
  String get verticalReading => 'Хондани амудӣ';

  @override
  String get quranPages => 'Саҳифаҳои Қуръон';

  @override
  String surahInfoLabel(int id, String name, int count) {
    return 'Сура $id. $name ($count оят)';
  }

  @override
  String get meccan => 'Маккӣ';

  @override
  String get medinan => 'Маданӣ';

  @override
  String get listenSurah => 'Гӯш кардани сура';

  @override
  String get pause => 'Таваққуф';

  @override
  String get listenAyah => 'Гӯш кардани оят';

  @override
  String get copyAyah => 'Нусхабардорӣ кардани оят';

  @override
  String get wordAnalysis => 'Таҳлили калимавӣ';

  @override
  String get tafsirSaadi => 'Тафсири ас-Саъдӣ';

  @override
  String get recitationCheck => 'Санҷиши қироат (Ҳифз)';

  @override
  String get addBookmark => 'Илова кардани хатбарак';

  @override
  String get removeBookmark => 'Нест кардани хатбарак';

  @override
  String ayahCopied(int surah, int ayah) {
    return 'Ояти $surah:$ayah нусхабардорӣ шуд';
  }

  @override
  String get copyFailed => 'Нусхабардорӣ нашуд.';

  @override
  String quranReference(int surah, int ayah) {
    return 'Қуръон ($surah:$ayah)';
  }

  @override
  String tafsirTitle(int surah, int ayah) {
    return 'Тафсири ас-Саъдӣ · $surah:$ayah';
  }

  @override
  String get tafsirSubtitle =>
      'Тафсири Қуръони Карим аз шайх Абдур-Раҳмон ас-Саъдӣ';

  @override
  String get tafsirNotFound => 'Тафсир барои ин оят ёфт нашуд.';

  @override
  String wordAnalysisTitle(int surah, int ayah) {
    return 'Таҳлили калимавӣ · $surah:$ayah';
  }

  @override
  String get wordAnalysisSubtitle =>
      'Барои грамматика ва решаи муфассал калимаро зер кунед';

  @override
  String get wordAnalysisNotFound => 'Таҳлили калимавӣ ёфт нашуд.';

  @override
  String get wordTranslation => 'Тарҷума';

  @override
  String get wordRoot => 'Реша';

  @override
  String get wordLemma => 'Лемма';

  @override
  String get wordPartOfSpeech => 'Ҳиссаи нутқ';

  @override
  String get notSpecified => 'Муайян нашудааст';

  @override
  String get close => 'Пӯшидан';

  @override
  String get sajda => 'Саҷда';

  @override
  String juz(int number) {
    return 'Ҷузъ $number';
  }

  @override
  String get autoScroll => 'Худҷунбонӣ';

  @override
  String get slower => 'Сусттар';

  @override
  String get faster => 'Зудтар';

  @override
  String linesPerMinute(int value) {
    return '$value с/д';
  }

  @override
  String get readerTipTitle => 'Маслиҳат барои хондан';

  @override
  String get readerTipBody =>
      'Тасвирчаҳоро дар паҳлӯи ҳар оят зер кунед барои таҳлили калимавӣ, тафсир ва хатбаракҳо.';

  @override
  String get understood => 'Фаҳмо';

  @override
  String get failedToOpenSurah => 'Кушодани сура муяссар нашуд.';

  @override
  String get noAyahsInSurah => 'Дар ин сура оят нест.';

  @override
  String failedToLoadPage(int page) {
    return 'Боркунии саҳифаи $page муяссар нашуд.';
  }

  @override
  String noAyahsOnPage(int page) {
    return 'Дар саҳифаи $page оят нест.';
  }

  @override
  String get retry => 'Такрор';

  @override
  String get failedToLoadData => 'Боркунии маълумот муяссар нашуд.';

  @override
  String pageOfTotal(int page) {
    return 'Саҳифаи $page аз 604';
  }

  @override
  String get textLayout => 'Тарҳбандии матнӣ';

  @override
  String get failedToOpenQuran => 'Кушодани Қуръон муяссар нашуд';

  @override
  String get checkStorageAndRestart =>
      'Ҷои холиро дар дастгоҳ санҷед ва барномаро аз нав оғоз кунед.';

  @override
  String get navigationSurahs => 'Сураҳо';

  @override
  String get navigationJuz => 'Ҷузъҳо';

  @override
  String get navigationHizb => 'Ҳизбҳо';

  @override
  String get navigationBookmarks => 'Хатбаракҳо';

  @override
  String get searchInQuran => 'Ҷустуҷӯ дар Қуръон';

  @override
  String get searchHint => 'Ҷустуҷӯ аз рӯи матн, тарҷума ё рақами оят';

  @override
  String get noResults => 'Чизе ёфт нашуд';

  @override
  String get recentSearches => 'Ҷустуҷӯҳои охирин';

  @override
  String get clearAll => 'Пок кардани ҳама';

  @override
  String get uiLanguage => 'Забони интерфейс';

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
  String get aboutTitle => 'Манбаъҳо ва муаллифон';

  @override
  String get aboutAppDescription =>
      'Барномаи ройгон барои хондани Қуръони Карим бе таблиғот ва ҷамъоварии маълумот.';

  @override
  String get aboutDataSources => 'МАНБАЪҲОИ МАЪЛУМОТ';

  @override
  String get sourceUthmaniTitle => 'Матни арабии Қуръон (Uthmani)';

  @override
  String get sourceUthmaniDesc =>
      'Аз ҷониби лоиҳаи Tanzil.net пешниҳод шудааст. Матни саҳеҳ ва санҷидашудаи Қуръон.';

  @override
  String get sourceKulievTitle => 'Тарҷумаи маъноҳо (Эльмир Кулиев)';

  @override
  String get sourceKulievDesc =>
      'Барои истифодаи ғайритиҷоратӣ ройгон паҳн карда мешавад.';

  @override
  String get sourceAbuAdelTitle => 'Тарҷумаи маъноҳо (Абу Одил)';

  @override
  String get sourceAbuAdelDesc =>
      'Барои истифодаи ғайритиҷоратӣ ройгон паҳн карда мешавад.';

  @override
  String get sourceTafsirTitle => 'Тафсир (Абдур-Раҳмон ас-Саъдӣ)';

  @override
  String get sourceTafsirDesc =>
      'Тафсири Қуръони Карим бо забони содда ва фаҳмо.';

  @override
  String get sourceFontTitle => 'Ҳарф (Amiri Quran)';

  @override
  String get sourceFontDesc =>
      'Шрифти кушодаи арабии Amiri зери литсензияи SIL OFL.';

  @override
  String get sourceMorphologyTitle => 'Таҳлили сарфу наҳви калима ба калима';

  @override
  String get sourceMorphologyDesc =>
      'Грамматика ва маънои калима ба калима: Quranic Arabic Corpus (corpus.quran.com, муаллиф Kais Dukes) таҳти литсензияи GNU GPL.';

  @override
  String get sourceAudioTitle => 'Аудиои қориён (EveryAyah)';

  @override
  String get sourceAudioDesc =>
      'Сабтҳои қироати Қуръон аз everyayah.com бор карда мешаванд. Ҳуқуқҳо ба қориён ва ношиирон тааллуқ доранд; барнома аудиоро дар бар намегирад ва онро танҳо барои шунидан истифода мебарад.';

  @override
  String get sourceOnlineApiTitle =>
      'Тарҷумаҳои онлайн ва замонбандии калимаҳо (Quran.com)';

  @override
  String get sourceOnlineApiDesc =>
      'Тарҷумаҳои иловагӣ (Saheeh International, тоҷикӣ, ӯзбекӣ, озарбойҷонӣ) ва замонбандии калимаҳои қориён тавассути API-и кушодаи Quran.com / Quran Foundation бор карда ва дар дастгоҳ нигоҳ дошта мешаванд.';

  @override
  String get sourceSpeechTitle => 'Шинохти нутқ (Whisper)';

  @override
  String get sourceSpeechDesc =>
      'Машқгари қироат сабти шуморо ба сервер бо модели OpenAI Whisper (литсензияи MIT) дар Modal мефиристад. Сабт пас аз коркард фавран нест карда мешавад.';

  @override
  String get sectionArabicFont => 'Шрифти арабӣ';

  @override
  String get fontHafs => 'Усмонӣ Ҳафс (Мусҳафи Мадина)';

  @override
  String get fontHafsSmart => 'Ҳафс Smart (барои экран)';

  @override
  String get fontAmiri => 'Amiri Quran (насхи классикӣ)';

  @override
  String get sourceFontKfgqpcTitle => 'Шрифтҳои KFGQPC Ҳафс';

  @override
  String get sourceFontKfgqpcDesc =>
      'Шрифтҳои «KFGQPC HAFS Uthmanic Script» ва «KFGQPC Hafs Smart»-и Маҷмааи Малик Фаҳд барои чопи Қуръон (Мадина). Литсензия истифода, нусхабардорӣ ва паҳнкунии ройгон бе тағйиротро иҷозат медиҳад; матни литсензия дар барнома оварда шудааст.';

  @override
  String get sourceFontSerifTitle => 'Шрифти тарҷума (PT Serif)';

  @override
  String get sourceFontSerifDesc =>
      'Тарҷумаҳо ва тафсир бо шрифти PT Serif-и ширкати ParaType таҳти литсензияи SIL Open Font License чида шудаанд.';

  @override
  String get viewLicenses => 'Литсензияҳои нармафзори кушодаасос';

  @override
  String get skip => 'Гузаштан';

  @override
  String get next => 'Баъдӣ';

  @override
  String get startReading => 'Бисмиллоҳ, оғози хондан';

  @override
  String get reminderTitle => 'Ёдоварӣ ба мӯъминон';

  @override
  String get reminderAyah =>
      '«Ин Китобест муборак, ки бар ту фурӯ фиристодем, то дар оятҳояш тафаккур кунанд ва соҳибони ақл панд гиранд.»';

  @override
  String get reminderRef => 'Сураи 38 «Сод», ояти 29';

  @override
  String get purityStatement =>
      'Танҳо Китоби Аллоҳ. Бе таблиғот ва омилҳои парешонкунанда. Офлайн кор мекунад (ба истиснои санҷиши садоии қироат).';

  @override
  String get readingModesTitle => 'ҲОЛАТҲОИ ХОНДАН';

  @override
  String get readingModesSubtitle => 'Тарзи бароҳати хонданро интихоб кунед';

  @override
  String get flowModeTitle => 'Хондани равон (Flow)';

  @override
  String get flowModeBadge => 'Ҳолати сатр ба сатр';

  @override
  String get flowModeDesc =>
      'Барои хондани ҳаррӯза хеле мувофиқ аст. Худҷунбонӣ ва таҳлили калимавиро дар бар мегирад.';

  @override
  String get mushafModeTitle => 'Мусҳафи классикӣ (604 саҳ.)';

  @override
  String get mushafModeBadge => 'Ҳолати саҳифагӣ';

  @override
  String get mushafModeDesc =>
      'Тарҳбандии саҳифа ба саҳифаи Мусҳафи Мадина. Барои ҳифз беҳтарин аст.';

  @override
  String get featuresTitle => 'ИМКОНИЯТҲО';

  @override
  String get featuresSubtitle => 'Ҳама чиз барои роҳати шумо';

  @override
  String get themesFeatureTitle => '4 мавзӯъ ва филтри шабона';

  @override
  String get themesFeatureBadge => 'Намуд';

  @override
  String get themesFeatureDesc =>
      'Пергамент, Зумуррад, OLED ва мавзӯи Равшан бо ҳифзи чашм дар торикӣ.';

  @override
  String get searchFeatureTitle => 'Ҷустуҷӯи оқилона дар тамоми Китоб';

  @override
  String get searchFeatureBadge => 'Ҷустуҷӯи фаврӣ';

  @override
  String get searchFeatureDesc =>
      'Ҷустуҷӯ бо матни арабӣ, тарҷумаҳо ё рақамҳои оят (масалан, 2:255).';

  @override
  String get khatmGoalTitle => 'Мақсади хондан (Хатм)';

  @override
  String get khatmDaysQuestion =>
      'Дар чанд рӯз мехоҳед тамоми Қуръонро (604 саҳифа) хатм кунед?';

  @override
  String daysCount(int days) {
    return '$days рӯз';
  }

  @override
  String dailyGoalPages(int pages) {
    return 'Мақсад: $pages саҳ. дар як рӯз';
  }

  @override
  String get cancel => 'Бекор кардан';

  @override
  String get startKhatm => 'Оғози Хатм';

  @override
  String khatmPlanTitle(int days) {
    return 'Хатм дар $days рӯз';
  }

  @override
  String get setKhatmGoal => 'Гузоштани мақсад (Хатм)';

  @override
  String get calculateDailyNorm => 'Ҳисоб кардани меъёри ҳаррӯзаи саҳифаҳо';

  @override
  String get editGoal => 'Тағйири мақсад';

  @override
  String get resetGoal => 'Анҷом / пок кардан';

  @override
  String khatmPagesRead(int completed) {
    return 'Хонда шуд: $completed аз 604 саҳ.';
  }

  @override
  String khatmDailyNormRemain(int daily, int remaining) {
    return 'Меъёр: $daily саҳ./рӯз · Боқӣ монд: $remaining рӯз';
  }

  @override
  String bookmarkTitle(int surah, int ayah) {
    return 'Хатбарак: Сураи $surah:$ayah';
  }

  @override
  String get delete => 'Нест кардан';

  @override
  String get folderCollection => 'Ҷузъдон / Маҷмӯа:';

  @override
  String get personalNote => 'Ёддошти шахсӣ (ихтиёрӣ):';

  @override
  String get personalNoteHint => 'Масалан: Ин ҳафта ҳифз кардан...';

  @override
  String get saveChanges => 'Сабти тағйирот';

  @override
  String get addToBookmarks => 'Ба хатбаракҳо илова кардан';

  @override
  String get selectReciter => 'Интихоби қорӣ (Тиловат)';

  @override
  String get playbackSpeed => 'Суръати пахш';

  @override
  String get downloadSurahOffline => 'Зеркашии сура барои хондани офлайн';

  @override
  String get speed => 'Суръат';

  @override
  String get repeatOn => 'Такрори оят фаъол аст';

  @override
  String get repeatOff => 'Такрори оят хомӯш аст';

  @override
  String get closePlayer => 'Пӯшидани плейер';

  @override
  String get prevAyah => 'Ояти гузашта';

  @override
  String get nextAyah => 'Ояти оянда';

  @override
  String ayahNumber(int number) {
    return 'Ояти $number';
  }

  @override
  String get hifzTrainerTitle => 'Санҷиши қироат (Ҳифз)';

  @override
  String hifzAyahInfo(int surahId, String surahName, int ayahNum) {
    return 'Сураи $surahId. $surahName · Ояти $ayahNum';
  }

  @override
  String get tajweedRules => 'Қоидаҳои Таҷвиди ин оят';

  @override
  String get byMemory => 'Аз ёд';

  @override
  String get withText => 'Бо матн';

  @override
  String get continuousMode => 'Хондани пайваста';

  @override
  String get oneAyahMode => 'Як оят';

  @override
  String get continuousModeDesc => 'Гузариши худкор ба ояти оянда';

  @override
  String get listenToAyah => 'Гӯш кардани оят';

  @override
  String get perfectReading => 'Мошоаллоҳ! Оят дуруст хонда шуд';

  @override
  String readingAccuracy(int accuracy, int correct, int total) {
    return 'Дурустӣ: $accuracy% ($correct/$total калима)';
  }

  @override
  String aiListening(String text) {
    return 'Мешунавам: \"$text\"';
  }

  @override
  String get startOver => 'Аз нав оғоз кардан';

  @override
  String get stopListening => 'Қатъ кардан';

  @override
  String get startListening => 'Хондан';

  @override
  String get readingInstructions =>
      'Микрофонро пахш намуда, хондани оятро оғоз кунед';

  @override
  String get listeningInProgress => 'Гӯш карда истодаам...';

  @override
  String get processingAudio => 'Коркард...';

  @override
  String get micError => 'Хатои микрофон. Розигиро тафтиш кунед.';

  @override
  String get recitationDisclaimerTitle => 'Огоҳии муҳим';

  @override
  String get recitationDisclaimerBody =>
      'Санҷиши худкори қироат метавонад хато кунад ва дақиқии 100%-ро кафолат намедиҳад. Онро танҳо ҳамчун воситаи ёрирасон истифода баред. Он омӯзиш ва санҷиши қироатро назди шайх, қорӣ ё омӯзгори соҳибихтисоси таҷвид иваз намекунад. Талаффузро танҳо аз рӯи натиҷаи барнома наомӯзед. Барои шинохтан сабти овозии шумо ба сервери беруна фиристода мешавад.';

  @override
  String get recitationDisclaimerAccept => 'Фаҳмидам, идома додан';
}
