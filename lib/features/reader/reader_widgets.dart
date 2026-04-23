part of 'reader_page.dart';

class _LibraryMushafPages extends StatelessWidget {
  const _LibraryMushafPages({
    required this.startPage,
    required this.onAyahSelected,
    required this.onPageChanged,
    required this.onPageTap,
  });

  final int startPage;
  final void Function(int surahNumber, int verseNumber) onAyahSelected;
  final void Function(int pageNumber) onPageChanged;
  final VoidCallback onPageTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: QuranLibraryScreen(
        key: ValueKey(startPage),
        parentContext: context,
        pageIndex: startPage - 1,
        withPageView: true,
        isShowTabBar: false,
        isDark: false,
        useDefaultAppBar: false,
        isShowAudioSlider: false,
        enableWordSelection: true,
        onPageChanged: onPageChanged,
        onPagePress: onPageTap,
        onAyahLongPress: (_, ayah) {
          onAyahSelected(ayah.surahNumber!, ayah.ayahNumber);
        },
        backgroundColor: const Color(0xFFE8DFC8),
        ayahSelectedBackgroundColor: const Color(0x40B49355),
        ayahSelectedFontColor: const Color(0xFF4A3720),
        textColor: const Color(0xFF4A3720),
      ),
    );
  }
}

class _MedinaDownloadGate extends StatelessWidget {
  const _MedinaDownloadGate({
    required this.isChecking,
    required this.isDownloading,
    required this.progress,
    required this.status,
    required this.error,
    required this.isConfigured,
    required this.onRefresh,
    required this.onStartDownload,
    required this.onCancelDownload,
    required this.onExit,
  });

