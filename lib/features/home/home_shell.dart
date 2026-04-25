import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/utils/arabic_numbers.dart';
import '../../data/egypt_prayer_cities.dart';
import '../../services/current_quran_text_source.dart';
import '../../services/quran_store.dart';
import '../reader/reader_page.dart';
import 'adhkar_page.dart';
import 'prayer_times_page.dart';
import 'prophet_section_page.dart';
import 'quran_section_shell.dart';
import 'tasbih_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final QuranStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _quranSource = currentQuranTextSource;
  static const _prayerNames = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  Timer? _countdownTimer;
  final ValueNotifier<DateTime> _nowNotifier = ValueNotifier(DateTime.now());

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _nowNotifier.value = DateTime.now();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nowNotifier.dispose();
    super.dispose();
  }

  Future<void> _showThemeModeSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final current = widget.store.savedThemeMode;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'وضع التطبيق',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('اختر بين الفاتح والداكن أو اتبع وضع الجهاز'),
              ),
              _ThemeModeTile(
                value: 'system',
                current: current,
                title: 'اتباع وضع الجهاز',
                icon: Icons.brightness_auto_rounded,
                onTap: () => Navigator.of(context).pop('system'),
              ),
              _ThemeModeTile(
                value: 'light',
                current: current,
                title: 'الوضع الفاتح',
                icon: Icons.light_mode_rounded,
                onTap: () => Navigator.of(context).pop('light'),
              ),
              _ThemeModeTile(
                value: 'dark',
                current: current,
                title: 'الوضع الداكن',
                icon: Icons.dark_mode_rounded,
                onTap: () => Navigator.of(context).pop('dark'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }
    await widget.store.saveThemeMode(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final rawTextScale = mediaQuery.textScaler.scale(16) / 16;
    final clampedTextScale = rawTextScale.clamp(1.0, 1.10);
    final lastRead = widget.store.lastRead;
    final prayerCity = _resolveSavedCity();
    final screenWidth = mediaQuery.size.width;
    final isCompact = screenWidth < 380;
    final crossAxisCount = screenWidth < 560 ? 2 : 3;
    double cardAspectRatio;
    if (crossAxisCount == 2) {
      if (screenWidth < 360) {
        cardAspectRatio = 0.76;
      } else if (screenWidth < 420) {
        cardAspectRatio = 0.82;
      } else {
        cardAspectRatio = 0.88;
      }
    } else {
      cardAspectRatio = screenWidth < 760 ? 0.94 : 1.00;
    }
    if (rawTextScale > 1.08) {
      cardAspectRatio -= 0.04;
    }

    final backgroundGradient = isDark
        ? const [Color(0xFF0D1417), Color(0xFF101A1E), Color(0xFF101A1E)]
        : const [Color(0xFF143A2A), Color(0xFF143A2A), Color(0xFFF6F0E2)];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundGradient,
            stops: const [0, 0.48, 0.80],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(clampedTextScale),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'رفيقك اليومي للقرآن والذكر',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontSize: isCompact ? 24 : 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.10 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showThemeModeSheet(context),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(switch (widget.store.savedThemeMode) {
                                'dark' => Icons.dark_mode_rounded,
                                'system' => Icons.brightness_auto_rounded,
                                _ => Icons.light_mode_rounded,
                              }, color: const Color(0xFFE6C16A)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'المصحف، مواقيت الصلاة، الأذكار والسبحة في مكان واحد.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: isCompact ? 14 : 15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: _nowNotifier,
                      builder: (context, now, _) {
                        final upcomingPrayer = _buildUpcomingPrayer(now);
                        final hijriDate = _buildHijriDate(now);
                        return _HomeUpcomingPrayerCard(
                          prayerName: upcomingPrayer.name,
                          prayerTime: _formatTime(upcomingPrayer.time),
                          remaining: _formatCountdown(
                            upcomingPrayer.time.difference(now),
                          ),
                          hijriDate: hijriDate,
                          cityLabel: prayerCity.name,
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    if (lastRead != null)
                      _ContinueCard(
                        surahName: _quranSource.getSurahNameArabic(
                          lastRead.surahNumber,
                        ),
                        verseNumber: lastRead.verseNumber,
                        onTap: () => _openPage(
                          context,
                          ReaderPage(
                            store: widget.store,
                            surahNumber: lastRead.surahNumber,
                            initialVerse: lastRead.verseNumber,
                          ),
                        ),
                      ),
                    if (lastRead != null) const SizedBox(height: 14),
                    _ProphetHighlightCard(
                      onTap: () => _openPage(
                        context,
                        ProphetSectionPage(store: widget.store),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: cardAspectRatio,
                      children: [
                        _FeatureCard(
                          title: 'المصحف',
                          subtitle: 'قراءة واستماع وتفسير وتجويد ومصاحف متعددة',
                          icon: Icons.menu_book_rounded,
                          accent: isDark
                              ? const Color(0xFFE6C16A)
                              : const Color(0xFF143A2A),
                          onTap: () => _openPage(
                            context,
                            QuranSectionShell(store: widget.store),
                          ),
                        ),
                        _FeatureCard(
                          title: 'مواقيت الصلاة',
                          subtitle: 'التوقيت والتنبيهات وبوصلة القبلة',
                          icon: Icons.access_time_filled_rounded,
                          accent: const Color(0xFF8C6A1F),
                          onTap: () => _openPage(
                            context,
                            PrayerTimesPage(store: widget.store),
                          ),
                        ),
                        _FeatureCard(
                          title: 'السبحة',
                          subtitle: 'عداد وأذكار مختارة وذكر مخصص',
                          icon: Icons.touch_app_rounded,
                          accent: isDark
                              ? const Color(0xFFE6C16A)
                              : const Color(0xFF2D5C4E),
                          onTap: () => _openPage(
                            context,
                            TasbihPage(store: widget.store),
                          ),
                        ),
                        _FeatureCard(
                          title: 'الأذكار',
                          subtitle: 'جميع الأذكار المهمة في حياة المسلم',
                          icon: Icons.auto_stories_rounded,
                          accent: const Color(0xFF6B7A44),
                          onTap: () => _openPage(
                            context,
                            AdhkarPage(store: widget.store),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            Directionality(textDirection: TextDirection.rtl, child: page),
      ),
    );
  }

  PrayerCity _resolveSavedCity() {
    final savedName = widget.store.savedPrayerCityName;
    return resolvePrayerCityByName(savedName);
  }

  PrayerTimes _buildPrayerTimes(DateTime date) {
    final city = _resolveSavedCity();
    final params = city.method.parameters;
    final offsets = widget.store.savedPrayerOffsets;
    final summerOffset = widget.store.savedPrayerSummerTimeEnabled ? 60 : 0;
    params.adjustments = {
      Prayer.fajr: (offsets['fajr'] ?? 0) + summerOffset,
      Prayer.sunrise: (offsets['sunrise'] ?? 0) + summerOffset,
      Prayer.dhuhr: (offsets['dhuhr'] ?? 0) + summerOffset,
      Prayer.asr: (offsets['asr'] ?? 0) + summerOffset,
      Prayer.maghrib: (offsets['maghrib'] ?? 0) + summerOffset,
      Prayer.isha: (offsets['isha'] ?? 0) + summerOffset,
    };
    return PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: city.coordinates,
      calculationParameters: params,
    );
  }

  _UpcomingPrayerData _buildUpcomingPrayer(DateTime now) {
    final enabledMap = widget.store.savedPrayerEnabledMap;
    final today = _buildPrayerTimes(now);
    final entries = <_UpcomingPrayerData>[
      _UpcomingPrayerData(
        key: 'fajr',
        name: _prayerNames['fajr']!,
        time: today.fajr.toLocal(),
      ),
      _UpcomingPrayerData(
        key: 'dhuhr',
        name: _prayerNames['dhuhr']!,
        time: today.dhuhr.toLocal(),
      ),
      _UpcomingPrayerData(
        key: 'asr',
        name: _prayerNames['asr']!,
        time: today.asr.toLocal(),
      ),
      _UpcomingPrayerData(
        key: 'maghrib',
        name: _prayerNames['maghrib']!,
        time: today.maghrib.toLocal(),
      ),
      _UpcomingPrayerData(
        key: 'isha',
        name: _prayerNames['isha']!,
        time: today.isha.toLocal(),
      ),
    ];

    for (final entry in entries) {
      if ((enabledMap[entry.key] ?? true) && entry.time.isAfter(now)) {
        return entry;
      }
    }

    final tomorrowFajr = _buildPrayerTimes(
      now.add(const Duration(days: 1)),
    ).fajr.toLocal();
    return _UpcomingPrayerData(
      key: 'fajr',
      name: _prayerNames['fajr']!,
      time: tomorrowFajr,
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'م' : 'ص';
    return '${toArabicNumber(hour)}:${_toArabicDigits(minute)} $suffix';
  }

  String _formatCountdown(Duration duration) {
    if (duration.isNegative) {
      return '٠٠:٠٠:٠٠';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${_toArabicDigits(hours.toString().padLeft(2, '0'))}:${_toArabicDigits(minutes.toString().padLeft(2, '0'))}:${_toArabicDigits(seconds.toString().padLeft(2, '0'))}';
  }

  String _toArabicDigits(String value) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      final index = western.indexOf(char);
      buffer.write(index == -1 ? char : eastern[index]);
    }
    return buffer.toString();
  }

  String _buildHijriDate(DateTime now) {
    HijriCalendar.setLocal('ar');
    final offset = widget.store.savedPrayerHijriOffset;
    final hijri = HijriCalendar.fromDate(
      DateTime(now.year, now.month, now.day).add(Duration(days: offset)),
    );
    return '${toArabicNumber(hijri.hDay)} ${hijri.longMonthName} ${toArabicNumber(hijri.hYear)}';
  }
}

class _UpcomingPrayerData {
  const _UpcomingPrayerData({
    required this.key,
    required this.name,
    required this.time,
  });

  final String key;
  final String name;
  final DateTime time;
}

class _HomeUpcomingPrayerCard extends StatelessWidget {
  const _HomeUpcomingPrayerCard({
    required this.prayerName,
    required this.prayerTime,
    required this.remaining,
    required this.hijriDate,
    required this.cityLabel,
  });

  final String prayerName;
  final String prayerTime;
  final String remaining;
  final String hijriDate;
  final String cityLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE6C16A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.access_time_filled_rounded,
              color: Color(0xFF143A2A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أقرب صلاة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$prayerName • $prayerTime',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cityLabel,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'الوقت المتبقي',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                remaining,
                style: const TextStyle(
                  color: Color(0xFFE6C16A),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hijriDate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.surahName,
    required this.verseNumber,
    required this.onTap,
  });

  final String surahName;
  final int verseNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF18242A)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF25343C)
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6C16A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF143A2A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'متابعة القراءة',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF4EEE0) : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سورة $surahName • آية ${toArabicNumber(verseNumber)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFD4CEC1) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final scale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      1.10,
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = shortestSide < 390 || scale > 1.06;
            final veryTight =
                constraints.maxHeight < 170 || constraints.maxWidth < 148;
            final iconBoxSize = veryTight
                ? 44.0
                : (shortestSide >= 430 ? 60.0 : (compact ? 50.0 : 54.0));
            final iconSize = veryTight
                ? 24.0
                : (shortestSide >= 430 ? 32.0 : (compact ? 27.0 : 29.0));
            final iconRadius = veryTight
                ? 14.0
                : (shortestSide >= 430 ? 20.0 : (compact ? 16.0 : 18.0));
            final titleSize = veryTight ? 16.0 : (compact ? 17.0 : 18.0);
            final subtitleSize = veryTight ? 10.0 : (compact ? 11.5 : 13.0);
            final betweenGap = veryTight ? 3.0 : (compact ? 4.0 : 6.0);
            final verticalPadding = veryTight
                ? 10.0
                : (scale > 1.06 ? 12.0 : 14.0);

            return Padding(
              padding: EdgeInsets.all(verticalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(iconRadius),
                    ),
                    child: Icon(icon, color: accent, size: iconSize),
                  ),
                  SizedBox(height: veryTight ? 6 : (compact ? 8 : 10)),
                  Text(
                    title,
                    textScaler: TextScaler.noScaling,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF1EBDE)
                          : const Color(0xFF143A2A),
                    ),
                  ),
                  SizedBox(height: betweenGap),
                  Text(
                    subtitle,
                    textScaler: TextScaler.noScaling,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      height: 1.30,
                      color: isDark
                          ? const Color(0xFFB8C0BC)
                          : const Color(0xFF5C655F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProphetHighlightCard extends StatelessWidget {
  const _ProphetHighlightCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [Color(0xFF4F4221), Color(0xFF7A6731)]
                  : const [Color(0xFFF2E2B6), Color(0xFFE4C778)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF9C8341) : const Color(0xFFD4B15A),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C6A1F).withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سيدنا النبي ﷺ',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF5EFD9)
                            : const Color(0xFF143A2A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'السيرة النبوية وإعدادات الصلاة والسلام',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFE4D6AE)
                            : const Color(0xFF5A4A24),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Color(0xFF8C6A1F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.value,
    required this.current,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final String current;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2F6A53))
          : const Icon(Icons.radio_button_unchecked_rounded),
      onTap: onTap,
    );
  }
}
