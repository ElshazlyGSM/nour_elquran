part of 'reader_page.dart';

extension _ReaderAutoScroll on _ReaderPageState {
  void _syncPagedMushafScaleFromFontSize() {
    if (!_isMedinaPagesMode) {
      return;
    }
    final scaleFactor = (1.0 + ((_fontSize - 28.0) / 14.0)).clamp(1.0, 2.0);
    try {
      QuranCtrl.instance.state.baseScaleFactor.value = scaleFactor;
      QuranCtrl.instance.state.scaleFactor.value = scaleFactor;
      QuranCtrl.instance.update(['_pageViewBuild']);
    } catch (_) {}
  }

  void _toggleAutoScroll() {
    if (_isPagedMushafMode) {
      return;
    }
    if (_isAutoScrollModeActive) {
      _stopAutoScrollMode();
    } else {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _updateState(() {
      _isAutoScrolling = true;
      _isAutoScrollPaused = false;
      _showControlBarWhileAutoScroll = true;
      _showBottomBar = true;
    });
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!_standardItemScrollController.isAttached) {
        return;
      }
      _standardScrollOffsetController.animateScroll(
        offset: _readingSpeed * 16,
        duration: const Duration(milliseconds: 80),
      );
    });
  }

  void _pauseAutoScroll() {
    _autoScrollTimer?.cancel();
    _controlBarHideTimer?.cancel();
    _updateState(() {
      _isAutoScrolling = false;
      _isAutoScrollPaused = true;
      _showControlBarWhileAutoScroll = true;
      _showBottomBar = true;
    });
  }

  void _resumeAutoScroll() {
    _controlBarHideTimer?.cancel();
    _startAutoScroll();
  }

  void _toggleAutoScrollPauseResume() {
    if (_isPagedMushafMode || !_isAutoScrollModeActive) {
      return;
    }
    if (_isAutoScrolling) {
      _pauseAutoScroll();
    } else {
      _resumeAutoScroll();
    }
  }

  void _stopAutoScrollMode() {
    _autoScrollTimer?.cancel();
    _controlBarHideTimer?.cancel();
    _ignoreAutoScrollTapUntil = null;
    _updateState(() {
      _isAutoScrolling = false;
      _isAutoScrollPaused = false;
      _showControlBarWhileAutoScroll = false;
      _showBottomBar = false;
    });
  }

  void _stopAutoScroll() {
    _stopAutoScrollMode();
  }

  void _showControlBarForFineTuning() {
    _controlBarHideTimer?.cancel();
    _updateState(() {
      _showControlBarWhileAutoScroll = true;
      _showBottomBar = true;
    });
    _controlBarHideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_isAutoScrolling) {
        return;
      }
      _updateState(() {
        _showControlBarWhileAutoScroll = false;
        _showBottomBar = false;
      });
    });
  }

  Future<void> _increaseReadingSpeed() async {
    if (_isPagedMushafMode) {
      return;
    }
    final targetMinutes = (_currentTargetJuzMinutes - 1).clamp(5, 60);
    _updateState(() {
      _readingSpeed = _readingSpeedForTargetJuzMinutes(targetMinutes);
    });
    unawaited(_persistReaderPreferences());
    if (!_isAutoScrolling) {
      _startAutoScroll();
    }
    _showControlBarForFineTuning();
  }

  Future<void> _decreaseReadingSpeed() async {
    if (_isPagedMushafMode) {
      return;
    }
    final targetMinutes = (_currentTargetJuzMinutes + 1).clamp(5, 60);
    _updateState(() {
      _readingSpeed = _readingSpeedForTargetJuzMinutes(targetMinutes);
    });
    unawaited(_persistReaderPreferences());
    if (!_isAutoScrolling) {
      _startAutoScroll();
    }
    _showControlBarForFineTuning();
  }

  void _increaseFontSize() {
    if (_isPagedMushafMode) {
      final currentScale = QuranCtrl.instance.state.scaleFactor.value;
      final nextScale = currentScale < 1.3
          ? 1.35
          : (currentScale + 0.15).clamp(1.0, 2.0);
      _updateState(() {
        _fontSize = ((nextScale - 1.0) * 14.0 + 28.0).clamp(14.0, 42.0);
      });
      try {
        QuranCtrl.instance.state.baseScaleFactor.value = nextScale;
        QuranCtrl.instance.state.scaleFactor.value = nextScale;
        QuranCtrl.instance.update(['_pageViewBuild']);
      } catch (_) {}
      unawaited(_persistReaderPreferences());
      return;
    }
    _updateState(() {
      _fontSize = (_fontSize + 2).clamp(14.0, 42.0);
      _lastContinuousFontSize = _fontSize;
    });
    _syncPagedMushafScaleFromFontSize();
    unawaited(_persistReaderPreferences());
  }

  void _decreaseFontSize() {
    if (_isPagedMushafMode) {
      final currentScale = QuranCtrl.instance.state.scaleFactor.value;
      final nextScale = currentScale <= 1.35
          ? 1.0
          : (currentScale - 0.15).clamp(1.0, 2.0);
      _updateState(() {
        _fontSize = ((nextScale - 1.0) * 14.0 + 28.0).clamp(14.0, 42.0);
      });
      try {
        QuranCtrl.instance.state.baseScaleFactor.value = nextScale;
        QuranCtrl.instance.state.scaleFactor.value = nextScale;
        QuranCtrl.instance.update(['_pageViewBuild']);
      } catch (_) {}
      unawaited(_persistReaderPreferences());
      return;
    }
    _updateState(() {
      _fontSize = (_fontSize - 2).clamp(14.0, 42.0);
      _lastContinuousFontSize = _fontSize;
    });
    _syncPagedMushafScaleFromFontSize();
    unawaited(_persistReaderPreferences());
  }
}
