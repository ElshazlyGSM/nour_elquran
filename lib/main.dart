import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran_library/quran_library.dart';

import 'app/quran_app.dart';
import 'data/egypt_prayer_cities.dart';
import 'features/home/adhkar_page.dart';
import 'features/home/prayer_times_page.dart';
import 'features/home/quran_section_shell.dart';
import 'features/home/tasbih_page.dart';
import 'features/reader/reader_page.dart';
import 'features/notifications/adhan/prayer_notification_service.dart';
import 'features/notifications/salawat/salawat_notification_service.dart';
import 'services/app_update_service.dart';
import 'services/current_quran_text_source.dart';
import 'services/daily_quran_reminder_service.dart';
import 'services/location_permission_prompt.dart';
import 'services/notification_watchdog_service.dart';
import 'services/prayer_times_widget_service.dart';
import 'services/background_execution_settings.dart';
import 'services/juz_names_service.dart';
import 'services/quran_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error');
    return true;
  };
  runZonedGuarded(() => runApp(const _BootstrapApp()), (error, stack) {
    debugPrint('Uncaught zone error: $error');
  });
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
          unawaited(_handleLaunchTarget(store));
          unawaited(_syncPrayerCityFromLocation(store));
          unawaited(_reschedulePrayerNotifications(store));
          unawaited(() async {
            try {
              await _rescheduleSalawat(store);
            } catch (_) {}
          }());
          unawaited(_refreshAndRescheduleDailyReminder(store));
          unawaited(PrayerTimesWidgetService.instance.updateFromStore(store));
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
    await JuzNamesService.ensureLoaded();
    try {
      await NotificationWatchdogService.instance.ensureScheduled();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() => _store = store);
    unawaited(_postBootstrapSetup(store));
    unawaited(
      Future<void>.delayed(const Duration(seconds: 20), () async {
        await AppUpdateService.instance.checkForUpdatesFromNavigator();
      }),
    );
  }

  Future<void> _postBootstrapSetup(QuranStore store) async {
    unawaited(_handleLaunchTarget(store));

    try {
      await _syncPrayerCityFromLocation(store);
    } catch (_) {}

    try {
      await PrayerNotificationService.instance.initialize();
    } catch (_) {}

    try {
      await _reschedulePrayerNotifications(store);
    } catch (_) {}

    unawaited(
      Future<void>.delayed(const Duration(seconds: 6), () async {
        try {
          await _rescheduleSalawat(store);
        } catch (_) {}
      }),
    );

    unawaited(_refreshAndRescheduleDailyReminder(store));
    unawaited(NotificationWatchdogService.instance.enqueueRepair());
    unawaited(PrayerTimesWidgetService.instance.updateFromStore(store));
  }

  Future<void> _syncPrayerCityFromLocation(QuranStore store) async {
    if (!store.savedPrayerAutoDetect) {
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return;
    }
    var permission = await LocationPermissionPrompt.ensurePermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } on TimeoutException {
      return;
    } catch (_) {
      return;
    }
    final nearest = nearestPrayerCity(position.latitude, position.longitude);
    if (nearest.name == store.savedPrayerCityName) {
      return;
    }

    await store.savePrayerPreferences(
      cityName: nearest.name,
      autoDetect: true,
      hijriOffset: store.savedPrayerHijriOffset,
      prayerOffsets: store.savedPrayerOffsets,
      adhanEnabled: store.savedPrayerAdhanEnabled,
      reminderMinutes: store.savedPrayerReminderMinutes,
      prayerEnabledMap: store.savedPrayerEnabledMap,
      prayerReminderByPrayer: store.savedPrayerReminderByPrayer,
      adhanProfile: store.savedPrayerAdhanProfile,
    );
  }

  Future<void> _reschedulePrayerNotifications(QuranStore store) {
    final city = resolvePrayerCityByName(store.savedPrayerCityName);
    return PrayerNotificationService.instance.reschedulePrayerNotifications(
      city: city,
      prayerOffsets: store.savedPrayerOffsets,
      summerTimeEnabled: store.savedPrayerSummerTimeEnabled,
      adhanEnabled: store.savedPrayerAdhanEnabled,
      prayerEnabledMap: store.savedPrayerEnabledMap,
      prayerReminderByPrayer: store.savedPrayerReminderByPrayer,
      adhanProfile: store.savedPrayerAdhanProfile,
    );
  }

  Future<void> _rescheduleSalawat(QuranStore store) {
    final city = resolvePrayerCityByName(store.savedPrayerCityName);
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
      summerTimeEnabled: store.savedPrayerSummerTimeEnabled,
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

  Future<void> _handleLaunchTarget(QuranStore store) async {
    final target = await BackgroundExecutionSettings.consumeLaunchTarget();
    if (target == null || target.trim().isEmpty) {
      return;
    }

    var navigatorState = AppUpdateService.navigatorKey.currentState;
    if (navigatorState == null) {
      for (var i = 0; i < 12; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        navigatorState = AppUpdateService.navigatorKey.currentState;
        if (navigatorState != null) {
          break;
        }
      }
    }
    if (navigatorState == null) {
      return;
    }

    final normalized = target.trim().toLowerCase();
    final page = switch (normalized) {
      'prayer' => PrayerTimesPage(store: store),
      'adhkar' => AdhkarPage(store: store),
      'tasbih' => TasbihPage(store: store),
      'continue' =>
        store.lastRead == null
            ? QuranSectionShell(store: store)
            : ReaderPage(
                store: store,
                surahNumber: store.lastRead!.surahNumber,
                initialVerse: store.lastRead!.verseNumber,
              ),
      _ => null,
    };
    if (page == null) {
      return;
    }

    final context = navigatorState.overlay?.context;
    if (context == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await navigatorState.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            Directionality(textDirection: TextDirection.rtl, child: page),
      ),
    );
  }

  String _todayIsoDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
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
