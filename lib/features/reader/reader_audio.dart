part of 'reader_page.dart';

extension _ReaderAudio on _ReaderPageState {
  //عدد تشغيل اول ايات 5 وبعدها 20 
  static const int _initialPlaylistBatchSize = 5;
  static const int _initialPreloadBatchSize = 20;
  static const int _backgroundPlaylistBatchSize = 10;

  int get _effectiveRepeatCount =>
      _selectedRepeatCount <= 0 ? 1 : _selectedRepeatCount;

  int get _totalRecitationVerseCount {
    var total = 0;
    for (
      var surahNumber = 1;
      surahNumber <= currentQuranTotalSurahCount;
      surahNumber++
    ) {
      total += _quranSource.getVerseCount(surahNumber);
    }
    return total;
  }

  void _notifyReciterPickerSheetRefresh() {
    final refresh = _reciterPickerSheetRefresh;
    if (refresh != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          refresh();
        }
      });
    }
  }

  Future<void> _refreshReciterDownloadStatus([
    ReaderReciter? targetReciter,
  ]) async {
    final reciters = targetReciter == null ? readerReciters : [targetReciter];
    final partial = <String>{};
    final downloadedIds = <String>{};
    for (final reciter in reciters) {
      if (reciter.isLegacy && reciter.legacyReciter != null) {
        final count = await _recitationCacheService.countCachedVersesForReciter(
          reciter.legacyReciter!,
        );
        if (count >= _totalRecitationVerseCount) {
          downloadedIds.add(reciter.id);
        } else if (count > 0) {
          partial.add(reciter.id);
        }
        continue;
      }
      if (reciter.isMp3Quran) {
        final count = await _recitationCacheService
            .countCachedSurahsForMp3QuranReciter(reciter);
        if (count >= currentQuranTotalSurahCount) {
          downloadedIds.add(reciter.id);
        } else if (count > 0) {
          partial.add(reciter.id);
        }
      }
    }
    if (!mounted) {
      return;
    }
    _updateState(() {
      if (targetReciter == null) {
        _downloadedReciterIds
          ..clear()
          ..addAll(downloadedIds);
        _partialReciterIds
          ..clear()
          ..addAll(partial);
      } else {
        _downloadedReciterIds.remove(targetReciter.id);
        _partialReciterIds.remove(targetReciter.id);
        _downloadedReciterIds.addAll(downloadedIds);
        _partialReciterIds.addAll(partial);
      }
    });
    _notifyReciterPickerSheetRefresh();
  }

  Future<void> _toggleReciterDownload(ReaderReciter reciter) async {
    if (!reciter.isLegacy || reciter.legacyReciter == null) {
      return;
    }
    final reciterId = reciter.id;
    final legacyReciter = reciter.legacyReciter!;
    if (_downloadingReciterIds.contains(reciterId)) {
      _updateState(() {
        _cancelRequestedReciterIds.add(reciterId);
      });
      _notifyReciterPickerSheetRefresh();
      return;
    }
    if (_downloadedReciterIds.contains(reciterId)) {
      await _recitationCacheService.deleteReciter(legacyReciter);
      await _refreshReciterDownloadStatus(reciter);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف تلاوات ${_reciterArabicName(reciter)} من الجهاز',
          ),
        ),
      );
      return;
    }

    _updateState(() {
      _cancelRequestedReciterIds.remove(reciterId);
      _downloadingReciterIds.add(reciterId);
      _reciterDownloadProgress[reciterId] = 0;
    });
    _notifyReciterPickerSheetRefresh();

    try {
      await _recitationCacheService.downloadReciter(
        reciter: legacyReciter,
        totalSurahCount: currentQuranTotalSurahCount,
        verseCountResolver: _quranSource.getVerseCount,
        urlBuilder: (surahNumber, verseNumber) =>
            _quranSource.getAudioUrlByVerse(
              surahNumber,
              verseNumber,
              reciter: legacyReciter,
            ),
        onProgress: (progress) async {
          if (!mounted) {
            return;
          }
          _updateState(() {
            _reciterDownloadProgress[reciterId] = progress;
          });
          _notifyReciterPickerSheetRefresh();
        },
        isCancelled: () => _cancelRequestedReciterIds.contains(reciterId),
      );
      await _refreshReciterDownloadStatus(reciter);
      if (!mounted) {
        return;
      }
      final wasCancelled = _cancelRequestedReciterIds.contains(reciterId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasCancelled
                ? 'تم إيقاف تنزيل تلاوات ${_reciterArabicName(reciter)}'
                : 'تم تنزيل تلاوات ${_reciterArabicName(reciter)} على الجهاز',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _updateState(() {
        _audioError = 'تعذر تنزيل التلاوة حاليًا. تأكد من اتصال الإنترنت.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تنزيل تلاوات ${_reciterArabicName(reciter)} حاليًا.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        _updateState(() {
          _downloadingReciterIds.remove(reciterId);
          _cancelRequestedReciterIds.remove(reciterId);
        });
        _notifyReciterPickerSheetRefresh();
      }
    }
  }

  Future<void> _cacheCurrentPlaybackLocally({
    required int surahNumber,
    required Iterable<int> verseNumbers,
  }) async {
    final legacyReciter = _selectedReciter.legacyReciter;
    if (!_selectedReciter.isLegacy || legacyReciter == null) {
      return;
    }
    final uniqueVerses = verseNumbers.toSet().toList()..sort();
    try {
      for (final verseNumber in uniqueVerses) {
        await _recitationCacheService.cacheVerseIfMissing(
          reciter: legacyReciter,
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          url: _quranSource.getAudioUrlByVerse(
            surahNumber,
            verseNumber,
            reciter: legacyReciter,
          ),
        );
      }
      await _refreshReciterDownloadStatus(
        readerReciters
                .where((item) => item.legacyReciter == legacyReciter)
                .firstOrNull ??
            _selectedReciter,
      );
    } catch (_) {
      return;
    }
  }

  int? _currentPlaybackVerseNumber() {
    final currentIndex = _audioPlayer.currentIndex;
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < _playlistVerseNumbers.length) {
      return _playlistVerseNumbers[currentIndex];
    }
    return _selectedVerseNumber ?? _playbackStartVerse;
  }

  Future<void> _applyRepeatCount(int repeatCount) async {
    _updateState(() {
      _selectedRepeatCount = repeatCount;
    });
    unawaited(_persistReaderPreferences());

    if ((_isPlayingAudio || _isPreparingAudio) &&
        _activeAudioEngine == _AudioEngine.local &&
        _playbackSurahNumber != null) {
      final currentVerse = _currentPlaybackVerseNumber();
      if (currentVerse != null) {
        await _playFromVerse(
          surahNumber: _playbackSurahNumber!,
          verseNumber: currentVerse,
        );
      }
    }
  }

  Future<void> _toggleSelectedVerseAudio() async {
    if (_isPlayingAudio) {
      await _stopAudio();
      return;
    }
    if (_isPreparingAudio) {
      return;
    }
    if (_selectedSurahNumber == null || _selectedVerseNumber == null) {
      return;
    }
    await _playFromVerse(
      surahNumber: _selectedSurahNumber!,
      verseNumber: _selectedVerseNumber!,
    );
  }

  Future<void> _playFromVerse({
    required int surahNumber,
    required int verseNumber,
  }) async {
    final requestId = ++_audioPlayRequestId;
    _updateState(() {
      _audioError = null;
      _isPreparingAudio = true;
      _isPlayingAudio = false;
      _suspendPlaylistIndexSelectionSync = true;
      _selectedSurahNumber = surahNumber;
      _selectedVerseNumber = verseNumber;
    });
    _currentMp3QuranTimings = const [];
    _activeAudioEngine = _AudioEngine.local;
    _isAdvancingToNextSurah = false;

    try {
      await Future.wait<void>([
        AudioCtrl.instance.state.audioPlayer.stop().catchError((_) {}),
        _audioPlayer.stop().catchError((_) {}),
      ], eagerError: false);
      final allowedSurahs = _selectedReciter.availableSurahs;
      if (allowedSurahs != null &&
          allowedSurahs.isNotEmpty &&
          !allowedSurahs.contains(surahNumber)) {
        final count = allowedSurahs.length;
        throw Exception(
          '\u0647\u0630\u0647 \u0627\u0644\u0633\u0648\u0631\u0629 \u063a\u064a\u0631 \u0645\u062a\u0627\u062d\u0629 \u0644\u0647\u0630\u0627 \u0627\u0644\u0642\u0627\u0631\u0626. \u0627\u0644\u0645\u062a\u0627\u062d \u0644\u0647 $count \u0633\u0648\u0631\u0629 \u0641\u0642\u0637.',
        );
      }
      if (_selectedReciter.isMp3Quran) {
        await _playFromVerseWithMp3Quran(
          requestId: requestId,
          surahNumber: surahNumber,
          verseNumber: verseNumber,
        );
        return;
      }

      final legacyReciter = _selectedReciter.legacyReciter;
      if (legacyReciter == null) {
        throw Exception('تعذر تحديد القارئ الحالي.');
      }
      _playbackSurahNumber = surahNumber;
      _playbackStartVerse = verseNumber;
      final verseCount = _quranSource.getVerseCount(surahNumber);
      final allVersesToPlay = <int>[
        for (var ayah = verseNumber; ayah <= verseCount; ayah++)
          for (var repeat = 0; repeat < _effectiveRepeatCount; repeat++) ayah,
      ];
      if (allVersesToPlay.isEmpty) {
        throw Exception('لا توجد آيات متاحة للتشغيل.');
      }
      final initialBatchCount =
          allVersesToPlay.length < _initialPlaylistBatchSize
          ? allVersesToPlay.length
          : _initialPlaylistBatchSize;
      final initialVerses = allVersesToPlay
          .take(initialBatchCount)
          .toList(growable: true);
      final preloadStart = initialBatchCount;
      final preloadEndExclusive = (preloadStart + _initialPreloadBatchSize)
          .clamp(0, allVersesToPlay.length);
      final preloadedVerses = allVersesToPlay
          .sublist(preloadStart, preloadEndExclusive)
          .toList(growable: false);
      _playlistVerseNumbers = [...initialVerses, ...preloadedVerses];
      _playbackResumeVerseAfterChunk =
          preloadEndExclusive < allVersesToPlay.length
          ? allVersesToPlay[preloadEndExclusive]
          : null;

      final initialSources = await _buildLegacyAudioSourcesForVerses(
        legacyReciter: legacyReciter,
        surahNumber: surahNumber,
        verses: initialVerses,
      );
      final preloadedSources = _buildNetworkAudioSourcesForVerses(
        legacyReciter: legacyReciter,
        surahNumber: surahNumber,
        verses: preloadedVerses,
      );
      if (initialSources.isEmpty) {
        throw Exception('No verses available for playback.');
      }
      await _audioPlayer.setAudioSources(
        [...initialSources, ...preloadedSources],
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      if (requestId != _audioPlayRequestId) {
        return;
      }
      await _audioPlayer.play();
      if (mounted && requestId == _audioPlayRequestId) {
        _updateState(() {
          _isPreparingAudio = false;
          _isPlayingAudio = true;
          _suspendPlaylistIndexSelectionSync = false;
          _audioError = null;
        });
      }

      unawaited(
        _cacheCurrentPlaybackLocally(
          surahNumber: surahNumber,
          verseNumbers: initialVerses.toSet(),
        ),
      );

      if (preloadEndExclusive < allVersesToPlay.length) {
        unawaited(() async {
          try {
            var nextStart = preloadEndExclusive;
            while (nextStart < allVersesToPlay.length) {
              final nextEndExclusive =
                  (nextStart + _backgroundPlaylistBatchSize).clamp(
                    0,
                    allVersesToPlay.length,
                  );
              final batchVerses = allVersesToPlay
                  .sublist(nextStart, nextEndExclusive)
                  .toList(growable: false);
              final batchSources = _buildNetworkAudioSourcesForVerses(
                legacyReciter: legacyReciter,
                surahNumber: surahNumber,
                verses: batchVerses,
              );
              if (!mounted ||
                  requestId != _audioPlayRequestId ||
                  _activeAudioEngine != _AudioEngine.local) {
                return;
              }
              if (batchSources.isEmpty) {
                break;
              }
              await _audioPlayer.addAudioSources(batchSources);
              if (!mounted ||
                  requestId != _audioPlayRequestId ||
                  _activeAudioEngine != _AudioEngine.local) {
                return;
              }
              _playlistVerseNumbers.addAll(batchVerses);
              nextStart = nextEndExclusive;
              _playbackResumeVerseAfterChunk =
                  nextStart < allVersesToPlay.length
                  ? allVersesToPlay[nextStart]
                  : null;
              unawaited(
                _cacheCurrentPlaybackLocally(
                  surahNumber: surahNumber,
                  verseNumbers: batchVerses.toSet(),
                ),
              );
            }
          } catch (error) {
            if (kDebugMode) {
              debugPrint(
                '[ReaderAudio] Background playlist append failed: $error',
              );
            }
            return;
          }
        }());
      }
      return;
    } catch (_) {
      if (requestId != _audioPlayRequestId) {
        return;
      }
      _updateState(() {
        _audioError = _isAdvancingToNextSurah
            ? null
            : '\u062a\u0639\u0630\u0631 \u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u0635\u0648\u062a. \u062a\u0623\u0643\u062f \u0645\u0646 \u0627\u062a\u0635\u0627\u0644 \u0627\u0644\u0625\u0646\u062a\u0631\u0646\u062a.';
        _isPreparingAudio = false;
        _isPlayingAudio = false;
        _suspendPlaylistIndexSelectionSync = false;
      });
      return;
    }
  }

  Future<void> _playFromVerseWithMp3Quran({
    required int requestId,
    required int surahNumber,
    required int verseNumber,
  }) async {
    final reciter = _selectedReciter;
    List<Mp3QuranAyahTiming> timings = const [];
    try {
      timings = await _mp3QuranRecitationService.fetchAyahTimings(
        reciter: reciter,
        surahNumber: surahNumber,
      );
    } catch (_) {
      timings = const [];
    }
    final timing = timings
        .where((item) => item.ayah == verseNumber)
        .firstOrNull;
    _currentMp3QuranTimings = timings;
    final url = _mp3QuranRecitationService.buildSurahAudioUrl(
      reciter: reciter,
      surahNumber: surahNumber,
    );
    final localPath = await _recitationCacheService.localPathForMp3QuranSurah(
      reciter: reciter,
      surahNumber: surahNumber,
    );
    _playbackSurahNumber = surahNumber;
    _playbackStartVerse = verseNumber;
    _playlistVerseNumbers = [verseNumber];
    _playbackResumeVerseAfterChunk = null;
    if (localPath != null) {
      if (mounted && requestId == _audioPlayRequestId) {
        _updateState(() {
          _isPreparingAudio = true;
          _isPlayingAudio = false;
        });
      }
      await _audioPlayer.setFilePath(localPath);
    } else {
      if (mounted && requestId == _audioPlayRequestId) {
        _updateState(() {
          _isPreparingAudio = true;
        });
      }
      await _audioPlayer.setUrl(url);
      unawaited(() async {
        try {
          await _recitationCacheService.cacheMp3QuranSurahIfMissing(
            reciter: reciter,
            surahNumber: surahNumber,
            url: url,
          );
          await _refreshReciterDownloadStatus(reciter);
        } catch (_) {
          return;
        }
      }());
    }
    if (requestId != _audioPlayRequestId) {
      return;
    }
    if (timing != null) {
      await _audioPlayer.seek(Duration(milliseconds: timing.startTimeMs));
    } else {
      await _audioPlayer.seek(Duration.zero);
      if (mounted && requestId == _audioPlayRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u0647\u0630\u0627 \u0627\u0644\u0642\u0627\u0631\u0626 \u0644\u0627 \u064a\u062f\u0639\u0645 \u062a\u0648\u0642\u064a\u062a \u0627\u0644\u0622\u064a\u0627\u062a. \u062a\u0645 \u0627\u0644\u062a\u0634\u063a\u064a\u0644 \u0645\u0646 \u0628\u062f\u0627\u064a\u0629 \u0627\u0644\u0633\u0648\u0631\u0629.',
            ),
          ),
        );
      }
    }
    await _audioPlayer.play();
    if (mounted && requestId == _audioPlayRequestId) {
      _updateState(() {
        _isPreparingAudio = false;
        _isPlayingAudio = true;
        _suspendPlaylistIndexSelectionSync = false;
        _audioError = null;
      });
    }
  }

  Future<void> _stopAudio() async {
    _audioPlayRequestId++;
    _playlistVerseNumbers = const [];
    _currentMp3QuranTimings = const [];
    _playbackResumeVerseAfterChunk = null;
    _isAdvancingToNextSurah = false;
    if (_isPagedMushafMode) {
      try {
        QuranCtrl.instance.clearExternalHighlights();
      } catch (_) {}
    }
    if (mounted) {
      _updateState(() {
        _isPreparingAudio = false;
        _isPlayingAudio = false;
        _suspendPlaylistIndexSelectionSync = false;
      });
    }
    await Future.wait<void>([
      AudioCtrl.instance.state.audioPlayer.stop().catchError((_) {}),
      _audioPlayer.stop().catchError((_) {}),
    ], eagerError: false);
  }

  Future<void> _handleLocalAudioCompleted() async {
    if (_isHandlingLocalCompletion) {
      return;
    }
    _isHandlingLocalCompletion = true;
    try {
      final currentSurah = _playbackSurahNumber;
      if (_isAdvancingToNextSurah) {
        return;
      }
      if (currentSurah == null) {
        await _stopAudio();
        return;
      }
      final resumeVerse = _playbackResumeVerseAfterChunk;
      if (resumeVerse != null) {
        final verseCount = _quranSource.getVerseCount(currentSurah);
        if (resumeVerse > verseCount) {
          _playbackResumeVerseAfterChunk = null;
        } else {
          _playbackResumeVerseAfterChunk = null;
          for (var attempt = 0; attempt < 2; attempt++) {
            await Future<void>.delayed(
              Duration(milliseconds: attempt == 0 ? 60 : 180),
            );
            try {
              await _playFromVerse(
                surahNumber: currentSurah,
                verseNumber: resumeVerse,
              );
              return;
            } catch (_) {
              if (attempt == 1) {
                break;
              }
            }
          }
        }
      }
      if (currentSurah >= currentQuranTotalSurahCount) {
        await _stopAudio();
        return;
      }
      _isAdvancingToNextSurah = true;
      await Future<void>.delayed(const Duration(milliseconds: 180));
      _updateState(() {
        _selectedSurahNumber = currentSurah + 1;
        _selectedVerseNumber = 1;
        _visibleSurahNumber = currentSurah + 1;
        _audioError = null;
      });
      try {
        await _playFromVerse(surahNumber: currentSurah + 1, verseNumber: 1);
      } catch (_) {
        if (mounted) {
          _updateState(() {
            _audioError = null;
            _isPreparingAudio = false;
            _isPlayingAudio = false;
          });
        }
      } finally {
        _isAdvancingToNextSurah = false;
      }
    } finally {
      _isHandlingLocalCompletion = false;
    }
  }

  Future<List<AudioSource>> _buildLegacyAudioSourcesForVerses({
    required dynamic legacyReciter,
    required int surahNumber,
    required List<int> verses,
  }) async {
    if (verses.isEmpty) {
      return const [];
    }
    final localPaths = await Future.wait<String?>([
      for (final ayah in verses)
        _recitationCacheService.localPathForVerse(
          reciter: legacyReciter,
          surahNumber: surahNumber,
          verseNumber: ayah,
        ),
    ], eagerError: false);
    return <AudioSource>[
      for (var i = 0; i < verses.length; i++)
        localPaths[i] != null
            ? AudioSource.file(localPaths[i]!)
            : AudioSource.uri(
                Uri.parse(
                  _quranSource.getAudioUrlByVerse(
                    surahNumber,
                    verses[i],
                    reciter: legacyReciter,
                  ),
                ),
              ),
    ];
  }

  List<AudioSource> _buildNetworkAudioSourcesForVerses({
    required dynamic legacyReciter,
    required int surahNumber,
    required List<int> verses,
  }) {
    if (verses.isEmpty) {
      return const [];
    }
    return <AudioSource>[
      for (final ayah in verses)
        AudioSource.uri(
          Uri.parse(
            _quranSource.getAudioUrlByVerse(
              surahNumber,
              ayah,
              reciter: legacyReciter,
            ),
          ),
        ),
    ];
  }
}
