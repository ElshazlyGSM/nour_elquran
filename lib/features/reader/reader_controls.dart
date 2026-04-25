part of 'reader_page.dart';

class _BottomControlBar extends StatelessWidget {
  const _BottomControlBar({
    required this.isPlayingAudio,
    required this.isPreparingAudio,
    required this.onShowMoreActions,
    required this.onSearch,
    required this.onShowTafsir,
    required this.onShowTajweedLegend,
    required this.onToggleAudio,
    required this.onSaveBookmark,
    required this.showTajweedLegend,
    required this.onInteract,
    required this.isAutoScrollModeActive,
    required this.isAutoScrollPaused,
    required this.autoScrollLabel,
    required this.fontSizeLabel,
    required this.onPauseResumeAutoScroll,
    required this.onToggleAutoScroll,
    required this.onIncreaseReadingSpeed,
    required this.onDecreaseReadingSpeed,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onCloseAutoScroll,
    required this.showAutoScrollToggle,
  });

  final bool isPlayingAudio;
  final bool isPreparingAudio;
  final Future<void> Function() onShowMoreActions;
  final Future<void> Function() onSearch;
  final Future<void> Function() onShowTafsir;
  final Future<void> Function() onShowTajweedLegend;
  final Future<void> Function() onToggleAudio;
  final Future<void> Function() onSaveBookmark;
  final bool showTajweedLegend;
  final VoidCallback onInteract;
  final bool isAutoScrollModeActive;
  final bool isAutoScrollPaused;
  final String autoScrollLabel;
  final String fontSizeLabel;
  final Future<void> Function() onPauseResumeAutoScroll;
  final Future<void> Function() onToggleAutoScroll;
  final Future<void> Function() onIncreaseReadingSpeed;
  final Future<void> Function() onDecreaseReadingSpeed;
  final Future<void> Function() onIncreaseFontSize;
  final Future<void> Function() onDecreaseFontSize;
  final Future<void> Function() onCloseAutoScroll;
  final bool showAutoScrollToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onInteract(),
      onPointerMove: (_) => onInteract(),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: SafeArea(
          top: false,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF152127) : Colors.white)
                      .withValues(alpha: 0.75),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF26343B)
                          : const Color(0xFFE8DEC7),
                    ),
                  ),
                ),
                child: SizedBox(
                  height: 56,
                  child: isAutoScrollModeActive
                      ? Row(
                          children: [
                            _BottomBarSquareAction(
                              icon: isAutoScrollPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              onTap: onPauseResumeAutoScroll,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _BottomBarInlineGroup(
                                icon: Icons.keyboard_double_arrow_down_rounded,
                                title: 'السرعة',
                                label: autoScrollLabel,
                                onDecrease: onDecreaseReadingSpeed,
                                onIncrease: onIncreaseReadingSpeed,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _BottomBarInlineGroup(
                                icon: Icons.format_size_rounded,
                                title: 'الخط',
                                label: fontSizeLabel,
                                onDecrease: onDecreaseFontSize,
                                onIncrease: onIncreaseFontSize,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _BottomBarSquareAction(
                              icon: Icons.close_rounded,
                              onTap: onCloseAutoScroll,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _BottomBarPrimaryAction(
                                icon: (isPlayingAudio || isPreparingAudio)
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                label: isPreparingAudio
                                    ? 'جاري التحميل'
                                    : 'الصوت',
                                onTap: onToggleAudio,
                                isLoading: isPreparingAudio,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (showAutoScrollToggle) ...[
                              Expanded(
                                child: _BottomBarPrimaryAction(
                                  icon:
                                      Icons.keyboard_double_arrow_down_rounded,
                                  label: 'نزول تلقائي',
                                  onTap: onToggleAutoScroll,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: _BottomBarPrimaryAction(
                                icon: Icons.search_rounded,
                                label: 'بحث',
                                onTap: onSearch,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BottomBarPrimaryAction(
                                icon: Icons.library_books_rounded,
                                label: 'تفسير',
                                onTap: onShowTafsir,
                              ),
                            ),
                            if (showTajweedLegend) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: _BottomBarCustomAction(
                                  label: 'التجويد',
                                  onTap: onShowTajweedLegend,
                                  child: const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CustomPaint(
                                      painter: _TajweedWheelPainter(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BottomBarPrimaryAction(
                                icon: Icons.bookmark_border_rounded,
                                label: 'علامة',
                                onTap: onSaveBookmark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BottomBarPrimaryAction(
                                icon: Icons.more_horiz_rounded,
                                label: 'المزيد',
                                onTap: onShowMoreActions,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarPrimaryAction extends StatelessWidget {
  const _BottomBarPrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayLabel = isLoading ? 'جاري التحميل' : label;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF18242A) : const Color(0xFFF6F0E1))
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                icon,
                size: 20,
                color: isDark
                    ? const Color(0xFFF2ECDF)
                    : const Color(0xFF143A2A),
              ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: isLoading ? 11.0 : 11.8,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF2ECDF)
                      : const Color(0xFF143A2A),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarCustomAction extends StatelessWidget {
  const _BottomBarCustomAction({
    required this.label,
    required this.child,
    required this.onTap,
  });

  final String label;
  final Widget child;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF18242A) : const Color(0xFFF6F0E1))
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF2ECDF)
                    : const Color(0xFF143A2A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarSquareAction extends StatelessWidget {
  const _BottomBarSquareAction({required this.icon, required this.onTap});

  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 44,
        height: 56,
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF18242A) : const Color(0xFFF6F0E1))
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFFF2ECDF) : const Color(0xFF143A2A),
        ),
      ),
    );
  }
}

class _BottomBarInlineGroup extends StatelessWidget {
  const _BottomBarInlineGroup({
    required this.icon,
    required this.title,
    required this.label,
    required this.onDecrease,
    required this.onIncrease,
  });

  final IconData icon;
  final String title;
  final String label;
  final Future<void> Function() onDecrease;
  final Future<void> Function() onIncrease;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF18242A) : const Color(0xFFF6F0E1))
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _BottomBarMiniAction(icon: Icons.remove_rounded, onTap: onDecrease),
          Expanded(
            child: _BottomBarStatusAction(
              icon: icon,
              title: title,
              label: label,
            ),
          ),
          _BottomBarMiniAction(icon: Icons.add_rounded, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _BottomBarMiniAction extends StatelessWidget {
  const _BottomBarMiniAction({required this.icon, required this.onTap});

  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 26,
        height: 56,
        child: Icon(
          icon,
          size: 16,
          color: isDark ? const Color(0xFFF2ECDF) : const Color(0xFF143A2A),
        ),
      ),
    );
  }
}

class _BottomBarStatusAction extends StatelessWidget {
  const _BottomBarStatusAction({
    required this.icon,
    required this.title,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Ink(
      height: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isDark
                    ? const Color(0xFFF2ECDF)
                    : const Color(0xFF143A2A),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFFF2ECDF)
                      : const Color(0xFF143A2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF2ECDF)
                    : const Color(0xFF143A2A),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _TajweedWheelPainter extends CustomPainter {
  const _TajweedWheelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const borderColor = Color(0xFFF6F0E1);
    final sectors = <({Color color, double sweepFactor})>[
      (color: const Color(0xFFB94B37), sweepFactor: 1.1),
      (color: const Color(0xFFFF4B3A), sweepFactor: 1.0),
      (color: const Color(0xFFFB913A), sweepFactor: 0.95),
      (color: const Color(0xFFD7AE54), sweepFactor: 0.9),
      (color: const Color(0xFF7FB071), sweepFactor: 1.05),
      (color: const Color(0xFFB8B6AB), sweepFactor: 0.9),
      (color: const Color(0xFF5D90A5), sweepFactor: 0.85),
      (color: const Color(0xFF66ABD0), sweepFactor: 0.7),
    ];
    final totalFactor = sectors.fold<double>(
      0,
      (sum, sector) => sum + sector.sweepFactor,
    );

    var startAngle = -math.pi / 2;
    for (final sector in sectors) {
      final sweep = (2 * math.pi) * (sector.sweepFactor / totalFactor);
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        true,
        Paint()
          ..color = sector.color
          ..style = PaintingStyle.fill,
      );
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        true,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      startAngle += sweep;
    }

    canvas.drawCircle(
      center,
      radius * 0.58,
      Paint()..color = const Color(0xFF143A2A),
    );
    canvas.drawCircle(
      center,
      radius * 0.58,
      Paint()
        ..color = const Color(0xFFE7C56A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ت',
        style: TextStyle(
          color: Color(0xFFE7C56A),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.children, required this.backgroundColor});

  final List<Widget> children;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1D4B4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _CompactValue extends StatelessWidget {
  const _CompactValue({required this.icon, required this.label, this.minWidth});

  final IconData icon;
  final String label;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final child = Container(
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF223038) : const Color(0xFFF1E9D5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? const Color(0xFFF2ECDF) : const Color(0xFF143A2A),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              strutStyle: const StrutStyle(
                fontSize: 15,
                height: 1,
                leading: 0,
                forceStrutHeight: true,
              ),
              style: TextStyle(
                fontSize: 15,
                height: 1,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? const Color(0xFFF2ECDF)
                    : const Color(0xFF143A2A),
              ),
            ),
          ],
        ),
      ),
    );

    return child;
  }
}

class _TinySquareButton extends StatelessWidget {
  const _TinySquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF223038) : const Color(0xFFF6F0E1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? const Color(0xFFF2ECDF) : null,
        ),
      ),
    );
  }
}
