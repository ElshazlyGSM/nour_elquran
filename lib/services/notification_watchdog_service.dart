import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/egypt_prayer_cities.dart';
import '../features/notifications/adhan/prayer_notification_service.dart';
import '../features/notifications/salawat/salawat_notification_service.dart';
import 'daily_quran_reminder_service.dart';
import 'prayer_times_widget_service.dart';
import 'quran_store.dart';
import 'white_days_reminder_service.dart';

const _watchdogPeriodicUniqueName = 'notification_watchdog_periodic_v1';
const _watchdogPeriodicTaskName = 'notification_watchdog_periodic_task';
const _watchdogRepairUniqueName = 'notification_watchdog_repair_v1';
const _watchdogRepairTaskName = 'notification_watchdog_repair_task';

void _logWatchdog(String message) {
  developer.log(message, name: 'NotificationWatchdog');
}

@pragma('vm:entry-point')
void notificationWatchdogDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    _logWatchdog('Task started: $task');

    try {
      final store = await QuranStore.create();
      final city = resolvePrayerCityByName(store.savedPrayerCityName);
      _logWatchdog(
        'Loaded store. salawatEnabled=${store.savedSalawatReminderEnabled}, '
        'interval=${store.savedSalawatReminderIntervalMinutes}, city=${city.name}',
      );

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
        _logWatchdog('Prayer notifications rescheduled');
      } catch (error) {
        _logWatchdog('Prayer reschedule failed: $error');
      }

      // Keep periodic watchdog lightweight: only top-up salawat when the
      // rolling queue is close to depletion. Full rebuild remains for repair.
      if (task == _watchdogPeriodicTaskName) {
        try {
          await SalawatNotificationService.instance.ensureRollingCapacity(
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
            minimumPendingNotifications: 96,
          );
          _logWatchdog('Salawat capacity check completed (periodic)');
        } catch (error) {
          _logWatchdog('Salawat capacity check failed (periodic): $error');
        }
      } else if (task == _watchdogRepairTaskName) {
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
          _logWatchdog('Salawat full reschedule completed (repair)');
        } catch (error) {
          _logWatchdog('Salawat full reschedule failed (repair): $error');
        }
      }

      final todayIsoDate = _todayIsoDate();
      try {
        await DailyQuranReminderService.instance.reschedule(
          todayIsoDate: todayIsoDate,
          lastAppOpenIsoDate: store.savedLastAppOpenDate,
        );
        _logWatchdog('Daily reminder rescheduled');
      } catch (error) {
        _logWatchdog('Daily reminder reschedule failed: $error');
      }

      try {
        await WhiteDaysReminderService.instance.reschedule(
          hijriOffset: store.savedPrayerHijriOffset,
        );
        _logWatchdog('White days reminder rescheduled');
      } catch (error) {
        _logWatchdog('White days reminder reschedule failed: $error');
      }

      try {
        await PrayerTimesWidgetService.instance.updateFromStore(store);
        _logWatchdog('Prayer widget updated');
      } catch (error) {
        _logWatchdog('Prayer widget update failed: $error');
      }
    } catch (error) {
      _logWatchdog('Task failed: $task, error=$error');
      return false;
    }

    _logWatchdog('Task completed: $task');
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
    _logWatchdog('ensureScheduled completed');
  }

  Future<void> enqueueRepair({
    Duration initialDelay = const Duration(minutes: 1),
  }) async {
    await _ensureInitialized();
    _logWatchdog('enqueueRepair: delay=${initialDelay.inSeconds}s');
    await Workmanager().registerOneOffTask(
      _watchdogRepairUniqueName,
      _watchdogRepairTaskName,
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.not_required),
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
    _logWatchdog('Workmanager initialized');
  }

  Future<void> _registerPeriodicTask() async {
    _logWatchdog('Register periodic watchdog task (15 min)');
    await Workmanager().registerPeriodicTask(
      _watchdogPeriodicUniqueName,
      _watchdogPeriodicTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 5),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }
}

String _todayIsoDate() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