  final bool isChecking;
  final bool isDownloading;
  final double progress;
  final String? status;
  final String? error;
  final bool isConfigured;
  final VoidCallback onRefresh;
  final VoidCallback onStartDownload;
  final VoidCallback onCancelDownload;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF4A3720),
    );
    final body = theme.textTheme.bodyMedium?.copyWith(
      height: 1.7,
      color: const Color(0xFF5F4B2F),
    );

    return ColoredBox(
      color: const Color(0xFFE8DFC8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1DE),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5D6B6)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(child: SizedBox(height: 1)),
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: onExit,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: Color(0xFF7A5B2A),
                ),
                const SizedBox(height: 10),
                Text(
                  'مصحف المدينة',
                  style: headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (isChecking) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text('جارٍ التحقق من الملفات...', style: body),
                ] else ...[
                  Text(
                    'يمكنك تحميل مصحف المدينة مرة واحدة ليعمل بكفاءة بدون الإنترنت.',
                    style: body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  if (error != null) ...[
                    Text(
                      error!,
                      style: body?.copyWith(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!isConfigured) ...[
                    Text(
                      'رابط التحميل غير مضبوط بعد.',
                      style: body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: onRefresh,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ] else if (isDownloading) ...[
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      status ?? 'جارٍ التنزيل ${(progress * 100).round()}%',
                      style: body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: onCancelDownload,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('إيقاف التحميل'),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: onStartDownload,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('تحميل مصحف المدينة'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سيظهر المصحف فور اكتمال التحميل.',
                      style: body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShamarlyDownloadGate extends StatelessWidget {
  const _ShamarlyDownloadGate({
    required this.isChecking,
    required this.isDownloading,
    required this.progress,
    required this.status,
    required this.error,
    required this.isConfigured,
    required this.onRefresh,
    required this.onStartDownload,
    required this.onCancelDownload,
    required this.onExit,
  });

  final bool isChecking;
  final bool isDownloading;
  final double progress;
  final String? status;
  final String? error;
  final bool isConfigured;
  final VoidCallback onRefresh;
  final VoidCallback onStartDownload;
  final VoidCallback onCancelDownload;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF4A3720),
    );
    final body = theme.textTheme.bodyMedium?.copyWith(
      height: 1.7,
      color: const Color(0xFF5F4B2F),
    );

    return ColoredBox(
      color: const Color(0xFFE8DFC8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1DE),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5D6B6)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(child: SizedBox(height: 1)),
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: onExit,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: Color(0xFF7A5B2A),
                ),
                const SizedBox(height: 10),
                Text(
                  'مصحف الشمرلي',
                  style: headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (isChecking) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text('جارٍ التحقق من الملفات...', style: body),
                ] else ...[
                  Text(
                    'يمكنك تحميل مصحف الشمرلي مرة واحدة ليعمل بدون إنترنت.',
                    style: body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  if (error != null) ...[
                    Text(
                      error!,
                      style: body?.copyWith(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!isConfigured) ...[
                    Text(
                      'رابط التحميل غير مضبوط بعد.',
                      style: body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: onRefresh,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ] else if (isDownloading) ...[
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      status ?? 'جارٍ التحميل ${(progress * 100).round()}%',
                      style: body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: onCancelDownload,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('إيقاف التحميل'),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: onStartDownload,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('تحميل مصحف الشمرلي'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سيظهر المصحف فور اكتمال التحميل.',
                      style: body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShamarlyPages extends StatefulWidget {
  const _ShamarlyPages({
    required this.startPage,
    required this.pagesDirectoryPath,
    required this.onPageTap,
    required this.onPageChanged,
  });

  final int startPage;
  final String? pagesDirectoryPath;
  final VoidCallback onPageTap;
  final void Function(int pageNumber) onPageChanged;

  @override
  State<_ShamarlyPages> createState() => _ShamarlyPagesState();
}

class _ShamarlyPagesState extends State<_ShamarlyPages> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: (widget.startPage - 1).clamp(
        0,
        ShamarlyPagesDownloadConfig.totalPages - 1,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _ShamarlyPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startPage != oldWidget.startPage) {
      final target = (widget.startPage - 1).clamp(
        0,
        ShamarlyPagesDownloadConfig.totalPages - 1,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_controller.hasClients) {
          _controller.animateToPage(
            target,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _pageFileName(int pageNumber) {
    final padded = pageNumber.toString().padLeft(
      ShamarlyPagesDownloadConfig.filePadding,
      '0',
    );
    return '${ShamarlyPagesDownloadConfig.filePrefix}$padded'
        '${ShamarlyPagesDownloadConfig.fileExtension}';
  }

  Widget _buildShamarlyPageCell(
    BuildContext context,
    String filePath,
    int pageNumber,
  ) {
    return SizedBox.expand(
      child: ClipRect(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          panEnabled: false,
          scaleEnabled: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const baseWidth = 400.0;
              const baseScale = 1.3;
              final scale = (constraints.maxWidth / baseWidth) * baseScale;
              //حجم مصحف الشمرلي وتكبيره لملاءمة الشاشة
              final clampedScale = scale.clamp(1.35, 1.4);
              return Transform.scale(
                scale: clampedScale,
                child: buildShamarlyPageImage(
                  context: context,
                  filePath: filePath,
                  fit: BoxFit.contain,
                  errorWidget: Text(
                    'تعذر تحميل صفحة ${toArabicNumber(pageNumber)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6D5430),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pagesDirectoryPath == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onPageTap,
        child: PageView.builder(
          controller: _controller,
          physics: const PageScrollPhysics(),
          reverse: false,
          clipBehavior: Clip.hardEdge,
          allowImplicitScrolling: true,
          itemCount: ShamarlyPagesDownloadConfig.totalPages,
          onPageChanged: (index) => widget.onPageChanged(index + 1),
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            final fileName = _pageFileName(pageNumber);
            final filePath = path.join(widget.pagesDirectoryPath!, fileName);
            return _buildShamarlyPageCell(context, filePath, pageNumber);
          },
        ),
      ),
    );
  }
}

class _QuranPageCard extends StatelessWidget {
  const _QuranPageCard({
    required this.pageNumber,
    required this.pageKey,
    required this.hasBookmark,
    required this.bookmarkColor,
    required this.initialSurahNumber,
    required this.initialVerse,
    required this.lastRead,
    required this.selectedSurahNumber,
    required this.selectedVerseNumber,
    required this.highlightQuery,
    required this.fontSize,
    required this.appearance,
    required this.verseKeyBuilder,
    required this.onVerseTap,
  });

  final int pageNumber;
  final GlobalKey pageKey;
  final bool hasBookmark;
  final Color? bookmarkColor;
  final int initialSurahNumber;
  final int initialVerse;
  final LastReadPosition? lastRead;
  final int? selectedSurahNumber;
  final int? selectedVerseNumber;
  final String? highlightQuery;
  final double fontSize;
  final _ReaderAppearance appearance;
  final GlobalKey Function(int surahNumber, int verseNumber) verseKeyBuilder;
  final Future<void> Function({
    required int surahNumber,
    required int verseNumber,
    required String verseText,
  })
  onVerseTap;
  static const int _lastSurahNumber = 114;
  static const int _lastSurahLastVerse = 6;

  @override
  Widget build(BuildContext context) {
    final pageData = _readerQuranSource.getPageData(pageNumber);
    final showSideQuarterMarker =
        appearance != _ReaderAppearance.medinaPages &&
        appearance != _ReaderAppearance.shamarlyPages;
    final content = Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: appearance.pageColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            //حجم الشريط الى بالطول فى اليمين نعدل من رقم 30
            3,
            8,
            showSideQuarterMarker ? 33 : 3,
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final dynamic item in pageData) ...[
                _SurahMarker(
                  surahNumber: item['surah'] as int,
                  startVerse: item['start'] as int,
                  appearance: appearance,
                  fontSize: fontSize,
                ),
                const SizedBox(height: 3),
                _VerseWrap(
                  surahNumber: item['surah'] as int,
                  startVerse: item['start'] as int,
                  endVerse: item['end'] as int,
                  initialSurahNumber: initialSurahNumber,
                  initialVerse: initialVerse,
                  lastRead: lastRead,
                  selectedSurahNumber: selectedSurahNumber,
                  selectedVerseNumber: selectedVerseNumber,
                  highlightQuery: highlightQuery,
                  fontSize: fontSize,
                  appearance: appearance,
                  verseKeyBuilder: verseKeyBuilder,
                  onVerseTap: onVerseTap,
                ),
                const SizedBox(height: 4),
              ],
              if (_shouldShowKhatmDua(pageData, initialSurahNumber)) ...[
                const SizedBox(height: 8),
                _KhatmDuaButton(appearance: appearance),
              ],
            ],
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              color: Colors.transparent,
              elevation: 0,
              child: content,
            ),
            _PageDivider(
              pageNumber: pageNumber,
              appearance: appearance,
              fontSize: fontSize,
            ),
          ],
        ),
        if (showSideQuarterMarker)
          Positioned.fill(
            child: IgnorePointer(
              child: _SideQuarterMarkerLayer(
                pageKey: pageKey,
                pageData: pageData,
                appearance: appearance,
                fontSize: fontSize,
                verseKeyBuilder: verseKeyBuilder,
              ),
            ),
          ),
        if (hasBookmark)
          Positioned(
            top: -4,
            left: 0,
            right: 0,
            child: Center(
              child: _BookmarkPageMarker(
                backgroundColor:
                    (bookmarkColor ?? appearance.selectedVerseColor).withValues(
                      alpha: 0.75,
                    ),
                foregroundColor: appearance.textColor,
                borderColor: (bookmarkColor ?? appearance.dividerColor)
                    .withValues(alpha: 0.9),
              ),
            ),
          ),
      ],
    );
  }

  bool _shouldShowKhatmDua(List<dynamic> pageData, int initialSurahNumber) {
    for (final dynamic item in pageData) {
      final surah = item['surah'] as int;
      final start = item['start'] as int;
      final end = item['end'] as int;
      if (surah == _lastSurahNumber &&
          start <= _lastSurahLastVerse &&
          end >= _lastSurahLastVerse) {
        return true;
      }
    }
    return false;
  }
}

class _BookmarkPageMarker extends StatelessWidget {
  const _BookmarkPageMarker({
    this.backgroundColor = const Color(0xFF84BD4B),
    this.foregroundColor = const Color(0xFF4E3A18),
    this.borderColor = const Color(0xFF7A6234),
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_rounded, size: 10, color: foregroundColor),
            const SizedBox(width: 3),
            Text(
              'علامة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: foregroundColor,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahMarker extends StatelessWidget {
  const _SurahMarker({
    required this.surahNumber,
    required this.startVerse,
    required this.appearance,
    required this.fontSize,
  });

  final int surahNumber;
  final int startVerse;
  final _ReaderAppearance appearance;
  final double fontSize;

  String? get _headerFontFamily => switch (appearance) {
    //خط البسملة في المصحف
    _ReaderAppearance.classic ||
    _ReaderAppearance.golden ||
    _ReaderAppearance.night => 'Uthmani_Hafs_Am9li9',
    _ReaderAppearance.tajweed ||
    _ReaderAppearance.nightTajweed => 'ScheherazadeNew',
    _ReaderAppearance.medinaPages => null,
    _ReaderAppearance.shamarlyPages => null,
  };

  String? get _surahNameFontFamily => switch (appearance) {
    _ReaderAppearance.classic ||
    _ReaderAppearance.golden ||
    _ReaderAppearance.night => 'SurahNames-font',
    _ReaderAppearance.tajweed ||
    _ReaderAppearance.nightTajweed => 'SurahNames-font',
    _ReaderAppearance.medinaPages => null,
    _ReaderAppearance.shamarlyPages => null,
  };

  String? get _headerFontPackage => switch (appearance) {
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    if (startVerse != 1) {
      return const SizedBox.shrink();
    }

    final showBasmala = surahNumber != 9;
    //حجم خط اسم السورة
    final titleFontSize = (fontSize * 0.82);
    //حجم خط البسملة
    final basmalaFontSize = (fontSize * 0.85);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: appearance.surahBadgeColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _readerQuranSource.getSurahNameArabic(surahNumber),
            style: TextStyle(
              fontFamily: _surahNameFontFamily,
              package: _headerFontPackage,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: titleFontSize,
              height: 1.2,
            ),
          ),
        ),
        if (showBasmala) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: appearance.initialVerseColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: appearance.quarterMarkerBorderColor.withValues(
                  alpha:
                      appearance == _ReaderAppearance.night ||
                          appearance == _ReaderAppearance.nightTajweed
                      ? 0.92
                      : 0.55,
                ),
              ),
            ),
            child: Text(
              _readerQuranSource.basmala,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: _headerFontFamily,
                package: _headerFontPackage,
                color: appearance.quarterMarkerTextColor,
                fontWeight: FontWeight.w700,
                fontSize: basmalaFontSize,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 3),
        ] else ...[
          const SizedBox(height: 1),
        ],
        const SizedBox(height: 2),
      ],
    );
  }
}

class _VerseWrap extends StatelessWidget {
  const _VerseWrap({
    required this.surahNumber,
    required this.startVerse,
    required this.endVerse,
    required this.initialSurahNumber,
    required this.initialVerse,
    required this.lastRead,
    required this.selectedSurahNumber,
    required this.selectedVerseNumber,
    required this.highlightQuery,
    required this.fontSize,
    required this.appearance,
    required this.verseKeyBuilder,
    required this.onVerseTap,
  });

  final int surahNumber;
  final int startVerse;
  final int endVerse;
  final int initialSurahNumber;
  final int initialVerse;
  final LastReadPosition? lastRead;
  final int? selectedSurahNumber;
  final int? selectedVerseNumber;
  final String? highlightQuery;
  final double fontSize;
  final _ReaderAppearance appearance;
  final GlobalKey Function(int surahNumber, int verseNumber) verseKeyBuilder;
  final Future<void> Function({
    required int surahNumber,
    required int verseNumber,
    required String verseText,
  })
  onVerseTap;

  String? get _mushafFontFamily => switch (appearance) {
    //خط المصحف المستخدم في نصوص الآيات
    _ReaderAppearance.classic ||
    _ReaderAppearance.golden ||
    _ReaderAppearance.night => 'UthmanicNeo',
    _ReaderAppearance.tajweed ||
    _ReaderAppearance.nightTajweed => 'ScheherazadeNew',
    _ReaderAppearance.medinaPages => null,
    _ReaderAppearance.shamarlyPages => null,
  };

  String? get _mushafFontPackage => switch (appearance) {
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final highlightRanges = <_VerseHighlightRange>[];
    final actualStart = surahNumber == 1 && startVerse == 1 ? 2 : startVerse;

    final useBalancedLines =
        appearance != _ReaderAppearance.medinaPages &&
        appearance != _ReaderAppearance.shamarlyPages &&
        fontSize >= 19.0 &&
        fontSize <= 24.0;
    final effectiveWordSpacing = fontSize * -0.15;

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: _mushafFontFamily,
      package: _mushafFontPackage,
      fontSize: fontSize,
      //خط المصحف والتباعد بين السطور
      height: 1.60,
      color: appearance.quarterMarkerTextColor,
      fontWeight: FontWeight.w500,
      //سماكه خط المصحف
      wordSpacing: effectiveWordSpacing,
    );

    for (
      var verseNumber = actualStart;
      verseNumber <= endVerse;
      verseNumber++
    ) {
      final isInitial =
          surahNumber == initialSurahNumber && verseNumber == initialVerse;
      final isSaved =
          lastRead?.surahNumber == surahNumber &&
          lastRead?.verseNumber == verseNumber;
      final isSelected =
          selectedSurahNumber == surahNumber &&
          selectedVerseNumber == verseNumber;
      final verseText = _readerQuranSource.getVerseText(
        surahNumber,
        verseNumber,
        verseEndSymbol: false,
      );
      final renderVerseText =
          appearance == _ReaderAppearance.tajweed ||
              appearance == _ReaderAppearance.nightTajweed
          ? _tajweedQuranSource.getVerseMarkup(
              surahNumber,
              verseNumber,
              verseEndSymbol: false,
            )
          : verseText;
      final highlightColor = isSelected
          ? appearance.selectedVerseColor
          : isSaved
          ? appearance.savedVerseColor
          : isInitial
          ? appearance.initialVerseColor
          : null;
      final query = highlightQuery?.trim();
      final shouldHighlightQuery =
          query != null && query.isNotEmpty && (isSelected || isInitial);

      final useSideQuarterMarker =
          appearance != _ReaderAppearance.medinaPages &&
          appearance != _ReaderAppearance.shamarlyPages;
      final isEndOfQuarter = _isEndOfHizbQuarter(surahNumber, verseNumber);
      final verseBuild = _buildInteractiveVerseSpan(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        verseText: renderVerseText,
        plainVerseText: verseText,
        baseStyle: baseStyle,
        showQuarterMarker: useSideQuarterMarker && isEndOfQuarter,
      );

      final startOffset = _textLengthOfSpans(spans) + verseBuild.contentStart;
      final endOffset = _textLengthOfSpans(spans) + verseBuild.contentEnd;
      spans.addAll(verseBuild.spans);
      if (highlightColor != null && endOffset > startOffset) {
        highlightRanges.add(
          _VerseHighlightRange(
            start: startOffset,
            end: endOffset,
            color: highlightColor,
          ),
        );
      }
      if (shouldHighlightQuery && endOffset > startOffset) {
        final wordHighlightColor = appearance.selectedVerseColor.withValues(
          alpha: 0.9,
        );
        final queryRanges = _findQueryRangesInVerse(verseText, query);
        for (final range in queryRanges) {
          final highlightStart = startOffset + range.start;
          final highlightEnd = startOffset + range.end;
          if (highlightEnd <= highlightStart) {
            continue;
          }
          highlightRanges.add(
            _VerseHighlightRange(
              start: highlightStart,
              end: highlightEnd,
              color: wordHighlightColor,
            ),
          );
        }
      }
    }

    final textSpan = TextSpan(style: baseStyle, children: spans);

    return _HighlightedRichText(
      text: textSpan,
      highlights: highlightRanges,
      //محازاة النص واتجاهه فى المصحف
      textAlign: useBalancedLines ? TextAlign.justify : TextAlign.center,
      textDirection: TextDirection.rtl,
      textWidthBasis: useBalancedLines
          ? TextWidthBasis.parent
          : TextWidthBasis.longestLine,
      softWrap: true,
    );
  }

  _VerseSpanBuildResult _buildInteractiveVerseSpan({
    required int surahNumber,
    required int verseNumber,
    required String verseText,
    required String plainVerseText,
    required TextStyle? baseStyle,
    required bool showQuarterMarker,
  }) {
    final tapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        onVerseTap(
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          verseText: plainVerseText,
        );
      };

    final markerHeight = fontSize * 1.05;
    final marker = WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _VersePlaceholderWidget(
        key: verseKeyBuilder(surahNumber, verseNumber),
        placeholderWidth: 0,
        placeholderHeight: markerHeight,
        child: SizedBox(width: 0, height: markerHeight),
      ),
    );

    final quarterMarkerLabel = _quarterMarkerLabel(surahNumber, verseNumber);
    final quarterMarkerDisplayLabel = _quarterMarkerDisplayLabel(
      quarterMarkerLabel,
    );
    final quarterMarkerFontSize = (fontSize * 0.42).clamp(11.0, 14.0);
    final useSideQuarterMarker =
        appearance != _ReaderAppearance.medinaPages &&
        appearance != _ReaderAppearance.shamarlyPages;
    final quarterMarkerWidth = useSideQuarterMarker
        ? 30.0
        : _measureQuarterMarkerWidth(
            quarterMarkerDisplayLabel,
            fontSize: quarterMarkerFontSize,
          );
    final quarterMarkerHeight = (fontSize * 2.1).clamp(44.0, 72.0);

    final quarterMarker = WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _VersePlaceholderWidget(
        placeholderWidth: useSideQuarterMarker ? 0 : quarterMarkerWidth,
        placeholderHeight: quarterMarkerHeight,
        child: SizedBox(
          width: 0,
          height: quarterMarkerHeight,
          child: OverflowBox(
            minWidth: quarterMarkerWidth,
            maxWidth: quarterMarkerWidth,
            minHeight: quarterMarkerHeight,
            maxHeight: quarterMarkerHeight,
            alignment: Alignment.centerRight,
            child: Transform.translate(
              offset: Offset(useSideQuarterMarker ? 34 : 0, 0),
              child: SizedBox(
                width: quarterMarkerWidth,
                height: quarterMarkerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: appearance.quarterMarkerFillColor.withValues(
                        alpha:
                            appearance == _ReaderAppearance.night ||
                                appearance == _ReaderAppearance.nightTajweed
                            ? 0.88
                            : 0.42,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: appearance.quarterMarkerBorderColor.withValues(
                          alpha:
                              appearance == _ReaderAppearance.night ||
                                  appearance == _ReaderAppearance.nightTajweed
                              ? 0.92
                              : 0.55,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        quarterMarkerDisplayLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: appearance.quarterMarkerTextColor,
                          fontSize: quarterMarkerFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          package: _mushafFontPackage,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final verseSpans = _buildVerseSpans(
      verseText,
      recognizer: tapRecognizer,
      highlightColor: null,
      baseStyle: baseStyle,
    );
    final verseLength = _textLengthOfSpans(verseSpans);

    final verseEndMarker = _buildVerseEndMarker(
      verseNumber: verseNumber,
      baseStyle: baseStyle,
      recognizer: tapRecognizer,
    );
    final verseEndMarkerLength = _textLengthOfSpans([verseEndMarker]);
    final sajdaMarker = _buildSajdaMarker(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      baseStyle: baseStyle,
      recognizer: tapRecognizer,
    );

    return _VerseSpanBuildResult(
      spans: [
        ...verseSpans,
        verseEndMarker,
        if (sajdaMarker != null && !useSideQuarterMarker) sajdaMarker,
        if (showQuarterMarker && !useSideQuarterMarker) quarterMarker,
        TextSpan(
          text: ' ',
          //اضافه
          style: baseStyle?.copyWith(wordSpacing: 0),
          recognizer: tapRecognizer,
        ),
        marker,
      ],
      contentStart: 0,
      contentEnd: verseLength + verseEndMarkerLength,
    );
  }

  InlineSpan _buildVerseEndMarker({
    required int verseNumber,
    required TextStyle? baseStyle,
    required GestureRecognizer recognizer,
  }) {
    return TextSpan(
      text: ' ﴿${toArabicNumber(verseNumber)}﴾',
      recognizer: recognizer,
      style: (baseStyle ?? const TextStyle()).copyWith(
        fontFamily: null,
        fontSize: ((baseStyle?.fontSize ?? fontSize) * 1.0).clamp(18.0, 30.0),
        height: 0.5,
        color: appearance.textColor.withValues(alpha: 0.88),
        fontWeight: FontWeight.w700,
        wordSpacing: 0,
        //اضافه
      ),
    );
  }

  InlineSpan? _buildSajdaMarker({
    required int surahNumber,
    required int verseNumber,
    required TextStyle? baseStyle,
    required GestureRecognizer recognizer,
  }) {
    if (!quran.isSajdahVerse(surahNumber, verseNumber)) {
      return null;
    }
    final markerSize = (baseStyle?.fontSize ?? fontSize) * 0.55;
    return TextSpan(
      text: ' سجدة',
      recognizer: recognizer,
      style: (baseStyle ?? const TextStyle()).copyWith(
        fontFamily: null,
        fontSize: markerSize.clamp(12.0, 18.0),
        height: 1.0,
        color: appearance.surahBadgeColor,
        fontWeight: FontWeight.w800,
        wordSpacing: 0,
      ),
    );
  }

  bool _isEndOfHizbQuarter(int surahNumber, int verseNumber) {
    final current = QuranCtrl.instance.getSingleAyahByAyahAndSurahNumber(
      verseNumber,
      surahNumber,
    );
    final currentQuarter = current.hizb;
    if (currentQuarter == null || currentQuarter <= 0) {
      return false;
    }

    final verseCount = _readerQuranSource.getVerseCount(surahNumber);
    final nextSurahNumber = verseNumber < verseCount
        ? surahNumber
        : surahNumber + 1;
    final nextVerseNumber = verseNumber < verseCount ? verseNumber + 1 : 1;

    if (nextSurahNumber > currentQuranTotalSurahCount) {
      return true;
    }

    final next = QuranCtrl.instance.getSingleAyahByAyahAndSurahNumber(
      nextVerseNumber,
      nextSurahNumber,
    );
    final nextQuarter = next.hizb;
    return nextQuarter != currentQuarter;
  }

  String _quarterMarkerLabel(int surahNumber, int verseNumber) {
    final ayah = QuranCtrl.instance.getSingleAyahByAyahAndSurahNumber(
      verseNumber,
      surahNumber,
    );
    final quarter = ayah.hizb;
    if (quarter == null || quarter <= 0) {
      return 'الحزب';
    }
    final hizbNumber = ((quarter - 1) ~/ 4) + 1;
    final isStartOfJuz = hizbNumber.isOdd && ((quarter - 1) % 4 == 0);
    final juzNumber = (hizbNumber + 1) ~/ 2;
    final quarterPosition = (quarter - 1) % 4;
    final labelPosition = (quarterPosition + 3) % 4;
    final quarterLabel = switch (labelPosition) {
      0 => 'ربع',
      1 => 'نصف',
      2 => 'ثلاثة أرباع',
      _ => 'الحزب',
    };
    final juzText = isStartOfJuz ? 'الجزء ${toArabicNumber(juzNumber)}' : '';
    if (quarterLabel == 'الحزب') {
      return isStartOfJuz
          ? '$juzText\nالحزب ${toArabicNumber(hizbNumber)}'
          : 'الحزب ${toArabicNumber(hizbNumber)}';
    }
    return isStartOfJuz
        ? '$juzText\n$quarterLabel الحزب ${toArabicNumber(hizbNumber)}'
        : '$quarterLabel الحزب ${toArabicNumber(hizbNumber)}';
  }

  String _quarterMarkerDisplayLabel(String label) {
    if (label.contains('\n')) {
      return label.split('\n').where((part) => part.isNotEmpty).join('\n');
    }
    return label
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join('\n');
  }

  double _measureQuarterMarkerWidth(String text, {required double fontSize}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          package: _mushafFontPackage,
        ),
      ),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    return painter.width + 32;
  }

  TextStyle? _highlightedStyle(TextStyle? baseStyle, Color? highlightColor) {
    if (highlightColor == null) {
      return baseStyle;
    }
    return baseStyle?.copyWith(fontWeight: FontWeight.w700);
  }

  List<InlineSpan> _buildVerseSpans(
    String text, {
    GestureRecognizer? recognizer,
    Color? highlightColor,
    TextStyle? baseStyle,
  }) {
    if (appearance != _ReaderAppearance.tajweed &&
        appearance != _ReaderAppearance.nightTajweed) {
      return [
        TextSpan(
          text: text,
          style: _highlightedStyle(baseStyle, highlightColor),
          recognizer: recognizer,
        ),
      ];
    }

    final spans = <InlineSpan>[];
    final tagPattern = RegExp(
      r'<tajweed class="?([a-z_]+)"?>(.*?)</tajweed>',
      dotAll: true,
    );

    var currentIndex = 0;
    for (final match in tagPattern.allMatches(text)) {
      if (match.start > currentIndex) {
        final plainText = text
            .substring(currentIndex, match.start)
            .replaceAll(RegExp(r'</?[^>]+>'), '');
        spans.addAll(
          _buildPlainTajweedAwareSpans(
            plainText,
            recognizer: recognizer,
            highlightColor: highlightColor,
            baseStyle: baseStyle,
          ),
        );
      }

      final tajweedClass = match.group(1) ?? '';
      final taggedText = (match.group(2) ?? '').replaceAll(
        RegExp(r'</?[^>]+>'),
        '',
      );
      spans.add(
        TextSpan(
          text: taggedText,
          style: _highlightedStyle(
            (baseStyle ?? const TextStyle()).copyWith(
              color: _colorForTajweedClass(tajweedClass),
            ),
            highlightColor,
          ),
          recognizer: recognizer,
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.addAll(
        _buildPlainTajweedAwareSpans(
          text.substring(currentIndex).replaceAll(RegExp(r'</?[^>]+>'), ''),
          recognizer: recognizer,
          highlightColor: highlightColor,
          baseStyle: baseStyle,
        ),
      );
    }

    return spans;
  }

  static const String _tafkheemLetters = 'خصضغطقظ';

  List<InlineSpan> _buildPlainTajweedAwareSpans(
    String text, {
    GestureRecognizer? recognizer,
    Color? highlightColor,
    TextStyle? baseStyle,
  }) {
    final cleanedText = text.replaceAll(RegExp(r'</?[^>]+>'), '');
    final spans = <InlineSpan>[];
    for (final char in cleanedText.split('')) {
      final color = _tafkheemLetters.contains(char)
          ? const Color(0xFF5D90A5)
          : null;
      spans.add(
        TextSpan(
          text: char,
          style: _highlightedStyle(
            (baseStyle ?? const TextStyle()).copyWith(color: color),
            highlightColor,
          ),
          recognizer: recognizer,
        ),
      );
    }
    return spans;
  }

  Color? _colorForTajweedClass(String tajweedClass) {
    return switch (tajweedClass) {
      'madda_necessary' => const Color(0xFFB94B37),
      'madda_obligatory' => const Color(0xFFFF4B3A),
      'madda_permissible' => const Color(0xFFF27A63),
      'madda_normal' => const Color(0xFFD7AE54),
      'ghunnah' ||
      'ikhafa' ||
      'ikhafa_shafawi' ||
      'iqlab' ||
      'idgham_ghunnah' ||
      'idgham_shafawi' => const Color(0xFF7FB071),
      'idgham_wo_ghunnah' => const Color(0xFFB8B6AB),
      'qalaqah' => const Color(0xFF66ABD0),
      _ => null,
    };
  }

  int _textLengthOfSpans(List<InlineSpan> spans) {
    var length = 0;
    for (final span in spans) {
      if (span is TextSpan) {
        length += span.text?.length ?? 0;
        if (span.children != null && span.children!.isNotEmpty) {
          length += _textLengthOfSpans(span.children!);
        }
      } else if (span is WidgetSpan) {
        length += 1;
      }
    }
    return length;
  }
}

class _VerseSpanBuildResult {
  const _VerseSpanBuildResult({
    required this.spans,
    required this.contentStart,
    required this.contentEnd,
  });

  final List<InlineSpan> spans;
  final int contentStart;
  final int contentEnd;
}

class _TextRange {
  const _TextRange(this.start, this.end);

  final int start;
  final int end;
}

class _VerseHighlightRange {
  const _VerseHighlightRange({
    required this.start,
    required this.end,
    required this.color,
  });

  final int start;
  final int end;
  final Color color;
}

class _NormalizedTextMap {
  _NormalizedTextMap(this.normalized, this.originalIndexByNormalizedIndex);

  final String normalized;
  final List<int> originalIndexByNormalizedIndex;
}

_NormalizedTextMap _normalizeArabicWithMap(String input) {
  final buffer = StringBuffer();
  final indexMap = <int>[];
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    final mapped = _normalizeArabicChar(char);
    if (mapped.isEmpty) {
      continue;
    }
    buffer.write(mapped);
    indexMap.add(i);
  }
  return _NormalizedTextMap(buffer.toString(), indexMap);
}

String _normalizeArabicChar(String char) {
  const diacriticsPattern = r'[\u064B-\u065F\u0670\u06D6-\u06ED]';
  if (RegExp(diacriticsPattern).hasMatch(char)) {
    return '';
  }
  return switch (char) {
    '\u0671' || '\u0623' || '\u0625' || '\u0622' => '\u0627',
    '\u0649' => '\u064a',
    '\u0624' => '\u0648',
    '\u0626' => '\u064a',
    '\u0629' => '\u0647',
    '\u0640' => '',
    _ => _isArabicOrSpace(char) ? char : '',
  };
}

bool _isArabicOrSpace(String char) {
  if (char == ' ') {
    return true;
  }
  final code = char.codeUnitAt(0);
  return (code >= 0x0600 && code <= 0x06FF) ||
      (code >= 0x0750 && code <= 0x077F) ||
      (code >= 0x08A0 && code <= 0x08FF);
}

List<_TextRange> _findQueryRangesInVerse(String verseText, String query) {
  final normalizedQuery = _normalizeArabicWithMap(query).normalized.trim();
  if (normalizedQuery.isEmpty) {
    return const [];
  }
  final normalizedVerse = _normalizeArabicWithMap(verseText);
  if (normalizedVerse.normalized.isEmpty ||
      normalizedQuery.length > normalizedVerse.normalized.length) {
    return const [];
  }

  final ranges = <_TextRange>[];
  var startIndex = 0;
  while (startIndex <=
      normalizedVerse.normalized.length - normalizedQuery.length) {
    final matchIndex = normalizedVerse.normalized.indexOf(
      normalizedQuery,
      startIndex,
    );
    if (matchIndex == -1) {
      break;
    }
    final matchEnd = matchIndex + normalizedQuery.length - 1;
    if (matchIndex < normalizedVerse.originalIndexByNormalizedIndex.length &&
        matchEnd < normalizedVerse.originalIndexByNormalizedIndex.length) {
      final originalStart =
          normalizedVerse.originalIndexByNormalizedIndex[matchIndex];
      final originalEnd =
          normalizedVerse.originalIndexByNormalizedIndex[matchEnd] + 1;
      ranges.add(_TextRange(originalStart, originalEnd));
    }
    startIndex = matchIndex + normalizedQuery.length;
  }
  return ranges;
}

class _HighlightedRichText extends StatelessWidget {
  const _HighlightedRichText({
    required this.text,
    required this.highlights,
    required this.textAlign,
    required this.textDirection,
    required this.textWidthBasis,
    required this.softWrap,
  });

  final InlineSpan text;
  final List<_VerseHighlightRange> highlights;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextWidthBasis textWidthBasis;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -2.0),
      child: CustomPaint(
        painter: _VerseHighlightPainter(
          text: text,
          highlights: highlights,
          textAlign: textAlign,
          textDirection: textDirection,
          textWidthBasis: textWidthBasis,
          textScaler: TextScaler.noScaling,
        ),
        child: RichText(
          textAlign: textAlign,
          textDirection: textDirection,
          textWidthBasis: textWidthBasis,
          softWrap: softWrap,
          textScaler: TextScaler.noScaling,
          text: text,
        ),
      ),
    );
  }
}

class _VerseHighlightPainter extends CustomPainter {
  const _VerseHighlightPainter({
    required this.text,
    required this.highlights,
    required this.textAlign,
    required this.textDirection,
    required this.textWidthBasis,
    required this.textScaler,
  });

  final InlineSpan text;
  final List<_VerseHighlightRange> highlights;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextWidthBasis textWidthBasis;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (highlights.isEmpty) {
      return;
    }

    final textPainter = TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: textDirection,
      textWidthBasis: textWidthBasis,
      textScaler: textScaler,
    );
    final placeholderDimensions = _collectPlaceholderDimensions(text);
    if (placeholderDimensions.isNotEmpty) {
      textPainter.setPlaceholderDimensions(placeholderDimensions);
    }
    textPainter.layout(maxWidth: size.width);

    for (final highlight in highlights) {
      final boxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: highlight.start, extentOffset: highlight.end),
      );
      final mergedBoxes = _mergeHighlightBoxes(boxes);
      final paint = Paint()
        ..color = highlight.color.withValues(alpha: 0.62)
        ..style = PaintingStyle.fill;

      for (final box in mergedBoxes) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            box.left - 2,
            box.top + 1.5,
            box.right + 2,
            box.bottom - 1.5,
          ),
          const Radius.circular(7),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VerseHighlightPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.highlights != highlights ||
        oldDelegate.textAlign != textAlign ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.textWidthBasis != textWidthBasis ||
        oldDelegate.textScaler != textScaler;
  }

  List<PlaceholderDimensions> _collectPlaceholderDimensions(InlineSpan span) {
    final dimensions = <PlaceholderDimensions>[];
    void walk(InlineSpan current, TextStyle? inheritedStyle) {
      if (current is TextSpan) {
        final effectiveStyle =
            inheritedStyle?.merge(current.style) ?? current.style;
        for (final child in current.children ?? const <InlineSpan>[]) {
          walk(child, effectiveStyle);
        }
        return;
      }

      if (current is WidgetSpan) {
        final fontSize = inheritedStyle?.fontSize ?? 16;
        final child = current.child;
        final width = child is _VersePlaceholderWidget
            ? child.placeholderWidth
            : 0.0;
        final height = child is _VersePlaceholderWidget
            ? child.placeholderHeight
            : fontSize * 1.05;
        dimensions.add(
          PlaceholderDimensions(
            size: Size(width, height),
            alignment: current.alignment,
            baseline: current.baseline,
          ),
        );
      }
    }

    walk(span, null);
    return dimensions;
  }

  List<TextBox> _mergeHighlightBoxes(List<TextBox> boxes) {
    if (boxes.length <= 1) {
      return boxes;
    }

    final sorted = [...boxes]
      ..sort((a, b) {
        final topCompare = a.top.compareTo(b.top);
        if (topCompare != 0) {
          return topCompare;
        }
        return a.left.compareTo(b.left);
      });

    const lineTolerance = 2.5;
    final merged = <TextBox>[];
    var currentLeft = sorted.first.left;
    var currentTop = sorted.first.top;
    var currentRight = sorted.first.right;
    var currentBottom = sorted.first.bottom;
    var currentDirection = sorted.first.direction;

    for (var i = 1; i < sorted.length; i++) {
      final box = sorted[i];
      final sameLine =
          (box.top - currentTop).abs() <= lineTolerance &&
          (box.bottom - currentBottom).abs() <= lineTolerance;
      final horizontalGap = box.left - currentRight;
      final shouldMerge = sameLine && horizontalGap <= 6.0;

      if (shouldMerge) {
        currentLeft = math.min(currentLeft, box.left);
        currentRight = math.max(currentRight, box.right);
        currentTop = math.min(currentTop, box.top);
        currentBottom = math.max(currentBottom, box.bottom);
        continue;
      }

      merged.add(
        TextBox.fromLTRBD(
          currentLeft,
          currentTop,
          currentRight,
          currentBottom,
          currentDirection,
        ),
      );
      currentLeft = box.left;
      currentTop = box.top;
      currentRight = box.right;
      currentBottom = box.bottom;
      currentDirection = box.direction;
    }

    merged.add(
      TextBox.fromLTRBD(
        currentLeft,
        currentTop,
        currentRight,
        currentBottom,
        currentDirection,
      ),
    );
    return merged;
  }
}

