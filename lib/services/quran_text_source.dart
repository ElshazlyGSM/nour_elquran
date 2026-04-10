import 'package:quran/quran.dart' as legacy_quran;

abstract class QuranTextSource {
  const QuranTextSource();

  String get basmala;

  String getSurahNameArabic(int surahNumber);
  String getSurahNameEnglish(int surahNumber);
  String getPlaceOfRevelationArabic(int surahNumber);
  int getVerseCount(int surahNumber);
  List<int> getSurahPages(int surahNumber);

  String getVerseText(
    int surahNumber,
    int verseNumber, {
    bool withTajweed = false,
    bool verseEndSymbol = false,
  });

  String getVerseMarkup(
    int surahNumber,
    int verseNumber, {
    bool verseEndSymbol = false,
  });

  List<Map<String, int>> getPageData(int pageNumber);
  int getPageNumber(int surahNumber, int verseNumber);
  Map<int, List<int>> getSurahAndVersesFromJuz(int juzNumber);

  String getAudioUrlByVerse(
    int surahNumber,
    int verseNumber, {
    required legacy_quran.Reciter reciter,
  });

  int getAyahUqBySurahAndAyah(int surahNumber, int verseNumber);
  String stripTajweedTags(String text);
}
