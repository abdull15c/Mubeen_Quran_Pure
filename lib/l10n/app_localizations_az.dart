// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get appTitle => 'Mubeen Quran';

  @override
  String get appName => 'MUBEEN';

  @override
  String get appSubtitle => 'QURAN';

  @override
  String get tabRead => 'Oxu';

  @override
  String get tabNavigation => 'Naviqasiya';

  @override
  String get tabSearch => 'Axtar';

  @override
  String get tabSettings => 'Parametrlər';

  @override
  String get settingsTitle => 'Oxu parametrləri';

  @override
  String get sectionAppearance => 'Görünüş';

  @override
  String get sectionTranslation => 'Tərcümə';

  @override
  String get sectionTextSize => 'Mətn ölçüsü';

  @override
  String get sectionHandsFreeReading => 'Avtomatik oxu';

  @override
  String get eyeCareFilter => 'Göz qoruması (Gecə filtri)';

  @override
  String get showTranslation => 'Tərcüməni göstər';

  @override
  String get showTranslationSubtitle => 'Ərəb mətni həmişə əsas olaraq qalır';

  @override
  String get onlineTranslation => 'Onlayn tərcümə';

  @override
  String get downloading => 'Yüklənir...';

  @override
  String get arabicTextSize => 'Ərəb mətni';

  @override
  String get translationTextSize => 'Tərcümə';

  @override
  String get autoScrollSpeed => 'Avto-sürüşdürmə sürəti';

  @override
  String autoScrollSpeedValue(String value) {
    return '$value sətir/dəq';
  }

  @override
  String get autoScrollHint =>
      'Şaquli oxu rejimində düymə ilə avto-sürüşdürməni başladın. Bir toxunuş dayandırır.';

  @override
  String get guideTitle => 'Bələdçi və məsləhətlər';

  @override
  String get guideSubtitle => 'Jestlər, avto-sürüşdürmə, təfsir və axtarış';

  @override
  String get onboardingTitle => 'Tətbiq haqqında';

  @override
  String get onboardingSubtitle => 'Xatırlatma ayəsi ilə giriş ekranını açın';

  @override
  String get sourcesTitle => 'Mənbələr və atribusiya';

  @override
  String get sourcesSubtitle => 'Mətnlər və lisenziyalar haqqında məlumat';

  @override
  String get privacyNote =>
      'Yalnız Quran. Reklam, qeydiyyat, lent, oxu analitikası və kənar bölmələr yoxdur. Parametrlər və əlfəcinlər cihazda saxlanılır.';

  @override
  String get themeParchment => 'Perqament';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeEmerald => 'Zümrüd';

  @override
  String get themeLight => 'İşıqlı';

  @override
  String themeLabel(String name) {
    return 'Mövzu $name';
  }

  @override
  String get jumpToAyah => 'Ayəyə keç';

  @override
  String get verticalReading => 'Şaquli oxu';

  @override
  String get quranPages => 'Quran səhifələri';

  @override
  String surahInfoLabel(int id, String name, int count) {
    return 'Surə $id. $name ($count ayə)';
  }

  @override
  String get meccan => 'Məkkə';

  @override
  String get medinan => 'Mədinə';

  @override
  String get listenSurah => 'Surəni dinlə';

  @override
  String get pause => 'Pauza';

  @override
  String get listenAyah => 'Ayəni dinlə';

  @override
  String get copyAyah => 'Ayəni kopyala';

  @override
  String get wordAnalysis => 'Sözbəsöz təhlil';

  @override
  String get tafsirSaadi => 'Təfsir əs-Sadi';

  @override
  String get recitationCheck => 'Qiraəti yoxla (Hifz)';

  @override
  String get addBookmark => 'Əlfəcin əlavə et';

  @override
  String get removeBookmark => 'Əlfəcini sil';

  @override
  String ayahCopied(int surah, int ayah) {
    return 'Ayə $surah:$ayah kopyalandı';
  }

  @override
  String get copyFailed => 'Ayəni kopyalamaq mümkün olmadı.';

  @override
  String quranReference(int surah, int ayah) {
    return 'Quran ($surah:$ayah)';
  }

  @override
  String tafsirTitle(int surah, int ayah) {
    return 'Təfsir əs-Sadi · $surah:$ayah';
  }

  @override
  String get tafsirSubtitle =>
      'Şeyx Abdur-Rəhman əs-Sadinin Qurani-Kərim təfsiri';

  @override
  String get tafsirNotFound => 'Bu ayə üçün təfsir tapılmadı.';

  @override
  String wordAnalysisTitle(int surah, int ayah) {
    return 'Söz təhlili · $surah:$ayah';
  }

  @override
  String get wordAnalysisSubtitle =>
      'Ətraflı qrammatika və kök üçün sözə toxunun';

  @override
  String get wordAnalysisNotFound => 'Söz təhlili tapılmadı.';

  @override
  String get wordTranslation => 'Tərcümə';

  @override
  String get wordRoot => 'Kök';

  @override
  String get wordLemma => 'Lemma';

  @override
  String get wordPartOfSpeech => 'Nitq hissəsi';

  @override
  String get notSpecified => 'Göstərilməyib';

  @override
  String get close => 'Bağla';

  @override
  String get sajda => 'Səcdə';

  @override
  String juz(int number) {
    return 'Cüz $number';
  }

  @override
  String get autoScroll => 'Avto-sürüşdürmə';

  @override
  String get slower => 'Yavaş';

  @override
  String get faster => 'Sürətli';

  @override
  String linesPerMinute(int value) {
    return '$value s/d';
  }

  @override
  String get readerTipTitle => 'Oxu məsləhəti';

  @override
  String get readerTipBody =>
      'Söz təhlili, təfsir və əlfəcinlər üçün hər ayənin yanındakı nişanlara toxunun.';

  @override
  String get understood => 'Aydındır';

  @override
  String get failedToOpenSurah => 'Surəni açmaq mümkün olmadı.';

  @override
  String get noAyahsInSurah => 'Bu surədə ayə yoxdur.';

  @override
  String failedToLoadPage(int page) {
    return '$page səhifəsini yükləmək mümkün olmadı.';
  }

  @override
  String noAyahsOnPage(int page) {
    return '$page səhifəsində ayə yoxdur.';
  }

  @override
  String get retry => 'Yenidən cəhd';

  @override
  String get failedToLoadData => 'Məlumatları yükləmək mümkün olmadı.';

  @override
  String pageOfTotal(int page) {
    return 'Səhifə $page / 604';
  }

  @override
  String get textLayout => 'Mətn düzülüşü';

  @override
  String get failedToOpenQuran => 'Quranı açmaq mümkün olmadı';

  @override
  String get checkStorageAndRestart =>
      'Cihazdakı boş yeri yoxlayın və tətbiqi yenidən başladın.';

  @override
  String get navigationSurahs => 'Surələr';

  @override
  String get navigationJuz => 'Cüzlər';

  @override
  String get navigationHizb => 'Hizblər';

  @override
  String get navigationBookmarks => 'Əlfəcinlər';

  @override
  String get searchInQuran => 'Quranda axtar';

  @override
  String get searchHint => 'Mətn, tərcümə və ya ayə nömrəsinə görə axtarış';

  @override
  String get noResults => 'Heç nə tapılmadı';

  @override
  String get recentSearches => 'Son axtarışlar';

  @override
  String get clearAll => 'Hamısını təmizlə';

  @override
  String get uiLanguage => 'İnterfeys dili';

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
  String get aboutTitle => 'Mənbələr və müəlliflər';

  @override
  String get aboutAppDescription =>
      'Qurani-Kərimi reklamsız və məlumat toplamadan oxumaq üçün pulsuz tətbiq.';

  @override
  String get aboutDataSources => 'MƏLUMAT MƏNBƏLƏRİ';

  @override
  String get sourceUthmaniTitle => 'Quranın ərəb mətni (Uthmani)';

  @override
  String get sourceUthmaniDesc =>
      'Tanzil.net layihəsi tərəfindən təqdim edilmişdir. Dəqiq və mötəbər Quran mətni.';

  @override
  String get sourceKulievTitle => 'Mənaların tərcüməsi (Elmir Quliyev)';

  @override
  String get sourceKulievDesc =>
      'Qeyri-kommersiya məqsədləri üçün pulsuz yayılır.';

  @override
  String get sourceAbuAdelTitle => 'Mənaların tərcüməsi (Əbu Adel)';

  @override
  String get sourceAbuAdelDesc =>
      'Qeyri-kommersiya məqsədləri üçün pulsuz yayılır.';

  @override
  String get sourceTafsirTitle => 'Təfsir (Abdurrəhman əs-Sədi)';

  @override
  String get sourceTafsirDesc =>
      'Qurani-Kərimin təfsiri təhsil və qeyri-kommersiya məqsədləri üçün təqdim edilir.';

  @override
  String get sourceFontTitle => 'Şrift (Amiri Quran)';

  @override
  String get sourceFontDesc =>
      'SIL OFL lisenziyası altında açıq ərəb Amiri şrifti.';

  @override
  String get sourceMorphologyTitle => 'Sözbəsöz morfologiya və qrammatika';

  @override
  String get sourceMorphologyDesc =>
      'Ərəb qrammatikası və sözbəsöz mənalar: Quranic Arabic Corpus (corpus.quran.com, müəllif Kais Dukes) GNU GPL lisenziyası altında.';

  @override
  String get sourceAudioTitle => 'Qarilərin audiosu (EveryAyah)';

  @override
  String get sourceAudioDesc =>
      'Quran qiraəti yazıları everyayah.com saytından yüklənir. Hüquqlar qarilərə və naşirlərə məxsusdur; tətbiq audionu özündə saxlamır və ondan yalnız dinləmək üçün istifadə edir.';

  @override
  String get sourceOnlineApiTitle =>
      'Onlayn tərcümələr və söz vaxtları (Quran.com)';

  @override
  String get sourceOnlineApiDesc =>
      'Əlavə tərcümələr (Saheeh International, tacik, özbək, azərbaycan) və qarilərin sözbəsöz vaxt işarələri açıq Quran.com / Quran Foundation API vasitəsilə yüklənir və cihazda saxlanılır.';

  @override
  String get sourceSpeechTitle => 'Nitqin tanınması (Whisper)';

  @override
  String get sourceSpeechDesc =>
      'Qiraət məşqçisi yazınızı Modal-da yerləşən OpenAI Whisper (MIT lisenziyası) modelli serverə göndərir. Yazı emaldan dərhal sonra silinir.';

  @override
  String get viewLicenses => 'Açıq mənbəli proqram təminatı lisenziyaları';

  @override
  String get skip => 'Keç';

  @override
  String get next => 'Növbəti';

  @override
  String get startReading => 'Bismillah, oxumağa başla';

  @override
  String get reminderTitle => 'Möminlərə nəsihət';

  @override
  String get reminderAyah =>
      '«Bu, ayələrini düşünüb dərk etsinlər və ağıl sahibləri ibrət alsınlar deyə sənə nazil etdiyimiz mübarək bir Kitabdır.»';

  @override
  String get reminderRef => '38-ci «Sad» surəsi, 29-cu ayə';

  @override
  String get purityStatement =>
      'Yalnız Allahın Kitabı. Reklam və diqqət yayındıran amillər yoxdur. Oflayn işləyir (səslə qiraət yoxlanışı istisna olmaqla).';

  @override
  String get readingModesTitle => 'OXU REJİMLƏRİ';

  @override
  String get readingModesSubtitle => 'Sizə uyğun oxu tərzini seçin';

  @override
  String get flowModeTitle => 'Rəvan oxu (Flow)';

  @override
  String get flowModeBadge => 'Sətirbəsətir rejim';

  @override
  String get flowModeDesc =>
      'Gündəlik dərindən oxumaq üçün əlverişlidir. Avto-sürüşdürmə və sözbəsöz təhlili ehtiva edir.';

  @override
  String get mushafModeTitle => 'Klassik Müs-həf (604 səh.)';

  @override
  String get mushafModeBadge => 'Səhifəli rejim';

  @override
  String get mushafModeDesc =>
      'Mədinə müs-həfinin ənənəvi səhifəbəsəhifə tərtibatı. Əzbərləmək (hifz) üçün idealdır.';

  @override
  String get featuresTitle => 'İMKANLAR';

  @override
  String get featuresSubtitle => 'Hər şey sizin rahatlığınız üçün';

  @override
  String get themesFeatureTitle => '4 mövzu və gecə filtri';

  @override
  String get themesFeatureBadge => 'Görünüş';

  @override
  String get themesFeatureDesc =>
      'Perqament, Zümrüd, OLED və İşıqlı mövzular göz qoruyucu kəhrəba filtri ilə.';

  @override
  String get searchFeatureTitle => 'Kitab üzrə ağıllı axtarış';

  @override
  String get searchFeatureBadge => 'Sürətli axtarış';

  @override
  String get searchFeatureDesc =>
      'Ərəb mətni, tərcümələr və ya ayə nömrələri (məsələn, 2:255) üzrə axtarın.';

  @override
  String get khatmGoalTitle => 'Oxu hədəfi (Xətm)';

  @override
  String get khatmDaysQuestion =>
      'Neçə günə bütün Quranı (604 səhifə) xətm etməyi planlaşdırırsınız?';

  @override
  String daysCount(int days) {
    return '$days gün';
  }

  @override
  String dailyGoalPages(int pages) {
    return 'Hədəf: gündə $pages səh.';
  }

  @override
  String get cancel => 'Ləğv et';

  @override
  String get startKhatm => 'Xətmə başla';

  @override
  String khatmPlanTitle(int days) {
    return '$days günlük Xətm';
  }

  @override
  String get setKhatmGoal => 'Oxu hədəfi qoy (Xətm)';

  @override
  String get calculateDailyNorm => 'Gündəlik səhifə normasını hesablayın';

  @override
  String get editGoal => 'Hədəfi dəyiş';

  @override
  String get resetGoal => 'Tamamla / sıfırla';

  @override
  String khatmPagesRead(int completed) {
    return '604 səhifədən $completed səhifə oxundu';
  }

  @override
  String khatmDailyNormRemain(int daily, int remaining) {
    return 'Norma: $daily səh./gün · Qaldı: $remaining gün';
  }

  @override
  String bookmarkTitle(int surah, int ayah) {
    return 'Əlfəcin: $surah-ci surə, $ayah-ci ayə';
  }

  @override
  String get delete => 'Sil';

  @override
  String get folderCollection => 'Qovluq / Kolleksiya:';

  @override
  String get personalNote => 'Şəxsi qeyd (istəyə görə):';

  @override
  String get personalNoteHint => 'Məsələn: Bu həftə əzbərləmək...';

  @override
  String get saveChanges => 'Dəyişiklikləri saxla';

  @override
  String get addToBookmarks => 'Əlfəcinlərə əlavə et';

  @override
  String get selectReciter => 'Qarini seçin (Tilavət)';

  @override
  String get playbackSpeed => 'Səsləndirmə sürəti';

  @override
  String get downloadSurahOffline => 'Oflayn oxumaq üçün surəni yüklə';

  @override
  String get speed => 'Sürət';

  @override
  String get repeatOn => 'Ayə təkrarı aktivdir';

  @override
  String get repeatOff => 'Ayə təkrarı sönülüdür';

  @override
  String get closePlayer => 'Pleyeri bağla';

  @override
  String get prevAyah => 'Əvvəlki ayə';

  @override
  String get nextAyah => 'Növbəti ayə';

  @override
  String ayahNumber(int number) {
    return '$number-ci ayə';
  }

  @override
  String get hifzTrainerTitle => 'Qiraəti yoxlama (Hifz)';

  @override
  String hifzAyahInfo(int surahId, String surahName, int ayahNum) {
    return 'Surə $surahId. $surahName · Ayə $ayahNum';
  }

  @override
  String get tajweedRules => 'Bu ayənin təcvid qaydaları';

  @override
  String get byMemory => 'Əzbərdən';

  @override
  String get withText => 'Mətnlə';

  @override
  String get continuousMode => 'Davamlı';

  @override
  String get oneAyahMode => 'Bir ayə';

  @override
  String get continuousModeDesc => 'Növbəti ayəyə avtomatik keçid';

  @override
  String get listenToAyah => 'Ayəni dinlə';

  @override
  String get perfectReading => 'MaşaAllah! Ayə düzgün oxundu';

  @override
  String readingAccuracy(int accuracy, int correct, int total) {
    return 'Dəqiqlik: $accuracy% ($correct/$total söz)';
  }

  @override
  String aiListening(String text) {
    return 'Eşidirəm: \"$text\"';
  }

  @override
  String get startOver => 'Yenidən başla';

  @override
  String get stopListening => 'Dayandır';

  @override
  String get startListening => 'Oxu';

  @override
  String get readingInstructions =>
      'Mikrofona toxunun və ərəbcə oxumağa başlayın';

  @override
  String get listeningInProgress => 'Eşidirəm...';

  @override
  String get processingAudio => 'Emal edilir...';

  @override
  String get micError => 'Mikrofon xətası. İcazələrin verildiyinə əmin olun.';

  @override
  String get recitationDisclaimerTitle => 'Vacib xəbərdarlıq';

  @override
  String get recitationDisclaimerBody =>
      'Qiraətin avtomatik yoxlanması səhv edə bilər və 100% dəqiqliyə zəmanət vermir. Ondan yalnız köməkçi vasitə kimi istifadə edin. Bu funksiya ixtisaslı şeyx, qari və ya təcvid müəllimindən öyrənməyi və qiraəti yoxlatmağı əvəz etmir. Tələffüzü yalnız tətbiqin nəticəsinə əsasən öyrənməyin. Səs yazınız tanınma üçün xarici serverə göndəriləcək.';

  @override
  String get recitationDisclaimerAccept => 'Başa düşdüm, davam et';
}
