import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/utils/html_utils.dart';
import '../models/tafsir_option.dart';
import 'current_quran_text_source.dart';

class TafsirService {
  TafsirService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, String> _memoryCache = {};
  final Map<int, Map<String, String>> _downloadedCache = {};
  final Map<int, bool> _completionCache = {};
  static const _quranSource = currentQuranTextSource;

  static const Duration _requestTimeout = Duration(seconds: 20);

  Future<String> fetchTafsir({
    required TafsirOption option,
    required int surahNumber,
    required int verseNumber,
  }) async {
    final key = '${option.id}:$surahNumber:$verseNumber';
    final cached = _memoryCache[key];
    if (cached != null) {
      return cached;
    }

    final downloaded = await _loadDownloadedTafsir(option);
    final downloadedText = downloaded['$surahNumber:$verseNumber'];
    if (downloadedText != null) {
      _memoryCache[key] = downloadedText;
      return downloadedText;
    }

    try {
      final text = await _fetchRemoteTafsir(
        option: option,
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
      _memoryCache[key] = text;
      return text;
    } on SocketException {
      throw const TafsirUnavailableException();
    } on http.ClientException {
      throw const TafsirUnavailableException();
    } on HttpException {
      throw const TafsirUnavailableException();
    } on FormatException {
      throw const TafsirUnavailableException();
    }
  }

  Future<bool> isTafsirDownloaded(TafsirOption option) async {
    await _loadDownloadedTafsir(option);
    return _completionCache[option.id] ?? false;
  }

  Future<int> downloadedVerseCount(TafsirOption option) async {
    final data = await _loadDownloadedTafsir(option);
    return data.length;
  }

  int totalVersesCount() {
    return List<int>.generate(
      currentQuranTotalSurahCount,
      (index) => _quranSource.getVerseCount(index + 1),
    ).fold<int>(0, (sum, count) => sum + count);
  }

  Future<bool> downloadTafsir(
    TafsirOption option, {
    void Function(int completed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final existing = await _loadDownloadedTafsir(option);
    final downloaded = <String, String>{...existing};
    final total = List<int>.generate(
      currentQuranTotalSurahCount,
      (index) => _quranSource.getVerseCount(index + 1),
    ).fold<int>(0, (sum, count) => sum + count);

    var completed = downloaded.length;
    onProgress?.call(completed, total);

    for (var surah = 1; surah <= currentQuranTotalSurahCount; surah++) {
      if (shouldCancel?.call() ?? false) {
        await _saveDownloadedTafsir(option, downloaded, false);
        return false;
      }
      final verseCount = _quranSource.getVerseCount(surah);
      for (var verse = 1; verse <= verseCount; verse++) {
        if (shouldCancel?.call() ?? false) {
          await _saveDownloadedTafsir(option, downloaded, false);
          return false;
        }
        final verseKey = '$surah:$verse';
        if (downloaded.containsKey(verseKey)) {
          continue;
        }
        late final String text;
        try {
          text = await _fetchRemoteTafsir(
            option: option,
            surahNumber: surah,
            verseNumber: verse,
          );
        } on SocketException {
          await _saveDownloadedTafsir(option, downloaded, false);
          return false;
        } on http.ClientException {
          await _saveDownloadedTafsir(option, downloaded, false);
          return false;
        } on HttpException {
          await _saveDownloadedTafsir(option, downloaded, false);
          return false;
        } on FormatException {
          await _saveDownloadedTafsir(option, downloaded, false);
          return false;
        }
        downloaded[verseKey] = text;
        _memoryCache['${option.id}:$verseKey'] = text;
        completed++;
        if (completed % 25 == 0) {
          await _saveDownloadedTafsir(option, downloaded, false);
        }
        if (completed % 5 == 0 || completed == total) {
          onProgress?.call(completed, total);
        }
      }
    }

    await _saveDownloadedTafsir(option, downloaded, true);
    return true;
  }

  Future<Map<String, String>> _loadDownloadedTafsir(TafsirOption option) async {
    final cached = _downloadedCache[option.id];
    if (cached != null) {
      return cached;
    }

    final file = await _tafsirCacheFile(option.id);
    if (!await file.exists()) {
      final empty = <String, String>{};
      _downloadedCache[option.id] = empty;
      return empty;
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      final empty = <String, String>{};
      _downloadedCache[option.id] = empty;
      _completionCache[option.id] = false;
      return empty;
    }

    final json = jsonDecode(content) as Map<String, dynamic>;
    final loaded = <String, String>{};
    var complete = false;
    if (json.containsKey('items')) {
      final items = (json['items'] as Map<String, dynamic>? ?? {});
      loaded.addAll(
        items.map((key, value) => MapEntry(key, (value as String?) ?? '')),
      );
      complete = json['complete'] == true;
    } else {
      loaded.addAll(
        json.map((key, value) => MapEntry(key, (value as String?) ?? '')),
      );
      complete = loaded.length >= totalVersesCount();
    }
    _downloadedCache[option.id] = loaded;
    _completionCache[option.id] = complete;
    return loaded;
  }

  Future<void> _saveDownloadedTafsir(
    TafsirOption option,
    Map<String, String> data,
    bool complete,
  ) async {
    final file = await _tafsirCacheFile(option.id);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'complete': complete, 'items': data}));
    _downloadedCache[option.id] = Map<String, String>.from(data);
    _completionCache[option.id] = complete;
  }

  Future<File> _tafsirCacheFile(int optionId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tafsir_cache/tafsir_$optionId.json');
  }

  Future<String> _fetchRemoteTafsir({
    required TafsirOption option,
    required int surahNumber,
    required int verseNumber,
  }) async {
    final uri = Uri.parse(
      'https://api.quran.com/api/v4/tafsirs/${option.id}/by_ayah/$surahNumber:$verseNumber',
    );
    final response = await _client.get(uri).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load tafsir');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final tafsir = body['tafsir'] as Map<String, dynamic>;
    return stripHtmlTags((tafsir['text'] as String?) ?? '');
  }
}

class TafsirUnavailableException implements Exception {
  const TafsirUnavailableException();
}
