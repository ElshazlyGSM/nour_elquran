import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

import 'app/quran_app.dart';
import 'data/egypt_prayer_cities.dart';
import 'features/notifications/adhan/prayer_notification_service.dart';
import 'features/notifications/salawat/salawat_notification_service.dart';
import 'services/daily_quran_reminder_service.dart';
import 'services/current_quran_text_source.dart';
import 'services/app_update_service.dart';
import 'services/quran_store.dart';
import 'services/salawat_unlock_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  QuranStore? _store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _BootstrapLifecycleObserver(
        onResume: () async {
          final store = _store;
          if (store == null) {
            return;
          }
          await _reschedulePrayerNotifications(store);
          await _rescheduleSalawat(store);
          unawaited(_refreshAndRescheduleDailyReminder(store));
        },
      );

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (store != null) {
      return QuranApp(store: store);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF143A2A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 200,
                  color: Colors.white,
                ),
                Text(
                  'نور القرآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    // letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _bootstrap() async {
    await QuranLibrary.init();
    QuranLibrary.initWordAudio();
    final store = await QuranStore.create();
    await ensureCurrentQuranTextSourceInitialized();
    if (!mounted) {
      return;
    }
    setState(() => _store = store);
    unawaited(_postBootstrapSetup(store));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        return AppUpdateService.instance.checkForUpdatesFromNavigator();
      });
    });
  }

  Future<void> _postBootstrapSetup(QuranStore store) async {
    try {
      await PrayerNotificationService.instance.initialize();
    } catch (_) {}

    try {
      await _reschedulePrayerNotifications(store);
    } catch (_) {}

    try {
      await _rescheduleSalawat(store);
    } catch (_) {}

    try {
      if (store.savedSalawatUnlockEnabled) {
        await SalawatUnlockService.start();
      } else {
        await SalawatUnlockService.stop();
      }
    } catch (_) {}

    unawaited(_refreshAndRescheduleDailyReminder(store));
  }

  Future<void> _reschedulePrayerNotifications(QuranStore store) {
    final city =
        _resolvePrayerCity(store.savedPrayerCityName) ??
        egyptPrayerCities.first;
    return PrayerNotificationService.instance.reschedulePrayerNotifications(
      city: city,
      prayerOffsets: store.savedPrayerOffsets,
      adhanEnabled: store.savedPrayerAdhanEnabled,
      prayerEnabledMap: store.savedPrayerEnabledMap,
      prayerReminderByPrayer: store.savedPrayerReminderByPrayer,
      adhanProfile: store.savedPrayerAdhanProfile,
    );
  }

  Future<void> _rescheduleSalawat(QuranStore store) {
    final city = _resolvePrayerCity(store.savedPrayerCityName);
    return SalawatNotificationService.instance.reschedule(
      enabled: store.savedSalawatReminderEnabled,
      intervalMinutes: store.savedSalawatReminderIntervalMinutes,
      pauseAtPrayer: store.savedSalawatPauseAtPrayer,
      prayerPauseMinutes: store.savedSalawatPrayerPauseMinutes,
      windowEnabled: store.savedSalawatWindowEnabled,
      windowStartMinutes: store.savedSalawatWindowStartMinutes,
      windowEndMinutes: store.savedSalawatWindowEndMinutes,
      vibrationEnabled: store.savedSalawatVibrationEnabled,
      city: city,
      prayerOffsets: store.savedPrayerOffsets,
    );
  }

  Future<void> _refreshAndRescheduleDailyReminder(QuranStore store) async {
    try {
      final todayIsoDate = _todayIsoDate();
      await store.saveLastAppOpenDate(todayIsoDate);
      await DailyQuranReminderService.instance.reschedule(
        todayIsoDate: todayIsoDate,
        lastAppOpenIsoDate: todayIsoDate,
      );
    } catch (_) {
      // This reminder is secondary and must never interfere with core notifications.
    }
  }

  String _todayIsoDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  PrayerCity? _resolvePrayerCity(String? cityName) {
    if (cityName == null) {
      return null;
    }
    for (final city in egyptPrayerCities) {
      if (city.name == cityName) {
        return city;
      }
    }
    return null;
  }
}

class _BootstrapLifecycleObserver with WidgetsBindingObserver {
  _BootstrapLifecycleObserver({required this.onResume});

  final Future<void> Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

