import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/arabic_numbers.dart';
import '../data/egypt_prayer_cities.dart';
import 'quran_store.dart';

class PrayerTimesWidgetService {
  PrayerTimesWidgetService._();

  static final PrayerTimesWidgetService instance = PrayerTimesWidgetService._();

  static const MethodChannel _channel = MethodChannel(
    'com.elshazly.noorquran/widget',
  );

  static const _prayerNames = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  Future<void> updateFromStore(QuranStore store) async {
    final prefs = await SharedPreferences.getInstance();
    final city = resolvePrayerCityByName(store.savedPrayerCityName);
    final now = DateTime.now();

    final todayTimes = _buildPrayerTimes(
      city: city,
      date: now,
      prayerOffsets: store.savedPrayerOffsets,
      summerTimeEnabled: store.savedPrayerSummerTimeEnabled,
    );
    final next = _nextPrayer(
      now: now,
      todayTimes: todayTimes,
      city: city,
      prayerOffsets: store.savedPrayerOffsets,
      summerTimeEnabled: store.savedPrayerSummerTimeEnabled,
    );

    await prefs.setString('widget_prayer_city', city.name);
    await prefs.setString('widget_hijri_date', _formatHijri(now));
    await prefs.setString('widget_next_prayer_key', _prayerKeyForName(next.$1));
    await prefs.setString('widget_next_prayer_name', next.$1);
    await prefs.setString('widget_next_prayer_time', _formatTime(next.$2));
    await prefs.setInt(
      'widget_next_prayer_epoch_ms',
      next.$2.millisecondsSinceEpoch,
    );
    await prefs.setString(
      'widget_next_remaining',
      _formatRemaining(next.$2.difference(now)),
    );
    await prefs.setString('widget_fajr_time', _formatTime(todayTimes.fajr.toLocal()));
    await prefs.setString('widget_sunrise_time', _formatTime(todayTimes.sunrise.toLocal()));
    await prefs.setString('widget_dhuhr_time', _formatTime(todayTimes.dhuhr.toLocal()));
    await prefs.setString('widget_asr_time', _formatTime(todayTimes.asr.toLocal()));
    await prefs.setString('widget_maghrib_time', _formatTime(todayTimes.maghrib.toLocal()));
    await prefs.setString('widget_isha_time', _formatTime(todayTimes.isha.toLocal()));
    await prefs.setString('widget_updated_at', _formatUpdated(now));

    try {
      await _channel.invokeMethod('refreshPrayerWidget');
    } catch (_) {}
  }

  PrayerTimes _buildPrayerTimes({
    required PrayerCity city,
    required DateTime date,
    required Map<String, int> prayerOffsets,
    required bool summerTimeEnabled,
  }) {
    final params = city.method.parameters;
    final summerOffset = summerTimeEnabled ? 60 : 0;
    params.adjustments = {
      Prayer.fajr: (prayerOffsets['fajr'] ?? 0) + summerOffset,
      Prayer.sunrise: (prayerOffsets['sunrise'] ?? 0) + summerOffset,
      Prayer.dhuhr: (prayerOffsets['dhuhr'] ?? 0) + summerOffset,
      Prayer.asr: (prayerOffsets['asr'] ?? 0) + summerOffset,
      Prayer.maghrib: (prayerOffsets['maghrib'] ?? 0) + summerOffset,
      Prayer.isha: (prayerOffsets['isha'] ?? 0) + summerOffset,
    };
    return PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: city.coordinates,
      calculationParameters: params,
    );
  }

  (String, DateTime) _nextPrayer({
    required DateTime now,
    required PrayerTimes todayTimes,
    required PrayerCity city,
    required Map<String, int> prayerOffsets,
    required bool summerTimeEnabled,
  }) {
    final entries = <(String, DateTime)>[
      (_prayerNames['fajr']!, todayTimes.fajr.toLocal()),
      (_prayerNames['dhuhr']!, todayTimes.dhuhr.toLocal()),
      (_prayerNames['asr']!, todayTimes.asr.toLocal()),
      (_prayerNames['maghrib']!, todayTimes.maghrib.toLocal()),
      (_prayerNames['isha']!, todayTimes.isha.toLocal()),
    ];
    for (final entry in entries) {
      if (entry.$2.isAfter(now)) {
        return entry;
      }
    }
    final tomorrow = _buildPrayerTimes(
      city: city,
      date: now.add(const Duration(days: 1)),
      prayerOffsets: prayerOffsets,
      summerTimeEnabled: summerTimeEnabled,
    );
    return (_prayerNames['fajr']!, tomorrow.fajr.toLocal());
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'م' : 'ص';
    return '${toArabicNumber(hour)}:${_toArabicDigits(minute)} $suffix';
  }

  String _formatUpdated(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    return '${toArabicNumber(value.hour)}:${_toArabicDigits(minute)}';
  }

  String _formatHijri(DateTime date) {
    final hijri = HijriCalendar.fromDate(date);
    return '${toArabicNumber(hijri.hDay)} ${hijri.longMonthName} ${toArabicNumber(hijri.hYear)}';
  }

  String _formatRemaining(Duration duration) {
    if (duration.isNegative) {
      return '٠٠:٠٠:٠٠';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${_toArabicDigits(hours.toString().padLeft(2, '0'))}:${_toArabicDigits(minutes.toString().padLeft(2, '0'))}:${_toArabicDigits(seconds.toString().padLeft(2, '0'))}';
  }

  String _prayerKeyForName(String name) {
    for (final entry in _prayerNames.entries) {
      if (entry.value == name) {
        return entry.key;
      }
    }
    return 'fajr';
  }

  String _toArabicDigits(String value) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      final index = western.indexOf(char);
      buffer.write(index == -1 ? char : eastern[index]);
    }
    return buffer.toString();
  }
}
