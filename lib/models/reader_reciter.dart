import 'package:quran/quran.dart' as quran;

enum ReaderReciterSource { legacy, mp3Quran }

class ReaderReciter {
  const ReaderReciter._({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.source,
    this.legacyReciter,
    this.mp3TimingReadId,
    this.mp3FolderUrl,
    this.rewaya,
    this.country,
    this.availableSurahs,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final ReaderReciterSource source;
  final quran.Reciter? legacyReciter;
  final int? mp3TimingReadId;
  final String? mp3FolderUrl;
  final String? rewaya;
  final String? country;
  final Set<int>? availableSurahs;

  bool get isLegacy => source == ReaderReciterSource.legacy;
  bool get isMp3Quran => source == ReaderReciterSource.mp3Quran;
  bool get supportsFullDownload => isLegacy;
  bool get hasLimitedSurahList =>
      availableSurahs != null && availableSurahs!.isNotEmpty;

  String get subtitle {
    if (rewaya != null && rewaya!.isNotEmpty) {
      return rewaya!;
    }
    return 'حفص عن عاصم';
  }

  factory ReaderReciter.legacy({
    required quran.Reciter reciter,
    required String nameAr,
    String rewaya = 'حفص عن عاصم',
  }) {
    return ReaderReciter._(
      id: 'legacy:${reciter.name}',
      nameAr: nameAr,
      nameEn: reciter.englishName,
      source: ReaderReciterSource.legacy,
      legacyReciter: reciter,
      rewaya: rewaya,
    );
  }

  factory ReaderReciter.mp3Quran({
    required int timingReadId,
    required String nameAr,
    required String folderUrl,
    required String rewaya,
    String country = 'مصر',
    Iterable<int>? availableSurahs,
  }) {
    return ReaderReciter._(
      id: 'mp3:$timingReadId',
      nameAr: nameAr,
      nameEn: nameAr,
      source: ReaderReciterSource.mp3Quran,
      mp3TimingReadId: timingReadId,
      mp3FolderUrl: folderUrl,
      rewaya: rewaya,
      country: country,
      availableSurahs: availableSurahs == null
          ? null
          : Set<int>.from(availableSurahs),
    );
  }
}
