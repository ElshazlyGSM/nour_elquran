import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/utils/arabic_numbers.dart';
import '../../../services/adhan_audio_cache_service.dart';

class PrayerSettingsResult {
  const PrayerSettingsResult({
    required this.adhanEnabled,
    required this.hijriOffset,
    required this.prayerOffsets,
    required this.prayerEnabledMap,
    required this.prayerReminderByPrayer,
    required this.adhanProfile,
  });

  final bool adhanEnabled;
  final int hijriOffset;
  final Map<String, int> prayerOffsets;
  final Map<String, bool> prayerEnabledMap;
  final Map<String, int> prayerReminderByPrayer;
  final String adhanProfile;
}

class PrayerSettingsPage extends StatefulWidget {
  const PrayerSettingsPage({
    super.key,
    required this.prayerKeys,
    required this.prayerNames,
    required this.prayerTimes,
    required this.initialAdhanEnabled,
    required this.initialHijriOffset,
    required this.initialPrayerOffsets,
    required this.initialPrayerEnabledMap,
    required this.initialPrayerReminderByPrayer,
    required this.initialAdhanProfile,
    required this.adhanProfiles,
    required this.onChanged,
  });

  final List<String> prayerKeys;
  final Map<String, String> prayerNames;
  final Map<String, DateTime> prayerTimes;
  final bool initialAdhanEnabled;
  final int initialHijriOffset;
  final Map<String, int> initialPrayerOffsets;
  final Map<String, bool> initialPrayerEnabledMap;
  final Map<String, int> initialPrayerReminderByPrayer;
  final String initialAdhanProfile;
  final List<(String, String)> adhanProfiles;
  final Future<void> Function(PrayerSettingsResult result) onChanged;

