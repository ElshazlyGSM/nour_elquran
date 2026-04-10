import 'package:quran/quran.dart' as quran;

import '../models/reader_reciter.dart';

final readerReciters = <ReaderReciter>[
  ReaderReciter.legacy(
    reciter: quran.Reciter.arShaatree,
    nameAr: 'أبو بكر الشاطري',
  ),
  ReaderReciter.legacy(
    reciter: quran.Reciter.arAhmedAjamy,
    nameAr: 'أحمد العجمي',
  ),
  ReaderReciter.mp3Quran(
    timingReadId: 203,
    nameAr: 'أحمد عامر',
    folderUrl: 'https://server10.mp3quran.net/Aamer/',
    rewaya: 'حفص عن عاصم',
  ),
  ReaderReciter.mp3Quran(
    timingReadId: 289,
    nameAr: 'أحمد المعصراوي',
    folderUrl:
        'https://server16.mp3quran.net/a_maasaraawi/Rewayat-Hafs-A-n-Assem/',
    rewaya: 'حفص عن عاصم',
  ),
  ReaderReciter.mp3Quran(
    timingReadId: 9,
    nameAr: 'أحمد نعينع',
    folderUrl: 'https://server11.mp3quran.net/ahmad_nu/',
    rewaya: 'حفص عن عاصم',
  ),
  ReaderReciter.legacy(reciter: quran.Reciter.arHudhaify, nameAr: 'الحذيفي'),
  ReaderReciter.legacy(reciter: quran.Reciter.arAlafasy, nameAr: 'العفاسي'),
  ReaderReciter.mp3Quran(
    timingReadId: 118,
    nameAr: 'الحصري',
    folderUrl: 'https://server13.mp3quran.net/husr/',
    rewaya: 'حفص عن عاصم',
  ),
  ReaderReciter.legacy(reciter: quran.Reciter.arMinshawi, nameAr: 'المنشاوي'),
  ReaderReciter.mp3Quran(
    timingReadId: 106,
    nameAr: 'الطبلاوي',
    folderUrl: 'https://server12.mp3quran.net/tblawi/',
    rewaya: 'حفص عن عاصم',
  ),
  ReaderReciter.mp3Quran(
    timingReadId: 30,
    nameAr: 'سعد الغامدي',
    folderUrl: 'https://server7.mp3quran.net/s_gmd/',
    rewaya: 'حفص عن عاصم',
  ),
  ReaderReciter.mp3Quran(
    timingReadId: 53,
    nameAr: 'عبدالباسط',
    folderUrl: 'https://server7.mp3quran.net/basit/',
    rewaya: 'حفص عن عاصم',
  ),
  ReaderReciter.legacy(
    reciter: quran.Reciter.arMuhammadAyyoub,
    nameAr: 'محمد أيوب',
  ),
  ReaderReciter.legacy(
    reciter: quran.Reciter.arMuhammadJibreel,
    nameAr: 'محمد جبريل',
  ),

  ReaderReciter.legacy(
    reciter: quran.Reciter.arMaherMuaiqly,
    nameAr: 'ماهر المعيقلي',
  ),
];

final ReaderReciter defaultReaderReciter = readerReciters.firstWhere(
  (reciter) => reciter.legacyReciter == quran.Reciter.arMinshawi,
  orElse: () => readerReciters.first,
);

ReaderReciter? findReaderReciterById(String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final reciter in readerReciters) {
    if (reciter.id == id) {
      return reciter;
    }
  }
  return null;
}
