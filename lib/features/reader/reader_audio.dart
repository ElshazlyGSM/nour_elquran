part of 'reader_page.dart';

extension _ReaderAudio on _ReaderPageState {
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
    _updateState(() {
      _audioError = null;
      _isPreparingAudio = false;
      _isPlayingAudio = false;
      _currentPlaybackUsesNetwork = false;
      _selectedSurahNumber = surahNumber;
      _selectedVerseNumber = verseNumber;
    });
    _currentMp3QuranTimings = const [];
    _activeAudioEngine = _AudioEngine.local;

    try {
      await AudioCtrl.instance.state.audioPlayer.stop();
      await _audioPlayer.stop();
      if (_selectedReciter.isMp3Quran) {
        await _playFromVerseWithMp3Quran(
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
      _playbackResumeVerseAfterChunk = null;
      final verseCount = _quranSource.getVerseCount(surahNumber);
      final localChunkVerses = <int>[];
      var firstMissingVerseAfterChunk = 0;
      for (var ayah = verseNumber; ayah <= verseCount; ayah++) {
        final localPath = await _recitationCacheService.localPathForVerse(
          reciter: legacyReciter,
          surahNumber: surahNumber,
          verseNumber: ayah,
        );
        if (localPath == null) {
          firstMissingVerseAfterChunk = ayah;
          break;
        }
        localChunkVerses.add(ayah);
      }

      final shouldUseLocalChunk = localChunkVerses.isNotEmpty;
      final versesToPlay = shouldUseLocalChunk
          ? localChunkVerses
          : [for (var ayah = verseNumber; ayah <= verseCount; ayah++) ayah];
      _playlistVerseNumbers = [
        for (final ayah in versesToPlay)
          for (var repeat = 0; repeat < _effectiveRepeatCount; repeat++) ayah,
      ];
      if (shouldUseLocalChunk &&
          firstMissingVerseAfterChunk > 0 &&
          firstMissingVerseAfterChunk <= verseCount) {
        _playbackResumeVerseAfterChunk = firstMissingVerseAfterChunk;
      }
      final playlist = <AudioSource>[];
      var allLocal = shouldUseLocalChunk;
      for (final ayah in _playlistVerseNumbers) {
        final localPath = await _recitationCacheService.localPathForVerse(
          reciter: legacyReciter,
          surahNumber: surahNumber,
          verseNumber: ayah,
        );
        if (localPath != null) {
          playlist.add(AudioSource.file(localPath));
          continue;
        }
        allLocal = false;
        playlist.add(
          AudioSource.uri(
            Uri.parse(
              _quranSource.getAudioUrlByVerse(
                surahNumber,
                ayah,
                reciter: legacyReciter,
              ),
            ),
          ),
        );
      }
      if (!allLocal && mounted) {
        _updateState(() {
          _currentPlaybackUsesNetwork = true;
          _isPreparingAudio = true;
        });
      } else if (mounted) {
        _updateState(() {
          _currentPlaybackUsesNetwork = false;
        });
      }
      unawaited(
        _cacheCurrentPlaybackLocally(
          surahNumber: surahNumber,
          verseNumbers: _playlistVerseNumbers,
        ),
      );
      if (allLocal && mounted) {
        _updateState(() {
          _isPreparingAudio = false;
          _isPlayingAudio = true;
        });
      }
      await _audioPlayer.setAudioSources(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await _audioPlayer.play();
      if (mounted) {
        _updateState(() {
          _isPreparingAudio = false;
          _isPlayingAudio = true;
          _audioError = null;
        });
      }
    } catch (_) {
      _updateState(() {
        _audioError = _isAdvancingToNextSurah
            ? null
            : '\u062a\u0639\u0630\u0631 \u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u0635\u0648\u062a. \u062a\u0623\u0643\u062f \u0645\u0646 \u0627\u062a\u0635\u0627\u0644 \u0627\u0644\u0625\u0646\u062a\u0631\u0646\u062a.';
        _isPreparingAudio = false;
        _isPlayingAudio = false;
      });
      return;
    }

    if (mounted) {
      _updateState(() {
        _isPreparingAudio = false;
      });
    }
  }

  Future<void> _playFromVerseWithMp3Quran({
    required int surahNumber,
    required int verseNumber,
  }) async {
    final reciter = _selectedReciter;
    final timings = await _mp3QuranRecitationService.fetchAyahTimings(
      reciter: reciter,
      surahNumber: surahNumber,
    );
    final timing = timings
        .where((item) => item.ayah == verseNumber)
        .firstOrNull;
    if (timing == null) {
      throw Exception('هذا القارئ لا يملك توقيتًا واضحًا لهذه الآية.');
    }
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
      if (mounted) {
        _updateState(() {
          _currentPlaybackUsesNetwork = false;
          _isPreparingAudio = false;
          _isPlayingAudio = true;
        });
      }
      await _audioPlayer.setFilePath(localPath);
    } else {
      if (mounted) {
        _updateState(() {
          _currentPlaybackUsesNetwork = true;
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
    await _audioPlayer.seek(Duration(milliseconds: timing.startTimeMs));
    await _audioPlayer.play();
    if (mounted) {
      _updateState(() {
        _currentPlaybackUsesNetwork = false;
        _isPreparingAudio = false;
        _isPlayingAudio = true;
        _audioError = null;
      });
    }
  }

  Future<void> _stopAudio() async {
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
        _currentPlaybackUsesNetwork = false;
        _isPreparingAudio = false;
        _isPlayingAudio = false;
      });
    }
    await AudioCtrl.instance.state.audioPlayer.stop();
    await _audioPlayer.stop();
  }

  Future<void> _handleLocalAudioCompleted() async {
    final currentSurah = _playbackSurahNumber;
    if (_isAdvancingToNextSurah || currentSurah == null) {
      await _stopAudio();
      return;
    }
    final resumeVerse = _playbackResumeVerseAfterChunk;
    if (resumeVerse != null) {
      _playbackResumeVerseAfterChunk = null;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      try {
        await _playFromVerse(
          surahNumber: currentSurah,
          verseNumber: resumeVerse,
        );
      } catch (_) {
        await _stopAudio();
      }
      return;
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
  }
}
