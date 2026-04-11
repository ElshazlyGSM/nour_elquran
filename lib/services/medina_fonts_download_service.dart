import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'medina_fonts_download_config.dart';

class MedinaFontsDownloadService {
  const MedinaFontsDownloadService();

  static const String _cacheFolderName = 'quran_fonts_cache';
  static const String _completionMarkerName = '.medina_fonts_complete';
  static const String _zipPartSuffix = '.part';

  Future<Directory?> _cacheDirectory() async {
    if (kIsWeb) {
      return null;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}${Platform.pathSeparator}$_cacheFolderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File?> _zipFile() async {
    final dir = await _cacheDirectory();
    if (dir == null) {
      return null;
    }
    return File(
      '${dir.path}${Platform.pathSeparator}${MedinaFontsDownloadConfig.zipFileName}',
    );
  }

  Future<File?> _pageFontFile(int page) async {
    final dir = await _cacheDirectory();
    if (dir == null) {
      return null;
    }
    return File('${dir.path}${Platform.pathSeparator}page$page.ttf');
  }

  Future<File?> _completionMarker() async {
    final dir = await _cacheDirectory();
    if (dir == null) {
      return null;
    }
    return File('${dir.path}${Platform.pathSeparator}$_completionMarkerName');
  }

  Future<int> countDownloadedPages() async {
    final dir = await _cacheDirectory();
    if (dir == null || !dir.existsSync()) {
      return 0;
    }
    return dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.ttf'))
        .length;
  }

  Future<bool> isFullyDownloaded() async {
    if (kIsWeb) {
      return false;
    }
    final marker = await _completionMarker();
    if (marker != null && marker.existsSync()) {
      final count = await countDownloadedPages();
      if (count >= MedinaFontsDownloadConfig.totalPages) {
        return true;
      }
      try {
        await marker.delete();
      } catch (_) {}
    }
    return (await countDownloadedPages()) >=
        MedinaFontsDownloadConfig.totalPages;
  }

  Future<void> downloadAll({
    required void Function(double progress) onProgress,
    void Function(String message)? onStatus,
    bool Function()? shouldCancel,
  }) async {
    if (kIsWeb) {
      throw Exception('Medina fonts download is not supported on web.');
    }
    if (MedinaFontsDownloadConfig.zipUrls.isEmpty) {
      throw Exception('Medina fonts ZIP URLs are not configured.');
    }
    if (await isFullyDownloaded()) {
      onProgress(1);
      onStatus?.call('تم تجهيز صفحات مصحف المدينة بالفعل.');
      return;
    }
    final cacheDir = await _cacheDirectory();
    if (cacheDir == null) {
      throw Exception('Unable to access cache directory.');
    }
    if (kDebugMode) {
      debugPrint(
        '[MedinaDownload] Starting download from ${MedinaFontsDownloadConfig.zipUrls.join(', ')}',
      );
      debugPrint('[MedinaDownload] Cache dir: ${cacheDir.path}');
    }
    try {
      final existing = cacheDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.ttf'));
      if (kDebugMode) {
        debugPrint('[MedinaDownload] Clearing ${existing.length} cached pages');
      }
      for (final file in existing) {
        await file.delete();
      }
      final marker = await _completionMarker();
      if (marker != null && marker.existsSync()) {
        await marker.delete();
      }
    } catch (_) {}

    final zipFile = await _zipFile();
    if (zipFile == null) {
      throw Exception('Unable to access storage.');
    }
    final tempFile = File('${zipFile.path}$_zipPartSuffix');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final errors = <String>[];
    for (var index = 0; index < MedinaFontsDownloadConfig.zipUrls.length; index++) {
      final url = MedinaFontsDownloadConfig.zipUrls[index];
      try {
        onProgress(0);
        onStatus?.call('جاري تنزيل ملف مصحف المدينة...');
        await _downloadZipFromUrl(
          url: url,
          zipFile: zipFile,
          tempFile: tempFile,
          onProgress: onProgress,
          shouldCancel: shouldCancel,
        );

        onStatus?.call('جاري فك الضغط...');
        final extracted = await _extractZip(zipFile, shouldCancel: shouldCancel);
        if (kDebugMode) {
          debugPrint('[MedinaDownload] Extracted pages: $extracted from $url');
        }
        final downloaded = await countDownloadedPages();
        if (kDebugMode) {
          debugPrint('[MedinaDownload] Cached pages after extract: $downloaded');
        }
        if (downloaded >= MedinaFontsDownloadConfig.totalPages) {
          final marker = await _completionMarker();
          await marker?.writeAsString('ok', flush: true);
          onProgress(1);
          onStatus?.call('تم تحميل مصحف المدينة بنجاح.');
          return;
        }
        throw Exception('Incomplete extraction: $downloaded pages.');
      } catch (error) {
        errors.add('$url -> $error');
        if (kDebugMode) {
          debugPrint('[MedinaDownload] Source failed: $url -> $error');
        }
        if (shouldCancel != null && shouldCancel()) {
          return;
        }
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
      }
    }

    throw Exception('فشل تنزيل مصحف المدينة من كل المصادر: ');
  }

  Future<void> _downloadZipFromUrl({
    required String url,
    required File zipFile,
    required File tempFile,
    required void Function(double progress) onProgress,
    bool Function()? shouldCancel,
  }) async {
    final client = http.Client();
    try {
      var existingBytes = 0;
      if (await tempFile.exists()) {
        existingBytes = await tempFile.length();
      }
      if (kDebugMode) {
        debugPrint('[MedinaDownload] Downloading from $url');
        debugPrint('[MedinaDownload] Existing temp bytes: $existingBytes');
      }
      final request = http.Request('GET', Uri.parse(url));
      if (existingBytes > 0) {
        request.headers['Range'] = 'bytes=$existingBytes-';
      }
      final response = await client.send(request);
      if (kDebugMode) {
        debugPrint(
          '[MedinaDownload] Response status: ${response.statusCode}, length=${response.contentLength}',
        );
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Download failed (${response.statusCode}).');
      }
      if (response.statusCode == 200 && existingBytes > 0) {
        existingBytes = 0;
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
      final totalBytes = response.contentLength ?? 0;
      var received = existingBytes;
      final sink = tempFile.openWrite(
        mode: existingBytes > 0 ? FileMode.append : FileMode.write,
      );
      await for (final chunk in response.stream) {
        if (shouldCancel != null && shouldCancel()) {
          await sink.close();
          return;
        }
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          final fullSize =
              response.statusCode == 206 ? totalBytes + existingBytes : totalBytes;
          if (fullSize > 0) {
            onProgress(received / fullSize);
          }
        }
      }
      await sink.flush();
      await sink.close();
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
      await tempFile.rename(zipFile.path);
    } finally {
      client.close();
    }
  }

  Future<void> deleteAll() async {
    final dir = await _cacheDirectory();
    if (dir == null) {
      return;
    }
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  Future<int> _extractZip(File zipFile, {bool Function()? shouldCancel}) async {
    final cacheDir = await _cacheDirectory();
    if (cacheDir == null) {
      throw Exception('Unable to access cache directory.');
    }
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    var extracted = 0;
    for (final entry in archive.files) {
      if (shouldCancel != null && shouldCancel()) {
        return extracted;
      }
      if (!entry.isFile) {
        continue;
      }
      final name = entry.name;
      final isTtf = name.toLowerCase().endsWith('.ttf');
      final isGz = name.toLowerCase().endsWith('.ttf.gz');
      if (!isTtf && !isGz) {
        continue;
      }
      final matches = RegExp(r'(\d{1,4})').allMatches(name).toList();
      if (matches.isEmpty) {
        continue;
      }
      final match = matches.last;
      final pageNumber = int.tryParse(match.group(1) ?? '');
      if (pageNumber == null ||
          pageNumber < 1 ||
          pageNumber > MedinaFontsDownloadConfig.totalPages) {
        continue;
      }
      final file = await _pageFontFile(pageNumber);
      if (file == null) {
        continue;
      }
      final raw = entry.content as List<int>;
      final data = isGz
          ? Uint8List.fromList(const GZipDecoder().decodeBytes(raw))
          : Uint8List.fromList(raw);
      final temp = File('${file.path}.part');
      await temp.writeAsBytes(data, flush: true);
      await _finalizeTempDownload(tempFile: temp, destination: file);
      extracted++;
    }
    return extracted;
  }

  Future<void> _finalizeTempDownload({
    required File tempFile,
    required File destination,
  }) async {
    final parent = destination.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
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
}




