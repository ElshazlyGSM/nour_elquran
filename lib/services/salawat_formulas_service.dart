import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/salawat_formulas.dart';
import 'salawat_formulas_config.dart';

class SalawatFormulasService {
  SalawatFormulasService._();

  static final SalawatFormulasService instance = SalawatFormulasService._();

  static const _prefsLastFetchKey = 'salawat_formulas_last_fetch';
  static const _prefsEtagKey = 'salawat_formulas_etag';
  static const _prefsLastModifiedKey = 'salawat_formulas_last_modified';
  static const _fileName = 'salawat_formulas.json';

  Future<List<SalawatFormula>> loadFormulas() async {
    await _ensureSeeded();
    final local = await _loadFromDisk();
    if (local.isNotEmpty) {
      unawaited(_refreshIfStale());
      return local;
    }
    unawaited(_refreshIfStale());
    return fallbackSalawatFormulas;
  }

  Future<SalawatFormulasRefreshResult> refreshNow() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final first = await _downloadAndCache(prefs, now, force: true);
    if (first != SalawatFormulasRefreshResult.failed) {
      return first;
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _downloadAndCache(prefs, now, force: true);
  }

  Future<void> refreshIfStaleBeforeOpen({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    await _ensureSeeded();
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt(_prefsLastFetchKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = Duration(milliseconds: now - lastMillis);
    if (elapsed < salawatFormulasRefreshInterval) {
      return;
    }
    try {
      await _downloadAndCache(prefs, now).timeout(timeout);
    } catch (_) {}
  }

  Future<void> _refreshIfStale() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt(_prefsLastFetchKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = Duration(milliseconds: now - lastMillis);
    if (elapsed < salawatFormulasRefreshInterval) {
      return;
    }
    await _downloadAndCache(prefs, now);
  }

  Future<void> _ensureSeeded() async {
    try {
      final file = await _resolveFile();
      if (await file.exists()) {
        return;
      }
      final raw = await rootBundle.loadString(salawatFormulasBundledAsset);
      if (raw.trim().isEmpty) {
        return;
      }
      final formulas = await _formulasFromRaw(raw);
      if (formulas.isEmpty) {
        return;
      }
      await file.writeAsString(raw, flush: true);
    } catch (_) {}
  }

  Future<SalawatFormulasRefreshResult> _downloadAndCache(
    SharedPreferences prefs,
    int nowMillis, {
    bool force = false,
  }) async {
    try {
      final uri = _buildUri(force: force);
      if (!force) {
        final headResult = await _headCheck(uri, prefs);
        if (headResult == SalawatFormulasRefreshResult.noChange) {
          await prefs.setInt(_prefsLastFetchKey, nowMillis);
          return SalawatFormulasRefreshResult.noChange;
        }
      }
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        return SalawatFormulasRefreshResult.failed;
      }
      final formulas = await _formulasFromRaw(response.body);
      if (formulas.isEmpty) {
        return SalawatFormulasRefreshResult.failed;
      }
      final changed = await _saveIfChanged(response.body);
      if (!changed) {
        await prefs.setInt(_prefsLastFetchKey, nowMillis);
        return SalawatFormulasRefreshResult.noChange;
      }
      await _saveToDisk(response.body);
      final etag = response.headers['etag'];
      final lastModified = response.headers['last-modified'];
      if (etag != null && etag.isNotEmpty) {
        await prefs.setString(_prefsEtagKey, etag);
      }
      if (lastModified != null && lastModified.isNotEmpty) {
        await prefs.setString(_prefsLastModifiedKey, lastModified);
      }
      await prefs.setInt(_prefsLastFetchKey, nowMillis);
      return SalawatFormulasRefreshResult.updated;
    } catch (_) {
      // Keep cached data if download fails.
      return SalawatFormulasRefreshResult.failed;
    }
  }

  Future<List<SalawatFormula>> _loadFromDisk() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const [];
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        return const [];
      }
      return _formulasFromRaw(contents);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveToDisk(String rawJson) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(rawJson, flush: true);
    } catch (_) {}
  }

  Future<bool> _saveIfChanged(String rawJson) async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return true;
      }
      final existing = await file.readAsString();
      return existing.trim() != rawJson.trim();
    } catch (_) {
      return true;
    }
  }

  Future<File> _resolveFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<SalawatFormula>> _formulasFromRaw(String raw) async {
    try {
      final parsed = await compute(_parseSalawatFormulasRaw, raw);
      return parsed
          .map(
            (entry) => SalawatFormula(
              title: entry['title'] ?? '',
              text: entry['text'] ?? '',
              note: entry['note'],
            ),
          )
          .where((formula) => formula.title.isNotEmpty && formula.text.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<SalawatFormulasRefreshResult?> _headCheck(
    Uri uri,
    SharedPreferences prefs,
  ) async {
    try {
      final response = await http.head(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final etag = response.headers['etag'];
      final lastModified = response.headers['last-modified'];
      final cachedEtag = prefs.getString(_prefsEtagKey);
      final cachedLastModified = prefs.getString(_prefsLastModifiedKey);
      if ((etag != null && etag.isNotEmpty && etag == cachedEtag) ||
          (lastModified != null &&
              lastModified.isNotEmpty &&
              lastModified == cachedLastModified)) {
        return SalawatFormulasRefreshResult.noChange;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Uri _buildUri({required bool force}) {
    final base = Uri.parse(salawatFormulasDownloadUrl);
    if (!force) {
      return base;
    }
    final query = Map<String, String>.from(base.queryParameters);
    query['ts'] = DateTime.now().millisecondsSinceEpoch.toString();
    return base.replace(queryParameters: query);
  }
}

enum SalawatFormulasRefreshResult { updated, noChange, failed }

List<Map<String, String?>> _parseSalawatFormulasRaw(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }
    final items = decoded['items'];
    if (items is! List) {
      return const [];
    }
    final results = <Map<String, String?>>[];
    for (final entry in items) {
      if (entry is! Map) {
        continue;
      }
      final title = entry['title']?.toString().trim() ?? '';
      final text = entry['text']?.toString().trim() ?? '';
      final note = entry['note']?.toString().trim();
      if (title.isEmpty || text.isEmpty) {
        continue;
      }
      results.add({'title': title, 'text': text, 'note': note});
    }
    return results;
  } catch (_) {
    return const [];
  }
}
