import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../data/egypt_prayer_cities.dart';
import '../../../services/quran_store.dart';
import '../../../services/salawat_unlock_service.dart';
import 'salawat_notification_service.dart';

class SalawatReminderPage extends StatefulWidget {
  const SalawatReminderPage({super.key, required this.store});

  final QuranStore store;

  @override
  State<SalawatReminderPage> createState() => _SalawatReminderPageState();
}

class _SalawatReminderPageState extends State<SalawatReminderPage> {
  static const _intervals = [1, 5, 10, 15, 30, 45, 60, 120];
  static const _prayerPauseOptions = [15, 20, 30, 45, 60];

  late bool _enabled;
  late int _intervalMinutes;
  late bool _pauseAtPrayer;
  late int _prayerPauseMinutes;
  late bool _windowEnabled;
  late int _windowStartMinutes;
  late int _windowEndMinutes;
  late bool _vibrationEnabled;
  late bool _unlockOnceEnabled;
  bool _saving = false;
  void _log(String message) {
    developer.log(message, name: 'SalawatSettings');
  }

  @override
  void initState() {
    super.initState();
    _enabled = widget.store.savedSalawatReminderEnabled;
    _intervalMinutes = widget.store.savedSalawatReminderIntervalMinutes;
    _pauseAtPrayer = widget.store.savedSalawatPauseAtPrayer;
    _prayerPauseMinutes = widget.store.savedSalawatPrayerPauseMinutes;
    _windowEnabled = widget.store.savedSalawatWindowEnabled;
    _windowStartMinutes = widget.store.savedSalawatWindowStartMinutes;
    _windowEndMinutes = widget.store.savedSalawatWindowEndMinutes;
    _vibrationEnabled = widget.store.savedSalawatVibrationEnabled;
    _unlockOnceEnabled = widget.store.savedSalawatUnlockEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF152127)
        : const Color(0xFFF8F3E7);
    final borderColor = isDark
        ? const Color(0xFF26343B)
        : const Color(0xFFE3D6B8);
    final textColor = isDark
        ? const Color(0xFFF2ECDF)
        : const Color(0xFF143A2A);
    final mutedTextColor = isDark
        ? const Color(0xFFBAC3BE)
        : const Color(0xFF4F5A53);
    final disabledTextColor = isDark
        ? const Color(0xFF7B8782)
        : const Color(0xFF8F9B95);

