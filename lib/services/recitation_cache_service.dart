import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

import '../models/reader_reciter.dart';

class RecitationCacheService {
  const RecitationCacheService();

  Future<void> _ensureParentDirectory(File file) async {
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
  }

  Future<void> _finalizeTempDownload({
    required File tempFile,
    required File destination,
  }) async {
    await _ensureParentDirectory(destination);
    if (!await tempFile.exists()) {
      return;
    }
    if (await destination.exists()) {
      await destination.delete();
    }
    try {
      await tempFile.rename(destination.path);
      return;
    } on FileSystemException {
      await tempFile.copy(destination.path);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<Directory> _rootDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}${Platform.pathSeparator}recitations');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _reciterFolderName(quran.Reciter reciter) => reciter.name;

  Future<Directory> _reciterDirectory(quran.Reciter reciter) async {
    final root = await _rootDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}${_reciterFolderName(reciter)}',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _completionMarker(quran.Reciter reciter) async {
    final dir = await _reciterDirectory(reciter);
    return File('${dir.path}${Platform.pathSeparator}.complete');
  }

  Future<Directory> _surahDirectory({
    required quran.Reciter reciter,
    required int surahNumber,
  }) async {
    final root = await _rootDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}${_reciterFolderName(reciter)}${Platform.pathSeparator}surah_$surahNumber',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> verseFile({
    required quran.Reciter reciter,
    required int surahNumber,
    required int verseNumber,
  }) async {
    final dir = await _surahDirectory(reciter: reciter, surahNumber: surahNumber);
    return File('${dir.path}${Platform.pathSeparator}$verseNumber.mp3');
  }

  String _mp3QuranReciterFolderName(ReaderReciter reciter) =>
      reciter.id.replaceAll(':', '_');

  Future<Directory> _mp3QuranReciterDirectory(ReaderReciter reciter) async {
    final root = await _rootDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}${_mp3QuranReciterFolderName(reciter)}',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> mp3QuranSurahFile({
    required ReaderReciter reciter,
    required int surahNumber,
  }) async {
    final dir = await _mp3QuranReciterDirectory(reciter);
    final paddedSurah = surahNumber.toString().padLeft(3, '0');
    return File('${dir.path}${Platform.pathSeparator}$paddedSurah.mp3');
  }

  Future<String?> localPathForMp3QuranSurah({
    required ReaderReciter reciter,
    required int surahNumber,
  }) async {
    final file = await mp3QuranSurahFile(
      reciter: reciter,
      surahNumber: surahNumber,
    );
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    return null;
  }

  Future<int> countCachedSurahsForMp3QuranReciter(ReaderReciter reciter) async {
    final dir = await _mp3QuranReciterDirectory(reciter);
    if (!await dir.exists()) {
      return 0;
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.mp3'))
        .length;
  }

  Future<String?> localPathForVerse({
    required quran.Reciter reciter,
    required int surahNumber,
    required int verseNumber,
  }) async {
    final file = await verseFile(
      reciter: reciter,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
    );
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    return null;
  }

  Future<bool> isSurahCached({
    required quran.Reciter reciter,
    required int surahNumber,
    required int verseCount,
  }) async {
    for (var verseNumber = 1; verseNumber <= verseCount; verseNumber++) {
      final path = await localPathForVerse(
        reciter: reciter,
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
      if (path == null) {
        return false;
      }
    }
    return true;
  }

  Future<void> deleteSurah({
    required quran.Reciter reciter,
    required int surahNumber,
  }) async {
    final dir = await _surahDirectory(reciter: reciter, surahNumber: surahNumber);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    final marker = await _completionMarker(reciter);
    if (await marker.exists()) {
      await marker.delete();
    }
  }

  Future<void> deleteReciter(quran.Reciter reciter) async {
    final dir = await _reciterDirectory(reciter);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<int> countCachedVersesForReciter(quran.Reciter reciter) async {
    final dir = await _reciterDirectory(reciter);
    if (!await dir.exists()) {
      return 0;
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.mp3'))
        .length;
  }

  Future<bool> isReciterFullyCached({
    required quran.Reciter reciter,
    required int totalVerseCount,
  }) async {
    final marker = await _completionMarker(reciter);
    if (await marker.exists()) {
      return true;
    }
    return (await countCachedVersesForReciter(reciter)) >= totalVerseCount;
  }

  Future<void> cacheVerseIfMissing({
    required quran.Reciter reciter,
    required int surahNumber,
    required int verseNumber,
    required String url,
  }) async {
    final destination = await verseFile(
      reciter: reciter,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
    );
    await _ensureParentDirectory(destination);
    if (await destination.exists() && await destination.length() > 0) {
      return;
    }
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
      final tempFile = File('${destination.path}.part');
      await _ensureParentDirectory(tempFile);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      final sink = tempFile.openWrite();
      try {
        await response.stream.pipe(sink);
      } finally {
        await sink.flush();
        await sink.close();
      }
      await _finalizeTempDownload(tempFile: tempFile, destination: destination);
    } finally {
      client.close();
    }
  }

  Future<void> cacheMp3QuranSurahIfMissing({
    required ReaderReciter reciter,
    required int surahNumber,
    required String url,
  }) async {
    final destination = await mp3QuranSurahFile(
      reciter: reciter,
      surahNumber: surahNumber,
    );
    await _ensureParentDirectory(destination);
    if (await destination.exists() && await destination.length() > 0) {
      return;
    }
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
      final tempFile = File('${destination.path}.part');
      await _ensureParentDirectory(tempFile);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      final sink = tempFile.openWrite();
      try {
        await response.stream.pipe(sink);
      } finally {
        await sink.flush();
        await sink.close();
      }
      await _finalizeTempDownload(tempFile: tempFile, destination: destination);
    } finally {
      client.close();
    }
  }

  Future<void> downloadSurah({
    required quran.Reciter reciter,
    required int surahNumber,
    required int verseCount,
    required String Function(int verseNumber) urlBuilder,
    Future<void> Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final client = http.Client();
    try {
      var completed = 0;
      for (var verseNumber = 1; verseNumber <= verseCount; verseNumber++) {
        if (isCancelled?.call() ?? false) {
          break;
        }
        final destination = await verseFile(
          reciter: reciter,
          surahNumber: surahNumber,
          verseNumber: verseNumber,
        );
        await _ensureParentDirectory(destination);
        if (await destination.exists() && await destination.length() > 0) {
          completed++;
          if (onProgress != null) {
            await onProgress(completed / verseCount);
          }
          continue;
        }

        final request = http.Request('GET', Uri.parse(urlBuilder(verseNumber)));
        final response = await client.send(request);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw http.ClientException(
            'Failed to download verse $verseNumber',
            request.url,
          );
        }

        final tempFile = File('${destination.path}.part');
        await _ensureParentDirectory(tempFile);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        final sink = tempFile.openWrite();
        try {
          await response.stream.pipe(sink);
        } finally {
          await sink.flush();
          await sink.close();
        }
        await _finalizeTempDownload(tempFile: tempFile, destination: destination);
        completed++;
        if (onProgress != null) {
          await onProgress(completed / verseCount);
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> downloadReciter({
    required quran.Reciter reciter,
    required int totalSurahCount,
    required int Function(int surahNumber) verseCountResolver,
    required String Function(int surahNumber, int verseNumber) urlBuilder,
    Future<void> Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final totalVerseCount = List<int>.generate(
      totalSurahCount,
      (index) => verseCountResolver(index + 1),
    ).fold<int>(0, (sum, count) => sum + count);
    var completed = await countCachedVersesForReciter(reciter);
    if (onProgress != null && totalVerseCount > 0) {
      await onProgress((completed / totalVerseCount).clamp(0.0, 1.0));
    }
    for (var surahNumber = 1; surahNumber <= totalSurahCount; surahNumber++) {
      if (isCancelled?.call() ?? false) {
        break;
      }
      final verseCount = verseCountResolver(surahNumber);
      await downloadSurah(
        reciter: reciter,
        surahNumber: surahNumber,
        verseCount: verseCount,
        urlBuilder: (verseNumber) => urlBuilder(surahNumber, verseNumber),
        onProgress: (_) async {
          final current = await countCachedVersesForReciter(reciter);
          completed = current > completed ? current : completed;
          if (onProgress != null && totalVerseCount > 0) {
            await onProgress((completed / totalVerseCount).clamp(0.0, 1.0));
          }
        },
        isCancelled: isCancelled,
      );
      completed = await countCachedVersesForReciter(reciter);
      if (onProgress != null && totalVerseCount > 0) {
        await onProgress((completed / totalVerseCount).clamp(0.0, 1.0));
      }
    }

    if (!(isCancelled?.call() ?? false) && completed >= totalVerseCount) {
      final marker = await _completionMarker(reciter);
      if (!await marker.exists()) {
        await marker.writeAsString('complete');
      }
    }
  }
}
