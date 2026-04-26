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
    );
    final next = _nextPrayer(
      now: now,
      todayTimes: todayTimes,
      city: city,
      prayerOffsets: store.savedPrayerOffsets,
    );

    final nextPrayerKey = _prayerKeyForName(next.$1);
    final hijriDate = _formatHijri(now);
    final nextPrayerTime = _formatTime(next.$2);
    final nextRemaining = _formatRemaining(next.$2.difference(now));
    final fajrTime = _formatTime(todayTimes.fajr.toLocal());
    final sunriseTime = _formatTime(todayTimes.sunrise.toLocal());
    final dhuhrTime = _formatTime(todayTimes.dhuhr.toLocal());
    final asrTime = _formatTime(todayTimes.asr.toLocal());
    final maghribTime = _formatTime(todayTimes.maghrib.toLocal());
    final ishaTime = _formatTime(todayTimes.isha.toLocal());
    final updatedAt = _formatUpdated(now);

    await prefs.setString('widget_prayer_city', city.name);
    await prefs.setString('widget_hijri_date', hijriDate);
    await prefs.setString('widget_next_prayer_key', nextPrayerKey);
    await prefs.setString('widget_next_prayer_name', next.$1);
    await prefs.setString('widget_next_prayer_time', nextPrayerTime);
    await prefs.setInt(
      'widget_next_prayer_epoch_ms',
      next.$2.millisecondsSinceEpoch,
    );
    await prefs.setString('widget_next_remaining', nextRemaining);
    await prefs.setString('widget_fajr_time', fajrTime);
    await prefs.setString('widget_sunrise_time', sunriseTime);
    await prefs.setString('widget_dhuhr_time', dhuhrTime);
    await prefs.setString('widget_asr_time', asrTime);
    await prefs.setString('widget_maghrib_time', maghribTime);
    await prefs.setString('widget_isha_time', ishaTime);
    await prefs.setString('widget_updated_at', updatedAt);

    try {
      await _channel.invokeMethod('refreshPrayerWidget', <String, Object?>{
        'city': city.name,
        'hijriDate': hijriDate,
        'nextPrayerKey': nextPrayerKey,
        'nextPrayerName': next.$1,
        'nextPrayerTime': nextPrayerTime,
        'nextPrayerEpochMs': next.$2.millisecondsSinceEpoch,
        'nextRemaining': nextRemaining,
        'fajrTime': fajrTime,
        'sunriseTime': sunriseTime,
        'dhuhrTime': dhuhrTime,
        'asrTime': asrTime,
        'maghribTime': maghribTime,
        'ishaTime': ishaTime,
        'updatedAt': updatedAt,
      });
    } catch (_) {}
  }

  PrayerTimes _buildPrayerTimes({
    required PrayerCity city,
    required DateTime date,
    required Map<String, int> prayerOffsets,
  }) {
    final params = city.method.parameters;
    params.adjustments = {
      Prayer.fajr: prayerOffsets['fajr'] ?? 0,
      Prayer.sunrise: prayerOffsets['sunrise'] ?? 0,
      Prayer.dhuhr: prayerOffsets['dhuhr'] ?? 0,
      Prayer.asr: prayerOffsets['asr'] ?? 0,
      Prayer.maghrib: prayerOffsets['maghrib'] ?? 0,
      Prayer.isha: prayerOffsets['isha'] ?? 0,
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
    HijriCalendar.setLocal('ar');
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
