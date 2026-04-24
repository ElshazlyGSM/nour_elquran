import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_permission_guard.dart';
class DailyQuranReminderService {
  DailyQuranReminderService._();

  static final instance = DailyQuranReminderService._();

  static const _notificationId = 70001;
  static const _fixedReminderHour = 20;
  static const _fixedReminderMinute = 0;
  static const _messages = [
    'لا تجعل يومك ينتهي قبل أن تقرأ وردك.',
    'اغتنم من نور القرآن قبل انتهاء يومك.',
    'بضع دقائق مع القرآن قد تصنع سكينة يومك كله.',
    'افتح المصحف الآن، فالوقت مع القرآن بركة.',
  ];

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Random _random = Random();

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

  Future<void> reschedule({
    required String todayIsoDate,
    required String? lastAppOpenIsoDate,
  }) async {
    await initialize();
    await _notifications.cancel(_notificationId);

    final now = tz.TZDateTime.now(tz.local);
    final openedToday = lastAppOpenIsoDate == todayIsoDate;

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _fixedReminderHour,
      _fixedReminderMinute,
    );

    if (openedToday || !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _notificationId,
      'نور القرآن',
      _messages[_random.nextInt(_messages.length)],
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  NotificationDetails get _notificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_quran_reminder_channel_v1',
      'التذكير اليومي بفتح المصحف',
      channelDescription: 'تذكير يومي هادئ لفتح المصحف إذا لم يتم فتح التطبيق خلال اليوم',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 220, 120, 320]),
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    ),
  );
}
