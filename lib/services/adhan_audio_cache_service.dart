import 'dart:io';

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

  bool supportsProfile(String profile) => _sources.containsKey(profile);

  Future<Directory> _rootDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}${Platform.pathSeparator}adhan_audio');
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
      throw ArgumentError.value(profile, 'profile', 'Unsupported adhan profile');
    }

    http.ClientException? lastError;
    for (final url in source.urls) {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response = await client.send(request);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastError = http.ClientException(
            'Failed to download adhan audio for $profile',
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
      } finally {
        client.close();
      }
    }

    throw lastError ?? http.ClientException('Failed to download adhan audio for $profile');
  }
}

class _AdhanAudioSource {
  const _AdhanAudioSource({
    required this.fileName,
    required this.urls,
  });

  final String fileName;
  final List<String> urls;
}


