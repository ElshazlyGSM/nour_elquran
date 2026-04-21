import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AdhanAudioCacheService {
  AdhanAudioCacheService._();

  static final AdhanAudioCacheService instance = AdhanAudioCacheService._();
  static const MethodChannel _channel = MethodChannel(
    'com.elshazly.noorquran/adhan_audio',
  );

  static const Map<String, _AdhanAudioSource> _sources = {
    'nsr_elden': _AdhanAudioSource(
      fileName: 'azan-nsr-elden.mp3',
      urls: [
        'https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/azan-nsr-elden.mp3',
      ],
    ),
    'egypt': _AdhanAudioSource(
      fileName: 'abdelbast.ogg',
      urls: [
        'https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/abdelbast.ogg',
        'https://storage.googleapis.com/nour-quran/abdelbast.ogg',
      ],
    ),
    'mnshawy': _AdhanAudioSource(
      fileName: 'azan-elmnshawy.mp3',
      urls: [
        'https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/azan-elmnshawy.mp3',
      ],
    ),
    'mowahd': _AdhanAudioSource(
      fileName: 'azan-mowahd.mp3',
      urls: [
        'https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/azan-mowahd.mp3',
      ],
    ),
    'haram': _AdhanAudioSource(
      fileName: 'harm.ogg',
      urls: [
        'https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/harm.ogg',
        'https://storage.googleapis.com/nour-quran/harm.ogg',
      ],
    ),
    'soft': _AdhanAudioSource(
      fileName: 'mashary.ogg',
      urls: [
        'https://huggingface.co/datasets/HaoElshazly/quran_data/resolve/main/mashary.ogg',
        'https://storage.googleapis.com/nour-quran/mashary.ogg',
      ],
    ),
  };

  static const List<String> _globalMirrors = <String>[
    'https://raw.githubusercontent.com/ElshazlyGSM/mushaf-pages/main/adhan_audio/{file}',
    'https://cdn.jsdelivr.net/gh/ElshazlyGSM/mushaf-pages@main/adhan_audio/{file}',
    'https://storage.googleapis.com/nour-quran/{file}',
    // Optional extra mirrors: if the main package host is down, try MP3Quran.
    'https://server8.mp3quran.net/adhan/{file}',
    'https://server7.mp3quran.net/adhan/{file}',
  ];

  bool supportsProfile(String profile) => _sources.containsKey(profile);

  Future<Directory> _rootDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(
      '${baseDir.path}${Platform.pathSeparator}adhan_audio',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File?> fileForProfile(String profile) async {
    final source = _sources[profile];
    if (source == null) {
      return null;
    }
    final root = await _rootDirectory();
    return File('${root.path}${Platform.pathSeparator}${source.fileName}');
  }

  Future<bool> isDownloaded(String profile) async {
    final file = await fileForProfile(profile);
    if (file == null) {
      return false;
    }
    return await file.exists() && await file.length() > 0;
  }

  Future<String?> localPathForProfile(String profile) async {
    final file = await fileForProfile(profile);
    if (file == null) {
      return null;
    }
    if (!await file.exists() || await file.length() == 0) {
      return null;
    }
    return file.path;
  }

  Future<String?> localUriForProfile(String profile) async {
    if (!Platform.isAndroid) {
      return null;
    }
    final file = await fileForProfile(profile);
    if (file == null) {
      return null;
    }
    if (!await file.exists() || await file.length() == 0) {
      return null;
    }
    final source = _sources[profile];
    if (source == null) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>('registerNotificationSound', {
        'filePath': file.path,
        'fileName': source.fileName,
      });
    } on PlatformException {
      return null;
    }
  }

  Future<void> downloadProfile({
    required String profile,
    Future<void> Function(double progress)? onProgress,
  }) async {
    final source = _sources[profile];
    final destination = await fileForProfile(profile);
    if (source == null || destination == null) {
      throw ArgumentError.value(
        profile,
        'profile',
        'Unsupported adhan profile',
      );
    }

    http.ClientException? lastError;
    for (final url in _candidateUrlsFor(source)) {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastError = http.ClientException(
            'Failed to download adhan audio for $profile',
            request.url,
          );
          continue;
        }

        final contentType = response.headers['content-type']?.toLowerCase();
        if (contentType != null &&
            (contentType.contains('text/html') ||
                contentType.contains('application/json') ||
                contentType.contains('text/plain'))) {
          lastError = http.ClientException(
            'Invalid audio content type for $profile: $contentType',
            request.url,
          );
          continue;
        }

        final tempFile = File('${destination.path}.part');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        final totalBytes = response.contentLength ?? 0;
        var receivedBytes = 0;
        final sink = tempFile.openWrite();
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (onProgress != null && totalBytes > 0) {
              await onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
            }
          }
        } finally {
          await sink.flush();
          await sink.close();
        }

        final expectedExtension = _fileExtension(source.fileName);
        final validAudio = await _looksLikeValidAudio(
          tempFile,
          expectedExtension: expectedExtension,
        );
        if (!validAudio) {
          try {
            await tempFile.delete();
          } catch (_) {}
          lastError = http.ClientException(
            'Downloaded file is not a valid audio stream for $profile',
            request.url,
          );
          continue;
        }

        if (await destination.exists()) {
          await destination.delete();
        }
        await tempFile.rename(destination.path);
        if (onProgress != null) {
          await onProgress(1.0);
        }
        return;
      } on http.ClientException catch (error) {
        lastError = error;
      } on TimeoutException {
        lastError = http.ClientException(
          'Timed out downloading adhan audio for $profile',
          Uri.parse(url),
        );
      } finally {
        client.close();
      }
    }

    throw lastError ??
        http.ClientException('Failed to download adhan audio for $profile');
  }

  Iterable<String> _candidateUrlsFor(_AdhanAudioSource source) sync* {
    final seen = <String>{};
    for (final url in source.urls) {
      if (seen.add(url)) {
        yield url;
      }
    }
    for (final mirror in _globalMirrors) {
      final url = mirror.replaceAll('{file}', source.fileName);
      if (seen.add(url)) {
        yield url;
      }
    }
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  Future<bool> _looksLikeValidAudio(
    File file, {
    required String expectedExtension,
  }) async {
    if (!await file.exists()) {
      return false;
    }
    final length = await file.length();
    if (length < 2048) {
      return false;
    }

    final sampleLength = length < 16 ? length : 16;
    final sampleBuilder = await file.openRead(0, sampleLength).fold<BytesBuilder>(
      BytesBuilder(),
      (builder, data) => builder..add(data),
    );
    final bytes = sampleBuilder.takeBytes();
    if (bytes.isEmpty) {
      return false;
    }
    if (_looksLikeHtmlOrJson(bytes)) {
      return false;
    }
    if (expectedExtension == 'ogg') {
      return _isOgg(bytes);
    }
    if (expectedExtension == 'mp3') {
      return _isMp3(bytes);
    }
    return _isOgg(bytes) || _isMp3(bytes);
  }

  bool _looksLikeHtmlOrJson(Uint8List bytes) {
    final text = String.fromCharCodes(bytes).trimLeft().toLowerCase();
    return text.startsWith('<!doctype') ||
        text.startsWith('<html') ||
        text.startsWith('{') ||
        text.startsWith('[');
  }

  bool _isOgg(Uint8List bytes) {
    if (bytes.length < 4) {
      return false;
    }
    return bytes[0] == 0x4F &&
        bytes[1] == 0x67 &&
        bytes[2] == 0x67 &&
        bytes[3] == 0x53;
  }

  bool _isMp3(Uint8List bytes) {
    if (bytes.length < 3) {
      return false;
    }
    final hasId3 = bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33;
    if (hasId3) {
      return true;
    }
    if (bytes.length < 2) {
      return false;
    }
    return bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
  }
}

class _AdhanAudioSource {
  const _AdhanAudioSource({required this.fileName, required this.urls});

  final String fileName;
  final List<String> urls;
}
