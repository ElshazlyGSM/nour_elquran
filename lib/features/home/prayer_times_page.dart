import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../data/egypt_prayer_cities.dart';
import '../notifications/adhan/adhan_notification_settings_page.dart';
import '../notifications/adhan/prayer_notification_service.dart';
import '../../services/location_permission_prompt.dart';
import '../../services/quran_store.dart';
import 'qibla_compass_page.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key, this.store});

  final QuranStore? store;

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  static const _prayerKeys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static const _prayerNames = {
    'fajr': '\u0627\u0644\u0641\u062c\u0631',
    'sunrise': '\u0627\u0644\u0634\u0631\u0648\u0642',
    'dhuhr': '\u0627\u0644\u0638\u0647\u0631',
    'asr': '\u0627\u0644\u0639\u0635\u0631',
    'maghrib': '\u0627\u0644\u0645\u063a\u0631\u0628',
    'isha': '\u0627\u0644\u0639\u0634\u0627\u0621',
  };

  static const _adhanProfiles = [
    ('default', 'نغمة النظام'),
    ('allah_akbar', 'الله أكبر'),
    ('__full_adhans__', 'أذانات كاملة'),
    ('nsr_elden', 'نصر الدين طوبار'),
    ('egypt', 'عبد الباسط'),
    ('mnshawy', 'المنشاوي'),
    ('mowahd', 'أذان مصر الموحد'),
    ('haram', 'أذان الحرم'),
    ('soft', 'مشاري'),
  ];

  late PrayerCity _selectedCity;
  late bool _autoDetectLocation;
  late bool _adhanEnabled;
  late int _hijriOffset;
  late Map<String, int> _prayerOffsets;
  late Map<String, bool> _prayerEnabledMap;
  late Map<String, int> _prayerReminderByPrayer;
  late String _adhanProfile;

  Timer? _countdownTimer;
  DateTime _now = DateTime.now();
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    _selectedCity = _resolveSavedCity();
    _autoDetectLocation = widget.store?.savedPrayerAutoDetect ?? true;
    _adhanEnabled = widget.store?.savedPrayerAdhanEnabled ?? false;
    _hijriOffset = widget.store?.savedPrayerHijriOffset ?? 0;
    _prayerOffsets = Map<String, int>.from(
      widget.store?.savedPrayerOffsets ??
          const {
            'fajr': 0,
            'sunrise': 0,
            'dhuhr': 0,
            'asr': 0,
            'maghrib': 0,
            'isha': 0,
          },
    );
    _prayerEnabledMap = Map<String, bool>.from(
      widget.store?.savedPrayerEnabledMap ??
          const {
            'fajr': true,
            'sunrise': true,
            'dhuhr': true,
            'asr': true,
            'maghrib': true,
            'isha': true,
          },
    );
    _prayerReminderByPrayer = Map<String, int>.from(
      widget.store?.savedPrayerReminderByPrayer ??
          const {
            'fajr': 0,
            'sunrise': 0,
            'dhuhr': 0,
            'asr': 0,
            'maghrib': 0,
            'isha': 0,
          },
    );
    _adhanProfile = widget.store?.savedPrayerAdhanProfile ?? 'default';

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await _rescheduleNotifications();
      if (!mounted) {
        return;
      }
      if (_autoDetectLocation) {
        unawaited(_detectCityFromLocation(showErrors: false));
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  PrayerCity _resolveSavedCity() {
    final savedName = widget.store?.savedPrayerCityName;
    return resolvePrayerCityByName(savedName);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final rawTextScale = mediaQuery.textScaler.scale(16) / 16;
    final clampedTextScale = rawTextScale.clamp(1.0, 1.10);
    final compactHeaderLayout =
        mediaQuery.size.width < 430 || rawTextScale > 1.12;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark
        ? const Color(0xFF101A1E)
        : const Color(0xFF143A2A);
    final prayerTimes = _buildPrayerTimes(_now);
    final entries = _buildEntries(prayerTimes);
    final nextPrayer = _buildUpcomingPrayer();
    final hasAnyEnabledAdhan =
        _adhanEnabled && _prayerEnabledMap.values.any((enabled) => enabled);

    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar.fromDate(
      DateTime(
        _now.year,
        _now.month,
        _now.day,
      ).add(Duration(days: _hijriOffset)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0645\u0648\u0627\u0639\u064a\u062f \u0627\u0644\u0635\u0644\u0627\u0629',
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Directionality(
                    textDirection: TextDirection.rtl,
                    child: QiblaCompassPage(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.explore_rounded),
          ),
          IconButton(
            onPressed: _showPrayerSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(clampedTextScale),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u0627\u0644\u0635\u0644\u0627\u0629 \u0627\u0644\u0642\u0627\u062f\u0645\u0629',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Text(
                        nextPrayer.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE6C16A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _formatTime(nextPrayer.time),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (_formatReminderShort(nextPrayer.key) !=
                          '\u0639\u0646\u062f \u0627\u0644\u0648\u0642\u062a')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6C16A),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _formatReminderShort(nextPrayer.key),
                            style: const TextStyle(
                              color: Color(0xFF143A2A),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\u0627\u0644\u0645\u062a\u0628\u0642\u064a ${_formatCountdown(nextPrayer.time.difference(_now))}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderChip(
                        icon: Icons.location_on_rounded,
                        label: _selectedCity.name,
                      ),
                      if (hasAnyEnabledAdhan)
                        const _HeaderChip(
                          icon: Icons.notifications_active_rounded,
                          label:
                              '\u0627\u0644\u0623\u0630\u0627\u0646 \u0645\u0641\u0639\u0644',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (compactHeaderLayout) ...[
                    _HeaderChip(
                      icon: Icons.calendar_month_rounded,
                      label:
                          '${toArabicNumber(hijri.hDay)} ${hijri.longMonthName} ${toArabicNumber(hijri.hYear)} \u0647\u0640',
                      expand: true,
                    ),
                    const SizedBox(height: 8),
                    _HeaderChip(
                      icon: Icons.today_rounded,
                      label:
                          '${toArabicNumber(_now.day)} / ${toArabicNumber(_now.month)} / ${toArabicNumber(_now.year)}',
                      expand: true,
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _HeaderChip(
                            icon: Icons.calendar_month_rounded,
                            label:
                                '${toArabicNumber(hijri.hDay)} ${hijri.longMonthName} ${toArabicNumber(hijri.hYear)} \u0647\u0640',
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HeaderChip(
                            icon: Icons.today_rounded,
                            label:
                                '${toArabicNumber(_now.day)} / ${toArabicNumber(_now.month)} / ${toArabicNumber(_now.year)}',
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PrayerCity>(
              initialValue: _selectedCity,
              decoration: const InputDecoration(
                labelText: '\u0627\u0644\u0645\u062f\u064a\u0646\u0629',
                prefixIcon: Icon(Icons.location_city_rounded),
              ),
              items: prayerCities
                  .map(
                    (city) => DropdownMenuItem(
                      value: city,
                      child: Text('${city.name} - ${city.governorate}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  _selectedCity = value;
                  _autoDetectLocation = false;
                  _locationStatus =
                      '\u062a\u0645 \u0627\u062e\u062a\u064a\u0627\u0631 \u0627\u0644\u0645\u062f\u064a\u0646\u0629 \u064a\u062f\u0648\u064a\u064b\u0627';
                });
                await _persistPrayerPreferences();
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '\u0627\u0643\u062a\u0634\u0627\u0641 \u0627\u0644\u0645\u062f\u064a\u0646\u0629 \u062a\u0644\u0642\u0627\u0626\u064a\u064b\u0627',
              ),
              subtitle: Text(
                _locationStatus ??
                    '\u0627\u062e\u062a\u064a\u0627\u0631 \u0623\u0642\u0631\u0628 \u0645\u062f\u064a\u0646\u0629 \u062d\u0633\u0628 \u0627\u0644\u0645\u0648\u0642\u0639',
              ),
              value: _autoDetectLocation,
              onChanged: (value) async {
                setState(() => _autoDetectLocation = value);
                await _persistPrayerPreferences();
                if (value) await _detectCityFromLocation(showErrors: true);
              },
            ),
            const SizedBox(height: 4),
            for (final entry in entries)
              Card(
                color: isDark ? const Color(0xFF152127) : null,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: entry.key == nextPrayer.key
                        ? const Color(0xFFE6C16A)
                        : const Color(0xFFE9DEC3),
                    foregroundColor: const Color(0xFF143A2A),
                    child: Icon(
                      entry.isPrayer
                          ? Icons.access_time_rounded
                          : Icons.wb_twilight_rounded,
                    ),
                  ),
                  title: Text(
                    entry.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    entry.isPrayer
                        ? ((_prayerEnabledMap[entry.key] ?? true)
                              ? '\u0627\u0644\u062a\u0646\u0628\u064a\u0647 ${_formatReminderShort(entry.key)}'
                              : '\u0627\u0644\u062a\u0646\u0628\u064a\u0647 \u0645\u062a\u0648\u0642\u0641')
                        : '\u0648\u0642\u062a \u0627\u0644\u0634\u0631\u0648\u0642',
                  ),
                  trailing: Text(
                    _formatTime(entry.time),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF143A2A),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PrayerTimes _buildPrayerTimes(DateTime date) {
    final params = _selectedCity.method.parameters;
    params.adjustments = {
      Prayer.fajr: _prayerOffsets['fajr'] ?? 0,
      Prayer.sunrise: _prayerOffsets['sunrise'] ?? 0,
      Prayer.dhuhr: _prayerOffsets['dhuhr'] ?? 0,
      Prayer.asr: _prayerOffsets['asr'] ?? 0,
      Prayer.maghrib: _prayerOffsets['maghrib'] ?? 0,
      Prayer.isha: _prayerOffsets['isha'] ?? 0,
    };
    return PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: _selectedCity.coordinates,
      calculationParameters: params,
    );
  }

  PrayerTimes _buildBasePrayerTimes(DateTime date) {
    final params = _selectedCity.method.parameters;
    params.adjustments = {
      Prayer.fajr: 0,
      Prayer.sunrise: 0,
      Prayer.dhuhr: 0,
      Prayer.asr: 0,
      Prayer.maghrib: 0,
      Prayer.isha: 0,
    };
    return PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: _selectedCity.coordinates,
      calculationParameters: params,
    );
  }

  List<_PrayerEntry> _buildEntries(PrayerTimes prayerTimes) => [
    _PrayerEntry(_prayerNames['fajr']!, prayerTimes.fajr.toLocal(), 'fajr'),
    _PrayerEntry(
      _prayerNames['sunrise']!,
      prayerTimes.sunrise.toLocal(),
      'sunrise',
      false,
    ),
    _PrayerEntry(_prayerNames['dhuhr']!, prayerTimes.dhuhr.toLocal(), 'dhuhr'),
    _PrayerEntry(_prayerNames['asr']!, prayerTimes.asr.toLocal(), 'asr'),
    _PrayerEntry(
      _prayerNames['maghrib']!,
      prayerTimes.maghrib.toLocal(),
      'maghrib',
    ),
    _PrayerEntry(_prayerNames['isha']!, prayerTimes.isha.toLocal(), 'isha'),
  ];

  _PrayerEntry _buildUpcomingPrayer() {
    final todayEntries = _buildEntries(
      _buildPrayerTimes(_now),
    ).where((entry) => entry.isPrayer);
    for (final entry in todayEntries) {
      if ((_prayerEnabledMap[entry.key] ?? true) && entry.time.isAfter(_now)) {
        return entry;
      }
    }
    final tomorrowFajr = _buildPrayerTimes(
      _now.add(const Duration(days: 1)),
    ).fajr.toLocal();
    return _PrayerEntry(_prayerNames['fajr']!, tomorrowFajr, 'fajr');
  }

  Future<void> _detectCityFromLocation({required bool showErrors}) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _locationStatus =
          '\u062c\u0627\u0631\u064d \u062a\u062d\u062f\u064a\u062f \u0645\u0648\u0642\u0639\u0643...';
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          '\u062e\u062f\u0645\u0629 \u0627\u0644\u0645\u0648\u0642\u0639 \u0645\u062a\u0648\u0642\u0641\u0629',
        );
      }
      var permission = await LocationPermissionPrompt.ensurePermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          '\u0644\u0645 \u064a\u062a\u0645 \u0645\u0646\u062d \u0625\u0630\u0646 \u0627\u0644\u0645\u0648\u0642\u0639',
        );
      }

      final position = await Geolocator.getCurrentPosition();
      final nearestCity = _nearestCity(position.latitude, position.longitude);
      String? placemarkCity;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          placemarkCity = placemarks.first.locality?.trim();
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _selectedCity = nearestCity;
        _locationStatus = placemarkCity == null || placemarkCity.isEmpty
            ? '\u062a\u0645 \u0627\u062e\u062a\u064a\u0627\u0631 \u0623\u0642\u0631\u0628 \u0645\u062f\u064a\u0646\u0629: ${nearestCity.name}'
            : '\u062a\u0645 \u062a\u062d\u062f\u064a\u062f \u0627\u0644\u0645\u0648\u0642\u0639: $placemarkCity';
      });
      await _persistPrayerPreferences();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationStatus = error.toString().replaceFirst('Exception: ', '');
      });
      if (showErrors) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_locationStatus!)));
      }
    }
  }

  PrayerCity _nearestCity(double latitude, double longitude) {
    return nearestPrayerCity(latitude, longitude);
  }

  Future<void> _showPrayerSettings() async {
    final basePrayerTimes = _buildBasePrayerTimes(_now);
    final prayerTimes = {
      for (final entry in _buildEntries(basePrayerTimes)) entry.key: entry.time,
    };

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: PrayerSettingsPage(
            prayerKeys: _prayerKeys,
            prayerNames: _prayerNames,
            prayerTimes: prayerTimes,
            initialAdhanEnabled: _adhanEnabled,
            initialHijriOffset: _hijriOffset,
            initialPrayerOffsets: _prayerOffsets,
            initialPrayerEnabledMap: _prayerEnabledMap,
            initialPrayerReminderByPrayer: _prayerReminderByPrayer,
            initialAdhanProfile: _adhanProfile,
            adhanProfiles: _adhanProfiles,
            onChanged: (result) async {
              final normalizedPrayerOffsets = _normalizePrayerOffsets(
                result.prayerOffsets,
              );
              final normalizedPrayerReminders = _normalizePrayerReminders(
                result.prayerReminderByPrayer,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _adhanEnabled = result.adhanEnabled;
                _hijriOffset = result.hijriOffset;
                _prayerOffsets = normalizedPrayerOffsets;
                _prayerEnabledMap = Map<String, bool>.from(
                  result.prayerEnabledMap,
                );
                _prayerReminderByPrayer = normalizedPrayerReminders;
                _adhanProfile = result.adhanProfile;
              });
              await _persistPrayerPreferences();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _persistPrayerPreferences() async {
    final normalizedPrayerOffsets = _normalizePrayerOffsets(_prayerOffsets);
    final normalizedPrayerReminders = _normalizePrayerReminders(
      _prayerReminderByPrayer,
    );
    _prayerOffsets = normalizedPrayerOffsets;
    _prayerReminderByPrayer = normalizedPrayerReminders;
    final store = widget.store;
    if (store != null) {
      await store.savePrayerPreferences(
        cityName: _selectedCity.name,
        autoDetect: _autoDetectLocation,
        hijriOffset: _hijriOffset,
        prayerOffsets: normalizedPrayerOffsets,
        adhanEnabled: _adhanEnabled,
        reminderMinutes: 0,
        prayerEnabledMap: _prayerEnabledMap,
        prayerReminderByPrayer: normalizedPrayerReminders,
        adhanProfile: _adhanProfile,
      );
    }
    await _rescheduleNotifications();
  }

  Map<String, int> _normalizePrayerOffsets(Map<String, int> source) => {
    for (final key in _prayerKeys) key: (source[key] ?? 0).clamp(-30, 30),
  };

  Map<String, int> _normalizePrayerReminders(Map<String, int> source) => {
    for (final key in _prayerKeys) key: (source[key] ?? 0).clamp(0, 60),
  };

  Future<void> _rescheduleNotifications() {
    return PrayerNotificationService.instance.reschedulePrayerNotifications(
      city: _selectedCity,
      prayerOffsets: _prayerOffsets,
      adhanEnabled: _adhanEnabled,
      prayerEnabledMap: _prayerEnabledMap,
      prayerReminderByPrayer: _prayerReminderByPrayer,
      adhanProfile: _adhanProfile,
    );
  }

  String _formatReminderShort(String key) {
    final reminder = _prayerReminderByPrayer[key] ?? 0;
    return reminder == 0
        ? '\u0639\u0646\u062f \u0627\u0644\u0648\u0642\u062a'
        : '\u0642\u0628\u0644\u0647\u0627 ${toArabicNumber(reminder)} \u062f';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? '\u0645' : '\u0635';
    return '${toArabicNumber(hour)}:${_toArabicDigits(minute)} $suffix';
  }

  String _formatCountdown(Duration duration) {
    if (duration.isNegative) return '\u0660\u0660:\u0660\u0660:\u0660\u0660';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${_toArabicDigits(hours.toString().padLeft(2, '0'))}:${_toArabicDigits(minutes.toString().padLeft(2, '0'))}:${_toArabicDigits(seconds.toString().padLeft(2, '0'))}';
  }

  String _toArabicDigits(String input) {
    const western = '0123456789';
    const eastern =
        '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669';
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      final index = western.indexOf(char);
      buffer.write(index == -1 ? char : eastern[index]);
    }
    return buffer.toString();
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    this.expand = false,
  });

  final IconData icon;
  final String label;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE6C16A)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerEntry {
  const _PrayerEntry(this.name, this.time, this.key, [this.isPrayer = true]);

  final String name;
  final DateTime time;
  final String key;
  final bool isPrayer;
}