    return Scaffold(
      appBar: AppBar(title: const Text('الصلاة على النبي')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        value: _enabled,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() => _enabled = value);
                          if (value) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'لا تنسَ حفظ الإعدادات في أسفل الصفحة',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                          }
                        },
                        title: const Text(
                          'تفعيل التذكير',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'تنبيه دوري بسيط للصلاة والسلام على سيدنا محمد',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        value: _unlockOnceEnabled,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() => _unlockOnceEnabled = value);
                          if (value) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'لا تنسَ حفظ الإعدادات في أسفل الصفحة',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                          }
                        },
                        title: Text(
                          'تشغيل ذكر عند فتح قفل الهاتف',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          'تشغيل مرة واحدة مع كل فتح للجهاز',
                          style: TextStyle(color: mutedTextColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        value: _pauseAtPrayer,
                        contentPadding: EdgeInsets.zero,
                        onChanged: _enabled
                            ? (value) => setState(() => _pauseAtPrayer = value)
                            : null,
                        title: Text(
                          'إيقاف التذكير وقت الصلاة',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _enabled ? textColor : disabledTextColor,
                          ),
                        ),
                        subtitle: Text(
                          'يتوقف قبل الفرض بخمس دقائق ثم يعود بعد الوقت المحدد',
                          style: TextStyle(
                            color: _enabled
                                ? mutedTextColor
                                : disabledTextColor,
                          ),
                        ),
                      ),
                      if (_enabled && _pauseAtPrayer) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final minutes in _prayerPauseOptions)
                              ChoiceChip(
                                label: Text(
                                  'بعد الصلاة بـ $minutes دقيقة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                                selected: _prayerPauseMinutes == minutes,
                                onSelected: (_) {
                                  setState(() => _prayerPauseMinutes = minutes);
                                },
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        value: _windowEnabled,
                        contentPadding: EdgeInsets.zero,
                        onChanged: _enabled
                            ? (value) => setState(() => _windowEnabled = value)
                            : null,
                        title: Text(
                          'جدولة وقت التشغيل',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _enabled ? textColor : disabledTextColor,
                          ),
                        ),
                        subtitle: Text(
                          'مثال: يعمل نهارًا ويتوقف ليلًا',
                          style: TextStyle(
                            color: _enabled
                                ? mutedTextColor
                                : disabledTextColor,
                          ),
                        ),
                      ),
                      if (_enabled && _windowEnabled) ...[
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 360;
                            if (compact) {
                              return Column(
                                children: [
                                  _TimeBox(
                                    label: 'من',
                                    value: _formatMinutes(_windowStartMinutes),
                                    onTap: () => _pickTime(true),
                                  ),
                                  const SizedBox(height: 10),
                                  _TimeBox(
                                    label: 'إلى',
                                    value: _formatMinutes(_windowEndMinutes),
                                    onTap: () => _pickTime(false),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _TimeBox(
                                    label: 'من',
                                    value: _formatMinutes(_windowStartMinutes),
                                    onTap: () => _pickTime(true),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TimeBox(
                                    label: 'إلى',
                                    value: _formatMinutes(_windowEndMinutes),
                                    onTap: () => _pickTime(false),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        value: _vibrationEnabled,
                        contentPadding: EdgeInsets.zero,
                        onChanged: _enabled
                            ? (value) =>
                                  setState(() => _vibrationEnabled = value)
                            : null,
                        title: Text(
                          'تشغيل الاهتزاز مع الإشعار',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _enabled ? textColor : disabledTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مرات تكرار الذكر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _enabled ? textColor : disabledTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: _enabled ? 1 : 0.5,
                        child: AbsorbPointer(
                          absorbing: !_enabled,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final minutes in _intervals)
                                ChoiceChip(
                                  label: Text(
                                    _intervalLabel(minutes),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                  selected: _intervalMinutes == minutes,
                                  onSelected: (_) {
                                    setState(() => _intervalMinutes = minutes);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ملاحظة: بعض الأجهزة تؤخر الإشعارات عندما تكون الشاشة مقفولة. '
                        'لو عايز التذكير يفضل منتظم، أضف التطبيق إلى استثناء توفير البطارية.',
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A252A)
                              : Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _summaryText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: mutedTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveSettings,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.notifications_active_rounded),
                          label: Text(_saving ? 'جارٍ الحفظ' : 'حفظ الإعدادات'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _summaryText {
    if (!_enabled) {
      return _unlockOnceEnabled
          ? 'التذكير متوقف حاليًا • ذكر عند فتح قفل الهاتف مفعل'
          : 'التذكير متوقف حاليًا';
    }

    final parts = <String>[
      'كل ${_intervalLabel(_intervalMinutes)}',
      _vibrationEnabled ? 'مع الاهتزاز' : 'بدون اهتزاز',
    ];
    if (_unlockOnceEnabled) {
      parts.add('ذكر عند فتح قفل الهاتف مفعل');
    }
    if (_windowEnabled) {
      parts.add(
        'من ${_formatMinutes(_windowStartMinutes)} إلى ${_formatMinutes(_windowEndMinutes)}',
      );
    }
    if (_pauseAtPrayer) {
      parts.add('يتوقف وقت الصلاة ويعود بعدها بـ $_prayerPauseMinutes دقيقة');
    }
    return 'سيصلك التذكير ${parts.join(' • ')}';
  }

  Future<void> _pickTime(bool isStart) async {
    final source = isStart ? _windowStartMinutes : _windowEndMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: source ~/ 60, minute: source % 60),
    );
    if (picked == null) {
      return;
    }
    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      if (isStart) {
        _windowStartMinutes = minutes;
      } else {
        _windowEndMinutes = minutes;
      }
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      _log(
        'Save pressed: enabled=$_enabled, interval=$_intervalMinutes, pauseAtPrayer=$_pauseAtPrayer, '
        'pauseMinutes=$_prayerPauseMinutes, window=$_windowEnabled '
        '($_windowStartMinutes-$_windowEndMinutes), vibration=$_vibrationEnabled, '
        'unlockOnce=$_unlockOnceEnabled',
      );
      await widget.store.saveSalawatReminderPreferences(
        enabled: _enabled,
        intervalMinutes: _intervalMinutes,
        pauseAtPrayer: _pauseAtPrayer,
        prayerPauseMinutes: _prayerPauseMinutes,
        windowEnabled: _windowEnabled,
        windowStartMinutes: _windowStartMinutes,
        windowEndMinutes: _windowEndMinutes,
        vibrationEnabled: _vibrationEnabled,
        unlockEnabled: _unlockOnceEnabled,
      );
      if (_unlockOnceEnabled) {
        await SalawatUnlockService.start();
      } else {
        await SalawatUnlockService.stop();
      }
      if (!mounted) {
        return;
      }

      final city = _resolvePrayerCity(widget.store.savedPrayerCityName);
      _log('Resolved city: ${city?.name ?? 'null'}');
      await SalawatNotificationService.instance.initialize();
      final canExact =
          SalawatNotificationService.instance.canScheduleExactAlarms;
      if (_enabled && !canExact && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'ملاحظة: الجهاز لا يسمح بالتنبيه الدقيق. قد تتأخر الإشعارات عند قفل الشاشة.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
      }
      unawaited(
        SalawatNotificationService.instance
            .reschedule(
              enabled: _enabled,
              intervalMinutes: _intervalMinutes,
              pauseAtPrayer: _pauseAtPrayer,
              prayerPauseMinutes: _prayerPauseMinutes,
              windowEnabled: _windowEnabled,
              windowStartMinutes: _windowStartMinutes,
              windowEndMinutes: _windowEndMinutes,
              vibrationEnabled: _vibrationEnabled,
              city: city,
              prayerOffsets: widget.store.savedPrayerOffsets,
            )
            .catchError((_) {}),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    }
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

  String _intervalLabel(int minutes) {
    if (minutes == 60) {
      return 'ساعة';
    }
    if (minutes == 120) {
      return 'ساعتين';
    }
    return '$minutes دقائق';
  }

  String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minuteLabel = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteLabel $period';
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF152127) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF26343B)
        : const Color(0xFFE3D6B8);
    final textColor = isDark
        ? const Color(0xFFF2ECDF)
        : const Color(0xFF143A2A);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.schedule_rounded, color: textColor),
          ],
        ),
      ),
    );
  }
}
