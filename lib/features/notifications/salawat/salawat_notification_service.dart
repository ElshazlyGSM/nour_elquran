import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../data/egypt_prayer_cities.dart';
import '../../../services/notification_permission_guard.dart';

class SalawatNotificationService {
  SalawatNotificationService._();

  static final SalawatNotificationService instance =
      SalawatNotificationService._();

  static const _scheduledBaseId = 90000;
  static const _instantNotificationId = 89999;
  // Keep a safety margin under the historical ~500 alarms ceiling while
  // extending the rolling window so reminders do not stop quickly on
  // short intervals unless the app is reopened.
  static const _maxScheduledNotifications = 180;
  static const _scheduledCeilingId =
      _scheduledBaseId + _maxScheduledNotifications;
  static const _prePrayerPauseMinutes = 5;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _canScheduleExactAlarms = true;
  Future<void>? _initializingFuture;

  void _log(String message) {
    developer.log(message, name: 'SalawatService');
  }

  bool get canScheduleExactAlarms => _canScheduleExactAlarms;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final inFlight = _initializingFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _initializeInternal();
    _initializingFuture = future;
    try {
      await future;
    } finally {
      _initializingFuture = null;
    }
  }

  Future<void> _initializeInternal() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _notifications.initialize(settings);

    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await NotificationPermissionGuard.shouldRequest()) {
      try {
        await android?.requestNotificationsPermission();
      } on PlatformException catch (error) {
        if (error.code != 'permissionRequestInProgress') {
          rethrow;
        }
      }
      try {
        await android?.requestExactAlarmsPermission();
      } on PlatformException catch (error) {
        if (error.code != 'permissionRequestInProgress') {
          rethrow;
        }
      }
      await NotificationPermissionGuard.markRequested();
    }
    _canScheduleExactAlarms =
        await android?.canScheduleExactNotifications() ?? true;

    _log('Initialized. canScheduleExact=$_canScheduleExactAlarms');
    _initialized = true;
  }
  Future<bool> ensureNotificationPermissionForToggle() async {
    await initialize();

    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabledBefore = await android?.areNotificationsEnabled() ?? true;
      if (!enabledBefore) {
        try {
          await android?.requestNotificationsPermission();
        } on PlatformException catch (error) {
          if (error.code != 'permissionRequestInProgress') {
            rethrow;
          }
        }
      }
      final enabledAfter = await android?.areNotificationsEnabled() ?? false;
      if (!enabledAfter) {
        return false;
      }
      try {
        await android?.requestExactAlarmsPermission();
      } on PlatformException catch (error) {
        if (error.code != 'permissionRequestInProgress') {
          rethrow;
        }
      }
      _canScheduleExactAlarms =
          await android?.canScheduleExactNotifications() ?? _canScheduleExactAlarms;
      return true;
    }

    if (Platform.isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }
  Future<void> reschedule({
    required bool enabled,
    required int intervalMinutes,
    required bool pauseAtPrayer,
    required int prayerPauseMinutes,
    required bool windowEnabled,
    required int windowStartMinutes,
    required int windowEndMinutes,
    required bool vibrationEnabled,
    PrayerCity? city,
    Map<String, int> prayerOffsets = const {},
    bool summerTimeEnabled = false,
  }) async {
    await initialize();
    await cancelAll();

    if (!enabled) {
      _log('Reschedule: disabled -> cancel only');
      return;
    }

    final safeInterval = intervalMinutes.clamp(1, 720);
    _log(
      'Reschedule: every=$safeInterval, pauseAtPrayer=$pauseAtPrayer, '
      'pauseMinutes=$prayerPauseMinutes, window=$windowEnabled '
      '($windowStartMinutes-$windowEndMinutes), vib=$vibrationEnabled, '
      'city=${city?.name ?? 'null'}',
    );
    await _scheduleSimpleRollingNotifications(
      intervalMinutes: safeInterval,
      details: _notificationDetails(vibrationEnabled),
      vibrationEnabled: vibrationEnabled,
      pauseAtPrayer: pauseAtPrayer,
      prayerPauseMinutes: prayerPauseMinutes,
      windowEnabled: windowEnabled,
      windowStartMinutes: windowStartMinutes,
      windowEndMinutes: windowEndMinutes,
      city: city,
      prayerOffsets: prayerOffsets,
      summerTimeEnabled: summerTimeEnabled,
    );
    final pending = await _notifications.pendingNotificationRequests();
    final pendingCount = pending
        .where(
          (item) =>
              item.id >= _scheduledBaseId && item.id < _scheduledCeilingId,
        )
        .length;
    _log('Reschedule: pendingCount=$pendingCount');
  }

  Future<void> showInstantReminder({
    required bool vibrationEnabled,
  }) async {
    await initialize();
    final notificationId =
        _instantNotificationId + (DateTime.now().millisecondsSinceEpoch % 9000);
    try {
      await _notifications.show(
        notificationId,
        _title,
        _body,
        _instantNotificationDetails(vibrationEnabled),
      );
    } on PlatformException catch (_) {
      _log('Instant reminder failed. Falling back.');
      await _notifications.show(
        notificationId,
        _title,
        _body,
        _fallbackNotificationDetails(vibrationEnabled),
      );
    }
  }

  Future<void> cancelAll() async {
    final pending = await _notifications.pendingNotificationRequests();
    _log('CancelAll: pending=${pending.length}');
    for (final request in pending) {
      if (request.id >= _scheduledBaseId && request.id < _scheduledCeilingId) {
        await _notifications.cancel(request.id);
      }
    }
  }

  Future<void> _scheduleSimpleRollingNotifications({
    required int intervalMinutes,
    required NotificationDetails details,
    required bool vibrationEnabled,
    required bool pauseAtPrayer,
    required int prayerPauseMinutes,
    required bool windowEnabled,
    required int windowStartMinutes,
    required int windowEndMinutes,
    required PrayerCity? city,
    required Map<String, int> prayerOffsets,
    required bool summerTimeEnabled,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var nextTime = now.add(Duration(minutes: intervalMinutes));
    var nextId = _scheduledBaseId;
    final pauseDuration = Duration(minutes: prayerPauseMinutes.clamp(5, 180));
    var scheduledCount = 0;
    var skippedCount = 0;

    while (nextId < _scheduledCeilingId) {
      final withinWindow = _isWithinWindow(
        nextTime,
        enabled: windowEnabled,
        startMinutes: windowStartMinutes,
        endMinutes: windowEndMinutes,
      );
      final withinPrayerPause = _isWithinPrayerPause(
        nextTime,
        city: city,
        prayerOffsets: prayerOffsets,
        summerTimeEnabled: summerTimeEnabled,
        pauseAtPrayer: pauseAtPrayer,
        pauseDuration: pauseDuration,
      );
      if (!withinWindow || withinPrayerPause) {
        if (skippedCount < 3) {
          _log(
            'Skip at ${nextTime.toLocal()} window=$withinWindow pause=$withinPrayerPause',
          );
          skippedCount++;
        }
        nextTime = nextTime.add(Duration(minutes: intervalMinutes));
        continue;
      }

      final preferredMode = _canScheduleExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      try {
        await _notifications.zonedSchedule(
          nextId,
          _title,
          _body,
          nextTime,
          details,
          androidScheduleMode: preferredMode,
        );
      } on PlatformException catch (error) {
        _log(
          'Schedule failed id=$nextId mode=$preferredMode: ${error.code} ${error.message}',
        );
        final message = error.message ?? '';
        if (message.contains('Maximum limit of concurrent alarms')) {
          break;
        }
        if (preferredMode == AndroidScheduleMode.inexactAllowWhileIdle) {
          try {
            await _notifications.zonedSchedule(
              nextId,
              _title,
              _body,
              nextTime,
              _fallbackNotificationDetails(vibrationEnabled),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } catch (fallbackError) {
            _log('Fallback(inexact) failed id=$nextId: $fallbackError');
            nextTime = nextTime.add(Duration(minutes: intervalMinutes));
            continue;
          }
          nextId++;
          scheduledCount++;
          nextTime = nextTime.add(Duration(minutes: intervalMinutes));
          continue;
        }
        _canScheduleExactAlarms = false;
        try {
          await _notifications.zonedSchedule(
            nextId,
            _title,
            _body,
            nextTime,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } on PlatformException catch (fallbackError) {
          _log(
            'Fallback failed id=$nextId: ${fallbackError.code} ${fallbackError.message}',
          );
          final fallbackMessage = fallbackError.message ?? '';
          if (fallbackMessage.contains('Maximum limit of concurrent alarms')) {
            break;
          }
          try {
            await _notifications.zonedSchedule(
              nextId,
              _title,
              _body,
              nextTime,
              _fallbackNotificationDetails(vibrationEnabled),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } catch (lastError) {
            _log('Fallback(secondary) failed id=$nextId: $lastError');
            nextTime = nextTime.add(Duration(minutes: intervalMinutes));
            continue;
          }
        }
      }

      nextId++;
      scheduledCount++;
      if (scheduledCount == 1) {
        _log('First scheduled at ${nextTime.toLocal()} mode=$preferredMode');
      }
      nextTime = nextTime.add(Duration(minutes: intervalMinutes));
    }
    _log('Scheduled count=$scheduledCount (limit=$_maxScheduledNotifications)');
  }

  bool _isWithinWindow(
    DateTime time, {
    required bool enabled,
    required int startMinutes,
    required int endMinutes,
  }) {
    if (!enabled) {
      return true;
    }

    final currentMinutes = time.hour * 60 + time.minute;
    if (startMinutes == endMinutes) {
      return true;
    }
    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }

  bool _isWithinPrayerPause(
    DateTime time, {
    required PrayerCity? city,
    required Map<String, int> prayerOffsets,
    required bool summerTimeEnabled,
    required bool pauseAtPrayer,
    required Duration pauseDuration,
  }) {
    if (!pauseAtPrayer || city == null) {
      return false;
    }

    final summerOffset = summerTimeEnabled ? 60 : 0;
    final params = city.method.parameters;
    params.adjustments = {
      Prayer.fajr: (prayerOffsets['fajr'] ?? 0) + summerOffset,
      Prayer.sunrise: (prayerOffsets['sunrise'] ?? 0) + summerOffset,
      Prayer.dhuhr: (prayerOffsets['dhuhr'] ?? 0) + summerOffset,
      Prayer.asr: (prayerOffsets['asr'] ?? 0) + summerOffset,
      Prayer.maghrib: (prayerOffsets['maghrib'] ?? 0) + summerOffset,
      Prayer.isha: (prayerOffsets['isha'] ?? 0) + summerOffset,
    };

    final prayerTimes = PrayerTimes(
      date: DateTime(time.year, time.month, time.day),
      coordinates: city.coordinates,
      calculationParameters: params,
    );

    final prayerMoments = [
      prayerTimes.fajr.toLocal(),
      prayerTimes.dhuhr.toLocal(),
      prayerTimes.asr.toLocal(),
      prayerTimes.maghrib.toLocal(),
      prayerTimes.isha.toLocal(),
    ];

    for (final prayerTime in prayerMoments) {
      final start = prayerTime.subtract(
        const Duration(minutes: _prePrayerPauseMinutes),
      );
      final end = prayerTime.add(pauseDuration);
      if (!time.isBefore(start) && time.isBefore(end)) {
        return true;
      }
    }

    return false;
  }

  NotificationDetails _notificationDetails(
    bool vibrationEnabled,
  ) => NotificationDetails(
    android: AndroidNotificationDetails(
      'salawat_reminders_channel_clean_v4_${vibrationEnabled ? 'vib' : 'silent'}',
      'تذكير الصلاة على النبي',
      channelDescription: 'تنبيهات دورية للصلاة والسلام على سيدنا النبي',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('saly'),
      enableVibration: vibrationEnabled,
      vibrationPattern: vibrationEnabled
          ? Int64List.fromList([0, 250, 160, 420])
          : null,
      timeoutAfter: 60000,
      onlyAlertOnce: false,
      category: AndroidNotificationCategory.reminder,
      audioAttributesUsage: AudioAttributesUsage.notification,
    ),
  );

  NotificationDetails _instantNotificationDetails(bool vibrationEnabled) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'salawat_activation_channel_v1_${vibrationEnabled ? 'vib' : 'silent'}',
          'تأكيد تشغيل الصلاة والسلام',
          channelDescription: 'إشعار فوري عند تفعيل الخدمة',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('saly'),
          enableVibration: vibrationEnabled,
          vibrationPattern: vibrationEnabled
              ? Int64List.fromList([0, 250, 160, 420])
              : null,
          timeoutAfter: 30000,
          onlyAlertOnce: false,
          category: AndroidNotificationCategory.reminder,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
      );
  NotificationDetails _fallbackNotificationDetails(bool vibrationEnabled) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'salawat_reminders_channel_fallback_${vibrationEnabled ? 'vib' : 'silent'}',
          'تذكير الصلاة على النبي',
          channelDescription: 'قناة احتياطية لضمان وصول التذكير',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: vibrationEnabled,
          vibrationPattern: vibrationEnabled
              ? Int64List.fromList([0, 250, 160, 420])
              : null,
          timeoutAfter: 60000,
          onlyAlertOnce: false,
          category: AndroidNotificationCategory.reminder,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
      );

  String get _title => 'الصلاة والسلام على سيدنا النبي';

  String get _body => 'اللهم صل وسلم وبارك على سيدنا محمد وعلى آله وصحبه وسلم';
}





