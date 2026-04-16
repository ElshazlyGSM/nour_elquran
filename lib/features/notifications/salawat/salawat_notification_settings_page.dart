import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/egypt_prayer_cities.dart';
import '../../../services/background_execution_settings.dart';
import '../../../services/quran_store.dart';
import 'salawat_notification_service.dart';

class SalawatReminderPage extends StatefulWidget {
  const SalawatReminderPage({super.key, required this.store});

  final QuranStore store;

  @override
  State<SalawatReminderPage> createState() => _SalawatReminderPageState();
}

class _SalawatReminderPageState extends State<SalawatReminderPage> {
  static const _intervals = [5, 10, 15, 30, 45, 60, 120];
  static const _prayerPauseOptions = [15, 20, 30, 45, 60];

  late bool _enabled;
  late int _intervalMinutes;
  late bool _pauseAtPrayer;
  late int _prayerPauseMinutes;
  late bool _windowEnabled;
  late int _windowStartMinutes;
  late int _windowEndMinutes;
  late bool _vibrationEnabled;
  Future<void> _saveFuture = Future<void>.value();
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.store.savedSalawatReminderEnabled;
    _intervalMinutes = widget.store.savedSalawatReminderIntervalMinutes;
    if (!_intervals.contains(_intervalMinutes)) {
      _intervalMinutes = _intervals.first;
    }
    _pauseAtPrayer = widget.store.savedSalawatPauseAtPrayer;
    _prayerPauseMinutes = widget.store.savedSalawatPrayerPauseMinutes;
    _windowEnabled = widget.store.savedSalawatWindowEnabled;
    _windowStartMinutes = widget.store.savedSalawatWindowStartMinutes;
    _windowEndMinutes = widget.store.savedSalawatWindowEndMinutes;
    _vibrationEnabled = widget.store.savedSalawatVibrationEnabled;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _mutate(VoidCallback action) {
    setState(() {
      action();
      _dirty = true;
    });
  }

  void _onEnabledChanged(bool value) {
    final wasEnabled = _enabled;
    _mutate(() => _enabled = value);
    if (!wasEnabled && value) {
      unawaited(
        SalawatNotificationService.instance.showInstantReminder(
          vibrationEnabled: _vibrationEnabled,
        ),
      );
    }
  }