class _VersePlaceholderWidget extends StatelessWidget {
  const _VersePlaceholderWidget({
    super.key,
    required this.placeholderWidth,
    required this.placeholderHeight,
    required this.child,
  });

  final double placeholderWidth;
  final double placeholderHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _SideQuarterMarkerLayer extends StatefulWidget {
  const _SideQuarterMarkerLayer({
    required this.pageKey,
    required this.pageData,
    required this.appearance,
    required this.fontSize,
    required this.verseKeyBuilder,
  });

  final GlobalKey pageKey;
  final List<dynamic> pageData;
  final _ReaderAppearance appearance;
  final double fontSize;
  final GlobalKey Function(int surahNumber, int verseNumber) verseKeyBuilder;

  @override
  State<_SideQuarterMarkerLayer> createState() =>
      _SideQuarterMarkerLayerState();
}

class _SideQuarterMarkerLayerState extends State<_SideQuarterMarkerLayer> {
  //تحريك مكان الحزب
  static const double _markerOffset = -15.0;
  List<_QuarterMarkerPosition> _positions = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPositions());
  }

  @override
  void didUpdateWidget(covariant _SideQuarterMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPositions());
  }

  void _syncPositions() {
    if (!mounted) {
      return;
    }
    final pageContext = widget.pageKey.currentContext;
    final pageBox = pageContext?.findRenderObject() as RenderBox?;
    if (pageBox == null || !pageBox.hasSize) {
      return;
    }

    final pageOrigin = pageBox.localToGlobal(Offset.zero);
    final nextPositions = <_QuarterMarkerPosition>[];

    for (final dynamic item in widget.pageData) {
      final surahNumber = item['surah'] as int;
      final startVerse = item['start'] as int;
      final endVerse = item['end'] as int;
      final actualStart = surahNumber == 1 && startVerse == 1 ? 2 : startVerse;

      for (
        var verseNumber = actualStart;
        verseNumber <= endVerse;
        verseNumber++
      ) {
        if (!_isStartOfHizbQuarter(surahNumber, verseNumber)) {
          continue;
        }
        final verseKey = widget.verseKeyBuilder(surahNumber, verseNumber);
        final verseContext = verseKey.currentContext;
        final verseBox = verseContext?.findRenderObject() as RenderBox?;
        if (verseBox == null || !verseBox.hasSize) {
          continue;
        }
        final verseOrigin = verseBox.localToGlobal(Offset.zero);
        final rawTop = verseOrigin.dy - pageOrigin.dy;
        //تحريك مكان علامة الحزب
        final top = rawTop - (verseBox.size.height * 1.5) + _markerOffset;
        nextPositions.add(
          _QuarterMarkerPosition(
            top: top,
            label: _quarterMarkerDisplayLabel(
              _quarterMarkerLabel(surahNumber, verseNumber),
            ),
            color: widget.appearance.quarterMarkerTextColor,
          ),
        );
      }

      for (
        var verseNumber = actualStart;
        verseNumber <= endVerse;
        verseNumber++
      ) {
        if (!quran.isSajdahVerse(surahNumber, verseNumber)) {
          continue;
        }
        final verseKey = widget.verseKeyBuilder(surahNumber, verseNumber);
        final verseContext = verseKey.currentContext;
        final verseBox = verseContext?.findRenderObject() as RenderBox?;
        if (verseBox == null || !verseBox.hasSize) {
          continue;
        }
        final verseOrigin = verseBox.localToGlobal(Offset.zero);
        final rawTop = verseOrigin.dy - pageOrigin.dy;
        final top = rawTop - (verseBox.size.height * -0.5) + _markerOffset;
        nextPositions.add(
          _QuarterMarkerPosition(
            top: top,
            label: 'سجدة',
            color: widget.appearance.textColor,
          ),
        );
      }
    }

    if (!_samePositions(_positions, nextPositions)) {
      setState(() {
        _positions = nextPositions;
      });
    }
  }

  bool _samePositions(
    List<_QuarterMarkerPosition> a,
    List<_QuarterMarkerPosition> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if ((a[i].top - b[i].top).abs() > 0.5 || a[i].label != b[i].label) {
        return false;
      }
    }
    return true;
  }

  bool _isStartOfHizbQuarter(int surahNumber, int verseNumber) {
    final current = QuranCtrl.instance.getSingleAyahByAyahAndSurahNumber(
      verseNumber,
      surahNumber,
    );
    final currentQuarter = current.hizb;
    if (currentQuarter == null || currentQuarter <= 0) {
      return false;
    }

    final previousSurahNumber = verseNumber > 1 ? surahNumber : surahNumber - 1;
    if (previousSurahNumber < 1) {
      return false;
    }

    final previousVerseNumber = verseNumber > 1
        ? verseNumber - 1
        : _readerQuranSource.getVerseCount(previousSurahNumber);
    final previous = QuranCtrl.instance.getSingleAyahByAyahAndSurahNumber(
      previousVerseNumber,
      previousSurahNumber,
    );
    final previousQuarter = previous.hizb;
    return previousQuarter != currentQuarter;
  }

  String _quarterMarkerLabel(int surahNumber, int verseNumber) {
    final ayah = QuranCtrl.instance.getSingleAyahByAyahAndSurahNumber(
      verseNumber,
      surahNumber,
    );
    final quarter = ayah.hizb;
    if (quarter == null || quarter <= 0) {
      return 'الحزب';
    }
    final hizbNumber = ((quarter - 1) ~/ 4) + 1;
    final isStartOfJuz = hizbNumber.isOdd && ((quarter - 1) % 4 == 0);
    final juzNumber = (hizbNumber + 1) ~/ 2;
    final quarterPosition = (quarter - 1) % 4;
    final labelPosition = (quarterPosition + 3) % 4;
    final quarterLabel = switch (labelPosition) {
      0 => 'ربع',
      1 => 'نصف',
      2 => 'ثلاثة أرباع',
      _ => 'الحزب',
    };
    final juzText = isStartOfJuz ? 'الجزء ${toArabicNumber(juzNumber)}' : '';
    if (quarterLabel == 'الحزب') {
      return isStartOfJuz
          ? '$juzText\nالحزب ${toArabicNumber(hizbNumber)}'
          : 'الحزب ${toArabicNumber(hizbNumber)}';
    }
    return isStartOfJuz
        ? '$juzText\n$quarterLabel الحزب ${toArabicNumber(hizbNumber)}'
        : '$quarterLabel الحزب ${toArabicNumber(hizbNumber)}';
  }

  String _quarterMarkerDisplayLabel(String label) {
    return label
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final markerWidth = 28.0;
    const markerHeight = 56.0;
    const markerFontSize = 11.5;
    //علامه الحزب وحجمه ولونه
    return Stack(
      children: [
        for (final position in _positions)
          Positioned(
            right: 1,
            top: position.top,
            child: SizedBox(
              width: markerWidth,
              height: markerHeight,
              child: Center(
                child: Text(
                  position.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        position.color ??
                        widget.appearance.quarterMarkerTextColor,
                    fontSize: markerFontSize,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuarterMarkerPosition {
  const _QuarterMarkerPosition({
    required this.top,
    required this.label,
    this.color,
  });

  final double top;
  final String label;
  final Color? color;
}

class _PageDivider extends StatelessWidget {
  const _PageDivider({
    required this.pageNumber,
    required this.appearance,
    required this.fontSize,
  });

  final int pageNumber;
  final _ReaderAppearance appearance;
  final double fontSize;

  String? get _pageNumberFontFamily => switch (appearance) {
    //خط المصحف المستخدم في أرقام الصفحات
    _ReaderAppearance.classic ||
    _ReaderAppearance.golden ||
    _ReaderAppearance.night => 'ScheherazadeNew',
    _ReaderAppearance.tajweed ||
    _ReaderAppearance.nightTajweed => 'ScheherazadeNew',
    _ReaderAppearance.medinaPages => null,
    _ReaderAppearance.shamarlyPages => null,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: appearance.dividerColor, thickness: 1.2),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: appearance.dividerColor),
              borderRadius: BorderRadius.circular(999),
              color: appearance.pageColor,
              boxShadow: [
                BoxShadow(
                  color: appearance.dividerColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              toArabicNumber(pageNumber),
              style: TextStyle(
                color: appearance.quarterMarkerTextColor,
                fontWeight: FontWeight.w800,
                fontFamily: _pageNumberFontFamily,
                //حجم خط أرقام الصفحات
                fontSize: (fontSize * 0.6),
                height: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: appearance.dividerColor, thickness: 1.2),
          ),
        ],
      ),
    );
  }
}

class _KhatmDuaButton extends StatelessWidget {
  const _KhatmDuaButton({required this.appearance});

  final _ReaderAppearance appearance;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: appearance.surahBadgeColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const KhatmQuranDoaPage()));
      },
      icon: const Icon(Icons.menu_book_rounded),
      label: const Text(
        'دعاء ختم القرآن',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }
}
