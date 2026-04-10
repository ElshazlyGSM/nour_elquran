import 'package:alfurqan/alfurqan.dart' as alfurqan;
import 'package:alfurqan/constant.dart' as alfurqan_constants;
import 'package:alfurqan/data/dart/types.dart' as alfurqan_types;
import 'package:quran/quran.dart' as legacy_quran;

import 'quran_text_source.dart';

class AlfurqanQuranSource implements QuranTextSource {
  const AlfurqanQuranSource();

  static const String _tajweedTagPattern = r'&lt;/?(?:tajweed|span)[^&]*?&gt;';
  static final RegExp _endSpanPattern = RegExp(
    r'<span class="?end"?>(.*?)</span>',
    dotAll: true,
  );
  static const int totalJuzCount = 30;
  static final int totalSurahCount = alfurqan.AlQuran.totalChapter;

  static final Map<int, List<alfurqan_types.Verse>> _uthmaniVersesByChapter = {
    for (var surah = 1; surah <= totalSurahCount; surah++)
      surah: alfurqan.AlQuran.versesByChapter(
        surah,
        mode: alfurqan_constants.VerseMode.uthmani,
      ),
  };

  static final Map<int, List<alfurqan_types.Verse>>
  _uthmaniTajweedVersesByChapter = {
    for (var surah = 1; surah <= totalSurahCount; surah++)
      surah: alfurqan.AlQuran.versesByChapter(
        surah,
        mode: alfurqan_constants.VerseMode.uthmaniTajweed,
      ),
  };

  static final Map<int, List<Map<String, int>>> _pageData = _buildPageData();
  static final int totalPagesCount = _pageData.keys.isEmpty
      ? 0
      : _pageData.keys.reduce((a, b) => a > b ? a : b);

  @override
  String get basmala => _decodeEntities(alfurqan.AlQuran.basmallah);

  @override
  String getSurahNameArabic(int surahNumber) {
    return alfurqan.AlQuran.chapter(surahNumber).nameArabic;
  }

  @override
  String getSurahNameEnglish(int surahNumber) {
    return alfurqan.AlQuran.chapter(surahNumber).nameSimple;
  }

  @override
  String getPlaceOfRevelationArabic(int surahNumber) {
    final place = alfurqan.AlQuran.chapter(surahNumber).revelationPlace;
    return switch (place) {
      alfurqan_types.ChapterRevelationPlace.madinah => 'مدنية',
      alfurqan_types.ChapterRevelationPlace.makkah => 'مكية',
    };
  }

  @override
  int getVerseCount(int surahNumber) {
    return alfurqan.AlQuran.chapter(surahNumber).versesCount;
  }

  @override
  List<int> getSurahPages(int surahNumber) {
    return alfurqan.AlQuran.chapter(surahNumber).pages;
  }

  @override
  String getVerseText(
    int surahNumber,
    int verseNumber, {
    bool withTajweed = false,
    bool verseEndSymbol = false,
  }) {
    final rawText = withTajweed
        ? getVerseMarkup(surahNumber, verseNumber, verseEndSymbol: false)
        : _decodeEntities(_verse(surahNumber, verseNumber).text);
    final cleanText = withTajweed ? stripTajweedTags(rawText) : rawText;
    if (!verseEndSymbol) {
      return cleanText;
    }
    return '$cleanText ${_verseEndSymbol(verseNumber)}';
  }

  @override
  String getVerseMarkup(
    int surahNumber,
    int verseNumber, {
    bool verseEndSymbol = false,
  }) {
    final raw = _decodeEntities(_tajweedVerse(surahNumber, verseNumber).text);
    final withoutEndMarker = raw.replaceAll(_endSpanPattern, '');
    if (!verseEndSymbol) {
      return withoutEndMarker.trimRight();
    }
    return '${withoutEndMarker.trimRight()} ${_verseEndSymbol(verseNumber)}';
  }

  List<alfurqan_types.Verse> versesByChapter(
    int surahNumber, {
    bool withTajweed = false,
  }) {
    final mode = withTajweed
        ? alfurqan_constants.VerseMode.uthmaniTajweed
        : alfurqan_constants.VerseMode.uthmani;
    return alfurqan.AlQuran.versesByChapter(surahNumber, mode: mode);
  }

  @override
  List<Map<String, int>> getPageData(int pageNumber) {
    return _pageData[pageNumber] ?? const [];
  }

  @override
  int getPageNumber(int surahNumber, int verseNumber) {
    return _verse(surahNumber, verseNumber).pageNumber;
  }

  @override
  Map<int, List<int>> getSurahAndVersesFromJuz(int juzNumber) {
    final verses = alfurqan.AlQuran.versesByJuz(
      juzNumber,
      mode: alfurqan_constants.VerseMode.uthmani,
    );
    final grouped = <int, List<int>>{};
    for (final verse in verses) {
      grouped
          .putIfAbsent(verse.chapterID, () => [])
          .add(_verseNumberFromKey(verse.verseKey));
    }
    return grouped;
  }

  @override
  String getAudioUrlByVerse(
    int surahNumber,
    int verseNumber, {
    required legacy_quran.Reciter reciter,
  }) {
    return legacy_quran.getAudioURLByVerse(
      surahNumber,
      verseNumber,
      reciter: reciter,
    );
  }

  @override
  int getAyahUqBySurahAndAyah(int surahNumber, int verseNumber) {
    var offset = 0;
    for (var surah = 1; surah < surahNumber; surah++) {
      offset += getVerseCount(surah);
    }
    return offset + verseNumber;
  }

  @override
  String stripTajweedTags(String text) {
    return _decodeEntities(text.replaceAll(RegExp(_tajweedTagPattern), ''));
  }

  alfurqan_types.Verse _verse(int surahNumber, int verseNumber) {
    return _uthmaniVersesByChapter[surahNumber]![verseNumber - 1];
  }

  alfurqan_types.Verse _tajweedVerse(int surahNumber, int verseNumber) {
    return _uthmaniTajweedVersesByChapter[surahNumber]![verseNumber - 1];
  }

  int _verseNumberFromKey(String verseKey) {
    return int.parse(verseKey.split(':').last);
  }

  String _verseEndSymbol(int verseNumber) {
    return '﴿${_toArabicDigits(verseNumber)}﴾';
  }

  String _toArabicDigits(int number) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    return number.toString().split('').map((digit) {
      final index = western.indexOf(digit);
      return index == -1 ? digit : eastern[index];
    }).join();
  }

  static Map<int, List<Map<String, int>>> _buildPageData() {
    final pageData = <int, List<Map<String, int>>>{};
    for (var surah = 1; surah <= totalSurahCount; surah++) {
      final verses = _uthmaniVersesByChapter[surah]!;
      for (final verse in verses) {
        final verseNumber = int.parse(verse.verseKey.split(':').last);
        final pageItems = pageData.putIfAbsent(verse.pageNumber, () => []);
        if (pageItems.isEmpty || pageItems.last['surah'] != surah) {
          pageItems.add({
            'surah': surah,
            'start': verseNumber,
            'end': verseNumber,
          });
        } else {
          pageItems.last['end'] = verseNumber;
        }
      }
    }
    return pageData;
  }

  String _decodeEntities(String text) {
    return text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
  }
}
