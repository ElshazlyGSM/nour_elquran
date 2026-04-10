import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/reader_reciter.dart';

class Mp3QuranAyahTiming {
  const Mp3QuranAyahTiming({
    required this.ayah,
    required this.startTimeMs,
    required this.endTimeMs,
  });

  final int ayah;
  final int startTimeMs;
  final int endTimeMs;

  factory Mp3QuranAyahTiming.fromJson(Map<String, dynamic> json) {
    return Mp3QuranAyahTiming(
      ayah: (json['ayah'] ?? 0) as int,
      startTimeMs: (json['start_time'] ?? 0) as int,
      endTimeMs: (json['end_time'] ?? 0) as int,
    );
  }
}

class Mp3QuranRecitationService {
  Mp3QuranRecitationService({http.Client? client})
    : _client = client ?? http.Client();

  static const _baseUrl = 'https://mp3quran.net/api/v3';
  final http.Client _client;
  final Map<String, List<Mp3QuranAyahTiming>> _timingsCache = {};

  Future<File> _timingsCacheFile({
    required int readId,
    required int surahNumber,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/mp3quran_timings');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/${readId}_$surahNumber.json');
  }

  Future<List<Mp3QuranAyahTiming>> fetchAyahTimings({
    required ReaderReciter reciter,
    required int surahNumber,
  }) async {
    final readId = reciter.mp3TimingReadId;
    if (readId == null) {
      throw Exception('القارئ المختار ليس من قراء MP3Quran.');
    }
    final cacheKey = '${readId}_$surahNumber';
    final cached = _timingsCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final cacheFile = await _timingsCacheFile(
      readId: readId,
      surahNumber: surahNumber,
    );
    if (await cacheFile.exists()) {
      try {
        final cachedBody = await cacheFile.readAsString();
        final decoded = jsonDecode(cachedBody) as List<dynamic>;
        final timings = decoded
            .map(
              (item) => Mp3QuranAyahTiming.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .where((item) => item.ayah > 0)
            .toList();
        if (timings.isNotEmpty) {
          _timingsCache[cacheKey] = timings;
          return timings;
        }
      } catch (_) {}
    }

    final uri = Uri.parse(
      '$_baseUrl/ayat_timing?surah=$surahNumber&read=$readId',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل توقيتات الآيات لهذا القارئ.');
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    final timings = decoded
        .map((item) => Mp3QuranAyahTiming.fromJson(item as Map<String, dynamic>))
        .where((item) => item.ayah > 0)
        .toList();
    try {
      await cacheFile.writeAsString(response.body);
    } catch (_) {}
    _timingsCache[cacheKey] = timings;
    return timings;
  }

  String buildSurahAudioUrl({
    required ReaderReciter reciter,
    required int surahNumber,
  }) {
    final folderUrl = reciter.mp3FolderUrl;
    if (folderUrl == null || folderUrl.isEmpty) {
      throw Exception('هذا القارئ لا يملك رابطًا صالحًا للتشغيل.');
    }
    final base = folderUrl.endsWith('/') ? folderUrl : '$folderUrl/';
    final surah = surahNumber.toString().padLeft(3, '0');
    return '$base$surah.mp3';
  }
}
