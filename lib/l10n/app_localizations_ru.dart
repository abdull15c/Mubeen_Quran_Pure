// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Mubeen Quran Pure';

  @override
  String get appName => 'MUBEEN';

  @override
  String get appSubtitle => 'QURAN PURE';

  @override
  String get tabRead => 'Читать';

  @override
  String get tabNavigation => 'Навигация';

  @override
  String get tabSearch => 'Поиск';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get settingsTitle => 'Настройки чтения';

  @override
  String get sectionAppearance => 'Оформление';

  @override
  String get sectionTranslation => 'Перевод смыслов';

  @override
  String get sectionTextSize => 'Размер текста';

  @override
  String get sectionHandsFreeReading => 'Чтение без рук';

  @override
  String get eyeCareFilter => 'Защита глаз (Ночной фильтр)';

  @override
  String get showTranslation => 'Показывать перевод';

  @override
  String get showTranslationSubtitle =>
      'Арабский текст всегда остаётся главным';

  @override
  String get onlineTranslation => 'Онлайн-перевод';

  @override
  String get downloading => 'Загрузка...';

  @override
  String get arabicTextSize => 'Арабский текст';

  @override
  String get translationTextSize => 'Русский перевод';

  @override
  String get autoScrollSpeed => 'Скорость автопрокрутки';

  @override
  String autoScrollSpeedValue(String value) {
    return '$value строк/мин';
  }

  @override
  String get autoScrollHint =>
      'Запустите автопрокрутку кнопкой в режиме вертикального чтения. Одно касание ставит её на паузу.';

  @override
  String get guideTitle => 'Руководство и подсказки';

  @override
  String get guideSubtitle => 'Жесты, автопрокрутка, тафсир и поиск';

  @override
  String get onboardingTitle => 'О приложении и напоминание';

  @override
  String get onboardingSubtitle => 'Открыть вводный экран с аятом-назиданием';

  @override
  String get sourcesTitle => 'Источники и атрибуция';

  @override
  String get sourcesSubtitle => 'Информация о текстах и лицензиях';

  @override
  String get privacyNote =>
      'Только Коран. Без рекламы, регистрации, ленты, аналитики чтения и посторонних разделов. Настройки и закладки хранятся на устройстве.';

  @override
  String get themeParchment => 'Пергамент';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeEmerald => 'Изумруд';

  @override
  String get themeLight => 'Светлая';

  @override
  String themeLabel(String name) {
    return 'Тема $name';
  }

  @override
  String get jumpToAyah => 'Перейти к аяту';

  @override
  String get verticalReading => 'Вертикальное чтение';

  @override
  String get quranPages => 'Страницы Корана';

  @override
  String surahInfoLabel(int id, String name, int count) {
    return 'Сура $id. $name ($count аятов)';
  }

  @override
  String get meccan => 'Мекканская';

  @override
  String get medinan => 'Мединская';

  @override
  String get listenSurah => 'Слушать суру';

  @override
  String get pause => 'Пауза';

  @override
  String get listenAyah => 'Слушать аят';

  @override
  String get copyAyah => 'Скопировать аят';

  @override
  String get wordAnalysis => 'Пословный разбор';

  @override
  String get tafsirSaadi => 'Тафсир ас-Саади';

  @override
  String get recitationCheck => 'Проверить чтение (Хифз)';

  @override
  String get addBookmark => 'Добавить закладку (зажмите для выбора папки)';

  @override
  String get removeBookmark => 'Удалить закладку (зажмите для выбора папки)';

  @override
  String ayahCopied(int surah, int ayah) {
    return 'Аят $surah:$ayah скопирован';
  }

  @override
  String get copyFailed => 'Не удалось скопировать аят.';

  @override
  String quranReference(int surah, int ayah) {
    return 'Коран ($surah:$ayah)';
  }

  @override
  String tafsirTitle(int surah, int ayah) {
    return 'Тафсир ас-Саади · $surah:$ayah';
  }

  @override
  String get tafsirSubtitle =>
      'Толкование Священного Корана шейха Абдур-Рахмана ас-Саади';

  @override
  String get tafsirNotFound => 'Тафсир для этого аята не найден.';

  @override
  String wordAnalysisTitle(int surah, int ayah) {
    return 'Пословный разбор · $surah:$ayah';
  }

  @override
  String get wordAnalysisSubtitle =>
      'Нажмите на слово для подробной грамматики и корня';

  @override
  String get wordAnalysisNotFound => 'Пословный разбор не найден.';

  @override
  String get wordTranslation => 'Перевод';

  @override
  String get wordRoot => 'Корень';

  @override
  String get wordLemma => 'Лемма';

  @override
  String get wordPartOfSpeech => 'Часть речи';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get close => 'Закрыть';

  @override
  String get sajda => 'Сажда';

  @override
  String juz(int number) {
    return 'Джуз $number';
  }

  @override
  String get autoScroll => 'Автопрокрутка';

  @override
  String get slower => 'Медленнее';

  @override
  String get faster => 'Быстрее';

  @override
  String linesPerMinute(int value) {
    return '$value стр/м';
  }

  @override
  String get readerTipTitle => 'Подсказка для чтения';

  @override
  String get readerTipBody =>
      'Нажимайте иконки возле каждого аята для пословного разбора, тафсира ас-Саади и закладок.';

  @override
  String get understood => 'Понятно';

  @override
  String get failedToOpenSurah => 'Не удалось открыть суру.';

  @override
  String get noAyahsInSurah => 'В этой суре нет аятов.';

  @override
  String failedToLoadPage(int page) {
    return 'Не удалось загрузить страницу $page.';
  }

  @override
  String noAyahsOnPage(int page) {
    return 'На странице $page нет аятов.';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get failedToLoadData => 'Не удалось загрузить данные.';

  @override
  String pageOfTotal(int page) {
    return 'Страница $page из 604';
  }

  @override
  String get textLayout => 'Текстовая вёрстка';

  @override
  String get failedToOpenQuran => 'Не удалось открыть Коран';

  @override
  String get checkStorageAndRestart =>
      'Проверьте свободное место на устройстве и перезапустите приложение.';

  @override
  String get navigationSurahs => 'Суры';

  @override
  String get navigationJuz => 'Джузы';

  @override
  String get navigationHizb => 'Хизбы';

  @override
  String get navigationBookmarks => 'Закладки';

  @override
  String get searchInQuran => 'Поиск в Коране';

  @override
  String get searchHint => 'Поиск по тексту, переводу или номеру аята';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String get recentSearches => 'Недавние запросы';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get uiLanguage => 'Язык интерфейса';

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
  String get aboutTitle => 'Источники и атрибуция';

  @override
  String get aboutAppDescription =>
      'Бесплатное приложение для чтения Священного Корана без рекламы и сбора данных.';

  @override
  String get aboutDataSources => 'ИСТОЧНИКИ ДАННЫХ';

  @override
  String get sourceUthmaniTitle => 'Арабский текст Корана (Uthmani)';

  @override
  String get sourceUthmaniDesc =>
      'Предоставлен проектом Tanzil.net. Используется на условиях лицензии Tanzil Quran License. Проект Tanzil предоставляет выверенный и аутентичный текст Священного Корана.';

  @override
  String get sourceKulievTitle => 'Перевод смыслов (Эльмир Кулиев)';

  @override
  String get sourceKulievDesc =>
      'Распространяется свободно. Текст перевода смыслов предоставлен для некоммерческого использования и бесплатного распространения.';

  @override
  String get sourceAbuAdelTitle => 'Перевод смыслов (Абу Адель)';

  @override
  String get sourceAbuAdelDesc =>
      'Распространяется свободно. Текст перевода смыслов предоставлен для некоммерческого использования и бесплатного распространения.';

  @override
  String get sourceTafsirTitle => 'Тафсир (Абдур-Рахман ас-Саади)';

  @override
  String get sourceTafsirDesc =>
      'Толкование Священного Корана. Текст распространяется свободно в образовательных и некоммерческих целях.';

  @override
  String get sourceFontTitle => 'Шрифт (Amiri Quran)';

  @override
  String get sourceFontDesc =>
      'Используется открытый арабский шрифт Amiri под лицензией SIL Open Font License (OFL).';

  @override
  String get sourceMorphologyTitle => 'Пословный разбор и морфология';

  @override
  String get sourceMorphologyDesc =>
      'Арабская грамматика и пословные значения: Quranic Arabic Corpus (corpus.quran.com, автор Kais Dukes) под лицензией GNU GPL.';

  @override
  String get sourceAudioTitle => 'Аудио чтецов (EveryAyah)';

  @override
  String get sourceAudioDesc =>
      'Записи чтения Корана загружаются по сети с everyayah.com. Права на записи принадлежат чтецам и издателям; приложение не содержит аудио в комплекте и использует его только для прослушивания.';

  @override
  String get sourceOnlineApiTitle =>
      'Онлайн-переводы и тайминги слов (Quran.com)';

  @override
  String get sourceOnlineApiDesc =>
      'Дополнительные переводы (Saheeh International, таджикский, узбекский, азербайджанский) и пословные тайминги чтецов загружаются через открытый API Quran.com / Quran Foundation и кэшируются на устройстве.';

  @override
  String get sourceSpeechTitle => 'Распознавание речи (Whisper)';

  @override
  String get sourceSpeechDesc =>
      'Тренажёр чтения отправляет запись на сервер с моделью OpenAI Whisper (лицензия MIT), размещённый на Modal. Запись удаляется сразу после обработки.';

  @override
  String get sectionArabicFont => 'Арабский шрифт';

  @override
  String get fontHafs => 'Усмани Хафс (мединский мусхаф)';

  @override
  String get fontHafsSmart => 'Хафс Smart (для экрана)';

  @override
  String get fontAmiri => 'Amiri Quran (классический насх)';

  @override
  String get sourceFontKfgqpcTitle => 'Шрифты KFGQPC Хафс';

  @override
  String get sourceFontKfgqpcDesc =>
      'Шрифты «KFGQPC HAFS Uthmanic Script» и «KFGQPC Hafs Smart» Комплекса имени Короля Фахда по изданию Корана (Медина). Лицензия разрешает бесплатное использование, копирование и распространение без изменений; текст лицензии включён в приложение.';

  @override
  String get sourceFontSerifTitle => 'Шрифт перевода (PT Serif)';

  @override
  String get sourceFontSerifDesc =>
      'Переводы и тафсир набраны шрифтом PT Serif компании ParaType под лицензией SIL Open Font License.';

  @override
  String get viewLicenses => 'Лицензии открытого ПО';

  @override
  String get skip => 'Пропустить';

  @override
  String get next => 'Далее';

  @override
  String get startReading => 'Бисмилля, начать чтение';

  @override
  String get reminderTitle => 'Напоминание верующим';

  @override
  String get reminderAyah =>
      '«Это — благословенное Писание, которое Мы ниспослали тебе, дабы они размышляли над его аятами и дабы обладающие разумом внимали назиданию.»';

  @override
  String get reminderRef => 'Сура 38 «Сад», аят 29';

  @override
  String get purityStatement =>
      'Только Книга Аллаха. Без рекламы, лент, сбора данных и отвлекающих факторов. Работает офлайн (кроме голосовой проверки чтения).';

  @override
  String get readingModesTitle => 'РЕЖИМЫ ЧТЕНИЯ';

  @override
  String get readingModesSubtitle => 'Выберите привычный способ чтения';

  @override
  String get flowModeTitle => 'Плавный свиток (Flow)';

  @override
  String get flowModeBadge => 'Построчный режим';

  @override
  String get flowModeDesc =>
      'Удобно для ежедневного вдумчивого чтения. Включает плавную автопрокрутку без рук, пословный разбор арабских корней и тафсир ас-Саади.';

  @override
  String get mushafModeTitle => 'Классический Мусхаф (604 стр.)';

  @override
  String get mushafModeBadge => 'Страничный режим';

  @override
  String get mushafModeDesc =>
      'Традиционная вёрстка страницы в страницу (Мединский мусхаф). Идеально подходит для заучивания (хифз) и повторения.';

  @override
  String get featuresTitle => 'ВОЗМОЖНОСТИ';

  @override
  String get featuresSubtitle => 'Всё для вашего удобства';

  @override
  String get themesFeatureTitle => '4 благородные темы и ночной фильтр';

  @override
  String get themesFeatureBadge => 'Оформление';

  @override
  String get themesFeatureDesc =>
      'Пергамент, Изумруд, глубокий OLED и Светлая тема с бережным янтарным фильтром для защиты глаз в темноте.';

  @override
  String get searchFeatureTitle => 'Умный поиск по всей Книге';

  @override
  String get searchFeatureBadge => 'Мгновенный поиск';

  @override
  String get searchFeatureDesc =>
      'Ищите по арабскому тексту (с огласовками и без), переводам, названиям сур или точным ссылкам (например, 2:255).';

  @override
  String get khatmGoalTitle => 'Цель чтения (Хатм)';

  @override
  String get khatmDaysQuestion =>
      'За сколько дней вы планируете прочитать весь Коран (604 страницы)?';

  @override
  String daysCount(int days) {
    return '$days дней';
  }

  @override
  String dailyGoalPages(int pages) {
    return 'Цель: $pages стр. в день';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get startKhatm => 'Начать Хатм';

  @override
  String khatmPlanTitle(int days) {
    return 'Хатм за $days дней';
  }

  @override
  String get setKhatmGoal => 'Поставить цель чтения (Хатм)';

  @override
  String get calculateDailyNorm => 'Рассчитайте ежедневную норму страниц';

  @override
  String get editGoal => 'Изменить цель';

  @override
  String get resetGoal => 'Завершить / сбросить';

  @override
  String khatmPagesRead(int completed) {
    return 'Прочитано $completed из 604 стр.';
  }

  @override
  String khatmDailyNormRemain(int daily, int remaining) {
    return 'Норма: $daily стр./день · Осталось: $remaining дн.';
  }

  @override
  String bookmarkTitle(int surah, int ayah) {
    return 'Закладка: Сура $surah:$ayah';
  }

  @override
  String get delete => 'Удалить';

  @override
  String get folderCollection => 'Папка / Коллекция:';

  @override
  String get personalNote => 'Личная заметка (необязательно):';

  @override
  String get personalNoteHint => 'Например: Заучить на этой неделе...';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get addToBookmarks => 'Добавить в закладки';

  @override
  String get selectReciter => 'Выберите чтеца (Тилява)';

  @override
  String get playbackSpeed => 'Скорость воспроизведения';

  @override
  String get downloadSurahOffline => 'Скачать суру для офлайн чтения';

  @override
  String get speed => 'Скорость';

  @override
  String get repeatOn => 'Повтор аята включен';

  @override
  String get repeatOff => 'Повтор аята выключен';

  @override
  String get closePlayer => 'Закрыть плеер';

  @override
  String get prevAyah => 'Предыдущий аят';

  @override
  String get nextAyah => 'Следующий аят';

  @override
  String ayahNumber(int number) {
    return 'Аят $number';
  }

  @override
  String get hifzTrainerTitle => 'Проверка чтения (Хифз)';

  @override
  String hifzAyahInfo(int surahId, String surahName, int ayahNum) {
    return 'Сура $surahId. $surahName · Аят $ayahNum';
  }

  @override
  String get tajweedRules => 'Правила Таджвида этого аята';

  @override
  String get byMemory => 'По памяти';

  @override
  String get withText => 'С текстом';

  @override
  String get continuousMode => 'Сплошное чтение';

  @override
  String get oneAyahMode => 'Один аят';

  @override
  String get continuousModeDesc => 'Авто-переход к следующему аяту';

  @override
  String get listenToAyah => 'Послушать аят';

  @override
  String get perfectReading => 'МашаАллах! Аят прочитан';

  @override
  String readingAccuracy(int accuracy, int correct, int total) {
    return 'Точность: $accuracy% ($correct/$total слов)';
  }

  @override
  String aiListening(String text) {
    return 'Слышу: \"$text\"';
  }

  @override
  String get startOver => 'Начать заново';

  @override
  String get stopListening => 'Остановить';

  @override
  String get startListening => 'Читать';

  @override
  String get readingInstructions =>
      'Нажмите на микрофон и начните читать аят на арабском';

  @override
  String get listeningInProgress => 'Слушаю вас...';

  @override
  String get processingAudio => 'Обработка...';

  @override
  String get micError => 'Ошибка микрофона. Убедитесь, что дано разрешение.';

  @override
  String get recitationDisclaimerTitle => 'Важное предупреждение';

  @override
  String get recitationDisclaimerBody =>
      'Автоматическая проверка чтения может ошибаться и не гарантирует 100% точность. Используйте её только как вспомогательный инструмент. Она не заменяет обучение и проверку чтения у квалифицированного шейха, кари или преподавателя таджвида. Не изучайте произношение, опираясь только на результат приложения. Для распознавания ваша аудиозапись будет отправлена на внешний сервер.';

  @override
  String get recitationDisclaimerAccept => 'Понимаю, продолжить';
}
