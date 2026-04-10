import 'dart:convert';
import 'dart:io';

import 'package:alfurqan/alfurqan.dart' as alfurqan;
import 'package:alfurqan/constant.dart' as alfurqan_constants;
import 'package:alfurqan/data/dart/types.dart' as alfurqan_types;
import 'package:quran/quran.dart' as legacy_quran;

void main() {
  final versesBySurah = <int, List<alfurqan_types.Verse>>{
    for (var surah = 1; surah <= alfurqan.AlQuran.totalChapter; surah++)
      surah: alfurqan.AlQuran.versesByChapter(
        surah,
        mode: alfurqan_constants.VerseMode.uthmani,
      ),
  };

  final totalPages = versesBySurah.values
      .expand((verses) => verses)
      .map((verse) => verse.pageNumber)
      .fold<int>(0, (max, page) => page > max ? page : max);

  final totalAyahs = versesBySurah.values.fold<int>(
    0,
    (sum, verses) => sum + verses.length,
  );

  final pageBlocks = <Map<String, Object>>[
    for (var page = 1; page <= totalPages; page++)
      {
        'page': page,
        'blocks': _buildPageBlocks(page, versesBySurah),
      },
  ];

  final juzBoundaries = <Map<String, Object>>[
    for (var juz = 1; juz <= legacy_quran.totalJuzCount; juz++)
      _buildJuzBoundary(juz, versesBySurah),
  ];

  final surahs = <Map<String, Object>>[
    for (var surah = 1; surah <= alfurqan.AlQuran.totalChapter; surah++)
      _buildSurahEntry(surah, versesBySurah[surah]!),
  ];

  final payload = <String, Object>{
    'meta': {
      'schemaVersion': '1.0.0',
      'title': 'Quran Text Dataset',
      'description':
          'Primary Quran dataset for the app. Fill only the verse text fields if you already trust the generated metadata.',
      'textStyle': 'uthmani',
      'encoding': 'UTF-8',
      'includesTashkeel': true,
      'includesVerseEndSymbolInsideText': false,
      'includesBasmalaAsFirstVerse': true,
      'pageSystem': 'medina',
      'totalSurahs': alfurqan.AlQuran.totalChapter,
      'totalAyahs': totalAyahs,
      'totalJuz': legacy_quran.totalJuzCount,
      'totalPages': totalPages,
      'generator': 'tool/generate_quran_data_template.dart',
      'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'notes': [
        'Every verse text is intentionally empty and ready for you to paste the Quran text.',
        'Do not place verse numbers inside the text field unless you want them rendered as part of the ayah text.',
        'Page, juz, surah metadata and page blocks were generated automatically from package data already present in the project.',
        'hizbQuarter is left null so you can fill a trusted source later if you want exact quarter markers from your own source.',
      ],
    },
    'basmala': _decodeEntities(alfurqan.AlQuran.basmallah),
    'surahs': surahs,
    'juzBoundaries': juzBoundaries,
    'pageBlocks': pageBlocks,
  };

  const encoder = JsonEncoder.withIndent('  ');
  final outputFile = File('assets/quran/data.json');
  outputFile.writeAsStringSync('${encoder.convert(payload)}\n');
  stdout.writeln(
    'Generated ${outputFile.path} with ${surahs.length} surahs and $totalAyahs verse placeholders.',
  );
}

Map<String, Object> _buildSurahEntry(
  int surah,
  List<alfurqan_types.Verse> verses,
) {
  final chapter = alfurqan.AlQuran.chapter(surah);
  final pages = chapter.pages.toSet().toList()..sort();

  return {
    'id': surah,
    'nameArabic': chapter.nameArabic,
    'nameEnglish': chapter.nameSimple,
    'revelationPlaceArabic': switch (chapter.revelationPlace) {
      alfurqan_types.ChapterRevelationPlace.madinah => 'مدنية',
      alfurqan_types.ChapterRevelationPlace.makkah => 'مكية',
    },
    'revelationPlaceEnglish': switch (chapter.revelationPlace) {
      alfurqan_types.ChapterRevelationPlace.madinah => 'Medinan',
      alfurqan_types.ChapterRevelationPlace.makkah => 'Meccan',
    },
    'ayahCount': verses.length,
    'pages': pages,
    'verses': [
      for (final verse in verses)
        {
          'ayah': _verseNumberFromKey(verse.verseKey),
          'verseKey': verse.verseKey,
          'globalAyahNumber': verse.id,
          'text': '',
          'page': verse.pageNumber,
          'juz': verse.juzNumber,
          'hizbQuarter': null,
          'sajda': legacy_quran.isSajdahVerse(
            surah,
            _verseNumberFromKey(verse.verseKey),
          ),
        },
    ],
  };
}

Map<String, Object> _buildJuzBoundary(
  int juz,
  Map<int, List<alfurqan_types.Verse>> versesBySurah,
) {
  final juzMap = legacy_quran.getSurahAndVersesFromJuz(juz);
  final sortedSurahs = juzMap.keys.toList()..sort();
  final startSurah = sortedSurahs.first;
  final startAyah = juzMap[startSurah]!.first;
  final endSurah = sortedSurahs.last;
  final endAyah = juzMap[endSurah]!.last;
  final startPage = _pageForVerse(versesBySurah, startSurah, startAyah);
  final endPage = _pageForVerse(versesBySurah, endSurah, endAyah);

  return {
    'juz': juz,
    'start': {
      'surah': startSurah,
      'ayah': startAyah,
      'page': startPage,
    },
    'end': {
      'surah': endSurah,
      'ayah': endAyah,
      'page': endPage,
    },
  };
}

List<Map<String, int>> _buildPageBlocks(
  int page,
  Map<int, List<alfurqan_types.Verse>> versesBySurah,
) {
  final blocks = <Map<String, int>>[];

  for (final entry in versesBySurah.entries) {
    final surah = entry.key;
    final versesOnPage = entry.value
        .where((verse) => verse.pageNumber == page)
        .map((verse) => _verseNumberFromKey(verse.verseKey))
        .toList();

    if (versesOnPage.isEmpty) {
      continue;
    }

    blocks.add({
      'surah': surah,
      'startAyah': versesOnPage.first,
      'endAyah': versesOnPage.last,
    });
  }

  return blocks;
}

int _pageForVerse(
  Map<int, List<alfurqan_types.Verse>> versesBySurah,
  int surah,
  int ayah,
) {
  return versesBySurah[surah]![ayah - 1].pageNumber;
}

int _verseNumberFromKey(String verseKey) {
  return int.parse(verseKey.split(':').last);
}

String _decodeEntities(String text) {
  return text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}
