import 'dart:io';
import 'dart:typed_data';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../data/egypt_prayer_cities.dart';
import '../../../services/adhan_audio_cache_service.dart';
import '../../../services/notification_permission_guard.dart';

class PrayerNotificationService {
  PrayerNotificationService._();

  static final PrayerNotificationService instance =
      PrayerNotificationService._();
  // Keep two+ weeks of upcoming alarms so missed app opens do not cause gaps.
  static const int _scheduleWindowDays = 30;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const _prayerNotificationMaxId = 30000;
  static const _volumePreviewNotificationId = 30098;

  bool _initialized = false;
  bool _canScheduleExactAlarms = true;
  Future<void>? _initializingFuture;

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
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (await NotificationPermissionGuard.shouldRequest()) {
      if (Platform.isAndroid) {
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
      } else if (Platform.isIOS) {
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
      }
      await NotificationPermissionGuard.markRequested();
    }
    _canScheduleExactAlarms = Platform.isAndroid
        ? await android?.canScheduleExactNotifications() ?? true
        : true;

    _initialized = true;
  }

  Future<bool> ensureNotificationPermissionForToggle() async {
    await initialize();

    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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
          await android?.canScheduleExactNotifications() ??
          _canScheduleExactAlarms;
      return true;
    }

    if (Platform.isIOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  Future<void> reschedulePrayerNotifications({
    required PrayerCity city,
    required Map<String, int> prayerOffsets,
    required bool summerTimeEnabled,
    required bool adhanEnabled,
    required Map<String, bool> prayerEnabledMap,
    required Map<String, int> prayerReminderByPrayer,
    required String adhanProfile,
  }) async {
    await initialize();
    await _refreshExactAlarmCapability();
    await _cancelPrayerNotificationsOnly();

    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < _scheduleWindowDays; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      final prayerTimes = _buildPrayerTimes(
        city: city,
        date: date,
        prayerOffsets: prayerOffsets,
        summerTimeEnabled: summerTimeEnabled,
      );

      final entries = <_ScheduledPrayer>[
        _ScheduledPrayer('fajr', 'الفجر', prayerTimes.fajr.toLocal(), 11),
        _ScheduledPrayer(
          'sunrise',
          'الشروق',
          prayerTimes.sunrise.toLocal(),
          16,
        ),
        _ScheduledPrayer('dhuhr', 'الظهر', prayerTimes.dhuhr.toLocal(), 22),
        _ScheduledPrayer('asr', 'العصر', prayerTimes.asr.toLocal(), 33),
        _ScheduledPrayer(
          'maghrib',
          'المغرب',
          prayerTimes.maghrib.toLocal(),
          44,
        ),
        _ScheduledPrayer('isha', 'العشاء', prayerTimes.isha.toLocal(), 55),
      ];

      for (final entry in entries) {
        if (!(prayerEnabledMap[entry.key] ?? true)) {
          continue;
        }
        if (!entry.time.isAfter(now)) {
          continue;
        }

        final isSunrise = entry.key == 'sunrise';
        if (adhanEnabled) {
          try {
            await _scheduleEntry(
              id: dayOffset * 1000 + entry.idSeed,
              title: 'حان الآن موعد ${entry.name}',
              body: 'دخل الوقت حسب توقيت ${city.name}',
              scheduledAt: entry.time,
              adhanProfile: adhanProfile,
              isPrayerTimeAlarm: true,
              soundOverride: isSunrise ? 'shoro2' : null,
              channelSuffixOverride: isSunrise ? 'sunrise' : null,
              channelNameOverride: isSunrise ? 'تنبيه الشروق' : null,
            );
          } catch (_) {
            // Keep scheduling the rest even if one entry fails.
          }
        }

        final reminderMinutes = prayerReminderByPrayer[entry.key] ?? 0;
        if (reminderMinutes > 0) {
          final reminderTime = entry.time.subtract(
            Duration(minutes: reminderMinutes),
          );
          if (reminderTime.isAfter(now)) {
            try {
              await _scheduleEntry(
                id: dayOffset * 1000 + entry.idSeed + 500,
                title: 'اقترب موعد ${entry.name}',
                body:
                    'متبقي ${reminderMinutes.toString()} دقيقة على ${entry.name} في ${city.name}',
                scheduledAt: reminderTime,
                adhanProfile: adhanProfile,
                soundOverride: isSunrise ? 'shoro2' : null,
                channelSuffixOverride: isSunrise ? 'sunrise' : null,
                channelNameOverride: isSunrise ? 'تنبيه الشروق' : null,
              );
            } catch (_) {
              // Keep scheduling the rest even if one entry fails.
            }
          }
        }
      }
    }
  }

  Future<void> _cancelPrayerNotificationsOnly() async {
    final pending = await _notifications.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id > 0 && request.id < _prayerNotificationMaxId) {
        await _notifications.cancel(request.id);
      }
    }

    const prayerIdSeeds = <int>[
      11,
      16,
      22,
      33,
      44,
      55,
      511,
      516,
      522,
      533,
      544,
      555,
    ];
    for (var dayOffset = 0; dayOffset < _scheduleWindowDays; dayOffset++) {
      final prefix = dayOffset * 1000;
      for (final seed in prayerIdSeeds) {
        await _notifications.cancel(prefix + seed);
      }
    }
  }

  Future<int> pendingScheduledCount() async {
    await initialize();
    final pending = await _notifications.pendingNotificationRequests();
    return pending
        .where(
          (request) => request.id > 0 && request.id < _prayerNotificationMaxId,
        )
        .length;
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
      date: date,
      coordinates: city.coordinates,
      calculationParameters: params,
    );
  }

  Future<void> _scheduleEntry({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String adhanProfile,
    bool isPrayerTimeAlarm = false,
    String? soundOverride,
    String? channelSuffixOverride,
    String? channelNameOverride,
  }) async {
    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);
    NotificationDetails details;
    try {
      details = await _notificationDetailsForProfile(
        adhanProfile,
        isPrayerTimeAlarm: isPrayerTimeAlarm,
        soundOverride: soundOverride,
        channelSuffixOverride: channelSuffixOverride,
        channelNameOverride: channelNameOverride,
      );
    } catch (_) {
      // Keep scheduling alive even if a specific adhan profile/sound is invalid.
      details = _fallbackNotificationDetails(
        isPrayerTimeAlarm: isPrayerTimeAlarm,
        channelSuffixOverride: channelSuffixOverride,
        channelNameOverride: channelNameOverride,
      );
    }
    if (!Platform.isAndroid) {
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          _fallbackNotificationDetails(
            isPrayerTimeAlarm: isPrayerTimeAlarm,
            channelSuffixOverride: channelSuffixOverride,
            channelNameOverride: channelNameOverride,
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      return;
    }

    final preferredMode = _canScheduleExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      return await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: preferredMode,
      );
    } on PlatformException catch (error) {
      final message = error.message ?? '';
      if (message.contains('Maximum limit of concurrent alarms')) {
        return;
      }
      if (preferredMode == AndroidScheduleMode.inexactAllowWhileIdle) {
        try {
          return await _notifications.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            _fallbackNotificationDetails(
              isPrayerTimeAlarm: isPrayerTimeAlarm,
              channelSuffixOverride: channelSuffixOverride,
              channelNameOverride: channelNameOverride,
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (_) {
          rethrow;
        }
      }
      _canScheduleExactAlarms = false;
      try {
        return _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } on PlatformException catch (fallbackError) {
        final fallbackMessage = fallbackError.message ?? '';
        if (fallbackMessage.contains('Maximum limit of concurrent alarms')) {
          return;
        }
        try {
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            _fallbackNotificationDetails(
              isPrayerTimeAlarm: isPrayerTimeAlarm,
              channelSuffixOverride: channelSuffixOverride,
              channelNameOverride: channelNameOverride,
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          return;
        } catch (_) {
          rethrow;
        }
      }
    }
  }

  Future<void> _refreshExactAlarmCapability() async {
    if (!Platform.isAndroid) {
      _canScheduleExactAlarms = true;
      return;
    }
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    _canScheduleExactAlarms =
        await android?.canScheduleExactNotifications() ??
        _canScheduleExactAlarms;
  }

  Future<void> showInstantPrayerPreview({
    required String adhanProfile,
    bool isSunriseTone = false,
  }) async {
    await initialize();
    final title = isSunriseTone ? 'معاينة صوت الشروق' : 'معاينة صوت الأذان';
    const body = 'يتم تشغيل هذا الصوت لتجربة مستوى صوت الإشعارات';
    try {
      final details = await _notificationDetailsForProfile(
        adhanProfile,
        isPrayerTimeAlarm: true,
        soundOverride: isSunriseTone ? 'shoro2' : null,
        channelSuffixOverride: isSunriseTone ? 'sunrise_preview' : 'preview',
        channelNameOverride: isSunriseTone ? 'معاينة الشروق' : 'معاينة الأذان',
      );
      await _notifications.show(
        _volumePreviewNotificationId,
        title,
        body,
        details,
      );
    } catch (_) {
      await _notifications.show(
        _volumePreviewNotificationId,
        title,
        body,
        _fallbackNotificationDetails(
          isPrayerTimeAlarm: true,
          channelSuffixOverride: isSunriseTone ? 'sunrise_preview' : 'preview',
          channelNameOverride: isSunriseTone
              ? 'معاينة الشروق'
              : 'معاينة الأذان',
        ),
      );
    }
  }

  NotificationDetails _fallbackNotificationDetails({
    required bool isPrayerTimeAlarm,
    String? channelSuffixOverride,
    String? channelNameOverride,
  }) {
    final suffix =
        channelSuffixOverride ??
        (isPrayerTimeAlarm ? 'prayer_fallback' : 'reminder_fallback');
    final name =
        channelNameOverride ??
        (isPrayerTimeAlarm ? 'تنبيهات الصلاة' : 'تذكير قبل الصلاة');
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_fallback_channel_$suffix',
        name,
        channelDescription: 'قناة احتياطية لضمان وصول الإشعارات',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 160, 400]),
        category: AndroidNotificationCategory.reminder,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  Future<NotificationDetails> _notificationDetailsForProfile(
    String adhanProfile, {
    required bool isPrayerTimeAlarm,
    String? soundOverride,
    String? channelSuffixOverride,
    String? channelNameOverride,
  }) async {
    final normalizedProfile = adhanProfile.trim().toLowerCase();
    final iosSound = _iOSBundledSoundForPrayer(
      profile: normalizedProfile,
      isPrayerTimeAlarm: isPrayerTimeAlarm,
      soundOverride: soundOverride,
    );

    if (!isPrayerTimeAlarm) {
      final reminderSound = soundOverride != null
          ? RawResourceAndroidNotificationSound(soundOverride)
          : RawResourceAndroidNotificationSound('a2trb');
      final reminderChannelSuffix = channelSuffixOverride ?? 'v3';
      final reminderChannelName = channelNameOverride ?? 'تذكير قبل الصلاة';
      return NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminder_channel_v4_$reminderChannelSuffix',
          reminderChannelName,
          channelDescription: 'تنبيهات تسبق وقت الصلاة بالصوت المخصص للتنبيه',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: reminderSound,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 180, 500]),
          timeoutAfter: 60000,
          onlyAlertOnce: false,
          category: AndroidNotificationCategory.reminder,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
          sound: iosSound,
        ),
      );
    }

    final downloaded = await AdhanAudioCacheService.instance.isDownloaded(
      normalizedProfile,
    );
    final channelSuffix =
        channelSuffixOverride ??
        switch (normalizedProfile) {
          'allah_akbar' => 'allah_akbar',
          'nsr_elden' => 'nsr_elden',
          'egypt' => 'abdelbast',
          'mnshawy' => 'mnshawy',
          'mowahd' => 'mowahd',
          'haram' => 'haram',
          'soft' => 'mashary',
          _ => 'default',
        };
    final channelName =
        channelNameOverride ??
        switch (normalizedProfile) {
          'allah_akbar' => 'تنبيهات الصلاة - تكبير فقط',
          'nsr_elden' => 'تنبيهات الصلاة - نصر الدين طوبار',
          'egypt' => 'تنبيهات الصلاة - عبد الباسط',
          'mnshawy' => 'تنبيهات الصلاة - المنشاوي',
          'mowahd' => 'تنبيهات الصلاة - أذان مصر الموحد',
          'haram' => 'تنبيهات الصلاة - أذان الحرم',
          'soft' => 'تنبيهات الصلاة - مشاري',
          _ => 'تنبيهات الصلاة',
        };
    final sound = soundOverride != null
        ? RawResourceAndroidNotificationSound(soundOverride)
        : await _androidSoundForProfile(normalizedProfile);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_times_channel_v5_${channelSuffix}_${downloaded ? 'downloaded' : 'system'}',
        channelName,
        channelDescription: 'تنبيهات دخول الوقت والتنبيه المسبق',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: sound,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 220, 700]),
        category: AndroidNotificationCategory.reminder,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        sound: iosSound,
      ),
    );
  }

  Future<AndroidNotificationSound?> _androidSoundForProfile(
    String profile,
  ) async {
    final localUri = await AdhanAudioCacheService.instance.localUriForProfile(
      profile,
    );
    if (localUri != null) {
      return UriAndroidNotificationSound(localUri);
    }
    // Never fall back to the system tone for prayer-time alarms.
    // If custom profile audio is unavailable, use bundled takbeer.
    return RawResourceAndroidNotificationSound('azan_alah_akbr');
  }

  String? _iOSBundledSoundForPrayer({
    required String profile,
    required bool isPrayerTimeAlarm,
    String? soundOverride,
  }) {
    if (soundOverride != null) {
      return _iOSBundledSoundName(soundOverride);
    }
    if (!isPrayerTimeAlarm) {
      return 'a2trb.caf';
    }
    return switch (profile) {
      'allah_akbar' => 'azan-alah-akbr.caf',
      'nsr_elden' => 'azan-nsr-elden.caf',
      'egypt' => 'abdelbast.caf',
      'mnshawy' => 'azan-elmnshawy.caf',
      'mowahd' => 'azan-mowahd.caf',
      'haram' => 'harm.caf',
      'soft' => 'mashary.caf',
      _ => null,
    };
  }

  String? _iOSBundledSoundName(String soundName) => switch (soundName) {
    'a2trb' => 'a2trb.caf',
    'shoro2' => 'shoro2.caf',
    'harm' => 'harm.caf',
    'abdelbast' => 'abdelbast.caf',
    'mashary' => 'mashary.caf',
    'azan_alah_akbr' => 'azan-alah-akbr.caf',
    'saly' => 'saly.caf',
    _ => null,
  };
}

class _ScheduledPrayer {
  const _ScheduledPrayer(this.key, this.name, this.time, this.idSeed);

  final String key;
  final String name;
  final DateTime time;
  final int idSeed;
}
