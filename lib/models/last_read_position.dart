import '../services/current_quran_text_source.dart';

const _lastReadQuranSource = currentQuranTextSource;

class LastReadPosition {
  const LastReadPosition({
    required this.surahNumber,
    required this.verseNumber,
  });

  final int surahNumber;
  final int verseNumber;

  int get pageNumber => _lastReadQuranSource.getPageNumber(surahNumber, verseNumber);

  String get surahName => _lastReadQuranSource.getSurahNameArabic(surahNumber);
}
