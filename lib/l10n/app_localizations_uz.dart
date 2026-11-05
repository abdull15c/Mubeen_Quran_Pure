// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Mubeen Qur\'on';

  @override
  String get appName => 'MUBEEN';

  @override
  String get appSubtitle => 'QUR\'ON';

  @override
  String get tabRead => 'O\'qish';

  @override
  String get tabNavigation => 'Navigatsiya';

  @override
  String get tabSearch => 'Qidirish';

  @override
  String get tabSettings => 'Sozlamalar';

  @override
  String get settingsTitle => 'O\'qish sozlamalari';

  @override
  String get sectionAppearance => 'Ko\'rinish';

  @override
  String get sectionTranslation => 'Tarjima';

  @override
  String get sectionTextSize => 'Matn hajmi';

  @override
  String get sectionHandsFreeReading => 'Avtomatik o\'qish';

  @override
  String get eyeCareFilter => 'Ko\'z himoyasi (Tungi filtr)';

  @override
  String get showTranslation => 'Tarjimani ko\'rsatish';

  @override
  String get showTranslationSubtitle =>
      'Arab matni har doim asosiy bo\'lib qoladi';

  @override
  String get onlineTranslation => 'Onlayn tarjima';

  @override
  String get downloading => 'Yuklanmoqda...';

  @override
  String get arabicTextSize => 'Arab matni';

  @override
  String get translationTextSize => 'Tarjima';

  @override
  String get autoScrollSpeed => 'Avto-aylantirish tezligi';

  @override
  String autoScrollSpeedValue(String value) {
    return '$value qator/daq';
  }

  @override
  String get autoScrollHint =>
      'Vertikal o\'qish rejimida tugma bilan avto-aylantirishni boshlang. Bir marta bosish to\'xtatadi.';

  @override
  String get guideTitle => 'Qo\'llanma va maslahatlar';

  @override
  String get guideSubtitle =>
      'Imo-ishoralar, avto-aylantirish, tafsir va qidiruv';

  @override
  String get onboardingTitle => 'Ilova haqida';

  @override
  String get onboardingSubtitle => 'Eslatma oyati bilan kirish ekranini ochish';

  @override
  String get sourcesTitle => 'Manbalar va atributsiya';

  @override
  String get sourcesSubtitle => 'Matnlar va litsenziyalar haqida ma\'lumot';

  @override
  String get privacyNote =>
      'Faqat Qur\'on. Reklama, ro\'yxatdan o\'tish, lenta, o\'qish tahlili va begona bo\'limlar yo\'q. Sozlamalar va xatcho\'plar qurilmada saqlanadi.';

  @override
  String get themeParchment => 'Pergament';

  @override
  String get themeOled => 'OLED';

  @override
  String get themeEmerald => 'Zumrad';

  @override
  String get themeLight => 'Yorug\'';

  @override
  String themeLabel(String name) {
    return 'Mavzu $name';
  }

  @override
  String get jumpToAyah => 'Oyatga o\'tish';

  @override
  String get verticalReading => 'Vertikal o\'qish';

  @override
  String get quranPages => 'Qur\'on sahifalari';

  @override
  String surahInfoLabel(int id, String name, int count) {
    return 'Sura $id. $name ($count oyat)';
  }

  @override
  String get meccan => 'Makkalik';

  @override
  String get medinan => 'Madaniylik';

  @override
  String get listenSurah => 'Surani tinglash';

  @override
  String get pause => 'Pauza';

  @override
  String get listenAyah => 'Oyatni tinglash';

  @override
  String get copyAyah => 'Oyatni nusxalash';

  @override
  String get wordAnalysis => 'So\'zma-so\'z tahlil';

  @override
  String get tafsirSaadi => 'Tafsir as-Sa\'diy';

  @override
  String get recitationCheck => 'Qiroatni tekshirish (Hifz)';

  @override
  String get addBookmark => 'Xatcho\'p qo\'shish';

  @override
  String get removeBookmark => 'Xatcho\'pni o\'chirish';

  @override
  String ayahCopied(int surah, int ayah) {
    return 'Oyat $surah:$ayah nusxalandi';
  }

  @override
  String get copyFailed => 'Oyatni nusxalab bo\'lmadi.';

  @override
  String quranReference(int surah, int ayah) {
    return 'Qur\'on ($surah:$ayah)';
  }

  @override
  String tafsirTitle(int surah, int ayah) {
    return 'Tafsir as-Sa\'diy · $surah:$ayah';
  }

  @override
  String get tafsirSubtitle =>
      'Shayx Abdur-Rohman as-Sa\'diy tomonidan Qur\'oni Karim tafsiri';

  @override
  String get tafsirNotFound => 'Bu oyat uchun tafsir topilmadi.';

  @override
  String wordAnalysisTitle(int surah, int ayah) {
    return 'So\'zma-so\'z tahlil · $surah:$ayah';
  }

  @override
  String get wordAnalysisSubtitle =>
      'Batafsil grammatika va ildiz uchun so\'zni bosing';

  @override
  String get wordAnalysisNotFound => 'So\'zma-so\'z tahlil topilmadi.';

  @override
  String get wordTranslation => 'Tarjima';

  @override
  String get wordRoot => 'Ildiz';

  @override
  String get wordLemma => 'Lemma';

  @override
  String get wordPartOfSpeech => 'Nutq qismi';

  @override
  String get notSpecified => 'Ko\'rsatilmagan';

  @override
  String get close => 'Yopish';

  @override
  String get sajda => 'Sajda';

  @override
  String juz(int number) {
    return 'Juz $number';
  }

  @override
  String get autoScroll => 'Avto-aylantirish';

  @override
  String get slower => 'Sekinroq';

  @override
  String get faster => 'Tezroq';

  @override
  String linesPerMinute(int value) {
    return '$value q/d';
  }

  @override
  String get readerTipTitle => 'O\'qish maslahati';

  @override
  String get readerTipBody =>
      'So\'zma-so\'z tahlil, tafsir va xatcho\'plar uchun har bir oyat yonidagi ikonkalarni bosing.';

  @override
  String get understood => 'Tushunarli';

  @override
  String get failedToOpenSurah => 'Surani ochib bo\'lmadi.';

  @override
  String get noAyahsInSurah => 'Bu surada oyat yo\'q.';

  @override
  String failedToLoadPage(int page) {
    return '$page-sahifani yuklab bo\'lmadi.';
  }

  @override
  String noAyahsOnPage(int page) {
    return '$page-sahifada oyat yo\'q.';
  }

  @override
  String get retry => 'Qayta urinish';

  @override
  String get failedToLoadData => 'Ma\'lumotlarni yuklab bo\'lmadi.';

  @override
  String pageOfTotal(int page) {
    return 'Sahifa $page / 604';
  }

  @override
  String get textLayout => 'Matn tartibi';

  @override
  String get failedToOpenQuran => 'Qur\'onni ochib bo\'lmadi';

  @override
  String get checkStorageAndRestart =>
      'Qurilmadagi bo\'sh joyni tekshiring va ilovani qayta ishga tushiring.';

  @override
  String get navigationSurahs => 'Suralar';

  @override
  String get navigationJuz => 'Juzlar';

  @override
  String get navigationHizb => 'Hizblar';

  @override
  String get navigationBookmarks => 'Xatcho\'plar';

  @override
  String get searchInQuran => 'Qur\'onda qidirish';

  @override
  String get searchHint => 'Matn, tarjima yoki oyat raqami bo\'yicha qidirish';

  @override
  String get noResults => 'Hech narsa topilmadi';

  @override
  String get recentSearches => 'So\'nggi qidiruvlar';

  @override
  String get clearAll => 'Hammasini tozalash';

  @override
  String get uiLanguage => 'Interfeys tili';

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
  String get aboutTitle => 'Manbalar va mualliflar';

  @override
  String get aboutAppDescription =>
      'Qur\'oni Karimni reklamasiz va ma\'lumot yig\'ishsiz o\'qish uchun bepul ilova.';

  @override
  String get aboutDataSources => 'MA\'LUMOT MANBALARI';

  @override
  String get sourceUthmaniTitle => 'Qur\'onning arabcha matni (Uthmani)';

  @override
  String get sourceUthmaniDesc =>
      'Tanzil.net loyihasi tomonidan taqdim etilgan. Tekshirilgan va ishonchli Qur\'on matni.';

  @override
  String get sourceKulievTitle => 'Ma\'nolar tarjimasi (Elmir Quliyev)';

  @override
  String get sourceKulievDesc => 'Notijorat maqsadlarda bepul tarqatiladi.';

  @override
  String get sourceAbuAdelTitle => 'Ma\'nolar tarjimasi (Abu Odil)';

  @override
  String get sourceAbuAdelDesc => 'Notijorat maqsadlarda bepul tarqatiladi.';

  @override
  String get sourceTafsirTitle => 'Tafsir (Abdurahmon as-Sa\'diy)';

  @override
  String get sourceTafsirDesc =>
      'Qur\'oni Karim tafsiri o\'rganish maqsadida bepul taqdim etilgan.';

  @override
  String get sourceFontTitle => 'Shrift (Amiri Quran)';

  @override
  String get sourceFontDesc =>
      'Ochiq arabcha Amiri shrifti SIL OFL litsenziyasi ostida.';

  @override
  String get sourceMorphologyTitle => 'So\'zma-so\'z tahlil va morfologiya';

  @override
  String get sourceMorphologyDesc =>
      'Arab grammatikasi va so\'zma-so\'z ma\'nolari: Quranic Arabic Corpus (corpus.quran.com, muallif Kais Dukes) GNU GPL litsenziyasi ostida.';

  @override
  String get sourceAudioTitle => 'Qorilar audiosi (EveryAyah)';

  @override
  String get sourceAudioDesc =>
      'Qur\'on tilovati yozuvlari everyayah.com saytidan yuklanadi. Huquqlar qorilar va nashriyotlarga tegishli; ilova audioni o\'z ichiga olmaydi va undan faqat tinglash uchun foydalanadi.';

  @override
  String get sourceOnlineApiTitle =>
      'Onlayn tarjimalar va so\'z vaqtlari (Quran.com)';

  @override
  String get sourceOnlineApiDesc =>
      'Qo\'shimcha tarjimalar (Saheeh International, tojik, o\'zbek, ozarbayjon) va qorilarning so\'zma-so\'z vaqt belgilari ochiq Quran.com / Quran Foundation API orqali yuklanadi va qurilmada saqlanadi.';

  @override
  String get sourceSpeechTitle => 'Nutqni aniqlash (Whisper)';

  @override
  String get sourceSpeechDesc =>
      'Tilovat mashqlari yozuvingizni Modal\'da joylashgan OpenAI Whisper (MIT litsenziyasi) modelli serverga yuboradi. Yozuv qayta ishlangandan so\'ng darhol o\'chiriladi.';

  @override
  String get sectionArabicFont => 'Arab shrifti';

  @override
  String get fontHafs => 'Usmoniy Hafs (Madina mushafi)';

  @override
  String get fontHafsSmart => 'Hafs Smart (ekran uchun)';

  @override
  String get fontAmiri => 'Amiri Quran (klassik nasx)';

  @override
  String get sourceFontKfgqpcTitle => 'KFGQPC Hafs shriftlari';

  @override
  String get sourceFontKfgqpcDesc =>
      'Qirol Fahd nomidagi Qur\'on nashriyot majmuasi (Madina) ning «KFGQPC HAFS Uthmanic Script» va «KFGQPC Hafs Smart» shriftlari. Litsenziya o\'zgartirishsiz bepul foydalanish, nusxalash va tarqatishga ruxsat beradi; litsenziya matni ilovaga kiritilgan.';

  @override
  String get sourceFontSerifTitle => 'Tarjima shrifti (PT Serif)';

  @override
  String get sourceFontSerifDesc =>
      'Tarjimalar va tafsir ParaType kompaniyasining PT Serif shriftida SIL Open Font License ostida terilgan.';

  @override
  String get viewLicenses => 'Ochiq kodli dasturiy ta\'minot litsenziyalari';

  @override
  String get skip => 'O\'tkazib yuborish';

  @override
  String get next => 'Keyingi';

  @override
  String get startReading => 'Bismilloh, o\'qishni boshlash';

  @override
  String get reminderTitle => 'Mo\'minlarga eslatma';

  @override
  String get reminderAyah =>
      '«Bu – oyatlarini tafakkur qilishlari va aql egalari eslatma olishlari uchun Biz senga nozil qilgan muborak Kitobdir.»';

  @override
  String get reminderRef => '38-sura «Sod», 29-oyat';

  @override
  String get purityStatement =>
      'Faqat Allohning Kitobi. Reklamasiz va chalg\'ituvchi omillarsiz. Oflayn ishlaydi (ovozli tilovat tekshiruvi bundan mustasno).';

  @override
  String get readingModesTitle => 'O\'QISH REJIMLARI';

  @override
  String get readingModesSubtitle =>
      'O\'zingizga qulay o\'qish usulini tanlang';

  @override
  String get flowModeTitle => 'Ravon o\'qish (Flow)';

  @override
  String get flowModeBadge => 'Qatorma-qator rejim';

  @override
  String get flowModeDesc =>
      'Kundalik chuqur o\'qish uchun qulay. Avto-aylantirish va so\'zma-so\'z tahlilni o\'z ichiga oladi.';

  @override
  String get mushafModeTitle => 'Klassik Mushaf (604 bet)';

  @override
  String get mushafModeBadge => 'Sahifali rejim';

  @override
  String get mushafModeDesc =>
      'Madina mushafining an\'anaviy sahifalash tartibi. Yodlash (hifz) uchun ayni muddao.';

  @override
  String get featuresTitle => 'IMKONIYATLAR';

  @override
  String get featuresSubtitle => 'Barchasi sizning qulayligingiz uchun';

  @override
  String get themesFeatureTitle => '4 ta mavzu va tungi filtr';

  @override
  String get themesFeatureBadge => 'Ko\'rinish';

  @override
  String get themesFeatureDesc =>
      'Pergament, Zumrad, OLED va Yorug\' mavzular ko\'zni himoya qiluvchi filtr bilan.';

  @override
  String get searchFeatureTitle => 'Kitob bo\'ylab aqlli qidiruv';

  @override
  String get searchFeatureBadge => 'Tezkor qidiruv';

  @override
  String get searchFeatureDesc =>
      'Arabcha matn, tarjimalar yoki oyat raqamlari (masalan, 2:255) bo\'yicha qidiring.';

  @override
  String get khatmGoalTitle => 'O\'qish maqsadi (Xatm)';

  @override
  String get khatmDaysQuestion =>
      'Necha kunda butun Qur\'onni (604 bet) xatm qilmoqchisiz?';

  @override
  String daysCount(int days) {
    return '$days kun';
  }

  @override
  String dailyGoalPages(int pages) {
    return 'Maqsad: kuniga $pages bet';
  }

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get startKhatm => 'Xatmni boshlash';

  @override
  String khatmPlanTitle(int days) {
    return '$days kunlik Xatm';
  }

  @override
  String get setKhatmGoal => 'O\'qish maqsadini qo\'yish (Xatm)';

  @override
  String get calculateDailyNorm => 'Kunlik sahifa me\'yorini hisoblang';

  @override
  String get editGoal => 'Maqsadni o\'zgartirish';

  @override
  String get resetGoal => 'Yakunlash / bekor qilish';

  @override
  String khatmPagesRead(int completed) {
    return '604 betdan $completed bet o\'qildi';
  }

  @override
  String khatmDailyNormRemain(int daily, int remaining) {
    return 'Me\'yor: $daily bet/kun · Qoldi: $remaining kun';
  }

  @override
  String bookmarkTitle(int surah, int ayah) {
    return 'Xatcho\'p: $surah-sura, $ayah-oyat';
  }

  @override
  String get delete => 'O\'chirish';

  @override
  String get folderCollection => 'Jild / To\'plam:';

  @override
  String get personalNote => 'Shaxsiy eslatma (ixtiyoriy):';

  @override
  String get personalNoteHint => 'Masalan: Bu hafta yodlash...';

  @override
  String get saveChanges => 'O\'zgarishlarni saqlash';

  @override
  String get addToBookmarks => 'Xatcho\'plarga qo\'shish';

  @override
  String get selectReciter => 'Qorini tanlang (Tilovat)';

  @override
  String get playbackSpeed => 'Ijro tezligi';

  @override
  String get downloadSurahOffline => 'Oflayn o\'qish uchun surani yuklab olish';

  @override
  String get speed => 'Tezlik';

  @override
  String get repeatOn => 'Oyat takrorlash yoqildi';

  @override
  String get repeatOff => 'Oyat takrorlash o\'chirildi';

  @override
  String get closePlayer => 'Pleyerni yopish';

  @override
  String get prevAyah => 'Oldingi oyat';

  @override
  String get nextAyah => 'Keyingi oyat';

  @override
  String ayahNumber(int number) {
    return '$number-oyat';
  }

  @override
  String get hifzTrainerTitle => 'Qiroatni tekshirish (Hifz)';

  @override
  String hifzAyahInfo(int surahId, String surahName, int ayahNum) {
    return 'Sura $surahId. $surahName · Oyat $ayahNum';
  }

  @override
  String get tajweedRules => 'Bu oyatning tajvid qoidalari';

  @override
  String get byMemory => 'Yoddan';

  @override
  String get withText => 'Matn bilan';

  @override
  String get continuousMode => 'Uzluksiz';

  @override
  String get oneAyahMode => 'Bitta oyat';

  @override
  String get continuousModeDesc => 'Keyingi oyatga avtomat o\'tish';

  @override
  String get listenToAyah => 'Oyatni tinglash';

  @override
  String get perfectReading => 'MashaAlloh! Oyat to\'g\'ri o\'qildi';

  @override
  String readingAccuracy(int accuracy, int correct, int total) {
    return 'Aniqlik: $accuracy% ($correct/$total so\'z)';
  }

  @override
  String aiListening(String text) {
    return 'Eshityapman: \"$text\"';
  }

  @override
  String get startOver => 'Qayta boshlash';

  @override
  String get stopListening => 'To\'xtatish';

  @override
  String get startListening => 'O\'qish';

  @override
  String get readingInstructions =>
      'Mikrofonni bosing va arab tilida o\'qishni boshlang';

  @override
  String get listeningInProgress => 'Eshityapman...';

  @override
  String get processingAudio => 'Ishlanmoqda...';

  @override
  String get micError => 'Mikrofon xatosi. Ruxsat berilganligini tekshiring.';

  @override
  String get recitationDisclaimerTitle => 'Muhim ogohlantirish';

  @override
  String get recitationDisclaimerBody =>
      'Qiroatni avtomatik tekshirish xato qilishi mumkin va 100% aniqlikni kafolatlamaydi. Undan faqat yordamchi vosita sifatida foydalaning. U malakali shayx, qori yoki tajvid ustozidan ta\'lim olish va qiroatni tekshirtirish o\'rnini bosmaydi. Talaffuzni faqat ilova natijasiga tayanib o\'rganmang. Ovozingizni aniqlash uchun audioyozuv tashqi serverga yuboriladi.';

  @override
  String get recitationDisclaimerAccept => 'Tushundim, davom etish';
}
