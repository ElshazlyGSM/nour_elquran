part of 'reader_page.dart';

extension _ReaderNavigation on _ReaderPageState {
  static const int _maxInitialStandardPositionAttempts = 8;
  static const Duration _playbackPageScrollDuration = Duration(milliseconds: 1420);
  static const Duration _playbackVerseCenterDuration = Duration(milliseconds: 1340);
  static const Duration _playbackRetryDelay = Duration(milliseconds: 1220);
  static const Curve _playbackScrollCurve = Curves.easeInOutCubic;

  static const List<Color> _bookmarkColors = [
    Color(0xFF2F6A53),
    Color(0xFF2E5AAC),
    Color(0xFF7A5B2A),
    Color(0xFFC45A2A),
    Color(0xFF8B3D6E),
    Color(0xFFB38B00),
    Color(0xFF4A3720),
    Color(0xFF0F3D3E),
  ];

  Future<({String? note, int? colorValue})?> _promptBookmarkDetails() async {
    final controller = TextEditingController();
    var selected = _bookmarkColors.first;
    final result = await showDialog<({String? note, int? colorValue})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تفاصيل العلامة'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bookmarkColors.map((color) {
                      final isSelected = color == selected;
                      return GestureDetector(
                        onTap: () => setState(() => selected = color),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isSelected)
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 2,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop((
                  note: controller.text.trim().isEmpty
                      ? null
                      : controller.text.trim(),
                  colorValue: selected.toARGB32(),
                ));
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    return result;
  }

  bool _pageHasBookmark(int pageNumber) {
    return widget.store.readerBookmarks.any(
      (bookmark) => bookmark.pageNumber == pageNumber,
    );
  }

  Color? _pageBookmarkColor(int pageNumber) {
    for (final bookmark in widget.store.readerBookmarks) {
      if (bookmark.pageNumber == pageNumber && bookmark.colorValue != null) {
        return Color(bookmark.colorValue!);
      }
    }
    return null;
  }

  String _bookmarkPreviewText(String verseText) {
    final words = verseText
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return words.take(3).join(' ');
  }

