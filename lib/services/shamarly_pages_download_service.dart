import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'shamarly_pages_download_config.dart';

class ShamarlyPagesDownloadService {
  const ShamarlyPagesDownloadService();

  static const String _completionMarkerName = '.shamarly_pages_complete';

  Future<Directory?> _baseDirectory() async {
    if (kIsWeb) {
      return null;
    }
    return getApplicationDocumentsDirectory();
  }

  Future<Directory?> _pagesDirectory() async {
    final base = await _baseDirectory();
    if (base == null) {
      return null;
    }
    final dir = Directory(
      path.join(base.path, ShamarlyPagesDownloadConfig.localFolderName),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File?> _zipFile() async {
    final base = await _baseDirectory();
    if (base == null) {
      return null;
    }
    return File(path.join(base.path, ShamarlyPagesDownloadConfig.zipFileName));
  }

  Future<File?> _completionMarker() async {
    final dir = await _pagesDirectory();
    if (dir == null) {
      return null;
    }
    return File(path.join(dir.path, _completionMarkerName));
  }

  String pageFileName(int pageNumber) {
    final padded =
        pageNumber.toString().padLeft(ShamarlyPagesDownloadConfig.filePadding, '0');
    return '${ShamarlyPagesDownloadConfig.filePrefix}$padded'
        '${ShamarlyPagesDownloadConfig.fileExtension}';
  }

  Future<String?> pagesDirectoryPath() async {
    final dir = await _pagesDirectory();
    return dir?.path;
  }

  Future<bool> isReady() async {
    if (kIsWeb) {
      return false;
    }
    final marker = await _completionMarker();
    if (marker != null && marker.existsSync()) {
      return true;
    }
    final count = await countExtractedPages();
    return count >= ShamarlyPagesDownloadConfig.totalPages;
  }

  Future<int> countExtractedPages() async {
    final dir = await _pagesDirectory();
    if (dir == null || !dir.existsSync()) {
      return 0;
    }
    return dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.jpg'))
        .length;
  }

  Future<void> downloadAndExtract({
    required void Function(double progress) onProgress,
    void Function(String message)? onStatus,
    bool Function()? shouldCancel,
  }) async {
    if (kIsWeb) {
      throw Exception('تعذر الوصول إلى تخزين الجهاز.');
    }
    if (ShamarlyPagesDownloadConfig.zipUrls.isEmpty) {
      throw Exception('تعذر الوصول إلى تخزين الجهاز.');
    }

    final zipFile = await _zipFile();
    if (zipFile == null) {
      throw Exception('تعذر الوصول إلى تخزين الجهاز.');
    }

    final tempFile = File('${zipFile.path}.part');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final errors = <String>[];
    for (var index = 0; index < ShamarlyPagesDownloadConfig.zipUrls.length; index++) {
      final url = ShamarlyPagesDownloadConfig.zipUrls[index];
      try {
        onProgress(0);
        onStatus?.call('جارٍ تنزيل ملف الشمرلي...');
        await _downloadZipFromUrl(
          url: url,
          zipFile: zipFile,
          tempFile: tempFile,
          onProgress: onProgress,
          shouldCancel: shouldCancel,
        );

        onStatus?.call('جاري فك الضغط...');
        await _extractZip(zipFile, shouldCancel: shouldCancel);

        final marker = await _completionMarker();
        await marker?.writeAsString('ok', flush: true);
        onProgress(1);
        onStatus?.call('تم تحميل مصحف الشمرلي بنجاح.');
        return;
      } catch (error) {
        errors.add('$url -> $error');
        if (kDebugMode) {
          debugPrint('[ShamarlyDownload] Source failed: $url -> $error');
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

    throw Exception('تعذر الوصول إلى تخزين الجهاز.');
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
      final request = http.Request('GET', Uri.parse(url));
      if (existingBytes > 0) {
        request.headers['Range'] = 'bytes=$existingBytes-';
      }
      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('تعذر الوصول إلى تخزين الجهاز.');
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

  Future<void> _extractZip(File zipFile, {bool Function()? shouldCancel}) async {
    final pagesDir = await _pagesDirectory();
    if (pagesDir == null) {
      throw Exception('تعذر الوصول إلى تخزين الجهاز.');
    }
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive.files) {
      if (shouldCancel != null && shouldCancel()) {
        return;
      }
      if (!entry.isFile) {
        continue;
      }
      final fileName = path.basename(entry.name);
      if (!fileName.toLowerCase().endsWith('.jpg')) {
        continue;
      }
      final file = File(path.join(pagesDir.path, fileName));
      await file.writeAsBytes(entry.content as List<int>, flush: true);
    }
  }
}