  Future<void> _flushPendingSave() async {
    if (_dirty) {
      await _saveSettings(showSuccess: false);
    }
    await _saveFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF152127) : const Color(0xFFF8F3E7);
    final borderColor = isDark ? const Color(0xFF26343B) : const Color(0xFFE3D6B8);
    final textColor = isDark ? const Color(0xFFF2ECDF) : const Color(0xFF143A2A);
    final mutedTextColor = isDark ? const Color(0xFFBAC3BE) : const Color(0xFF4F5A53);
    final disabledTextColor = isDark ? const Color(0xFF7B8782) : const Color(0xFF8F9B95);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, _) {
        unawaited(_flushPendingSave());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('الصلاة والسلام على النبي')),
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
                          onChanged: _onEnabledChanged,
                          title: const Text(
                            'تفعيل التذكير',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            'تنبيه دوري بسيط للصلاة والسلام على سيدنا محمد صلى الله عليه وسلم',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'فاصل التذكير',
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
                                      style: TextStyle(fontSize: 12, color: textColor),
                                    ),
                                    selected: _intervalMinutes == minutes,
                                    onSelected: (_) => _mutate(() => _intervalMinutes = minutes),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          value: _pauseAtPrayer,
                          contentPadding: EdgeInsets.zero,
                          onChanged: _enabled ? (value) => _mutate(() => _pauseAtPrayer = value) : null,
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
                              color: _enabled ? mutedTextColor : disabledTextColor,
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
                                    style: TextStyle(fontSize: 12, color: textColor),
                                  ),
                                  selected: _prayerPauseMinutes == minutes,
                                  onSelected: (_) => _mutate(() => _prayerPauseMinutes = minutes),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          value: _windowEnabled,
                          contentPadding: EdgeInsets.zero,
                          onChanged: _enabled ? (value) => _mutate(() => _windowEnabled = value) : null,
                          title: Text(
                            'تحديد فترة التشغيل',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _enabled ? textColor : disabledTextColor,
                            ),
                          ),
                          subtitle: Text(
                            'مثال: يعمل نهارًا ويتوقف ليلًا',
                            style: TextStyle(
                              color: _enabled ? mutedTextColor : disabledTextColor,
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
                          onChanged: _enabled ? (value) => _mutate(() => _vibrationEnabled = value) : null,
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
                          'ملحوظة: بعض الأجهزة قد تؤخر الإشعارات عند قفل الشاشة أو مع تقييد البطارية. سيأخذك الزر إلى إعدادات التطبيق، ومن هناك ادخل إلى البطارية أو التشغيل في الخلفية واسمح للتطبيق بالعمل دون تقييد.',
                          style: TextStyle(fontSize: 12, color: mutedTextColor),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await BackgroundExecutionSettings.openBackgroundSettings();
                          },
                          icon: const Icon(Icons.battery_saver_rounded),
                          label: const Text('فتح إعدادات التطبيق والبطارية'),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A252A) : Colors.white.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _summaryText,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: mutedTextColor),
                          ),
                        ),
                        if (_saving) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'جارٍ حفظ التغييرات...',
                                style: TextStyle(color: mutedTextColor, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _summaryText {
    if (!_enabled) {
      return 'التذكير الدوري متوقف حاليًا';
    }

    final parts = <String>[
      'كل ${_intervalLabel(_intervalMinutes)}',
      _vibrationEnabled ? 'مع الاهتزاز' : 'بدون اهتزاز',
    ];
    if (_windowEnabled) {
      parts.add('من ${_formatMinutes(_windowStartMinutes)} إلى ${_formatMinutes(_windowEndMinutes)}');
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
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    _mutate(() {
      if (isStart) {
        _windowStartMinutes = minutes;
      } else {
        _windowEndMinutes = minutes;
      }
    });
  }

  Future<void> _saveSettings({required bool showSuccess}) {
    _saveFuture = _saveFuture.then((_) async {
      if (mounted) {
        setState(() => _saving = true);
      }
      try {
        await widget.store.saveSalawatReminderPreferences(
          enabled: _enabled,
          intervalMinutes: _intervalMinutes,
          pauseAtPrayer: _pauseAtPrayer,
        prayerPauseMinutes: _prayerPauseMinutes,
        windowEnabled: _windowEnabled,
        windowStartMinutes: _windowStartMinutes,
        windowEndMinutes: _windowEndMinutes,
        vibrationEnabled: _vibrationEnabled,
        unlockEnabled: false,
      );

        if (mounted) {
          setState(() {
            _saving = false;
            _dirty = false;
          });
        }

        unawaited(() async {
          final city = _resolvePrayerCity(widget.store.savedPrayerCityName);
          await SalawatNotificationService.instance.initialize();
          final canExact = SalawatNotificationService.instance.canScheduleExactAlarms;
          if (_enabled && !canExact && mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('ملاحظة: الجهاز قد يؤخر بعض الإشعارات الدقيقة عند قفل الشاشة.'),
                  duration: Duration(seconds: 3),
                ),
              );
          }

          await SalawatNotificationService.instance.reschedule(
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
          );
          if (showSuccess && mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات')));
          }
        }());
      } catch (_) {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    });
    return _saveFuture;
  }

  PrayerCity? _resolvePrayerCity(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) {
      return null;
    }
    return resolvePrayerCityByName(cityName);
  }

  String _intervalLabel(int minutes) {
    if (minutes == 60) return 'ساعة';
    if (minutes == 120) return 'ساعتين';
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
    final borderColor = isDark ? const Color(0xFF26343B) : const Color(0xFFE3D6B8);
    final textColor = isDark ? const Color(0xFFF2ECDF) : const Color(0xFF143A2A);

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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
              ),
            ),
            Icon(Icons.schedule_rounded, color: textColor),
          ],
        ),
      ),
    );
  }
}