  Future<void> _toggleCurrentVerseBookmark() async {
    final surahNumber = _selectedSurahNumber;
    final verseNumber = _selectedVerseNumber;
    if (surahNumber == null || verseNumber == null) {
      return;
    }

    final existing = widget.store.readerBookmarks.where(
      (bookmark) =>
          bookmark.surahNumber == surahNumber &&
          bookmark.verseNumber == verseNumber,
    );

    if (existing.isNotEmpty) {
      await widget.store.removeReaderBookmarkByVerse(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف العلامة')));
      return;
    }

    final meta = await _promptBookmarkDetails();
    if (meta == null) {
      return;
    }
    final verseText = _quranSource.getVerseText(surahNumber, verseNumber);
    final pageNumber = _quranSource.getPageNumber(surahNumber, verseNumber);
    final juzNumber = _currentJuzNumberFromPage(pageNumber);
    final bookmark = ReaderBookmark(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      juzNumber: juzNumber,
      surahName: _quranSource.getSurahNameArabic(surahNumber),
      previewText: _bookmarkPreviewText(verseText),
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      note: meta.note,
      colorValue: meta.colorValue,
    );
    await widget.store.upsertReaderBookmark(bookmark);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمت إضافة علامة عند ${bookmark.surahName} • الآية ${toArabicNumber(bookmark.verseNumber)}',
        ),
      ),
    );
  }

  Future<void> _jumpToReaderBookmark(ReaderBookmark bookmark) async {
    _updateState(() {
      _selectedSurahNumber = bookmark.surahNumber;
      _selectedVerseNumber = bookmark.verseNumber;
      _visibleSurahNumber = bookmark.surahNumber;
      _visibleStandardPageNumber = bookmark.pageNumber;
      if (_isMedinaPagesMode) {
        _pagedStartPage = bookmark.pageNumber;
        _isSwitchingToPagedMushaf = false;
      } else if (_isShamarlyPagesMode) {
        _shamarlyCurrentPage = bookmark.pageNumber;
      } else {
        _standardInitialPage = bookmark.pageNumber;
      }
    });
    _showBottomBarTemporarily();
    await _persistCurrentPosition();
    _scrollSelectedVerseIntoView();
  }

  Future<void> _showVerseActions({
    required int surahNumber,
    required int verseNumber,
    required String verseText,
  }) async {
    _updateState(() {
      _selectedSurahNumber = surahNumber;
      _selectedVerseNumber = verseNumber;
    });
    _showBottomBarTemporarily();
    unawaited(_persistCurrentPosition());
  }

  void _scrollSelectedVerseIntoView({
    bool allowApproximateJump = true,
    double? alignment,
  }) {
    if (_selectedSurahNumber == null || _selectedVerseNumber == null) {
      return;
    }
    if (_isMedinaPagesMode) {
      _jumpPagedToSelectedVerse();
      return;
    }
    if (_isShamarlyPagesMode) {
      final pageNumber = _resolveShamarlyPage(
        _selectedSurahNumber!,
        _selectedVerseNumber!,
      );
      _updateState(() {
        _shamarlyCurrentPage = pageNumber;
      });
      return;
    }

    final targetPage = _quranSource.getPageNumber(
      _selectedSurahNumber!,
      _selectedVerseNumber!,
    );
    final isPlaybackScroll = alignment != null;
    final key = _findVerseKey(
      _selectedSurahNumber!,
      _selectedVerseNumber!,
      pageNumber: targetPage,
    );
    final targetContext = key?.currentContext;
    if (targetContext == null) {
      if (allowApproximateJump &&
          _standardItemScrollController.isAttached &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              !_standardItemScrollController.isAttached ||
              _isPagedMushafMode) {
            return;
          }
          if (isPlaybackScroll) {
            _standardItemScrollController.scrollTo(
              index: targetPage - 1,
              duration: _playbackPageScrollDuration,
              curve: _playbackScrollCurve,
              alignment: 0,
            );
          } else {
            _standardItemScrollController.jumpTo(index: targetPage - 1);
          }
          Future.delayed(_playbackRetryDelay, () {
            if (!mounted) {
              return;
            }
            _scrollSelectedVerseIntoView(
              allowApproximateJump: false,
              alignment: alignment,
            );
          });
        });
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !targetContext.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        alignment: alignment ?? 0.28,
        duration: isPlaybackScroll
            ? _playbackVerseCenterDuration
            : Duration.zero,
        curve: _playbackScrollCurve,
      );
    });
  }


  GlobalKey? _findVerseKey(int surahNumber, int verseNumber, {int? pageNumber}) {
    if (pageNumber != null) {
      final exact = _verseKeys['$pageNumber:$surahNumber:$verseNumber'];
      if (exact != null) {
        return exact;
      }
    }
    final suffix = ':$surahNumber:$verseNumber';
    for (final entry in _verseKeys.entries) {
      if (entry.key.endsWith(suffix)) {
        return entry.value;
      }
    }
    return null;
  }
  void _jumpPagedToSelectedVerse() {
    if (!_isMedinaPagesMode) {
      return;
    }
    if (_selectedSurahNumber == null || _selectedVerseNumber == null) {
      return;
    }
    final ayahUq = _quranSource.getAyahUqBySurahAndAyah(
      _selectedSurahNumber!,
      _selectedVerseNumber!,
    );
    final pageNumber = QuranCtrl.instance.getPageNumberByAyahUqNumber(ayahUq);
    _primePagedMushafTargetPage(pageNumber);
    if (_pagedStartPage != pageNumber && mounted) {
      _updateState(() {
        _pagedStartPage = pageNumber;
      });
    }

    void scheduleSelection([Duration delay = Duration.zero]) {
      Future<void>.delayed(delay, () {
        if (!mounted || !_isMedinaPagesMode) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_isMedinaPagesMode) {
            return;
          }
          try {
            QuranCtrl.instance.jumpToPage(pageNumber - 1);
            QuranCtrl.instance.setExternalHighlights([ayahUq]);
            QuranCtrl.instance.update();
          } catch (_) {}
          if (delay >= const Duration(milliseconds: 220)) {
            _finishPagedMushafSwitching();
          }
        });
      });
    }

    scheduleSelection();
    scheduleSelection(const Duration(milliseconds: 220));
    scheduleSelection(const Duration(milliseconds: 460));
  }

  void _startInitialStandardPositioning() {
    if (!mounted || _isPagedMushafMode) {
      return;
    }
    if (_selectedSurahNumber == null || _selectedVerseNumber == null) {
      _updateState(() {
        _isInitialStandardPositioning = false;
      });
      return;
    }
    _updateState(() {
      _isInitialStandardPositioning = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isPagedMushafMode) {
        return;
      }
      _attemptInitialStandardPositioning(0);
    });
  }

  void _jumpStandardReaderNearTargetPage() {
    if (!mounted ||
        _isPagedMushafMode ||
        !_standardItemScrollController.isAttached) {
      return;
    }
    final targetPage = _quranSource.getPageNumber(
      widget.surahNumber,
      widget.initialVerse,
    );
    _standardItemScrollController.jumpTo(index: targetPage - 1);
  }

  void _attemptInitialStandardPositioning(int attempt) {
    if (!mounted || _isPagedMushafMode) {
      return;
    }
    if (!_isInitialStandardPositioning) {
      return;
    }
    if (_selectedSurahNumber == null || _selectedVerseNumber == null) {
      _updateState(() {
        _isInitialStandardPositioning = false;
      });
      return;
    }
    if (!_standardItemScrollController.isAttached) {
      if (attempt >= _maxInitialStandardPositionAttempts) {
        _updateState(() {
          _isInitialStandardPositioning = false;
        });
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptInitialStandardPositioning(attempt + 1);
      });
      return;
    }

    final targetPage = _quranSource.getPageNumber(
      _selectedSurahNumber!,
      _selectedVerseNumber!,
    );
    _standardItemScrollController.jumpTo(index: targetPage - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isPagedMushafMode) {
        return;
      }

      final verseContext =
          _findVerseKey(
            _selectedSurahNumber!,
            _selectedVerseNumber!,
            pageNumber: targetPage,
          )?.currentContext;
      if (verseContext != null && verseContext.mounted) {
        Scrollable.ensureVisible(
          verseContext,
          alignment: widget.initialVerseAlignment,
          duration: _playbackPageScrollDuration,
          curve: _playbackScrollCurve,
        );
        _updateState(() {
          _isInitialStandardPositioning = false;
        });
        return;
      }

      if (attempt >= _maxInitialStandardPositionAttempts) {
        _updateState(() {
          _isInitialStandardPositioning = false;
        });
        return;
      }

      Future.delayed(const Duration(milliseconds: 70), () {
        if (!mounted) {
          return;
        }
        _attemptInitialStandardPositioning(attempt + 1);
      });
    });
  }

  int? _currentVisibleStandardPage() {
    final positions = _standardItemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      return null;
    }
    final visiblePositions =
        positions
            .where(
              (position) =>
                  position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1,
            )
            .toList()
          ..sort((a, b) {
            final aVisible =
                (a.itemTrailingEdge.clamp(0.0, 1.0) -
                        a.itemLeadingEdge.clamp(0.0, 1.0))
                    .abs();
            final bVisible =
                (b.itemTrailingEdge.clamp(0.0, 1.0) -
                        b.itemLeadingEdge.clamp(0.0, 1.0))
                    .abs();
            return bVisible.compareTo(aVisible);
          });
    if (visiblePositions.isEmpty) {
      return null;
    }
    return visiblePositions.first.index + 1;
  }

  void _handleReaderScroll() {
    if (_isPagedMushafMode ||
        _isInitialStandardPositioning ||
        !_standardItemScrollController.isAttached) {
      return;
    }

    final candidatePage = _currentVisibleStandardPage();

    if (candidatePage == null) {
      return;
    }

    final pageData = _quranSource.getPageData(candidatePage);
    if (pageData.isEmpty) {
      return;
    }

    final surahNumber = pageData.first['surah'] as int;
    if (_visibleSurahNumber == surahNumber &&
        _visibleStandardPageNumber == candidatePage) {
      return;
    }

    _updateState(() {
      _visibleSurahNumber = surahNumber;
      _visibleStandardPageNumber = candidatePage;
    });
  }

  Future<void> _openSelectedVerseTafsir() async {
    if (_selectedSurahNumber == null || _selectedVerseNumber == null) {
      return;
    }
    await _showTafsirSheet(
      surahNumber: _selectedSurahNumber!,
      verseNumber: _selectedVerseNumber!,
      verseText: _quranSource.getVerseText(
        _selectedSurahNumber!,
        _selectedVerseNumber!,
        verseEndSymbol: true,
      ),
    );
  }

  Future<void> _openVerseSearch() async {
    final result = await showSearch<_ReaderSearchHit?>(
      context: context,
      delegate: _ReaderSearchDelegate(),
    );

    if (!mounted || result == null) {
      return;
    }

    if (_isPagedMushafMode || result.surahNumber == widget.surahNumber) {
      _updateState(() {
        _selectedSurahNumber = result.surahNumber;
        _selectedVerseNumber = result.verseNumber;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scrollSelectedVerseIntoView();
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) {
          return;
        }
        _scrollSelectedVerseIntoView();
      });
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: ReaderPage(
            store: widget.store,
            surahNumber: result.surahNumber,
            initialVerse: result.verseNumber,
          ),
        ),
      ),
    );
  }
}











