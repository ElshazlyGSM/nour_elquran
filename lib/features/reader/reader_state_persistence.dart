part of 'reader_page.dart';

extension _ReaderStatePersistence on _ReaderPageState {
  bool _resolveReaderDarkModeEnabled() {
    final mode = widget.store.savedThemeMode;
    if (mode == 'dark') {
      return true;
    }
    if (mode == 'light') {
      return false;
    }
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  _ReaderAppearance _appearanceForThemePreference(
    _ReaderAppearance appearance,
    bool darkModeEnabled,
  ) {
    if (darkModeEnabled) {
      return switch (appearance) {
        _ReaderAppearance.classic ||
        _ReaderAppearance.golden => _ReaderAppearance.night,
        _ReaderAppearance.tajweed => _ReaderAppearance.nightTajweed,
        _ReaderAppearance.medinaPages => _ReaderAppearance.medinaPages,
        _ReaderAppearance.shamarlyPages => _ReaderAppearance.shamarlyPages,
        _ => appearance,
      };
    }
    return switch (appearance) {
      _ReaderAppearance.night => _ReaderAppearance.classic,
      _ReaderAppearance.nightTajweed => _ReaderAppearance.tajweed,
      _ => appearance,
    };
  }

  int get _selectedReciterIndex {
    final index = readerReciters.indexWhere(
      (item) => item.id == _selectedReciter.id,
    );
    return index >= 0 ? index : 0;
  }

  ReaderReciter _readerReciterFromLegacyReciter(quran.Reciter reciter) {
    final directMatch = readerReciters
        .where((item) => item.legacyReciter == reciter)
        .firstOrNull;
    if (directMatch != null) {
      return directMatch;
    }
    return switch (reciter) {
      quran.Reciter.arHusary =>
        findReaderReciterById('mp3:118') ?? readerReciters.first,
      quran.Reciter.arMinshawi =>
        readerReciters
                .where((item) => item.legacyReciter == quran.Reciter.arMinshawi)
                .firstOrNull ??
            defaultReaderReciter,
      _ => defaultReaderReciter,
    };
  }

  String get _repeatCountLabel => _selectedRepeatCount == 0
      ? 'بدون تكرار'
      : '${toArabicNumber(_selectedRepeatCount)}×';

  String get _estimatedJuzReadingTimeLabel {
    final minutes =
        _isAutoScrollModeActive && _lockedAutoScrollTargetMinutes != null
        ? _lockedAutoScrollTargetMinutes!
        : _currentTargetJuzMinutes;
    return '\u0648\u0642\u062a \u0627\u0644\u062c\u0632\u0621 ${toArabicNumber(minutes)} \u062f';
  }

  int get _currentTargetJuzMinutes =>
      _estimatedJuzMinutesValue.round().clamp(5, 60);

  double get _estimatedJuzMinutesValue {
    final currentPage =
        _currentVisibleStandardPage() ??
        _quranSource.getPageNumber(
          _selectedSurahNumber ?? widget.surahNumber,
          _selectedVerseNumber ?? widget.initialVerse,
        );
    final juzRange = _currentJuzPageRange(currentPage);
    final pageHeight = _currentEstimatedPageHeight;
    final pixelsPerSecond = (_readingSpeed * 16) / 0.08;
    final totalPixels = juzRange.pageCount * pageHeight;
    return (totalPixels / pixelsPerSecond / 60).clamp(5, 60);
  }

  double _readingSpeedForTargetJuzMinutes(int minutes) {
    final currentPage =
        _currentVisibleStandardPage() ??
        _quranSource.getPageNumber(
          _selectedSurahNumber ?? widget.surahNumber,
          _selectedVerseNumber ?? widget.initialVerse,
        );
    final juzRange = _currentJuzPageRange(currentPage);
    final pageHeight = _currentEstimatedPageHeight;
    final totalPixels = juzRange.pageCount * pageHeight;
    final clampedMinutes = minutes.clamp(5, 60);
    final pixelsPerSecond = totalPixels / (clampedMinutes * 60);
    return ((pixelsPerSecond * 0.08) / 16).clamp(0.05, 3.0);
  }

  ({int startPage, int endPage, int pageCount}) _currentJuzPageRange(
    int currentPage,
  ) {
    for (
      var juzNumber = 1;
      juzNumber <= currentQuranTotalJuzCount;
      juzNumber++
    ) {
      final verses = _quranSource.getSurahAndVersesFromJuz(juzNumber);
      final firstSurah = verses.keys.first;
      final firstVerse = verses[firstSurah]!.first;
      final startPage = _quranSource.getPageNumber(firstSurah, firstVerse);

      int endPage = currentQuranTotalPagesCount;
      if (juzNumber < currentQuranTotalJuzCount) {
        final nextVerses = _quranSource.getSurahAndVersesFromJuz(juzNumber + 1);
        final nextSurah = nextVerses.keys.first;
        final nextVerse = nextVerses[nextSurah]!.first;
        endPage = _quranSource.getPageNumber(nextSurah, nextVerse) - 1;
      }

      if (currentPage >= startPage && currentPage <= endPage) {
        return (
          startPage: startPage,
          endPage: endPage,
          pageCount: endPage - startPage + 1,
        );
      }
    }

    return (startPage: 1, endPage: 20, pageCount: 20);
  }

  int _currentJuzNumberFromPage(int currentPage) {
    for (
      var juzNumber = 1;
      juzNumber <= currentQuranTotalJuzCount;
      juzNumber++
    ) {
      final verses = _quranSource.getSurahAndVersesFromJuz(juzNumber);
      final firstSurah = verses.keys.first;
      final firstVerse = verses[firstSurah]!.first;
      final startPage = _quranSource.getPageNumber(firstSurah, firstVerse);

      int endPage = currentQuranTotalPagesCount;
      if (juzNumber < currentQuranTotalJuzCount) {
        final nextVerses = _quranSource.getSurahAndVersesFromJuz(juzNumber + 1);
        final nextSurah = nextVerses.keys.first;
        final nextVerse = nextVerses[nextSurah]!.first;
        endPage = _quranSource.getPageNumber(nextSurah, nextVerse) - 1;
      }

      if (currentPage >= startPage && currentPage <= endPage) {
        return juzNumber;
      }
    }
    return 1;
  }

  double get _currentEstimatedPageHeight {
    final currentPage = _currentVisibleStandardPage();
    final candidates = <double>[];

    if (currentPage != null) {
      final currentContext = _pageKeys[currentPage]?.currentContext;
      final currentRender = currentContext?.findRenderObject() as RenderBox?;
      final currentHeight = currentRender?.size.height;
      if (currentHeight != null && currentHeight > 0) {
        return currentHeight;
      }
    }

    for (final key in _pageKeys.values) {
      final render = key.currentContext?.findRenderObject() as RenderBox?;
      final height = render?.size.height;
      if (height != null && height > 0) {
        candidates.add(height);
      }
    }

    if (candidates.isNotEmpty) {
      final sum = candidates.reduce((a, b) => a + b);
      return sum / candidates.length;
    }

    return 920;
  }

  GlobalKey _pageKeyFor(int pageNumber) {
    return _pageKeys.putIfAbsent(pageNumber, GlobalKey.new);
  }

  void _restoreReaderPreferences() {
    final savedReciterId = widget.store.savedReciterId;
    final savedReciter = findReaderReciterById(savedReciterId);
    if (savedReciter != null) {
      _selectedReciter = savedReciter;
    }

    final savedReciterIndex = widget.store.savedReciterIndex;
    if (savedReciter == null &&
        savedReciterIndex != null &&
        savedReciterIndex >= 0 &&
        savedReciterIndex < quran.Reciter.values.length) {
      final legacyReciter = quran.Reciter.values[savedReciterIndex];
      _selectedReciter = _readerReciterFromLegacyReciter(legacyReciter);
    }

    if (savedReciter == null && savedReciterIndex == null) {
      _selectedReciter = defaultReaderReciter;
    }

    final savedTafsirId = widget.store.savedTafsirId;
    if (savedTafsirId != null) {
      _selectedTafsir = TafsirOption.values.firstWhere(
        (option) => option.id == savedTafsirId,
        orElse: () => TafsirOption.muyassar,
      );
    }

    _selectedRepeatCount = widget.store.savedRepeatCount.clamp(0, 10);
    if (_selectedRepeatCount == 1) {
      _selectedRepeatCount = 0;
    }
    final darkModeEnabled = _resolveReaderDarkModeEnabled();

    final savedAppearance = widget.store.savedAppearance;
    if (savedAppearance != null) {
      _appearance = _appearanceForThemePreference(
        _ReaderAppearance.values.firstWhere(
          (appearance) => appearance.name == savedAppearance,
          orElse: () => _ReaderAppearance.classic,
        ),
        darkModeEnabled,
      );
    } else if (darkModeEnabled) {
      _appearance = _ReaderAppearance.night;
    }

    final fallbackFontSize = _appearance == _ReaderAppearance.golden
        ? 24.0
        : _fontSize;
    _fontSize = (widget.store.savedFontSize ?? fallbackFontSize).clamp(
      14.0,
      42.0,
    );
    _lastContinuousFontSize = _fontSize;
    _readingSpeed =
        (widget.store.savedReadingSpeed ?? _readingSpeedForTargetJuzMinutes(15))
            .clamp(0.05, 3.0);
    _shamarlyZoomScale = widget.store.savedShamarlyZoomScale;

    unawaited(_refreshReciterDownloadStatus(_selectedReciter));
  }

  Future<void> _persistCurrentPosition() async {
    if (_isShamarlyPagesMode &&
        (_selectedSurahNumber == null || _selectedVerseNumber == null)) {
      final anchor = _resolveShamarlyAnchorForPage(_shamarlyCurrentPage);
      if (anchor != null) {
        _selectedSurahNumber = anchor.surahNumber;
        _selectedVerseNumber = anchor.verseNumber;
      }
    }
    if (_selectedSurahNumber == null || _selectedVerseNumber == null) {
      return;
    }
    await widget.store.saveLastRead(
      surahNumber: _selectedSurahNumber!,
      verseNumber: _selectedVerseNumber!,
    );
  }

  Future<void> _persistReaderPreferences() {
    var fontSize = _fontSize;
    if (_isPagedMushafMode) {
      fontSize = _lastContinuousFontSize;
      if (_isMedinaPagesMode && !_useMedinaOnDemandDownload && mounted) {
        final scaleFactor = QuranCtrl.instance.state.scaleFactor.value;
        _fontSize = ((scaleFactor - 1.0) * 14.0 + 28.0).clamp(14.0, 42.0);
      }
    }
    return widget.store.saveReaderPreferences(
      reciterIndex: _selectedReciterIndex,
      reciterId: _selectedReciter.id,
      tafsirId: _selectedTafsir.id,
      repeatCount: _selectedRepeatCount,
      fontSize: fontSize,
      readingSpeed: _readingSpeed,
      appearance: _appearance.name,
      shamarlyZoomScale: _shamarlyZoomScale,
    );
  }

  String _reciterArabicName(ReaderReciter reciter) {
    return reciter.nameAr;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}
