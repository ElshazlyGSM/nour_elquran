import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/egypt_prayer_cities.dart';
import '../features/notifications/adhan/prayer_notification_service.dart';
import '../features/notifications/salawat/salawat_notification_service.dart';
import 'daily_quran_reminder_service.dart';
import 'quran_store.dart';
import 'white_days_reminder_service.dart';

const _watchdogPeriodicUniqueName = 'notification_watchdog_periodic_v1';
const _watchdogPeriodicTaskName = 'notification_watchdog_periodic_task';
const _watchdogRepairUniqueName = 'notification_watchdog_repair_v1';
const _watchdogRepairTaskName = 'notification_watchdog_repair_task';

@pragma('vm:entry-point')
void notificationWatchdogDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final store = await QuranStore.create();
      final city = resolvePrayerCityByName(store.savedPrayerCityName);

      try {
        await PrayerNotificationService.instance.reschedulePrayerNotifications(
          city: city,
          prayerOffsets: store.savedPrayerOffsets,
          summerTimeEnabled: store.savedPrayerSummerTimeEnabled,
          adhanEnabled: store.savedPrayerAdhanEnabled,
          prayerEnabledMap: store.savedPrayerEnabledMap,
          prayerReminderByPrayer: store.savedPrayerReminderByPrayer,
          adhanProfile: store.savedPrayerAdhanProfile,
        );
      } catch (_) {}

      try {
        await SalawatNotificationService.instance.reschedule(
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
      } catch (_) {}

      final todayIsoDate = _todayIsoDate();
      try {
        await DailyQuranReminderService.instance.reschedule(
          todayIsoDate: todayIsoDate,
          lastAppOpenIsoDate: store.savedLastAppOpenDate,
        );
      } catch (_) {}

      try {
        await WhiteDaysReminderService.instance.reschedule(
          hijriOffset: store.savedPrayerHijriOffset,
        );
      } catch (_) {}
    } catch (_) {
      return false;
    }

    return true;
  });
}

class NotificationWatchdogService {
  NotificationWatchdogService._();

  static final NotificationWatchdogService instance =
      NotificationWatchdogService._();

  bool _initialized = false;

  Future<void> ensureScheduled() async {
    await _ensureInitialized();
    await _registerPeriodicTask();
    await enqueueRepair();
  }

  Future<void> enqueueRepair({
    Duration initialDelay = const Duration(minutes: 1),
  }) async {
    await _ensureInitialized();
    await Workmanager().registerOneOffTask(
      _watchdogRepairUniqueName,
      _watchdogRepairTaskName,
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await Workmanager().initialize(
      notificationWatchdogDispatcher,
      isInDebugMode: false,
    );
    _initialized = true;
  }

  Future<void> _registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      _watchdogPeriodicUniqueName,
      _watchdogPeriodicTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 5),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }
}

String _todayIsoDate() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
