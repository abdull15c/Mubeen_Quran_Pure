// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mubeen Quran Pure';

  @override
  String get appName => 'MUBEEN';

  @override
  String get appSubtitle => 'QURAN PURE';

  @override
  String get tabRead => 'Read';

  @override
  String get tabNavigation => 'Navigate';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabSettings => 'Settings';

  @override
  String get settingsTitle => 'Reading settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionTranslation => 'Translation';

  @override
  String get sectionTextSize => 'Text size';

  @override
  String get sectionHandsFreeReading => 'Hands-free reading';

  @override
  String get eyeCareFilter => 'Eye care (Night filter)';

  @override
  String get showTranslation => 'Show translation';

  @override
  String get showTranslationSubtitle => 'Arabic text always remains primary';

  @override
  String get onlineTranslation => 'Online translation';

  @override
  String get downloading => 'Downloading...';

  @override
  String get arabicTextSize => 'Arabic text';

  @override
  String get translationTextSize => 'Translation';

  @override
  String get autoScrollSpeed => 'Auto-scroll speed';

  @override
  String autoScrollSpeedValue(String value) {
    return '$value lines/min';
  }

  @override
  String get autoScrollHint =>
      'Start auto-scroll with the button in vertical reading mode. One tap pauses it.';

  @override
  String get guideTitle => 'Guide & tips';

  @override
  String get guideSubtitle => 'Gestures, auto-scroll, tafsir and search';

  @override
  String get onboardingTitle => 'About the app';

  @override
  String get onboardingSubtitle =>
      'Open the intro screen with a reminder verse';

  @override
  String get sourcesTitle => 'Sources & attribution';

  @override
  String get sourcesSubtitle => 'Text sources and licenses';

  @override
  String get privacyNote =>
      'Only the Quran. No ads, registration, feed, reading analytics or unrelated sections. Settings and bookmarks are stored on device.';

  @override
  String get themeParchment => 'Parchment';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeEmerald => 'Emerald';

  @override
  String get themeLight => 'Light';

  @override
  String themeLabel(String name) {
    return 'Theme $name';
  }

  @override
  String get jumpToAyah => 'Jump to ayah';

  @override
  String get verticalReading => 'Vertical reading';

  @override
  String get quranPages => 'Quran pages';

  @override
  String surahInfoLabel(int id, String name, int count) {
    return 'Surah $id. $name ($count ayahs)';
  }

  @override
  String get meccan => 'Meccan';

  @override
  String get medinan => 'Medinan';

  @override
  String get listenSurah => 'Listen to surah';

  @override
  String get pause => 'Pause';

  @override
  String get listenAyah => 'Listen to ayah';

  @override
  String get copyAyah => 'Copy ayah';

  @override
  String get wordAnalysis => 'Word-by-word analysis';

  @override
  String get tafsirSaadi => 'Tafsir as-Sa\'di';

  @override
  String get recitationCheck => 'Check recitation (Hifz)';

  @override
  String get addBookmark => 'Add bookmark (long press to choose folder)';

  @override
  String get removeBookmark => 'Remove bookmark (long press to choose folder)';

  @override
  String ayahCopied(int surah, int ayah) {
    return 'Ayah $surah:$ayah copied';
  }

  @override
  String get copyFailed => 'Failed to copy ayah.';

  @override
  String quranReference(int surah, int ayah) {
    return 'Quran ($surah:$ayah)';
  }

  @override
  String tafsirTitle(int surah, int ayah) {
    return 'Tafsir as-Sa\'di · $surah:$ayah';
  }

  @override
  String get tafsirSubtitle =>
      'Commentary on the Holy Quran by Sheikh Abdur-Rahman as-Sa\'di';

  @override
  String get tafsirNotFound => 'Tafsir not found for this ayah.';

  @override
  String wordAnalysisTitle(int surah, int ayah) {
    return 'Word analysis · $surah:$ayah';
  }

  @override
  String get wordAnalysisSubtitle => 'Tap a word for detailed grammar and root';

  @override
  String get wordAnalysisNotFound => 'Word analysis not found.';

  @override
  String get wordTranslation => 'Translation';

  @override
  String get wordRoot => 'Root';

  @override
  String get wordLemma => 'Lemma';

  @override
  String get wordPartOfSpeech => 'Part of speech';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get close => 'Close';

  @override
  String get sajda => 'Sajda';

  @override
  String juz(int number) {
    return 'Juz $number';
  }

  @override
  String get autoScroll => 'Auto-scroll';

  @override
  String get slower => 'Slower';

  @override
  String get faster => 'Faster';

  @override
  String linesPerMinute(int value) {
    return '$value l/m';
  }

  @override
  String get readerTipTitle => 'Reading tip';

  @override
  String get readerTipBody =>
      'Tap the icons next to each ayah for word analysis, tafsir as-Sa\'di and bookmarks.';

  @override
  String get understood => 'Got it';

  @override
  String get failedToOpenSurah => 'Failed to open surah.';

  @override
  String get noAyahsInSurah => 'No ayahs in this surah.';

  @override
  String failedToLoadPage(int page) {
    return 'Failed to load page $page.';
  }

  @override
  String noAyahsOnPage(int page) {
    return 'No ayahs on page $page.';
  }

  @override
  String get retry => 'Retry';

  @override
  String get failedToLoadData => 'Failed to load data.';

  @override
  String pageOfTotal(int page) {
    return 'Page $page of 604';
  }

  @override
  String get textLayout => 'Text layout';

  @override
  String get failedToOpenQuran => 'Failed to open the Quran';

  @override
  String get checkStorageAndRestart =>
      'Check available storage and restart the app.';

  @override
  String get navigationSurahs => 'Surahs';

  @override
  String get navigationJuz => 'Juz';

  @override
  String get navigationHizb => 'Hizb';

  @override
  String get navigationBookmarks => 'Bookmarks';

  @override
  String get searchInQuran => 'Search in the Quran';

  @override
  String get searchHint => 'Search by text, translation or ayah number';

  @override
  String get noResults => 'Nothing found';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearAll => 'Clear all';

  @override
  String get uiLanguage => 'Interface language';

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
  String get aboutTitle => 'Sources & attribution';

  @override
  String get aboutAppDescription =>
      'Free app for reading the Holy Quran without ads or data collection.';

  @override
  String get aboutDataSources => 'DATA SOURCES';

  @override
  String get sourceUthmaniTitle => 'Arabic Quran Text (Uthmani)';

  @override
  String get sourceUthmaniDesc =>
      'Provided by Tanzil.net under Tanzil Quran License. Provides verified and authentic text of the Holy Quran.';

  @override
  String get sourceKulievTitle => 'Translation (Elmir Kuliev)';

  @override
  String get sourceKulievDesc =>
      'Freely distributed for non-commercial educational use.';

  @override
  String get sourceAbuAdelTitle => 'Translation (Abu Adel)';

  @override
  String get sourceAbuAdelDesc =>
      'Freely distributed for non-commercial educational use.';

  @override
  String get sourceTafsirTitle => 'Tafsir (Abdur-Rahman as-Sa\'di)';

  @override
  String get sourceTafsirDesc =>
      'Commentary on the Holy Quran. Freely distributed for non-commercial purposes.';

  @override
  String get sourceFontTitle => 'Font (Amiri Quran)';

  @override
  String get sourceFontDesc =>
      'Open Arabic font Amiri under SIL Open Font License (OFL).';

  @override
  String get sourceMorphologyTitle => 'Word-by-Word Morphology';

  @override
  String get sourceMorphologyDesc =>
      'Arabic grammar and word-by-word data: Quranic Arabic Corpus (corpus.quran.com, by Kais Dukes) under GNU GPL.';

  @override
  String get sourceAudioTitle => 'Reciter audio (EveryAyah)';

  @override
  String get sourceAudioDesc =>
      'Quran recitations are streamed from everyayah.com. Rights belong to the reciters and publishers; the app bundles no audio and uses it for listening only.';

  @override
  String get sourceOnlineApiTitle =>
      'Online translations and word timings (Quran.com)';

  @override
  String get sourceOnlineApiDesc =>
      'Additional translations (Saheeh International, Tajik, Uzbek, Azerbaijani) and word-level reciter timings are fetched through the open Quran.com / Quran Foundation API and cached on the device.';

  @override
  String get sourceSpeechTitle => 'Speech recognition (Whisper)';

  @override
  String get sourceSpeechDesc =>
      'The recitation trainer sends your recording to a server running OpenAI Whisper (MIT license) hosted on Modal. The recording is deleted right after processing.';

  @override
  String get viewLicenses => 'Open Source Licenses';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get startReading => 'Bismillah, start reading';

  @override
  String get reminderTitle => 'Reminder for believers';

  @override
  String get reminderAyah =>
      '«This is a blessed Book which We have revealed to you, that they might reflect upon its verses and that those of understanding would be reminded.»';

  @override
  String get reminderRef => 'Surah 38 «Sad», ayah 29';

  @override
  String get purityStatement =>
      'Only the Book of Allah. No ads, feeds, tracking or distractions. Works offline (except for voice recitation checking).';

  @override
  String get readingModesTitle => 'READING MODES';

  @override
  String get readingModesSubtitle => 'Choose your preferred reading style';

  @override
  String get flowModeTitle => 'Continuous Scroll (Flow)';

  @override
  String get flowModeBadge => 'Continuous mode';

  @override
  String get flowModeDesc =>
      'Convenient for daily reflective reading. Includes hands-free auto-scroll, word-by-word roots and tafsir as-Sa\'di.';

  @override
  String get mushafModeTitle => 'Classic Mushaf (604 pages)';

  @override
  String get mushafModeBadge => 'Page mode';

  @override
  String get mushafModeDesc =>
      'Traditional page-by-page Medina Mushaf layout. Ideal for memorization (Hifz) and revision.';

  @override
  String get featuresTitle => 'FEATURES';

  @override
  String get featuresSubtitle => 'Designed for your comfort';

  @override
  String get themesFeatureTitle => '4 noble themes & night filter';

  @override
  String get themesFeatureBadge => 'Appearance';

  @override
  String get themesFeatureDesc =>
      'Parchment, Emerald, OLED black and Light theme with gentle amber eye protection.';

  @override
  String get searchFeatureTitle => 'Smart search across the Book';

  @override
  String get searchFeatureBadge => 'Instant search';

  @override
  String get searchFeatureDesc =>
      'Search Arabic text (with or without harakat), translations, surah names, or exact references (e.g., 2:255).';

  @override
  String get khatmGoalTitle => 'Reading goal (Khatm)';

  @override
  String get khatmDaysQuestion =>
      'In how many days do you plan to complete the entire Quran (604 pages)?';

  @override
  String daysCount(int days) {
    return '$days days';
  }

  @override
  String dailyGoalPages(int pages) {
    return 'Goal: $pages pages/day';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get startKhatm => 'Start Khatm';

  @override
  String khatmPlanTitle(int days) {
    return 'Khatm in $days days';
  }

  @override
  String get setKhatmGoal => 'Set reading goal (Khatm)';

  @override
  String get calculateDailyNorm => 'Calculate daily page target';

  @override
  String get editGoal => 'Edit goal';

  @override
  String get resetGoal => 'Finish / reset';

  @override
  String khatmPagesRead(int completed) {
    return 'Read $completed of 604 pages';
  }

  @override
  String khatmDailyNormRemain(int daily, int remaining) {
    return 'Target: $daily pages/day · Remaining: $remaining days';
  }

  @override
  String bookmarkTitle(int surah, int ayah) {
    return 'Bookmark: Surah $surah:$ayah';
  }

  @override
  String get delete => 'Delete';

  @override
  String get folderCollection => 'Folder / Collection:';

  @override
  String get personalNote => 'Personal note (optional):';

  @override
  String get personalNoteHint => 'e.g., Memorize this week...';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get addToBookmarks => 'Add to bookmarks';

  @override
  String get selectReciter => 'Select reciter (Tilawa)';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get downloadSurahOffline => 'Download surah for offline reading';

  @override
  String get speed => 'Speed';

  @override
  String get repeatOn => 'Ayah repeat is ON';

  @override
  String get repeatOff => 'Ayah repeat is OFF';

  @override
  String get closePlayer => 'Close player';

  @override
  String get prevAyah => 'Previous ayah';

  @override
  String get nextAyah => 'Next ayah';

  @override
  String ayahNumber(int number) {
    return 'Ayah $number';
  }

  @override
  String get hifzTrainerTitle => 'Recitation Check (Hifz)';

  @override
  String hifzAyahInfo(int surahId, String surahName, int ayahNum) {
    return 'Surah $surahId. $surahName · Ayah $ayahNum';
  }

  @override
  String get tajweedRules => 'Tajweed rules of this ayah';

  @override
  String get byMemory => 'By memory';

  @override
  String get withText => 'With text';

  @override
  String get continuousMode => 'Continuous';

  @override
  String get oneAyahMode => 'One ayah';

  @override
  String get continuousModeDesc => 'Auto-advance to the next ayah';

  @override
  String get listenToAyah => 'Listen to ayah';

  @override
  String get perfectReading => 'MashaAllah! Perfectly read';

  @override
  String readingAccuracy(int accuracy, int correct, int total) {
    return 'Accuracy: $accuracy% ($correct/$total words)';
  }

  @override
  String aiListening(String text) {
    return 'Hearing: \"$text\"';
  }

  @override
  String get startOver => 'Start over';

  @override
  String get stopListening => 'Stop';

  @override
  String get startListening => 'Record';

  @override
  String get readingInstructions => 'Tap the mic and start reciting in Arabic';

  @override
  String get listeningInProgress => 'Listening...';

  @override
  String get processingAudio => 'Processing...';

  @override
  String get micError => 'Microphone error. Ensure permissions are granted.';

  @override
  String get recitationDisclaimerTitle => 'Important notice';

  @override
  String get recitationDisclaimerBody =>
      'The automated recitation check can make mistakes and is not guaranteed to be 100% accurate. Use it only as an assistive tool. It does not replace learning or having your recitation checked by a qualified sheikh, qari, or tajweed teacher. Do not learn pronunciation based only on the app\'s result. Your audio recording will be sent to an external server for recognition.';

  @override
  String get recitationDisclaimerAccept => 'I understand, continue';
}
