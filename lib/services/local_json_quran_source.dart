import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/quran.dart' as legacy_quran;

import 'quran_text_source.dart';

class LocalJsonQuranSource implements QuranTextSource {
  const LocalJsonQuranSource();

  static const String _assetPath = 'assets/quran/data.json';
  static bool _initialized = false;
  static late final String _basmala;
  static late final List<_SurahData> _surahs;
  static late final Map<int, List<Map<String, int>>> _pageData;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    _basmala = json['basmala'] as String? ?? '';
    final surahList = json['surahs'] as List<dynamic>? ?? const [];
    _surahs = surahList
        .map((item) => _SurahData.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    _pageData = <int, List<Map<String, int>>>{};
    for (final surah in _surahs) {
      for (final verse in surah.verses) {
        final pageItems = _pageData.putIfAbsent(verse.page, () => []);
        if (pageItems.isEmpty || pageItems.last['surah'] != surah.id) {
          pageItems.add({
            'surah': surah.id,
            'start': verse.ayah,
            'end': verse.ayah,
          });
        } else {
          pageItems.last['end'] = verse.ayah;
        }
      }
    }

    _initialized = true;
  }

  static void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'LocalJsonQuranSource is not initialized. Call ensureInitialized() first.',
      );
    }
  }

  @override
  String get basmala {
    _assertInitialized();
    return _basmala;
  }

  @override
  String getSurahNameArabic(int surahNumber) {
    return _surah(surahNumber).nameArabic;
  }

  @override
  String getSurahNameEnglish(int surahNumber) {
    return _surah(surahNumber).nameEnglish;
  }

  @override
  String getPlaceOfRevelationArabic(int surahNumber) {
    return _surah(surahNumber).revelationPlaceArabic;
  }

  @override
  int getVerseCount(int surahNumber) {
    return _surah(surahNumber).verses.length;
  }

  @override
  List<int> getSurahPages(int surahNumber) {
    return _surah(surahNumber).pages;
  }

  @override
  String getVerseText(
    int surahNumber,
    int verseNumber, {
    bool withTajweed = false,
    bool verseEndSymbol = false,
  }) {
    final text = _verse(surahNumber, verseNumber).text;
    if (!verseEndSymbol) {
      return text;
    }
    return '$text ${_verseEndSymbol(verseNumber)}';
  }

  @override
  String getVerseMarkup(
    int surahNumber,
    int verseNumber, {
    bool verseEndSymbol = false,
  }) {
    return getVerseText(
      surahNumber,
      verseNumber,
      verseEndSymbol: verseEndSymbol,
    );
  }

  @override
  List<Map<String, int>> getPageData(int pageNumber) {
    _assertInitialized();
    return _pageData[pageNumber] ?? const [];
  }

  @override
  int getPageNumber(int surahNumber, int verseNumber) {
    return _verse(surahNumber, verseNumber).page;
  }

  @override
  Map<int, List<int>> getSurahAndVersesFromJuz(int juzNumber) {
    _assertInitialized();
    final grouped = <int, List<int>>{};
    for (final surah in _surahs) {
      for (final verse in surah.verses) {
        if (verse.juz != juzNumber) continue;
        grouped.putIfAbsent(surah.id, () => []).add(verse.ayah);
      }
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
    return _verse(surahNumber, verseNumber).globalAyahNumber;
  }

  @override
  String stripTajweedTags(String text) => text;

  _SurahData _surah(int surahNumber) {
    _assertInitialized();
    return _surahs[surahNumber - 1];
  }

  _VerseData _verse(int surahNumber, int verseNumber) {
    return _surah(surahNumber).verses[verseNumber - 1];
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
}

class _SurahData {
  const _SurahData({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.revelationPlaceArabic,
    required this.pages,
    required this.verses,
  });

  factory _SurahData.fromJson(Map<String, dynamic> json) {
    return _SurahData(
      id: json['id'] as int,
      nameArabic: json['nameArabic'] as String? ?? '',
      nameEnglish: json['nameEnglish'] as String? ?? '',
      revelationPlaceArabic: json['revelationPlaceArabic'] as String? ?? '',
      pages: ((json['pages'] as List<dynamic>?) ?? const [])
          .map((item) => item as int)
          .toList(growable: false),
      verses: ((json['verses'] as List<dynamic>?) ?? const [])
          .map((item) => _VerseData.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String revelationPlaceArabic;
  final List<int> pages;
  final List<_VerseData> verses;
}

class _VerseData {
  const _VerseData({
    required this.ayah,
    required this.globalAyahNumber,
    required this.text,
    required this.page,
    required this.juz,
  });

  factory _VerseData.fromJson(Map<String, dynamic> json) {
    return _VerseData(
      ayah: json['ayah'] as int,
      globalAyahNumber: json['globalAyahNumber'] as int,
      text: json['text'] as String? ?? '',
      page: json['page'] as int,
      juz: json['juz'] as int,
    );
  }

  final int ayah;
  final int globalAyahNumber;
  final String text;
  final int page;
  final int juz;
}
