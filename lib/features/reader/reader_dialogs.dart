part of 'reader_page.dart';

extension _ReaderDialogs on _ReaderPageState {
  Future<void> _refreshDownloadedTafsirIds() async {
    final downloaded = <int>{};
    final partial = <int>{};
    for (final option in TafsirOption.values) {
      final isDownloaded = await _tafsirService.isTafsirDownloaded(option);
      final downloadedCount = await _tafsirService.downloadedVerseCount(option);
      if (isDownloaded) {
        downloaded.add(option.id);
      } else if (downloadedCount > 0) {
        partial.add(option.id);
      }
    }
    if (!mounted) {
      return;
    }
    _updateState(() {
      _downloadedTafsirIds
        ..clear()
        ..addAll(downloaded);
      _partialTafsirIds
        ..clear()
        ..addAll(partial);
    });
  }

  Future<void> _showTajweedLegendSheet() async {
    const legendItems = [
      _TajweedLegendItem(color: Color(0xFFB94B37), label: 'المد الكلمي المثقل'),
      _TajweedLegendItem(color: Color(0xFFFF4B3A), label: 'المد الواجب المتصل'),
      _TajweedLegendItem(
        color: Color(0xFFF27A63),
        label: 'المد الجائز المنفصل',
      ),
      _TajweedLegendItem(color: Color(0xFFD7AE54), label: 'المد الطبيعي'),
      _TajweedLegendItem(color: Color(0xFF7FB071), label: 'غنة مع إخفاء'),
      _TajweedLegendItem(color: Color(0xFFB8B6AB), label: 'إدغام بلا غنة'),
      _TajweedLegendItem(
        color: Color(0xFF5D90A5),
        label: 'حروف التفخيم خص ضغط قظ',
      ),
      _TajweedLegendItem(color: Color(0xFF66ABD0), label: 'قلقلة'),
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const SizedBox(height: 6),
              const SizedBox(
                height: 110,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(painter: _TajweedWheelPainter()),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'دليل ألوان التجويد',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'كل لون في هذا الدليل يشرح الحكم المقابل له داخل مصحف التجويد.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6A6559),
                  height: 1.7,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF7EE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8DEC7)),
                ),
                child: Column(
                  children: [
                    for (final item in legendItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFE5DCC7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTafsirSheet({
    required int surahNumber,
    required int verseNumber,
    required String verseText,
  }) async {
    await _refreshDownloadedTafsirIds();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final tafsirTextColor = isDark
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF1E241F);
        TafsirOption currentOption = _selectedTafsir;
        Future<String> currentFuture = _tafsirService.fetchTafsir(
          option: currentOption,
          surahNumber: surahNumber,
          verseNumber: verseNumber,
        );

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDownloaded = _downloadedTafsirIds.contains(
              currentOption.id,
            );
            final isDownloading = _downloadingTafsirIds.contains(
              currentOption.id,
            );
            final isPartial = _partialTafsirIds.contains(currentOption.id);
            final progress = _tafsirDownloadProgress[currentOption.id];

            Future<void> startDownload(TafsirOption option) async {
              _updateState(() {
                _cancelRequestedTafsirIds.remove(option.id);
                _downloadingTafsirIds.add(option.id);
                _tafsirDownloadProgress[option.id] = 0;
              });
              if (context.mounted) {
                setSheetState(() {});
              }
              try {
                await _tafsirService.downloadTafsir(
                  option,
                  onProgress: (completed, total) {
                    if (!mounted) {
                      return;
                    }
                    _updateState(() {
                      _tafsirDownloadProgress[option.id] = total == 0
                          ? 0
                          : completed / total;
                    });
                    if (context.mounted) {
                      setSheetState(() {});
                    }
                  },
                  shouldCancel: () =>
                      _cancelRequestedTafsirIds.contains(option.id),
                );
                await _refreshDownloadedTafsirIds();
              } finally {
                if (mounted) {
                  _updateState(() {
                    _downloadingTafsirIds.remove(option.id);
                    _cancelRequestedTafsirIds.remove(option.id);
                  });
                }
                if (context.mounted) {
                  setSheetState(() {});
                }
              }
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.82,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'إغلاق',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            onPressed: isDownloaded
                                ? null
                                : isDownloading
                                ? () {
                                    _updateState(() {
                                      _cancelRequestedTafsirIds.add(
                                        currentOption.id,
                                      );
                                    });
                                    if (context.mounted) {
                                      setSheetState(() {});
                                    }
                                  }
                                : () => startDownload(currentOption),
                            icon: Icon(
                              isDownloaded
                                  ? Icons.download_done_rounded
                                  : isDownloading
                                  ? Icons.stop_circle_outlined
                                  : Icons.download_rounded,
                            ),
                            label: Text(
                              isDownloaded
                                  ? 'تم التحميل'
                                  : isDownloading
                                  ? 'إيقاف التحميل'
                                  : isPartial
                                  ? 'استكمال التحميل'
                                  : 'تحميل التفسير',
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_quranSource.getSurahNameArabic(surahNumber)} • الآية ${toArabicNumber(verseNumber)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        verseText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          height: 1.95,
                          color: tafsirTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final option = await _pickTafsirOption(currentOption);
                          if (option == null) {
                            return;
                          }
                          _updateState(() {
                            _selectedTafsir = option;
                          });
                          setSheetState(() {
                            currentOption = option;
                            currentFuture = _tafsirService.fetchTafsir(
                              option: option,
                              surahNumber: surahNumber,
                              verseNumber: verseNumber,
                            );
                          });
                        },
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(currentOption.name),
                      ),
                      if (isDownloading && progress != null) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 6),
                        Text(
                          'يتم تنزيل التفسير على الجهاز ${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: currentFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return const Center(
                                child: Text('تعذر تحميل التفسير حاليًا.'),
                              );
                            }

                            return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Text(
                                snapshot.data ?? '',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: 18,
                                      height: 2.0,
                                      color: tafsirTextColor,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<T?> _showCompactListSheet<T>({required List<Widget> children}) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 0.82,
                child: Material(
                  color: isDark ? const Color(0xFF152127) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.62,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'إغلاق',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: isDark
                                      ? const Color(0xFFF2ECDF)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                            children: children,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReciterPicker() async {
    await _refreshReciterDownloadStatus();
    if (!mounted) {
      return;
    }
    final selected = await _showCompactListSheet<ReaderReciter>(
      children: [
        StatefulBuilder(
          builder: (context, setSheetState) {
            _reciterPickerSheetRefresh = () {
              if (context.mounted) {
                setSheetState(() {});
              }
            };
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: readerReciters.map((reciter) {
                final isSelected = reciter == _selectedReciter;
                final isDownloading = _downloadingReciterIds.contains(
                  reciter.id,
                );
                final isDownloaded = _downloadedReciterIds.contains(reciter.id);
                final isPartial = _partialReciterIds.contains(reciter.id);
                final progress = _reciterDownloadProgress[reciter.id];
                return ListTile(
                  title: Text(_reciterArabicName(reciter)),
                  subtitle: Text(
                    isDownloading
                        ? 'جارٍ التنزيل ${(100 * (progress ?? 0)).round()}%'
                        : isDownloaded
                        ? 'تحميل كلي'
                        : isPartial
                        ? 'تحميل جزئي'
                        : reciter.subtitle,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reciter.supportsFullDownload)
                        IconButton(
                          tooltip: isDownloading
                              ? 'إيقاف التحميل'
                              : isDownloaded
                              ? 'حذف التنزيل'
                              : isPartial
                              ? 'استكمال التنزيل'
                              : 'تحميل',
                          onPressed: () async {
                            final future = _toggleReciterDownload(reciter);
                            if (context.mounted) {
                              setSheetState(() {});
                            }
                            await future;
                          },
                          icon: Icon(
                            isDownloading
                                ? Icons.stop_circle_outlined
                                : isDownloaded
                                ? Icons.download_done_rounded
                                : Icons.download_rounded,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.cloud_done_outlined),
                        ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pop(reciter),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
    _reciterPickerSheetRefresh = null;
    if (selected != null) {
      final currentSurah = _playbackSurahNumber ?? _selectedSurahNumber;
      final currentVerse =
          _currentPlaybackVerseNumber() ?? _selectedVerseNumber;
      final shouldResumePlayback =
          (_isPlayingAudio || _isPreparingAudio) &&
          currentSurah != null &&
          currentVerse != null;
      _updateState(() {
        _selectedReciter = selected;
      });
      _readerMoreSheetRefresh?.call();
      unawaited(_persistReaderPreferences());
      unawaited(_refreshReciterDownloadStatus(selected));
      if (shouldResumePlayback) {
        await _playFromVerse(
          surahNumber: currentSurah,
          verseNumber: currentVerse,
        );
      }
    }
  }

  Future<void> _showRepeatPicker() async {
    final selected = await _showCompactListSheet<int>(
      children: [
        for (final count in [0, 2, 3, 4, 5, 6, 7, 8, 9, 10])
          ListTile(
            title: Text(
              count == 0 ? 'بدون تكرار' : 'تكرار ${toArabicNumber(count)} مرة',
            ),
            trailing: Icon(
              count == _selectedRepeatCount
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
            ),
            onTap: () => Navigator.of(context).pop(count),
          ),
      ],
    );
    if (selected != null) {
      await _applyRepeatCount(selected);
    }
  }

  Future<void> _showReaderMoreSheet() async {
    await _showCompactListSheet<void>(
      children: [
        StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            _readerMoreSheetRefresh = () {
              if (context.mounted) {
                setSheetState(() {});
              }
            };
            Future<void> refreshSheet(
              Future<void> Function() action, {
              bool closeSheetFirst = false,
            }) async {
              if (closeSheetFirst && context.mounted) {
                Navigator.of(context).pop();
              }
              await Future<void>.delayed(
                closeSheetFirst
                    ? const Duration(milliseconds: 80)
                    : Duration.zero,
              );
              if (!mounted) return;
              await action();
              if (context.mounted) {
                setSheetState(() {});
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('أنواع المصاحف'),
                  subtitle: Text(_appearance.label),
                  onTap: () => refreshSheet(
                    _showAppearancePicker,
                    closeSheetFirst: true,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.record_voice_over_rounded),
                  title: const Text('القارئ'),
                  subtitle: Text(_reciterArabicName(_selectedReciter)),
                  onTap: () => refreshSheet(_showReciterPicker),
                ),
                ListTile(
                  leading: const Icon(Icons.repeat_rounded),
                  title: const Text('تكرار الآية'),
                  subtitle: Text(_repeatCountLabel),
                  onTap: () => refreshSheet(_showRepeatPicker),
                ),

                if (!_isPagedMushafMode) ...[const SizedBox(height: 2)],
                if (!_isPagedMushafMode) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'حجم الخط',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ControlGroup(
                      backgroundColor: isDark
                          ? const Color(0xFF18242A)
                          : const Color(0xFFF4EAD3),
                      children: [
                        _TinySquareButton(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            _decreaseFontSize();
                            if (context.mounted) {
                              setSheetState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        _CompactValue(
                          icon: Icons.format_size_rounded,
                          label: 'حجم ${toArabicNumber(_fontSize.round())}',
                          minWidth: 82,
                        ),
                        const SizedBox(width: 6),
                        _TinySquareButton(
                          icon: Icons.add_rounded,
                          onTap: () {
                            _increaseFontSize();
                            if (context.mounted) {
                              setSheetState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
    _readerMoreSheetRefresh = null;
  }

  Future<void> _openBookmarksSheet() async {
    final currentSurah = _selectedSurahNumber;
    final currentVerse = _selectedVerseNumber;
    final currentBookmarked =
        currentSurah != null &&
        currentVerse != null &&
        widget.store.isVerseBookmarked(
          surahNumber: currentSurah,
          verseNumber: currentVerse,
        );

    await _showCompactListSheet<void>(
      children: [
        ListTile(
          leading: Icon(
            currentBookmarked
                ? Icons.bookmark_remove_rounded
                : Icons.bookmark_add_rounded,
            color: const Color(0xFF143A2A),
          ),
          title: Text(
            currentBookmarked ? 'حذف العلامة من هنا' : 'إضافة علامة هنا',
          ),
          subtitle: currentSurah != null && currentVerse != null
              ? Text(
                  '${_quranSource.getSurahNameArabic(currentSurah)} • جزء ${toArabicNumber(_currentJuzNumberFromPage(_quranSource.getPageNumber(currentSurah, currentVerse)))} • آية ${toArabicNumber(currentVerse)}',
                )
              : const Text('اختر آية أولًا'),
          onTap: currentSurah == null || currentVerse == null
              ? null
              : () async {
                  Navigator.of(context).pop();
                  await _toggleCurrentVerseBookmark();
                },
        ),
        const Divider(height: 1),
        if (widget.store.readerBookmarks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Text(
              'لا توجد علامات محفوظة بعد',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...widget.store.readerBookmarks.map((bookmark) {
            final bookmarkColor = bookmark.colorValue == null
                ? const Color(0xFF9E8244)
                : Color(bookmark.colorValue!);
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: bookmarkColor,
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              title: Text(
                '${bookmark.surahName} • جزء ${toArabicNumber(bookmark.juzNumber)} • آية ${toArabicNumber(bookmark.verseNumber)}',
              ),
              subtitle: Text(
                (bookmark.note?.isNotEmpty ?? false)
                    ? bookmark.note!
                    : bookmark.previewText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'حذف',
                onPressed: () async {
                  await widget.store.removeReaderBookmark(bookmark.id);
                  if (mounted && context.mounted) {
                    Navigator.of(context).pop();
                    _openBookmarksSheet();
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _jumpToReaderBookmark(bookmark);
              },
            );
          }),
      ],
    );
  }

  Future<void> _showAppearancePicker() async {
    final isContinuous =
        _appearance != _ReaderAppearance.medinaPages &&
        _appearance != _ReaderAppearance.shamarlyPages;
    final selected = await _showCompactListSheet<_ReaderAppearance>(
      children: [
        ListTile(
          title: const Text('مصحف القراءة المستمرة'),
          subtitle: Text(isContinuous ? _appearance.label : 'اختر النمط'),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: () async {
            Navigator.of(context).pop();
            final picked = await _showContinuousMushafPicker();
            if (picked != null) {
              await _applyAppearanceSelection(picked);
            }
          },
        ),
        ListTile(
          title: const Text('مصحف المدينة'),
          subtitle: const Text('صفحات المدينة الورقية'),
          trailing: Icon(
            _appearance == _ReaderAppearance.medinaPages
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
          ),
          onTap: () => Navigator.of(context).pop(_ReaderAppearance.medinaPages),
        ),
        ListTile(
          title: const Text('مصحف الشمرلي'),
          subtitle: const Text('صور صفحات الشمرلي'),
          trailing: Icon(
            _appearance == _ReaderAppearance.shamarlyPages
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
          ),
          onTap: () =>
              Navigator.of(context).pop(_ReaderAppearance.shamarlyPages),
        ),
      ],
    );
    if (selected != null) {
      await _applyAppearanceSelection(selected);
    }
  }

  Future<_ReaderAppearance?> _showContinuousMushafPicker() {
    const options = [
      _ReaderAppearance.golden,
      _ReaderAppearance.classic,
      _ReaderAppearance.tajweed,
      _ReaderAppearance.night,
      _ReaderAppearance.nightTajweed,
    ];
    return _showCompactListSheet<_ReaderAppearance>(
      children: [
        for (final appearance in options)
          ListTile(
            title: Text(appearance.label),
            subtitle: Text(appearance.description),
            trailing: Icon(
              appearance == _appearance
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
            ),
            onTap: () => Navigator.of(context).pop(appearance),
          ),
      ],
    );
  }

  Future<void> _applyAppearanceSelection(_ReaderAppearance selected) async {
    final wasPagedMushaf = _isPagedMushafMode;
    if (!wasPagedMushaf) {
      _lastContinuousAppearance = _appearance;
      _lastContinuousFontSize = _fontSize;
    }
    var targetSurahNumber = _selectedSurahNumber;
    var targetVerseNumber = _selectedVerseNumber;
    if (wasPagedMushaf) {
      final selectedAyahs = QuranCtrl.instance.selectedAyahsByUnequeNumber;
      if (selectedAyahs.isNotEmpty) {
        final ayah = QuranCtrl.instance.getAyahByUq(selectedAyahs.last);
        targetSurahNumber = ayah.surahNumber;
        targetVerseNumber = ayah.ayahNumber;
      } else {
        final currentPage = QuranCtrl.instance.state.currentPageNumber.value;
        final pageData = _quranSource.getPageData(currentPage);
        if (pageData.isNotEmpty) {
          final firstAyahOnPage = pageData.first;
          targetSurahNumber =
              targetSurahNumber ?? firstAyahOnPage['surah'] as int;
          targetVerseNumber =
              targetVerseNumber ?? firstAyahOnPage['start'] as int;
        }
      }
    }
    final fallbackPage = _quranSource.getPageNumber(
      targetSurahNumber ?? widget.surahNumber,
      targetVerseNumber ?? widget.initialVerse,
    );
    final targetPage = selected == _ReaderAppearance.shamarlyPages
        ? _resolveShamarlyPage(
            targetSurahNumber ?? widget.surahNumber,
            targetVerseNumber ?? widget.initialVerse,
          )
        : fallbackPage;
    final isPagedAppearance =
        selected == _ReaderAppearance.medinaPages ||
        selected == _ReaderAppearance.shamarlyPages;
    if (!isPagedAppearance) {
      _lastContinuousAppearance = selected;
      _lastContinuousFontSize = _fontSize;
    }
    if (selected == _ReaderAppearance.medinaPages) {
      _stopAutoScroll();
      _primePagedMushafTargetPage(targetPage);
      unawaited(_refreshMedinaFontsAvailability());
    } else if (selected == _ReaderAppearance.shamarlyPages) {
      _stopAutoScroll();
      _shamarlyCurrentPage = targetPage;
      unawaited(_ensureShamarlyPageMapReady());
      unawaited(_refreshShamarlyPagesAvailability());
    }
    _updateState(() {
      _selectedSurahNumber = targetSurahNumber ?? widget.surahNumber;
      _selectedVerseNumber = targetVerseNumber ?? widget.initialVerse;
      _pagedStartPage = targetPage;
      _standardInitialPage = targetPage;
      _appearance = selected;
      _isSwitchingToPagedMushaf = selected == _ReaderAppearance.medinaPages;
      _showBottomBar = !isPagedAppearance;
      _isInitialStandardPositioning = !isPagedAppearance;
    });
    unawaited(_persistCurrentPosition());
    unawaited(_persistReaderPreferences());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_isMedinaPagesMode) {
        _applyPagedMushafScaleNow();
        _jumpPagedToSelectedVerse();
        Future<void>.delayed(const Duration(milliseconds: 700), () {
          if (!mounted || !_isPagedMushafMode) {
            return;
          }
          _finishPagedMushafSwitching();
        });
      } else if (_isShamarlyPagesMode) {
        _finishPagedMushafSwitching();
      } else {
        _startInitialStandardPositioning();
      }
    });
  }

  Future<TafsirOption?> _pickTafsirOption(TafsirOption currentOption) async {
    await _refreshDownloadedTafsirIds();
    if (!mounted) return null;
    return showModalBottomSheet<TafsirOption>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ColoredBox(
                color: isDark ? const Color(0xFF152127) : Colors.white,
                child: ListView(
                  shrinkWrap: true,
                  children: TafsirOption.values.map((option) {
                    final isSelected = option.id == currentOption.id;
                    final isDownloaded = _downloadedTafsirIds.contains(
                      option.id,
                    );
                    final isDownloading = _downloadingTafsirIds.contains(
                      option.id,
                    );
                    final isPartial = _partialTafsirIds.contains(option.id);
                    final progress = _tafsirDownloadProgress[option.id];
                    return ListTile(
                      title: Text(option.name),
                      subtitle: Text(
                        isDownloading && progress != null
                            ? '${option.author} • ${(progress * 100).round()}%'
                            : isDownloaded
                            ? '${option.author} • تم التحميل'
                            : isPartial
                            ? '${option.author} • تنزيل جزئي'
                            : option.author,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: isDownloaded ? 'تم التحميل' : 'تحميل',
                            onPressed: isDownloaded || isDownloading
                                ? null
                                : () async {
                                    _updateState(() {
                                      _cancelRequestedTafsirIds.remove(
                                        option.id,
                                      );
                                      _downloadingTafsirIds.add(option.id);
                                      _tafsirDownloadProgress[option.id] = 0;
                                    });
                                    if (context.mounted) {
                                      setSheetState(() {});
                                    }
                                    try {
                                      await _tafsirService.downloadTafsir(
                                        option,
                                        onProgress: (completed, total) {
                                          if (!mounted) {
                                            return;
                                          }
                                          _updateState(() {
                                            _tafsirDownloadProgress[option.id] =
                                                total == 0
                                                ? 0
                                                : completed / total;
                                          });
                                          if (context.mounted) {
                                            setSheetState(() {});
                                          }
                                        },
                                        shouldCancel: () =>
                                            _cancelRequestedTafsirIds.contains(
                                              option.id,
                                            ),
                                      );
                                      await _refreshDownloadedTafsirIds();
                                    } finally {
                                      if (mounted) {
                                        _updateState(() {
                                          _downloadingTafsirIds.remove(
                                            option.id,
                                          );
                                          _cancelRequestedTafsirIds.remove(
                                            option.id,
                                          );
                                        });
                                      }
                                      if (context.mounted) {
                                        setSheetState(() {});
                                      }
                                    }
                                  },
                            icon: Icon(
                              isDownloaded
                                  ? Icons.download_done_rounded
                                  : isDownloading
                                  ? Icons.stop_circle_outlined
                                  : Icons.download_rounded,
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).pop(option),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TajweedLegendItem {
  const _TajweedLegendItem({required this.color, required this.label});

  final Color color;
  final String label;
}
