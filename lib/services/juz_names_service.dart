import 'dart:convert';

import 'package:flutter/services.dart';

class JuzNamesService {
  JuzNamesService._();

  static const List<String> _fallbackNames = <String>[
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
  ];

  static List<String> _names = _fallbackNames;

  static Future<void> ensureLoaded() async {
    try {
      final raw = await rootBundle.loadString('assets/quran/juz_names.json');
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final rawNames = decoded['names'];
      if (rawNames is List) {
        final parsed = rawNames
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        if (parsed.length >= 30) {
          _names = parsed;
          return;
        }
      }

      final rawNumbers = decoded['numbers'];
      if (rawNumbers is List) {
        final parsed = rawNumbers
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        if (parsed.length >= 30) {
          _names = parsed;
        }
      }
    } catch (_) {
      // Keep fallback names if file is missing/invalid.
    }
  }

  static String nameFor(int juzNumber) {
    final index = juzNumber.clamp(1, _names.length) - 1;
    return _names[index];
  }

  static String labelFor(int juzNumber) => nameFor(juzNumber);
}
