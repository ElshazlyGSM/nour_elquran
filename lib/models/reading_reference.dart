import '../core/utils/arabic_numbers.dart';
import '../services/current_quran_text_source.dart';

const readingReferenceQuranSource = currentQuranTextSource;

abstract class ReadingReference {
  const ReadingReference({
    required this.index,
    required this.title,
    required this.surahNumber,
    required this.verseNumber,
  });

  final int index;
  final String title;
  final int surahNumber;
  final int verseNumber;

  String get startLabel =>
      '${readingReferenceQuranSource.getSurahNameArabic(surahNumber)} • الآية ${toArabicNumber(verseNumber)}';

  int get pageNumber =>
      readingReferenceQuranSource.getPageNumber(surahNumber, verseNumber);
}

class JuzReference extends ReadingReference {
  JuzReference(int index, int surahNumber, int verseNumber)
    : super(
        index: index,
        title: 'الجزء ${toArabicNumber(index)}',
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
}

class HizbReference extends ReadingReference {
  HizbReference(int index, int surahNumber, int verseNumber)
    : super(
        index: index,
        title: 'الحزب ${toArabicNumber(index)}',
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
}
