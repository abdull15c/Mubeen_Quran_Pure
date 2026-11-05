final class Reciter {
  const Reciter({
    required this.id,
    required this.nameRussian,
    required this.nameArabic,
    required this.subfolder,
    this.quality = '128 kbps',
    this.quranComReciterId,
  });

  final String id;
  final String nameRussian;
  final String nameArabic;
  final String subfolder;
  final String quality;

  /// The ID used on api.quran.com to fetch word-by-word timestamps.
  /// If null, this reciter does not have karaoke timestamps available.
  final int? quranComReciterId;

  String getAyahAudioUrl(int surahNumber, int ayahNumber) {
    final String s = surahNumber.toString().padLeft(3, '0');
    final String a = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$subfolder/$s$a.mp3';
  }
}

const List<Reciter> kAvailableReciters = <Reciter>[
  Reciter(
    id: 'alafasy',
    nameRussian: 'Мишари Рашид аль-Афаси',
    nameArabic: 'مشاري راشد العفاسي',
    subfolder: 'Alafasy_128kbps',
    quranComReciterId: 7,
  ),
  Reciter(
    id: 'sudais',
    nameRussian: 'Абдуррахман ас-Судейс',
    nameArabic: 'عبد الرحمن السديس',
    subfolder: 'Abdurrahmaan_As-Sudais_192kbps',
    quality: '192 kbps',
    quranComReciterId: 3,
  ),
  Reciter(
    id: 'ajamy',
    nameRussian: 'Ахмад аль-Аджми',
    nameArabic: 'أحمد بن علي العجمي',
    subfolder: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
  ),
  Reciter(
    id: 'husary',
    nameRussian: 'Махмуд Халиль аль-Хусари',
    nameArabic: 'محمود خليل الحصري',
    subfolder: 'Husary_128kbps',
    quranComReciterId: 6,
  ),
  Reciter(
    id: 'minshawi',
    nameRussian: 'Мухаммад Сиддик аль-Миншави',
    nameArabic: 'محمد صديق المنشاوي',
    subfolder: 'Minshawy_Murattal_128kbps',
    quranComReciterId: 9,
  ),
  Reciter(
    id: 'abdulsamad',
    nameRussian: 'Абдуль-Басит Абдус-Самад',
    nameArabic: 'عبد الباسط عبد الصمد',
    subfolder: 'AbdulSamad_64kbps_QuranExplorer.Com',
    quality: '64 kbps',
    quranComReciterId: 2,
  ),
  Reciter(
    id: 'shatri',
    nameRussian: 'Абу Бакр аш-Шатри',
    nameArabic: 'أبو بكر الشاطري',
    subfolder: 'Abu_Bakr_Ash-Shaatree_128kbps',
    quranComReciterId: 4,
  ),
  Reciter(
    id: 'muaiqly',
    nameRussian: 'Махир аль-Муайкли',
    nameArabic: 'ماهر المعيقلي',
    subfolder: 'Maher_AlMuaiqly_64kbps',
    quality: '64 kbps',
  ),
  Reciter(
    id: 'rifai',
    nameRussian: 'Хани ар-Рифаи',
    nameArabic: 'هاني الرفاعي',
    subfolder: 'Hani_Rifai_192kbps',
    quality: '192 kbps',
    quranComReciterId: 5,
  ),
  Reciter(
    id: 'ayyoub',
    nameRussian: 'Мухаммад Айюб',
    nameArabic: 'محمد أيوب',
    subfolder: 'Muhammad_Ayyoub_128kbps',
  ),
  Reciter(
    id: 'shuraim',
    nameRussian: 'Сауд аш-Шурейм',
    nameArabic: 'سعود الشريم',
    subfolder: 'Saood_ash-Shuraym_128kbps',
    quranComReciterId: 10,
  ),
];