  @override
  State<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends State<PrayerSettingsPage> {
  late bool _adhanEnabled;
  late int _hijriOffset;
  late Map<String, int> _prayerOffsets;
  late Map<String, bool> _prayerEnabledMap;
  late Map<String, int> _prayerReminderByPrayer;
  late String _adhanProfile;

  final AudioPlayer _previewPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _isPreviewLoading = false;
  String? _previewingProfile;
  String? _pendingPreviewProfile;
  bool _isSunrisePreviewing = false;
  Future<void> _previewOperation = Future<void>.value();
  final Set<String> _downloadedProfiles = <String>{};
  final Set<String> _downloadingProfiles = <String>{};
  final Map<String, double> _downloadProgress = <String, double>{};
  bool _downloadStatesLoaded = false;
  Future<void> _saveFuture = Future<void>.value();
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _adhanEnabled = widget.initialAdhanEnabled;
    _hijriOffset = widget.initialHijriOffset;
    _prayerOffsets = {
      for (final entry in widget.initialPrayerOffsets.entries)
        entry.key: entry.value.clamp(-30, 30),
    };
    _prayerEnabledMap = Map<String, bool>.from(widget.initialPrayerEnabledMap);
    _prayerReminderByPrayer = {
      for (final entry in widget.initialPrayerReminderByPrayer.entries)
        entry.key: entry.value.clamp(0, 60),
    };
    _adhanProfile = widget.initialAdhanProfile;

    _playerStateSub = _previewPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (_isSunrisePreviewing &&
          (state.processingState == ProcessingState.completed ||
              (!state.playing &&
                  state.processingState == ProcessingState.idle))) {
        setState(() => _isSunrisePreviewing = false);
      }
      if (_isPreviewLoading &&
          _pendingPreviewProfile != null &&
          (state.playing ||
              state.processingState == ProcessingState.ready ||
              state.processingState == ProcessingState.buffering)) {
        setState(() {
          _isPreviewLoading = false;
          _previewingProfile = _pendingPreviewProfile;
          _pendingPreviewProfile = null;
        });
        return;
      }
      if (state.processingState == ProcessingState.completed ||
          (!_isPreviewLoading &&
              !state.playing &&
              state.processingState == ProcessingState.idle)) {
        setState(() {
          _previewingProfile = null;
          _pendingPreviewProfile = null;
          _isPreviewLoading = false;
        });
      }
    });

    unawaited(_loadDownloadStates());
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _previewPlayer.dispose();
    super.dispose();
  }

  PrayerSettingsResult _buildResult() {
    return PrayerSettingsResult(
      adhanEnabled: _adhanEnabled,
      hijriOffset: _hijriOffset,
      prayerOffsets: Map<String, int>.from(_prayerOffsets),
      prayerEnabledMap: Map<String, bool>.from(_prayerEnabledMap),
      prayerReminderByPrayer: Map<String, int>.from(_prayerReminderByPrayer),
      adhanProfile: _adhanProfile,
    );
  }

  Future<void> _persistNow() {
    final result = _buildResult();
    _saveFuture = _saveFuture.then((_) async {
      await widget.onChanged(result);
      _dirty = false;
    });
    return _saveFuture;
  }

  Future<void> _flushPendingSave() async {
    if (_dirty) {
      await _persistNow();
    }
    await _saveFuture;
  }

  void _mutate(VoidCallback action) {
    setState(() {
      action();
      _dirty = true;
    });
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'م' : 'ص';
    return '${toArabicNumber(hour)}:${_toArabicDigits(minute)} $suffix';
  }

  DateTime? _effectivePrayerTime(String key) {
    final baseTime = widget.prayerTimes[key];
    if (baseTime == null) return null;
    final offset = _prayerOffsets[key] ?? 0;
    return baseTime.add(Duration(minutes: offset));
  }

  String _toArabicDigits(String input) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      final index = western.indexOf(char);
      buffer.write(index == -1 ? char : eastern[index]);
    }
    return buffer.toString();
  }

  String _formatHijriOffset(int value) {
    if (value == 0) return 'بدون';
    final sign = value > 0 ? '+' : '-';
    return '$sign ${toArabicNumber(value.abs())} يوم';
  }

  Future<void> _loadDownloadStates() async {
    final downloaded = <String>{};
    for (final profile in widget.adhanProfiles) {
      if (!AdhanAudioCacheService.instance.supportsProfile(profile.$1))
        continue;
      if (await AdhanAudioCacheService.instance.isDownloaded(profile.$1)) {
        downloaded.add(profile.$1);
      }
    }
    if (!mounted) return;
    setState(() {
      _downloadStatesLoaded = true;
      _downloadedProfiles
        ..clear()
        ..addAll(downloaded);
    });
  }

  Future<void> _stopAllPreviewState() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _previewingProfile = null;
      _pendingPreviewProfile = null;
      _isPreviewLoading = false;
      _isSunrisePreviewing = false;
    });
  }

  Future<void> _runSerializedPreview(Future<void> Function() action) async {
    _previewOperation = _previewOperation.then((_) => action());
    await _previewOperation;
  }

  Future<void> _previewAdhan(String profile) async {
    await _runSerializedPreview(() async {
      if (_isDividerProfile(profile)) {
        return;
      }

      final isSameRunning =
          (_previewingProfile == profile ||
              _pendingPreviewProfile == profile) &&
          (_previewPlayer.playing || _isPreviewLoading);
      if (isSameRunning) {
        await _stopAllPreviewState();
        return;
      }

      await _stopAllPreviewState();

      if (profile == 'default') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا الخيار يستخدم نغمة الهاتف الافتراضية'),
          ),
        );
        return;
      }

      if (_isBundledProfile(profile)) {
        if (!mounted) return;
        setState(() {
          _previewingProfile = profile;
          _pendingPreviewProfile = null;
          _isPreviewLoading = false;
          _isSunrisePreviewing = false;
        });
        await _previewPlayer.setAsset('assets/audio/azan-alah-akbr.ogg');
        unawaited(_previewPlayer.play());
        return;
      }

      final localPath = await AdhanAudioCacheService.instance
          .localPathForProfile(profile);
      if (localPath == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حمّل هذا الأذان أولًا لتجربته واستخدامه'),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _previewingProfile = profile;
        _pendingPreviewProfile = null;
        _isPreviewLoading = false;
        _isSunrisePreviewing = false;
      });

      await _previewPlayer.setFilePath(localPath);
      unawaited(_previewPlayer.play());
    });
  }

  Future<void> _previewSunriseTone() async {
    await _runSerializedPreview(() async {
      final isSameRunning = _isSunrisePreviewing && _previewPlayer.playing;
      if (isSameRunning) {
        await _stopAllPreviewState();
        return;
      }

      await _stopAllPreviewState();

      if (!mounted) return;
      setState(() {
        _previewingProfile = null;
        _pendingPreviewProfile = null;
        _isPreviewLoading = false;
        _isSunrisePreviewing = true;
      });

      try {
        await _previewPlayer.setAsset('assets/audio/shoro2.ogg');
        unawaited(_previewPlayer.play());
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSunrisePreviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تشغيل معاينة الشروق')),
        );
      }
    });
  }

  bool _isDividerProfile(String profile) => profile == '__full_adhans__';

  bool _isBundledProfile(String profile) => profile == 'allah_akbar';

  String? _profileSubtitle(String profile) {
    if (_isDividerProfile(profile)) {
      return null;
    }
    if (profile == 'default') {
      return null;
    }
    if (_isBundledProfile(profile)) {
      return null;
    }
    final isDownloading = _downloadingProfiles.contains(profile);
    final isDownloaded = _downloadedProfiles.contains(profile);
    if (isDownloading) {
      return 'قيد التحميل';
    }
    if (isDownloaded) {
      return 'جاهز للاستخدام';
    }
    return 'حمّله أولًا';
  }

  Future<void> _downloadAdhan(String profile) async {
    if (_downloadingProfiles.contains(profile) ||
        _downloadedProfiles.contains(profile)) {
      return;
    }

    setState(() {
      _downloadingProfiles.add(profile);
      _downloadProgress[profile] = 0;
    });

    try {
      await AdhanAudioCacheService.instance.downloadProfile(
        profile: profile,
        onProgress: (progress) async {
          if (!mounted) return;
          setState(() => _downloadProgress[profile] = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _downloadingProfiles.remove(profile);
        _downloadProgress.remove(profile);
        _downloadedProfiles.add(profile);
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تم تنزيل الأذان وبات جاهزًا للاختيار فورًا'),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloadingProfiles.remove(profile);
        _downloadProgress.remove(profile);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تنزيل ملف الأذان')));
    }
  }

  Widget _buildDownloadAction(String profile) {
    if (!AdhanAudioCacheService.instance.supportsProfile(profile) ||
        _isBundledProfile(profile)) {
      return const SizedBox(width: 40);
    }
    if (!_downloadStatesLoaded) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final isDownloading = _downloadingProfiles.contains(profile);
    final isDownloaded = _downloadedProfiles.contains(profile);
    final progress = _downloadProgress[profile] ?? 0;

    return IconButton(
      tooltip: isDownloaded ? 'تم التنزيل' : 'تنزيل الأذان',
      onPressed: isDownloading || isDownloaded
          ? null
          : () => _downloadAdhan(profile),
      icon: isDownloading
          ? SizedBox(
              width: 22,
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    strokeWidth: 2.2,
                  ),
                  Text(
                    '${(progress * 100).round()}',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          : Icon(
              isDownloaded
                  ? Icons.download_done_rounded
                  : Icons.download_for_offline_rounded,
              color: isDownloaded ? const Color(0xFF355B3D) : null,
            ),
    );
  }

  bool _canSelectProfile(String profile) {
    if (_isDividerProfile(profile)) {
      return false;
    }
    if (!AdhanAudioCacheService.instance.supportsProfile(profile) ||
        _isBundledProfile(profile)) {
      return true;
    }
    if (!_downloadStatesLoaded) {
      return false;
    }
    return _downloadedProfiles.contains(profile);
  }

  void _selectProfile(String profile) {
    if (_isDividerProfile(profile)) {
      return;
    }
    if (_canSelectProfile(profile)) {
      _mutate(() => _adhanProfile = profile);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('حمّل هذا الأذان أولًا ثم اختره')),
      );
  }

  Widget _buildAdhanProfilesCard(
    Color surfaceColor,
    Color borderColor,
    Color titleColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        childrenPadding: EdgeInsets.zero,
        dense: true,
        minTileHeight: 52,
        leading: const Icon(Icons.music_note_rounded),
        title: const Text(
          'نغمة الأذان',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          widget.adhanProfiles
              .firstWhere((profile) => profile.$1 == _adhanProfile)
              .$2,
          style: TextStyle(color: mutedColor, fontWeight: FontWeight.w700),
        ),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wb_twilight_rounded),
            title: const Text(
              'تنبيه الشروق',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'يعمل مع الشروق فقط',
              style: TextStyle(color: mutedColor),
            ),
            trailing: IconButton(
              onPressed: _previewSunriseTone,
              icon: Icon(
                _isSunrisePreviewing
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_fill_rounded,
              ),
            ),
          ),
          const Divider(height: 18),
          for (final profile in widget.adhanProfiles)
            Builder(
              builder: (context) {
                if (_isDividerProfile(profile.$1)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: borderColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            profile.$2,
                            style: TextStyle(
                              color: mutedColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: borderColor)),
                      ],
                    ),
                  );
                }

                final canSelect = _canSelectProfile(profile.$1);
                final subtitle = _profileSubtitle(profile.$1);
                final showPreview = profile.$1 != 'default';
                return ListTile(
                  onTap: canSelect ? () => _selectProfile(profile.$1) : null,
                  enabled: canSelect,
                  contentPadding: EdgeInsets.zero,
                  minLeadingWidth: 32,
                  leading: Icon(
                    _adhanProfile == profile.$1
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: _adhanProfile == profile.$1
                        ? const Color(0xFF355B3D)
                        : canSelect
                        ? const Color(0xFFB6AA8A)
                        : const Color(0xFFD0C7B3),
                  ),
                  title: Text(
                    profile.$2,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: canSelect ? titleColor : mutedColor,
                    ),
                  ),
                  subtitle: subtitle == null
                      ? null
                      : Text(subtitle, style: TextStyle(color: mutedColor)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDownloadAction(profile.$1),
                      if (showPreview)
                        IconButton(
                          onPressed: () => _previewAdhan(profile.$1),
                          icon: SizedBox(
                            width: 26,
                            height: 26,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  (_previewingProfile == profile.$1 ||
                                          _pendingPreviewProfile == profile.$1)
                                      ? Icons.stop_circle_rounded
                                      : Icons.play_circle_fill_rounded,
                                ),
                                if (_isPreviewLoading &&
                                    _pendingPreviewProfile == profile.$1)
                                  const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPrayerTile(String key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reminder = _prayerReminderByPrayer[key] ?? 0;
    final offset = _prayerOffsets[key] ?? 0;
    final enabled = _prayerEnabledMap[key] ?? true;
    final adhanControlsEnabled = _adhanEnabled && enabled;
    final reminderControlsEnabled = enabled;
    final prayerTime = _effectivePrayerTime(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152127) : const Color(0xFFF8F3E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF26343B) : const Color(0xFFE8DCC0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  widget.prayerNames[key] ?? key,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF2ECDF) : null,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      prayerTime == null ? '--' : _formatTime(prayerTime),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFF2ECDF)
                            : const Color(0xFF143A2A),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Switch.adaptive(
                    value: adhanControlsEnabled,
                    onChanged: _adhanEnabled
                        ? (value) =>
                              _mutate(() => _prayerEnabledMap[key] = value)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PrayerSettingBox(
                  title: 'تعديل الوقت',
                  value: offset == 0
                      ? 'بدون'
                      : '${offset > 0 ? '+' : '-'} ${toArabicNumber(offset.abs())} د',
                  onMinus: reminderControlsEnabled
                      ? () => _mutate(
                          () => _prayerOffsets[key] =
                              ((_prayerOffsets[key] ?? 0) - 1).clamp(-30, 30),
                        )
                      : null,
                  onPlus: reminderControlsEnabled
                      ? () => _mutate(
                          () => _prayerOffsets[key] =
                              ((_prayerOffsets[key] ?? 0) + 1).clamp(-30, 30),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PrayerSettingBox(
                  title: 'تذكير قبل الموعد',
                  value: reminder == 0
                      ? 'عند الوقت'
                      : '${toArabicNumber(reminder)} د',
                  onMinus: !reminderControlsEnabled
                      ? null
                      : () => _mutate(
                          () => _prayerReminderByPrayer[key] = (reminder - 1)
                              .clamp(0, 60),
                        ),
                  onPlus: !reminderControlsEnabled
                      ? null
                      : () => _mutate(
                          () => _prayerReminderByPrayer[key] = (reminder + 1)
                              .clamp(0, 60),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF152127)
        : const Color(0xFFF8F3E7);
    final borderColor = isDark
        ? const Color(0xFF26343B)
        : const Color(0xFFE8DCC0);
    final titleColor = isDark
        ? const Color(0xFFF2ECDF)
        : const Color(0xFF143A2A);
    final mutedColor = isDark
        ? const Color(0xFFB7C1BC)
        : const Color(0xFF8E8677);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, _) {
        unawaited(_flushPendingSave());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('إعدادات مواقيت الصلاة')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _adhanEnabled,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) =>
                          _mutate(() => _adhanEnabled = value),
                      title: const Text(
                        'تفعيل إشعارات الصلاة',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text(
                        'يمكنك إيقاف صوت الأذان مع بقاء تذكيرات ما قبل الموعد مفعلة',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildAdhanProfilesCard(
                surfaceColor,
                borderColor,
                titleColor,
                mutedColor,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'تعديل التاريخ الهجري',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _mutate(
                        () => _hijriOffset = (_hijriOffset - 1).clamp(-3, 3),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        _formatHijriOffset(_hijriOffset),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _mutate(
                        () => _hijriOffset = (_hijriOffset + 1).clamp(-3, 3),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final key in widget.prayerKeys) _buildPrayerTile(key),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerSettingBox extends StatelessWidget {
  const _PrayerSettingBox({
    required this.title,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String title;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: isDark ? const Color(0xFFF2ECDF) : null,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                onPressed: onMinus,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_rounded, size: 18),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFF2ECDF)
                        : const Color(0xFF143A2A),
                  ),
                ),
              ),
              IconButton(
                onPressed: onPlus,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
