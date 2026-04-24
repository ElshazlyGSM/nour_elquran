import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_permission_guard.dart';
class WhiteDaysReminderService {
  WhiteDaysReminderService._();

  static final instance = WhiteDaysReminderService._();

  static const _baseNotificationId = 71000;
  static const _maxNotifications = 12;
  static const _reminderHour = 20;
  static const _reminderMinute = 0;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (await NotificationPermissionGuard.shouldRequest()) {
      if (Platform.isAndroid) {
        await android?.requestNotificationsPermission();
        await android?.requestExactAlarmsPermission();
      } else if (Platform.isIOS) {
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
      }
      await NotificationPermissionGuard.markRequested();
    }

    _initialized = true;
  }

  Future<void> reschedule({required int hijriOffset}) async {
    await initialize();
    await _cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = 0;
    var dayCursor = DateTime(now.year, now.month, now.day);

    while (scheduled < _maxNotifications) {
      final reminderDate = DateTime(
        dayCursor.year,
        dayCursor.month,
        dayCursor.day,
        _reminderHour,
        _reminderMinute,
      );

      if (reminderDate.isAfter(now.toLocal()) &&
          _isTwelfthHijriDay(reminderDate, hijriOffset)) {
        await _notifications.zonedSchedule(
          _baseNotificationId + scheduled,
          'تذكير الأيام البيض',
          'غدًا 13 هجري، بداية صيام الأيام البيض.',
          tz.TZDateTime.from(reminderDate, tz.local),
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        scheduled++;
      }

      dayCursor = dayCursor.add(const Duration(days: 1));
    }
  }

  Future<void> _cancelAll() async {
    for (var id = _baseNotificationId; id < _baseNotificationId + _maxNotifications; id++) {
      await _notifications.cancel(id);
    }
  }

  bool _isTwelfthHijriDay(DateTime gregorianDate, int hijriOffset) {
    final adjustedDate = gregorianDate.add(Duration(days: hijriOffset));
    final hijri = HijriCalendar.fromDate(adjustedDate);
    return hijri.hDay == 12;
  }

  NotificationDetails get _notificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'white_days_reminder_channel_v1',
      'تذكير صيام الأيام البيض',
      channelDescription: 'تذكير شهري بأن غدًا بداية صيام الأيام البيض',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    ),
  );
}
