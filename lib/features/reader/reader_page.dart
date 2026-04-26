import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_library/quran_library.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/utils/arabic_numbers.dart';
import '../home/quran_section_shell.dart';
import '../shared/khatm_quran_doa_page.dart';
import '../../data/reader_reciters.dart';
import '../../models/last_read_position.dart';
import '../../models/reader_reciter.dart';
import '../../models/reader_bookmark.dart';
import '../../models/tafsir_option.dart';
import '../../services/alfurqan_quran_source.dart';
import '../../services/current_quran_text_source.dart';
import '../../services/medina_fonts_download_config.dart';
import '../../services/medina_fonts_download_service.dart';
import '../../services/mp3quran_recitation_service.dart';
import '../../services/juz_names_service.dart';
import '../../services/quran_store.dart';
import '../../services/recitation_cache_service.dart';
import '../../services/shamarly_pages_download_config.dart';
import '../../services/shamarly_pages_download_service.dart';
import '../../services/tafsir_service.dart';
import 'shamarly_page_image_stub.dart'
    if (dart.library.io) 'shamarly_page_image_io.dart';

part 'reader_state_persistence.dart';
part 'reader_navigation.dart';
part 'reader_audio.dart';
part 'reader_dialogs.dart';
part 'reader_autoscroll.dart';
part 'reader_widgets.dart';
part 'reader_controls.dart';
part 'reader_search.dart';

const _readerQuranSource = currentQuranTextSource;
const _tajweedQuranSource = AlfurqanQuranSource();

Map<String, Object?> _parseShamarlyPageMapPayload(String rawJson) {
  final decoded = json.decode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    return <String, Object?>{
      'map': <String, int>{},
      'pageToSurah': <int, int>{},
      'pageFirstAyah': <int, List<int>>{},
    };
  }
  final mapNode = decoded['map'];
  if (mapNode is! Map) {
    return <String, Object?>{
      'map': <String, int>{},
      'pageToSurah': <int, int>{},
      'pageFirstAyah': <int, List<int>>{},
    };
  }

  final parsed = <String, int>{};
  final pageToSurah = <int, int>{};
  final pageFirstAyah = <int, List<int>>{};
  mapNode.forEach((key, value) {
    if (key is! String) {
      return;
    }
    final page = switch (value) {
      int v => v,
      num v => v.toInt(),
      _ => null,
    };
    if (page == null || page < 1) {
      return;
    }
    parsed[key] = page;
    final parts = key.split(':');
    if (parts.length != 2) {
      return;
    }
    final surah = int.tryParse(parts[0]);
    final verse = int.tryParse(parts[1]);
    if (surah == null) {
      return;
    }
    final existingSurah = pageToSurah[page];
    if (existingSurah == null || surah > existingSurah) {
      pageToSurah[page] = surah;
    }
    if (verse != null && verse >= 1) {
      final existing = pageFirstAyah[page];
      if (existing == null ||
          surah < existing[0] ||
          (surah == existing[0] && verse < existing[1])) {
        pageFirstAyah[page] = <int>[surah, verse];
      }
    }
  });

  return <String, Object?>{
    'map': parsed,
    'pageToSurah': pageToSurah,
    'pageFirstAyah': pageFirstAyah,
  };
}

enum _ReaderAppearance {
  classic,
  golden,
  tajweed,
  night,
  nightTajweed,
  medinaPages,
  shamarlyPages,
}

enum _AudioEngine { local, library }

extension on _ReaderAppearance {
  String get label => switch (this) {
    _ReaderAppearance.classic => '\u0643\u0644\u0627\u0633\u064a\u0643\u064a',
    _ReaderAppearance.golden => '\u0630\u0647\u0628\u064a',
    _ReaderAppearance.tajweed => '\u062a\u062c\u0648\u064a\u062f',
    _ReaderAppearance.night => '\u0644\u064a\u0644\u064a',
    _ReaderAppearance.nightTajweed =>
      '\u0644\u064a\u0644\u064a \u0628\u0627\u0644\u062a\u062c\u0648\u064a\u062f',
    _ReaderAppearance.medinaPages =>
      '\u0645\u0635\u062d\u0641 \u0627\u0644\u0645\u062f\u064a\u0646\u0629',
    _ReaderAppearance.shamarlyPages =>
      '\u0645\u0635\u062d\u0641 \u0627\u0644\u0634\u0645\u0631\u0644\u064a',
  };

  String get description => switch (this) {
    _ReaderAppearance.classic =>
      '\u0645\u0635\u062d\u0641 \u0647\u0627\u062f\u0626 \u0628\u0623\u0644\u0648\u0627\u0646 \u062a\u0642\u0644\u064a\u062f\u064a\u0629',
    _ReaderAppearance.golden =>
      '\u062f\u0631\u062c\u0627\u062a \u0630\u0647\u0628\u064a\u0629 \u062f\u0627\u0641\u0626\u0629',
    _ReaderAppearance.tajweed =>
      '\u0623\u0644\u0648\u0627\u0646 \u0623\u0648\u0636\u062d \u0645\u0639 \u062a\u0644\u0648\u064a\u0646 \u0623\u062d\u0643\u0627\u0645 \u0627\u0644\u062a\u062c\u0648\u064a\u062f',
    _ReaderAppearance.night =>
      '\u062e\u0644\u0641\u064a\u0629 \u0644\u064a\u0644\u064a\u0629 \u0647\u0627\u062f\u0626\u0629 \u0644\u0644\u0642\u0631\u0627\u0621\u0629',
    _ReaderAppearance.nightTajweed =>
      '\u062e\u0644\u0641\u064a\u0629 \u0644\u064a\u0644\u064a\u0629 \u0645\u0639 \u062a\u0644\u0648\u064a\u0646 \u0623\u062d\u0643\u0627\u0645 \u0627\u0644\u062a\u062c\u0648\u064a\u062f',
    _ReaderAppearance.medinaPages =>
      '\u0645\u0635\u062d\u0641 \u0627\u0644\u0645\u062f\u064a\u0646\u0629 \u0628\u0635\u0641\u062d\u0627\u062a\u0647 \u0627\u0644\u0648\u0631\u0642\u064a\u0629',
    _ReaderAppearance.shamarlyPages =>
      '\u0645\u0635\u062d\u0641 \u0627\u0644\u0634\u0645\u0631\u0644\u064a \u0628\u0635\u0648\u0631 \u0635\u0641\u062d\u0627\u062a\u0647',
  };

  Color get scaffoldColor => switch (this) {
    _ReaderAppearance.classic => const Color(0xFFF7F3E9),
    _ReaderAppearance.golden => const Color(0xFFFBF4DE),
    _ReaderAppearance.tajweed => const Color(0xFFF1F7F6),
    _ReaderAppearance.night => const Color(0xFF0E171B),
    _ReaderAppearance.nightTajweed => const Color(0xFF091217),
    _ReaderAppearance.medinaPages => const Color(0xFFE8DFC8),
    _ReaderAppearance.shamarlyPages => const Color(0xFFE8DFC8),
  };

  Color get appBarColor => switch (this) {
    _ReaderAppearance.classic => const Color(0xFF143A2A),
    _ReaderAppearance.golden => const Color(0xFF8C6A1F),
    _ReaderAppearance.tajweed => const Color(0xFF0F5C63),
    _ReaderAppearance.night => const Color(0xFF16262D),
    _ReaderAppearance.nightTajweed => const Color(0xFF10232A),
    _ReaderAppearance.medinaPages => const Color(0xFF6D5430),
    _ReaderAppearance.shamarlyPages => const Color(0xFF6D5430),
  };

  Color get pageColor => switch (this) {
    _ReaderAppearance.classic => Colors.white,
    _ReaderAppearance.golden => const Color(0xFFFFF8EA),
    _ReaderAppearance.tajweed => const Color(0xFFF8FFFE),
    _ReaderAppearance.night => const Color(0xFF132128),
    _ReaderAppearance.nightTajweed => const Color(0xFF0E1A20),
    _ReaderAppearance.medinaPages => const Color(0xFFF8F1DE),
    _ReaderAppearance.shamarlyPages => const Color(0xFFF8F1DE),
  };

  Color get textColor => switch (this) {
    _ReaderAppearance.classic => const Color(0xFF1E241F),
    _ReaderAppearance.golden => const Color(0xFF5A4713),
    _ReaderAppearance.tajweed => const Color(0xFF153A3F),
    _ReaderAppearance.night => const Color(0xFFE6E2D3),
    _ReaderAppearance.nightTajweed => const Color(0xFFEAE7DB),
    _ReaderAppearance.medinaPages => const Color(0xFF4A3720),
    _ReaderAppearance.shamarlyPages => const Color(0xFF4A3720),
  };

  Color get surahBadgeColor => switch (this) {
    _ReaderAppearance.classic => const Color(0xFF143A2A),
    _ReaderAppearance.golden => const Color(0xFF8A6720),
    _ReaderAppearance.tajweed => const Color(0xFF0F6A73),
    _ReaderAppearance.night => const Color(0xFF21414C),
    _ReaderAppearance.nightTajweed => const Color(0xFF1A3943),
    _ReaderAppearance.medinaPages => const Color(0xFF7A5B2A),
    _ReaderAppearance.shamarlyPages => const Color(0xFF7A5B2A),
  };

  Color get dividerColor => switch (this) {
    _ReaderAppearance.classic => const Color(0xFFB29D67),
    _ReaderAppearance.golden => const Color(0xFFC89D2C),
    _ReaderAppearance.tajweed => const Color(0xFF52A3A9),
    _ReaderAppearance.night => const Color(0xFF4F7277),
    _ReaderAppearance.nightTajweed => const Color(0xFF467B84),
    _ReaderAppearance.medinaPages => const Color(0xFFB49355),
    _ReaderAppearance.shamarlyPages => const Color(0xFFB49355),
  };

  Color get selectedVerseColor => switch (this) {
    _ReaderAppearance.classic => const Color(0xFF9DD996),
    _ReaderAppearance.golden => const Color(0xFFF7E0A3),
    _ReaderAppearance.tajweed => const ui.Color.fromARGB(255, 157, 215, 219),
    _ReaderAppearance.night => const Color(0x332CA2B0),
    _ReaderAppearance.nightTajweed => const Color(0x3333AFC0),
    _ReaderAppearance.medinaPages => const Color(0xFFEBDCB6),
    _ReaderAppearance.shamarlyPages => const Color(0xFFEBDCB6),
  };

  Color get savedVerseColor => switch (this) {
    _ReaderAppearance.classic => const Color(0xFFDDEEDF),
    _ReaderAppearance.golden => const Color(0xFFEDE3BC),
    _ReaderAppearance.tajweed => const Color(0xFFD7F5E8),
    _ReaderAppearance.night => const Color(0x3338B48B),
    _ReaderAppearance.nightTajweed => const Color(0x3343C697),
    _ReaderAppearance.medinaPages => const Color(0xFFE8E0C4),
    _ReaderAppearance.shamarlyPages => const Color(0xFFE8E0C4),
  };

  Color get initialVerseColor => switch (this) {
    _ReaderAppearance.classic => const Color(0xFFF4E8C8),
    _ReaderAppearance.golden => const Color(0xFFF9EBC2),
    _ReaderAppearance.tajweed => const Color(0xFFE1F1FF),
    _ReaderAppearance.night => const Color(0x334B6870),
    _ReaderAppearance.nightTajweed => const Color(0x3349606B),
    _ReaderAppearance.medinaPages => const Color(0xFFF4E8C8),
    _ReaderAppearance.shamarlyPages => const Color(0xFFF4E8C8),
  };
}

extension _ReaderAppearanceQuarterMarkerColors on _ReaderAppearance {
  Color get quarterMarkerTextColor => switch (this) {
    _ReaderAppearance.night => const Color(0xFFF3E6A8),
    _ReaderAppearance.nightTajweed => const Color(0xFFF0E0A0),
    _ => textColor,
  };

  Color get quarterMarkerFillColor => switch (this) {
    _ReaderAppearance.night => const Color(0xFF2B3D2E),
    _ReaderAppearance.nightTajweed => const Color(0xFF243A34),
    _ => initialVerseColor,
  };

  Color get quarterMarkerBorderColor => switch (this) {
    _ReaderAppearance.night => const Color(0xFFBDA35A),
    _ReaderAppearance.nightTajweed => const Color(0xFFC1A861),
    _ => dividerColor,
  };
}

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.store,
    required this.surahNumber,
    this.initialVerse = 1,
    this.highlightQuery,
    this.initialVerseAlignment = 0.18,
  });

  final QuranStore store;
  final int surahNumber;
  final int initialVerse;
  final String? highlightQuery;
  final double initialVerseAlignment;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _quranSource = _readerQuranSource;
  final TafsirService _tafsirService = TafsirService();
  final RecitationCacheService _recitationCacheService =
      const RecitationCacheService();
  final MedinaFontsDownloadService _medinaFontsDownloadService =
      const MedinaFontsDownloadService();
  final ShamarlyPagesDownloadService _shamarlyPagesDownloadService =
      const ShamarlyPagesDownloadService();
  final ItemScrollController _standardItemScrollController =
      ItemScrollController();
  final ItemPositionsListener _standardItemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetController _standardScrollOffsetController =
      ScrollOffsetController();
  final ScrollController _bottomBarScrollController = ScrollController();
  StreamSubscription<PlayerState>? _libraryAudioStateSubscription;
  StreamSubscription<int>? _libraryAyahSubscription;
  StreamSubscription<List<int>>? _librarySelectionSubscription;
  StreamSubscription<int>? _libraryPageSubscription;

  final Mp3QuranRecitationService _mp3QuranRecitationService =
      Mp3QuranRecitationService();

  ReaderReciter _selectedReciter = defaultReaderReciter;
  TafsirOption _selectedTafsir = TafsirOption.muyassar;
  int _selectedRepeatCount = 1;
  double _fontSize = 24;
  double _readingSpeed = 1.0;
  double _lastContinuousFontSize = 28;
  //نوع المصحف الى البرنامج حيفتح عليه
  _ReaderAppearance _appearance = _ReaderAppearance.classic;

  Timer? _autoScrollTimer;
  Timer? _controlBarHideTimer;
  Timer? _visibleSurahSyncTimer;
  DateTime? _ignoreAutoScrollTapUntil;
  double _bottomBarOffset = 0;
  bool _isAutoScrolling = false;
  int? _lockedAutoScrollTargetMinutes;

  bool _isAutoScrollPaused = false;
  bool _showControlBarWhileAutoScroll = false;
  bool _showBottomBar = false;
  bool _isPlayingAudio = false;
  bool _isPreparingAudio = false;
  int _audioPlayRequestId = 0;
  bool _suspendPlaylistIndexSelectionSync = false;
  bool _isAdvancingToNextSurah = false;
  bool _isHandlingLocalCompletion = false;
  bool _pendingLocalCompletion = false;
  Timer? _audioBufferingHintTimer;
  Timer? _audioPreparingTimeoutTimer;
  bool _audioBufferingHintShown = false;
  bool _isInitialStandardPositioning = false;
  bool _isSwitchingToPagedMushaf = false;
  bool _isCheckingMedinaFonts =
      MedinaFontsDownloadConfig.enableOnDemandDownload;
  bool _isMedinaFontsReady = !MedinaFontsDownloadConfig.enableOnDemandDownload;
  bool _isDownloadingMedinaFonts = false;
  bool _cancelMedinaFontsDownload = false;
  double _medinaFontsDownloadProgress = 0;
  String? _medinaFontsDownloadStatus;
  String? _medinaFontsDownloadError;
  int _lastMedinaProgressLog = -1;
  bool _isCheckingShamarlyPages =
      ShamarlyPagesDownloadConfig.enableOnDemandDownload;
  bool _isShamarlyPagesReady =
      !ShamarlyPagesDownloadConfig.enableOnDemandDownload;
  bool _isDownloadingShamarlyPages = false;
  bool _cancelShamarlyPagesDownload = false;
  _ReaderAppearance _lastContinuousAppearance = _ReaderAppearance.classic;
  double _shamarlyPagesDownloadProgress = 0;
  String? _shamarlyPagesDownloadStatus;
  String? _shamarlyPagesDownloadError;
  int _shamarlyCurrentPage = 1;
  String? _shamarlyPagesDirectoryPath;
  Map<String, int>? _shamarlyPageMap;
  Map<int, int>? _shamarlyPageToSurahMap;
  Map<int, List<int>>? _shamarlyPageFirstAyahMap;
  List<int>? _shamarlyJuzStartPages;
  Map<int, int>? _medinaPageToSurahMap;
  List<int>? _medinaJuzStartPages;
  bool _isLoadingShamarlyPageMap = false;
  final Map<int, Offset> _activePointerPositions = <int, Offset>{};
  double? _manualPinchStartDistance;
  double? _manualPinchStartFontSize;
  double? _manualPinchStartPagedFactor;
  bool _isPinchPriorityActive = false;
  String? _audioError;
  int? _selectedSurahNumber;
  int? _selectedVerseNumber;
  int? _visibleSurahNumber;
  int? _visiblePagedPageNumber;
  int? _visibleStandardPageNumber;
  int? _playbackSurahNumber;
  int? _playbackStartVerse;
  int? _playbackResumeVerseAfterChunk;
  Uri? _mediaArtworkUri;
  double _shamarlyZoomScale = 1.0;
  List<int> _playlistVerseNumbers = const [];
  final Map<String, GlobalKey> _verseKeys = {};
  final Map<String, GlobalKey> _quarterMarkerAnchorKeys = {};
  final Map<int, GlobalKey> _pageKeys = {};
  final Set<int> _downloadedTafsirIds = {};
  final Set<int> _downloadingTafsirIds = {};
  final Set<int> _cancelRequestedTafsirIds = {};
  final Set<int> _partialTafsirIds = {};
  final Map<int, double> _tafsirDownloadProgress = {};
  final Set<String> _downloadedReciterIds = {};
  final Set<String> _downloadingReciterIds = {};
  final Set<String> _partialReciterIds = {};
  final Set<String> _cancelRequestedReciterIds = {};
  final Map<String, double> _reciterDownloadProgress = {};
  List<Mp3QuranAyahTiming> _currentMp3QuranTimings = const [];
  VoidCallback? _reciterPickerSheetRefresh;
  VoidCallback? _readerMoreSheetRefresh;
  _AudioEngine? _activeAudioEngine;
  int? _pagedStartPage;
  int? _standardInitialPage;

  double _snapFontSize(double size) {
    final primaryRange =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? 1.8 : 1.0;
    if ((size - 26.0).abs() <= primaryRange) {
      return 26.0;
    }
    if ((size - 23.0).abs() <= 0.8) {
      return 23.0;
    }
    return size;
  }

  // Make pinch feel easier: small finger movement gives a slightly bigger
  // visual change without being jumpy.
  double _pinchScaleWithSensitivity(double rawScale) {
    final sensitivity =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? 0.45 : 1.10;
    return 1 + ((rawScale - 1) * sensitivity);
  }

  void _setPinchPriorityActive(bool value) {
    if (_isPinchPriorityActive == value) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isPinchPriorityActive = value;
    });
  }

  double? _currentTwoPointersDistance() {
    if (_activePointerPositions.length < 2) {
      return null;
    }
    final points = _activePointerPositions.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _activateManualPinchIfReady() {
    if (_isShamarlyPagesMode) {
      return;
    }
    if (_activePointerPositions.length < 2) {
      return;
    }
    final distance = _currentTwoPointersDistance();
    if (distance == null || distance <= 0) {
      return;
    }
    _manualPinchStartDistance ??= distance;
    _manualPinchStartFontSize ??= _fontSize;
    if (_isMedinaPagesMode) {
      try {
        _manualPinchStartPagedFactor ??=
            QuranCtrl.instance.state.scaleFactor.value;
      } catch (_) {
        _manualPinchStartPagedFactor ??= 1.0;
      }
    }
    _setPinchPriorityActive(true);
  }

  void _handleReaderPointerDown(PointerDownEvent event) {
    _activePointerPositions[event.pointer] = event.position;
    if (_activePointerPositions.length >= 2) {
      _activateManualPinchIfReady();
      return;
    }
    if (_isAutoScrollModeActive) {
      final now = DateTime.now();
      if (_ignoreAutoScrollTapUntil != null &&
          now.isBefore(_ignoreAutoScrollTapUntil!)) {
        return;
      }
      _toggleAutoScrollPauseResume();
    }
  }

  void _handleReaderPointerMove(PointerMoveEvent event) {
    if (!_activePointerPositions.containsKey(event.pointer)) {
      return;
    }
    _activePointerPositions[event.pointer] = event.position;
    if (_activePointerPositions.length < 2) {
      return;
    }
    if (_isShamarlyPagesMode) {
      return;
    }
    _activateManualPinchIfReady();
    final startDistance = _manualPinchStartDistance;
    if (startDistance == null || startDistance <= 0) {
      return;
    }
    final currentDistance = _currentTwoPointersDistance();
    if (currentDistance == null || currentDistance <= 0) {
      return;
    }
    final deadZone =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? 18.0 : 8.0;
    if ((currentDistance - startDistance).abs() < deadZone) {
      return;
    }
    final adjustedScale = _pinchScaleWithSensitivity(
      currentDistance / startDistance,
    );

    if (_isMedinaPagesMode) {
      final startFactor = _manualPinchStartPagedFactor;
      if (startFactor == null) {
        return;
      }
      final nextFactor = (startFactor * adjustedScale).clamp(1.0, 2.0);
      try {
        final current = QuranCtrl.instance.state.scaleFactor.value;
        if ((nextFactor - current).abs() < 0.008) {
          return;
        }
        QuranCtrl.instance.state.baseScaleFactor.value = nextFactor;
        QuranCtrl.instance.state.scaleFactor.value = nextFactor;
        QuranCtrl.instance.update(['_pageViewBuild']);
        if (!mounted) {
          return;
        }
        setState(() {
          _fontSize = ((nextFactor - 1.0) * 14.0 + 28.0).clamp(14.0, 42.0);
          _lastContinuousFontSize = _fontSize;
        });
      } catch (_) {}
      return;
    }

    final startSize = _manualPinchStartFontSize;
    if (startSize == null) {
      return;
    }
    final nextSize = (startSize * adjustedScale).clamp(14.0, 42.0);
    if ((nextSize - _fontSize).abs() < 0.06) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _fontSize = _snapFontSize(nextSize);
      _lastContinuousFontSize = _fontSize;
    });
  }

  void _handleReaderPointerUpOrCancel(PointerEvent event) {
    _activePointerPositions.remove(event.pointer);
    if (_activePointerPositions.length < 2) {
      final wasPinching = _isPinchPriorityActive;
      _manualPinchStartDistance = null;
      _manualPinchStartFontSize = null;
      _manualPinchStartPagedFactor = null;
      _setPinchPriorityActive(false);
      if (wasPinching) {
        unawaited(_persistReaderPreferences());
      }
    }
  }

  int get _startPage =>
      _quranSource.getPageNumber(widget.surahNumber, widget.initialVerse);

  bool get _isPagedMushafMode =>
      _appearance == _ReaderAppearance.medinaPages ||
      _appearance == _ReaderAppearance.shamarlyPages;
  bool get _isMedinaPagesMode => _appearance == _ReaderAppearance.medinaPages;
  bool get _isShamarlyPagesMode =>
      _appearance == _ReaderAppearance.shamarlyPages;
  bool get _useMedinaOnDemandDownload =>
      MedinaFontsDownloadConfig.enableOnDemandDownload;

  bool get _shouldShowBottomBar =>
      _isAutoScrollPaused ||
      (_showBottomBar &&
          !((_isAutoScrolling || _isAutoScrollPaused) &&
              !_showControlBarWhileAutoScroll));

  bool get _isAutoScrollModeActive => _isAutoScrolling || _isAutoScrollPaused;

  bool get _shouldShowAppBar => !_isPagedMushafMode || _showBottomBar;

  void _logMedina(String message) {
    if (kDebugMode) {
      debugPrint('[Medina] $message');
    }
  }

  void _showPagedControlBar() {
    _showBottomBarTemporarily();
  }

  Future<void> _exitPagedMushafGate() async {
    if (!_isPagedMushafMode) {
      return;
    }
    final fallback = _lastContinuousAppearance;
    _updateState(() {
      _appearance = fallback;
      _fontSize = _lastContinuousFontSize;
      _showBottomBar = true;
      _isInitialStandardPositioning = true;
    });
    unawaited(_persistReaderPreferences());
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) {
      return;
    }
    _startInitialStandardPositioning();
  }

  void _finishPagedMushafSwitching() {
    if (!_isSwitchingToPagedMushaf || !mounted) {
      return;
    }
    _updateState(() {
      _isSwitchingToPagedMushaf = false;
    });
  }

  void _primePagedMushafTargetPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > currentQuranTotalPagesCount) {
      return;
    }
    try {
      QuranCtrl.instance.state.currentPageNumber.value = pageNumber;
      QuranCtrl.instance.saveLastPage(pageNumber);
      QuranCtrl.instance.jumpToPage(pageNumber - 1);
    } catch (_) {}
  }

  void _applyPagedMushafScaleNow() {
    if (!_isMedinaPagesMode) {
      return;
    }
    _syncPagedMushafScaleFromFontSize();
  }

  Future<void> _openQuranChooser(int index) async {
    final currentPage = _isMedinaPagesMode
        ? QuranCtrl.instance.state.currentPageNumber.value
        : (_isShamarlyPagesMode
              ? _shamarlyCurrentPage.clamp(
                  1,
                  ShamarlyPagesDownloadConfig.totalPages,
                )
              : (_currentVisibleStandardPage() ??
                    _quranSource.getPageNumber(
                      _selectedSurahNumber ?? widget.surahNumber,
                      _selectedVerseNumber ?? widget.initialVerse,
                    )));
    final displayedSurahNumber = _isMedinaPagesMode
        ? ((_isPlayingAudio || _isPreparingAudio)
              ? (_selectedSurahNumber ??
                    _visibleSurahNumber ??
                    widget.surahNumber)
              : (_visibleSurahNumber ??
                    _selectedSurahNumber ??
                    widget.surahNumber))
        : (_isShamarlyPagesMode
              ? _currentShamarlySurahNumberFromPage(currentPage)
              : (_visibleSurahNumber ??
                    _selectedSurahNumber ??
                    widget.surahNumber));
    final currentJuzNumber = _isShamarlyPagesMode
        ? _currentShamarlyJuzNumberFromPage(currentPage)
        : _currentJuzNumberFromPage(currentPage);

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: QuranSectionShell(
            store: widget.store,
            initialIndex: index,
            initialSurahNumber: displayedSurahNumber,
            initialJuzNumber: currentJuzNumber,
          ),
        ),
      ),
    );
  }

  GlobalKey _verseKeyFor(int surahNumber, int verseNumber, [int? pageNumber]) {
    final key = '${pageNumber ?? 0}:$surahNumber:$verseNumber';
    return _verseKeys.putIfAbsent(key, GlobalKey.new);
  }

  GlobalKey _quarterMarkerAnchorKeyFor(
    int surahNumber,
    int verseNumber, [
    int? pageNumber,
  ]) {
    final key = 'q:${pageNumber ?? 0}:$surahNumber:$verseNumber';
    return _quarterMarkerAnchorKeys.putIfAbsent(key, GlobalKey.new);
  }

  void _showBottomBarTemporarily() {
    _ignoreAutoScrollTapUntil = DateTime.now().add(
      const Duration(milliseconds: 300),
    );
    if (_isAutoScrollModeActive) {
      _controlBarHideTimer?.cancel();
      _updateState(() {
        _showBottomBar = true;
        _showControlBarWhileAutoScroll = true;
      });
      return;
    }
    if (_isAutoScrolling) {
      return;
    }
    if (_isAutoScrollPaused) {
      _controlBarHideTimer?.cancel();
      _updateState(() {
        _showBottomBar = true;
        _showControlBarWhileAutoScroll = true;
      });
      return;
    }
    _controlBarHideTimer?.cancel();
    final wasHidden = !_showBottomBar;
    if (wasHidden) {
      _updateState(() {
        _showBottomBar = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_bottomBarScrollController.hasClients) {
          return;
        }
        final maxExtent = _bottomBarScrollController.position.maxScrollExtent;
        final targetOffset = _bottomBarOffset.clamp(0.0, maxExtent).toDouble();
        _bottomBarScrollController.jumpTo(targetOffset);
      });
    }
    _controlBarHideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_showBottomBar) {
        return;
      }
      _updateState(() {
        _showBottomBar = false;
      });
    });
  }

  void _updateState(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(fn);
        unawaited(_syncWakeLock());
      });
      return;
    }
    setState(fn);
    unawaited(_syncWakeLock());
  }

  Future<void> _syncWakeLock() async {
    final shouldKeepAwake =
        _isAutoScrolling || _isPlayingAudio || _isPreparingAudio;
    try {
      await WakelockPlus.toggle(enable: shouldKeepAwake);
    } catch (_) {
      // Ignore platform channel startup issues and avoid crashing the reader.
    }
  }

  int _normalizeMedinaPageNumberFromLibrary(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= currentQuranTotalPagesCount) {
      return pageNumber;
    }
    if (pageNumber >= 0 && pageNumber < currentQuranTotalPagesCount) {
      return pageNumber + 1;
    }
    return pageNumber.clamp(1, currentQuranTotalPagesCount);
  }

  int _normalizeMedinaPageNumberFromPageViewIndex(int pageIndex) {
    return (pageIndex + 1).clamp(1, currentQuranTotalPagesCount);
  }

  int? _resolveShamarlyVisibleSurahNumber(int pageNumber) {
    final pageToSurah = _shamarlyPageToSurahMap;
    if (pageToSurah == null) {
      return null;
    }
    return pageToSurah[pageNumber];
  }

  int _currentShamarlyJuzNumberFromPage(int pageNumber) {
    final starts = _shamarlyJuzStartPages;
    if (starts == null || starts.isEmpty) {
      return _currentJuzNumberFromPage(pageNumber);
    }
    var currentJuz = 1;
    for (var i = 0; i < starts.length; i++) {
      if (pageNumber >= starts[i]) {
        currentJuz = i + 1;
      } else {
        break;
      }
    }
    return currentJuz.clamp(1, currentQuranTotalJuzCount);
  }

  void _buildMedinaPageLookup() {
    if (_medinaPageToSurahMap != null && _medinaJuzStartPages != null) {
      return;
    }
    final pageToSurah = <int, int>{};
    for (var page = 1; page <= currentQuranTotalPagesCount; page++) {
      final pageData = _quranSource.getPageData(page);
      if (pageData.isEmpty) {
        continue;
      }
      final firstSurah = pageData.first['surah'];
      final lastSurah = pageData.last['surah'];
      if (lastSurah is int) {
        pageToSurah[page] = lastSurah;
      } else if (firstSurah is int) {
        pageToSurah[page] = firstSurah;
      }
    }

    final juzStarts = List<int>.generate(currentQuranTotalJuzCount, (index) {
      final juzNumber = index + 1;
      final juzVerses = _quranSource.getSurahAndVersesFromJuz(juzNumber);
      final firstSurah = juzVerses.keys.first;
      final firstVerse = juzVerses[firstSurah]!.first;
      return _quranSource.getPageNumber(firstSurah, firstVerse);
    });

    _medinaPageToSurahMap = pageToSurah;
    _medinaJuzStartPages = juzStarts;
  }

  int _currentMedinaJuzNumberFromPage(int pageNumber) {
    final starts = _medinaJuzStartPages;
    if (starts == null || starts.isEmpty) {
      return _currentJuzNumberFromPage(pageNumber);
    }
    var currentJuz = 1;
    for (var i = 0; i < starts.length; i++) {
      if (pageNumber >= starts[i]) {
        currentJuz = i + 1;
      } else {
        break;
      }
    }
    return currentJuz.clamp(1, currentQuranTotalJuzCount);
  }

  int _currentMedinaSurahNumberFromPage(int pageNumber) {
    final normalizedPage = pageNumber.clamp(1, currentQuranTotalPagesCount);
    final pageToSurah = _medinaPageToSurahMap;
    if (pageToSurah == null || pageToSurah.isEmpty) {
      return _visibleSurahNumber ?? _selectedSurahNumber ?? widget.surahNumber;
    }
    final direct = pageToSurah[normalizedPage];
    if (direct != null) {
      return direct;
    }
    for (var page = normalizedPage - 1; page >= 1; page--) {
      final fallback = pageToSurah[page];
      if (fallback != null) {
        return fallback;
      }
    }
    for (
      var page = normalizedPage + 1;
      page <= currentQuranTotalPagesCount;
      page++
    ) {
      final fallback = pageToSurah[page];
      if (fallback != null) {
        return fallback;
      }
    }
    return _visibleSurahNumber ?? _selectedSurahNumber ?? widget.surahNumber;
  }

  int _currentShamarlySurahNumberFromPage(int pageNumber) {
    final normalizedPage = pageNumber.clamp(
      1,
      ShamarlyPagesDownloadConfig.totalPages,
    );
    final pageToSurah = _shamarlyPageToSurahMap;
    if (pageToSurah == null || pageToSurah.isEmpty) {
      return _visibleSurahNumber ?? _selectedSurahNumber ?? widget.surahNumber;
    }

    final direct = pageToSurah[normalizedPage];
    if (direct != null) {
      return direct;
    }

    for (var page = normalizedPage - 1; page >= 1; page--) {
      final fallback = pageToSurah[page];
      if (fallback != null) {
        return fallback;
      }
    }

    for (
      var page = normalizedPage + 1;
      page <= ShamarlyPagesDownloadConfig.totalPages;
      page++
    ) {
      final fallback = pageToSurah[page];
      if (fallback != null) {
        return fallback;
      }
    }

    return _visibleSurahNumber ?? _selectedSurahNumber ?? widget.surahNumber;
  }

  String _juzJumpLabel(int juzNumber) {
    return JuzNamesService.labelFor(juzNumber);
  }

  int _resolveShamarlyPage(int surahNumber, int verseNumber) {
    final map = _shamarlyPageMap;
    if (map != null) {
      final mapped = map['$surahNumber:$verseNumber'];
      if (mapped != null && mapped >= 1) {
        return mapped;
      }
    }
    return _quranSource.getPageNumber(surahNumber, verseNumber);
  }

  ({int surahNumber, int verseNumber})? _resolveShamarlyAnchorForPage(
    int pageNumber,
  ) {
    final map = _shamarlyPageFirstAyahMap;
    if (map == null || map.isEmpty) {
      return null;
    }
    final normalizedPage = pageNumber.clamp(
      1,
      ShamarlyPagesDownloadConfig.totalPages,
    );
    List<int>? direct = map[normalizedPage];
    if (direct == null) {
      for (var page = normalizedPage - 1; page >= 1; page--) {
        final fallback = map[page];
        if (fallback != null) {
          direct = fallback;
          break;
        }
      }
    }
    if (direct == null) {
      for (
        var page = normalizedPage + 1;
        page <= ShamarlyPagesDownloadConfig.totalPages;
        page++
      ) {
        final fallback = map[page];
        if (fallback != null) {
          direct = fallback;
          break;
        }
      }
    }
    if (direct == null || direct.length < 2) {
      return null;
    }
    final surah = direct[0];
    final verse = direct[1];
    if (surah < 1 || verse < 1) {
      return null;
    }
    return (surahNumber: surah, verseNumber: verse);
  }

  ({int surahNumber, int verseNumber})? _effectiveActionAnchor() {
    if (_isShamarlyPagesMode) {
      final anchor = _resolveShamarlyAnchorForPage(_shamarlyCurrentPage);
      if (anchor != null) {
        return anchor;
      }
    }
    if (_selectedSurahNumber == null || _selectedVerseNumber == null) {
      return null;
    }
    return (
      surahNumber: _selectedSurahNumber!,
      verseNumber: _selectedVerseNumber!,
    );
  }

  Future<void> _ensureShamarlyPageMapReady() async {
    if (_shamarlyPageMap != null || _isLoadingShamarlyPageMap) {
      return;
    }
    _isLoadingShamarlyPageMap = true;
    try {
      final raw = await rootBundle.loadString(
        'assets/quran/shamarly_page_map.json',
      );
      final parsedPayload = await compute(_parseShamarlyPageMapPayload, raw);
      final parsedRaw = parsedPayload['map'];
      final pageToSurahRaw = parsedPayload['pageToSurah'];
      final pageFirstAyahRaw = parsedPayload['pageFirstAyah'];
      if (parsedRaw is Map &&
          pageToSurahRaw is Map &&
          pageFirstAyahRaw is Map) {
        final parsed = <String, int>{};
        parsedRaw.forEach((key, value) {
          if (key is String && value is int) {
            parsed[key] = value;
          }
        });
        final pageToSurah = <int, int>{};
        pageToSurahRaw.forEach((key, value) {
          if (key is int && value is int) {
            pageToSurah[key] = value;
          }
        });
        final pageFirstAyah = <int, List<int>>{};
        pageFirstAyahRaw.forEach((key, value) {
          if (key is int && value is List && value.length >= 2) {
            final surah = value[0];
            final verse = value[1];
            if (surah is int && verse is int && surah >= 1 && verse >= 1) {
              pageFirstAyah[key] = <int>[surah, verse];
            }
          }
        });
        _shamarlyPageMap = parsed;
        _shamarlyPageToSurahMap = pageToSurah;
        _shamarlyPageFirstAyahMap = pageFirstAyah;
        _shamarlyJuzStartPages = List<int>.generate(currentQuranTotalJuzCount, (
          index,
        ) {
          final juzVerses = _quranSource.getSurahAndVersesFromJuz(index + 1);
          final firstSurah = juzVerses.keys.first;
          final firstVerse = juzVerses[firstSurah]!.first;
          return parsed['$firstSurah:$firstVerse'] ??
              _quranSource.getPageNumber(firstSurah, firstVerse);
        }, growable: false);
      } else {
        _shamarlyPageMap = <String, int>{};
        _shamarlyPageToSurahMap = <int, int>{};
        _shamarlyPageFirstAyahMap = <int, List<int>>{};
        _shamarlyJuzStartPages = null;
      }
    } finally {
      _isLoadingShamarlyPageMap = false;
      if (mounted && _isShamarlyPagesMode) {
        final resolved = _resolveShamarlyPage(
          _selectedSurahNumber ?? widget.surahNumber,
          _selectedVerseNumber ?? widget.initialVerse,
        );
        if (resolved != _shamarlyCurrentPage) {
          _updateState(() {
            _shamarlyCurrentPage = resolved;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_syncWakeLock());
    _selectedSurahNumber = widget.surahNumber;
    _selectedVerseNumber = widget.initialVerse;
    _visibleSurahNumber = widget.surahNumber;
    _visiblePagedPageNumber = _startPage;
    _visibleStandardPageNumber = _startPage;
    _pagedStartPage = _startPage;
    _standardInitialPage = _startPage;
    _buildMedinaPageLookup();
    unawaited(_prepareMediaArtworkUri());
    _restoreReaderPreferences();
    _lastContinuousFontSize = _fontSize;
    if (_appearance == _ReaderAppearance.medinaPages) {
      _isSwitchingToPagedMushaf = true;
      _primePagedMushafTargetPage(_pagedStartPage ?? _startPage);
      _applyPagedMushafScaleNow();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 700), () {
          if (!mounted || !_isPagedMushafMode) {
            return;
          }
          _finishPagedMushafSwitching();
        });
      });
    }
    if (_appearance == _ReaderAppearance.shamarlyPages) {
      unawaited(_ensureShamarlyPageMapReady());
      _shamarlyCurrentPage = _resolveShamarlyPage(
        _selectedSurahNumber ?? widget.surahNumber,
        _selectedVerseNumber ?? widget.initialVerse,
      );
    }
    _bottomBarScrollController.addListener(() {
      if (_bottomBarScrollController.hasClients) {
        _bottomBarOffset = _bottomBarScrollController.offset;
      }
    });
    _isInitialStandardPositioning = !_isPagedMushafMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_isMedinaPagesMode) {
        _applyPagedMushafScaleNow();
        _jumpPagedToSelectedVerse();
      } else if (_isShamarlyPagesMode) {
        _updateState(() {
          _isSwitchingToPagedMushaf = false;
        });
      } else {
        _jumpStandardReaderNearTargetPage();
        _startInitialStandardPositioning();
        if (widget.highlightQuery != null &&
            widget.highlightQuery!.trim().isNotEmpty) {
          Future<void>.delayed(const Duration(milliseconds: 220), () {
            if (!mounted || _isPagedMushafMode) {
              return;
            }
            _scrollSelectedVerseIntoView(
              alignment: widget.initialVerseAlignment,
            );
          });
          Future<void>.delayed(const Duration(milliseconds: 520), () {
            if (!mounted || _isPagedMushafMode) {
              return;
            }
            _scrollSelectedVerseIntoView(
              alignment: widget.initialVerseAlignment,
            );
          });
        }
      }
    });
    _standardItemPositionsListener.itemPositions.addListener(
      _handleReaderScroll,
    );
    if (!_isPagedMushafMode) {
      _lastContinuousAppearance = _appearance;
    }

    unawaited(_refreshMedinaFontsAvailability());
    unawaited(_refreshShamarlyPagesAvailability());

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted || _activeAudioEngine == _AudioEngine.library) {
        return;
      }
      if (state.processingState == ProcessingState.completed) {
        _audioBufferingHintTimer?.cancel();
        _cancelAudioPreparingTimeout();
        _updateState(() {
          _isPlayingAudio = false;
          _isPreparingAudio = true;
        });
        if (_isHandlingLocalCompletion || _isAdvancingToNextSurah) {
          _pendingLocalCompletion = true;
        } else {
          unawaited(_handleLocalAudioCompleted());
        }
        return;
      }
      _updateState(() {
        _isPlayingAudio = state.playing;
        if (state.playing) {
          _audioBufferingHintTimer?.cancel();
          _cancelAudioPreparingTimeout();
          _audioBufferingHintShown = false;
          _isPreparingAudio = false;
          _suspendPlaylistIndexSelectionSync = false;
        } else if (state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering ||
            (_isPreparingAudio &&
                state.processingState == ProcessingState.ready)) {
          if (_audioBufferingHintShown && !_audioPlayer.playing) {
            _isPreparingAudio = false;
            _isPlayingAudio = false;
          } else {
            // Keep showing loading until playback actually starts.
            _isPreparingAudio = true;
          }
          if (!_audioBufferingHintShown &&
              !_audioPlayer.playing &&
              _isPreparingAudio) {
            _startAudioPreparingTimeout();
            _audioBufferingHintTimer ??= Timer(const Duration(seconds: 6), () {
              _audioBufferingHintTimer = null;
              if (!mounted ||
                  _activeAudioEngine != _AudioEngine.local ||
                  _audioPlayer.playing ||
                  _audioBufferingHintShown) {
                return;
              }
              _audioBufferingHintShown = true;
              _updateState(() {
                _isPreparingAudio = false;
                _isPlayingAudio = false;
                _audioError = 'انقطع الاتصال بالإنترنت أثناء التشغيل.';
              });
              unawaited(_audioPlayer.stop().catchError((_) {}));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('انقطع الاتصال بالإنترنت أثناء التشغيل.'),
                ),
              );
            });
          }
        } else if (state.processingState == ProcessingState.idle) {
          _audioBufferingHintTimer?.cancel();
          _audioBufferingHintTimer = null;
          _cancelAudioPreparingTimeout();
          _isPreparingAudio = false;
          final currentIndex = _audioPlayer.currentIndex;
          final hasPendingItems =
              currentIndex != null &&
              currentIndex >= 0 &&
              currentIndex < (_playlistVerseNumbers.length - 1);
          if (hasPendingItems &&
              !_isAdvancingToNextSurah &&
              !_isHandlingLocalCompletion &&
              !_audioBufferingHintShown) {
            _audioBufferingHintShown = true;
            _audioError = 'تعذر تشغيل الصوت. تأكد من اتصال الإنترنت.';
          }
        } else {
          _audioBufferingHintTimer?.cancel();
          _audioBufferingHintTimer = null;
          _cancelAudioPreparingTimeout();
        }
      });
    });

    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object _) {
        if (!mounted || _activeAudioEngine != _AudioEngine.local) {
          return;
        }
        _audioBufferingHintTimer?.cancel();
        _audioBufferingHintTimer = null;
        _cancelAudioPreparingTimeout();
        _audioBufferingHintShown = true;
        _updateState(() {
          _isPreparingAudio = false;
          _isPlayingAudio = false;
          _audioError = 'انقطع الاتصال بالإنترنت أثناء التشغيل.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('انقطع الاتصال بالإنترنت أثناء التشغيل.'),
          ),
        );
      },
    );

    _audioPlayer.currentIndexStream.listen((index) {
      if (!mounted ||
          index == null ||
          _activeAudioEngine == _AudioEngine.library ||
          _suspendPlaylistIndexSelectionSync) {
        return;
      }
      if (_playbackSurahNumber == null || _playbackStartVerse == null) {
        return;
      }
      _updateState(() {
        _selectedSurahNumber = _playbackSurahNumber;
        _selectedVerseNumber = index < _playlistVerseNumbers.length
            ? _playlistVerseNumbers[index]
            : _playbackStartVerse! + index;
      });
      unawaited(_persistCurrentPosition());
      _scrollSelectedVerseIntoView(alignment: 0.5);
    });

    _audioPlayer.positionStream.listen((position) {
      if (!mounted || _activeAudioEngine != _AudioEngine.local) {
        return;
      }
      if (!_selectedReciter.isMp3Quran ||
          _playbackSurahNumber == null ||
          _currentMp3QuranTimings.isEmpty) {
        return;
      }

      final currentMs = position.inMilliseconds;
      Mp3QuranAyahTiming? activeTiming = _currentMp3QuranTimings
          .where(
            (item) =>
                currentMs >= item.startTimeMs && currentMs < item.endTimeMs,
          )
          .firstOrNull;
      activeTiming ??= _currentMp3QuranTimings
          .where((item) => currentMs >= item.startTimeMs)
          .lastOrNull;
      if (activeTiming == null) {
        return;
      }

      if (_selectedSurahNumber == _playbackSurahNumber &&
          _selectedVerseNumber == activeTiming.ayah) {
        return;
      }

      _updateState(() {
        _selectedSurahNumber = _playbackSurahNumber;
        _selectedVerseNumber = activeTiming!.ayah;
      });
      unawaited(_persistCurrentPosition());
      _scrollSelectedVerseIntoView(alignment: 0.5);
    });

    _libraryAudioStateSubscription = AudioCtrl
        .instance
        .state
        .audioPlayer
        .playerStateStream
        .listen((state) {
          if (!mounted || _activeAudioEngine != _AudioEngine.library) {
            return;
          }
          _updateState(() {
            _isPlayingAudio = state.playing;
            if (state.playing) {
              _isPreparingAudio = false;
            } else if (state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering ||
                (_isPreparingAudio &&
                    state.processingState == ProcessingState.ready)) {
              _isPreparingAudio = true;
            } else if (state.processingState == ProcessingState.idle) {
              _isPreparingAudio = false;
            }
          });
        });

    _libraryAyahSubscription = AudioCtrl
        .instance
        .state
        .currentAyahUniqueNumber
        .stream
        .listen((ayahUq) {
          if (!mounted || _activeAudioEngine != _AudioEngine.library) {
            return;
          }
          final ayah = QuranCtrl.instance.getAyahByUq(ayahUq);
          _updateState(() {
            _selectedSurahNumber = ayah.surahNumber;
            _selectedVerseNumber = ayah.ayahNumber;
          });
          unawaited(_persistCurrentPosition());
          _scrollSelectedVerseIntoView(alignment: 0.5);
        });

    _librarySelectionSubscription = QuranCtrl
        .instance
        .selectedAyahsByUnequeNumber
        .stream
        .listen((selectedAyahs) {
          if (!mounted || !_isMedinaPagesMode || selectedAyahs.isEmpty) {
            return;
          }
          final ayah = QuranCtrl.instance.getAyahByUq(selectedAyahs.last);
          _updateState(() {
            _selectedSurahNumber = ayah.surahNumber;
            _selectedVerseNumber = ayah.ayahNumber;
          });
          unawaited(_persistCurrentPosition());
        });

    _libraryPageSubscription = QuranCtrl.instance.state.currentPageNumber.stream
        .listen((pageNumber) {
          if (!mounted || !_isMedinaPagesMode) {
            return;
          }
          if (!_isPlayingAudio && !_isPreparingAudio) {
            return;
          }
          final normalizedPage = _normalizeMedinaPageNumberFromLibrary(
            pageNumber,
          );
          try {
            if (_visiblePagedPageNumber == normalizedPage) {
              return;
            }
            _updateState(() {
              _visiblePagedPageNumber = normalizedPage;
            });
          } catch (_) {
            return;
          }
        });
  }

  void _startAudioPreparingTimeout() {
    _audioPreparingTimeoutTimer?.cancel();
    _audioPreparingTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted ||
          _activeAudioEngine != _AudioEngine.local ||
          _audioPlayer.playing ||
          !_isPreparingAudio) {
        return;
      }
      _audioBufferingHintShown = true;
      _updateState(() {
        _isPreparingAudio = false;
        _isPlayingAudio = false;
        _audioError = 'انقطع الاتصال بالإنترنت أثناء التشغيل.';
      });
      unawaited(_audioPlayer.stop().catchError((_) {}));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انقطع الاتصال بالإنترنت أثناء التشغيل.')),
      );
    });
  }

  void _cancelAudioPreparingTimeout() {
    _audioPreparingTimeoutTimer?.cancel();
    _audioPreparingTimeoutTimer = null;
  }

  Future<void> _prepareMediaArtworkUri() async {
    if (kIsWeb) {
      return;
    }
    try {
      final data = await rootBundle.load('assets/IMG_4554.png');
      final dir = await getTemporaryDirectory();
      final file = File(path.join(dir.path, 'now_playing_artwork.png'));
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (!mounted) {
        return;
      }
      _mediaArtworkUri = file.uri;
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _controlBarHideTimer?.cancel();
    _visibleSurahSyncTimer?.cancel();
    _audioBufferingHintTimer?.cancel();
    _cancelAudioPreparingTimeout();
    _libraryAudioStateSubscription?.cancel();
    _libraryAyahSubscription?.cancel();
    _librarySelectionSubscription?.cancel();
    _libraryPageSubscription?.cancel();
    _standardItemPositionsListener.itemPositions.removeListener(
      _handleReaderScroll,
    );
    unawaited(_persistCurrentPosition());
    unawaited(_persistReaderPreferences());
    unawaited(_disableWakeLockSafely());
    _audioPlayer.dispose();
    _bottomBarScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistCurrentPosition());
      unawaited(_persistReaderPreferences());
      unawaited(_disableWakeLockSafely());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_syncWakeLock());
    }
  }

  Future<void> _disableWakeLockSafely() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedPageNumber = _isMedinaPagesMode
        ? (_visiblePagedPageNumber ??
              _normalizeMedinaPageNumberFromLibrary(
                QuranCtrl.instance.state.currentPageNumber.value,
              ))
        : (_isShamarlyPagesMode
              ? _shamarlyCurrentPage.clamp(
                  1,
                  ShamarlyPagesDownloadConfig.totalPages,
                )
              : (_visibleStandardPageNumber ??
                    _quranSource.getPageNumber(
                      _selectedSurahNumber ?? widget.surahNumber,
                      _selectedVerseNumber ?? widget.initialVerse,
                    )));
    final displayedSurahNumber = _isMedinaPagesMode
        ? _currentMedinaSurahNumberFromPage(displayedPageNumber)
        : (_isShamarlyPagesMode
              ? _currentShamarlySurahNumberFromPage(displayedPageNumber)
              : (_visibleSurahNumber ??
                    _selectedSurahNumber ??
                    widget.surahNumber));
    final surahName = _quranSource.getSurahNameArabic(displayedSurahNumber);
    final displayedJuzNumber = _isShamarlyPagesMode
        ? _currentShamarlyJuzNumberFromPage(displayedPageNumber)
        : (_isMedinaPagesMode
              ? _currentMedinaJuzNumberFromPage(displayedPageNumber)
              : _currentJuzNumberFromPage(displayedPageNumber));
    final surahJumpLabel = surahName;
    final juzJumpLabel = _juzJumpLabel(displayedJuzNumber);

    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return Scaffold(
          extendBody: true,
          backgroundColor: _appearance.scaffoldColor,
          appBar: _shouldShowAppBar
              ? AppBar(
                  backgroundColor: _appearance.appBarColor,
                  foregroundColor: Colors.white,
                  titleSpacing: 10,
                  title: Row(
                    children: [
                      Expanded(
                        child: _ReaderTopJumpButton(
                          label: surahJumpLabel,
                          fontFamily: 'SurahNames-font',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          textColor: _appearance.appBarColor,
                          onTap: () => _openQuranChooser(0),
                        ),
                      ),
                      const SizedBox(width: 35),
                      Expanded(
                        child: _ReaderTopJumpButton(
                          label: juzJumpLabel,
                          fontFamily: 'Ajzaa-ALQuran-font',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          textColor: _appearance.appBarColor,
                          onTap: () => _openQuranChooser(1),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handleReaderPointerDown,
            onPointerMove: _handleReaderPointerMove,
            onPointerUp: _handleReaderPointerUpOrCancel,
            onPointerCancel: _handleReaderPointerUpOrCancel,
            child: Stack(
              children: [
                SafeArea(
                  top: !_isPagedMushafMode,
                  bottom: false,
                  child: Column(
                    children: [
                      if (_audioError != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1EE),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            _audioError!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      Expanded(
                        child: _isPagedMushafMode
                            ? _buildPagedMushafContent()
                            : NotificationListener<ScrollStartNotification>(
                                onNotification: (_) {
                                  if (_isInitialStandardPositioning) {
                                    _updateState(() {
                                      _isInitialStandardPositioning = false;
                                    });
                                  }
                                  return false;
                                },
                                child: ScrollablePositionedList.builder(
                                  key: ValueKey(
                                    _standardInitialPage ?? _startPage,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    2,
                                    8,
                                    2,
                                    24,
                                  ),
                                  itemCount: currentQuranTotalPagesCount,
                                  initialScrollIndex:
                                      ((_standardInitialPage ?? _startPage) - 1)
                                          .clamp(
                                            0,
                                            currentQuranTotalPagesCount - 1,
                                          ),
                                  initialAlignment: 0,
                                  itemScrollController:
                                      _standardItemScrollController,
                                  itemPositionsListener:
                                      _standardItemPositionsListener,
                                  scrollOffsetController:
                                      _standardScrollOffsetController,
                                  physics: _isPinchPriorityActive
                                      ? const NeverScrollableScrollPhysics()
                                      : const ClampingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final pageNumber = index + 1;
                                    final pageKey = _pageKeyFor(pageNumber);
                                    return Padding(
                                      key: pageKey,
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _QuranPageCard(
                                        pageNumber: pageNumber,
                                        pageKey: pageKey,
                                        hasBookmark: _pageHasBookmark(
                                          pageNumber,
                                        ),
                                        bookmarkColor: _pageBookmarkColor(
                                          pageNumber,
                                        ),
                                        initialSurahNumber: widget.surahNumber,
                                        initialVerse: widget.initialVerse,
                                        lastRead: widget.store.lastRead,
                                        selectedSurahNumber:
                                            _selectedSurahNumber,
                                        selectedVerseNumber:
                                            _selectedVerseNumber,
                                        highlightQuery: widget.highlightQuery,
                                        fontSize: _fontSize,
                                        appearance: _appearance,
                                        verseKeyBuilder: (s, v) =>
                                            _verseKeyFor(s, v, pageNumber),
                                        quarterMarkerAnchorKeyBuilder: (s, v) =>
                                            _quarterMarkerAnchorKeyFor(
                                              s,
                                              v,
                                              pageNumber,
                                            ),
                                        onVerseTap: _showVerseActions,
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                if (_shouldShowBottomBar)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: !_shouldShowBottomBar,
                      child: Material(
                        type: MaterialType.transparency,
                        child: _BottomControlBar(
                          onShowMoreActions: _showReaderMoreSheet,
                          isPlayingAudio: _isPlayingAudio,
                          isPreparingAudio: _isPreparingAudio,
                          onSearch: _openVerseSearch,
                          onShowTafsir: _openSelectedVerseTafsir,
                          onShowTajweedLegend: _showTajweedLegendSheet,
                          onToggleAudio: _toggleSelectedVerseAudio,
                          onSaveBookmark: _openBookmarksSheet,
                          showTajweedLegend:
                              _appearance == _ReaderAppearance.tajweed ||
                              _appearance == _ReaderAppearance.nightTajweed,
                          onInteract: _showBottomBarTemporarily,
                          isAutoScrollModeActive: _isAutoScrollModeActive,
                          isAutoScrollPaused: _isAutoScrollPaused,
                          autoScrollLabel: _estimatedJuzReadingTimeLabel,
                          fontSizeLabel:
                              'حجم ${toArabicNumber(_fontSize.round())}',
                          onPauseResumeAutoScroll: () async =>
                              _toggleAutoScrollPauseResume(),
                          onToggleAutoScroll: () async => _toggleAutoScroll(),
                          onIncreaseReadingSpeed: _decreaseReadingSpeed,
                          onDecreaseReadingSpeed: _increaseReadingSpeed,
                          onIncreaseFontSize: () async => _increaseFontSize(),
                          onDecreaseFontSize: () async => _decreaseFontSize(),
                          onCloseAutoScroll: () async => _stopAutoScrollMode(),
                          showAutoScrollToggle: !_isPagedMushafMode,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagedMushafContent() {
    if (_isShamarlyPagesMode) {
      return _buildShamarlyMushafContent();
    }
    return _buildMedinaMushafContent();
  }

  Widget _buildMedinaMushafContent() {
    if (_useMedinaOnDemandDownload && !_isMedinaFontsReady) {
      return _MedinaDownloadGate(
        isChecking: _isCheckingMedinaFonts,
        isDownloading: _isDownloadingMedinaFonts,
        progress: _medinaFontsDownloadProgress,
        status: _medinaFontsDownloadStatus,
        error: _medinaFontsDownloadError,
        isConfigured: MedinaFontsDownloadConfig.zipUrls.isNotEmpty,
        onRefresh: _refreshMedinaFontsAvailability,
        onStartDownload: _startMedinaFontsDownload,
        onCancelDownload: _cancelMedinaFontsDownloadRequest,
        onExit: _exitPagedMushafGate,
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: _LibraryMushafPages(
            startPage: _pagedStartPage ?? _startPage,
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
            onPageTap: _showPagedControlBar,
            onPageChanged: (rawPageNumber) {
              if (_isSwitchingToPagedMushaf) {
                _updateState(() {
                  _isSwitchingToPagedMushaf = false;
                });
              }
              final pageNumber = _normalizeMedinaPageNumberFromPageViewIndex(
                rawPageNumber,
              );
              _updateState(() {
                _visiblePagedPageNumber = pageNumber;
              });
            },
            onAyahSelected: (surahNumber, verseNumber) {
              final ayahUq = _quranSource.getAyahUqBySurahAndAyah(
                surahNumber,
                verseNumber,
              );
              try {
                QuranCtrl.instance.setExternalHighlights([ayahUq]);
                QuranCtrl.instance.update();
              } catch (_) {}
              _updateState(() {
                _selectedSurahNumber = surahNumber;
                _selectedVerseNumber = verseNumber;
              });
              unawaited(_persistCurrentPosition());
            },
          ),
        ),
        if (_isSwitchingToPagedMushaf)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.transparent,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildShamarlyMushafContent() {
    if (ShamarlyPagesDownloadConfig.enableOnDemandDownload &&
        !_isShamarlyPagesReady) {
      return _ShamarlyDownloadGate(
        isChecking: _isCheckingShamarlyPages,
        isDownloading: _isDownloadingShamarlyPages,
        progress: _shamarlyPagesDownloadProgress,
        status: _shamarlyPagesDownloadStatus,
        error: _shamarlyPagesDownloadError,
        isConfigured: ShamarlyPagesDownloadConfig.zipUrls.isNotEmpty,
        onRefresh: _refreshShamarlyPagesAvailability,
        onStartDownload: _startShamarlyPagesDownload,
        onCancelDownload: _cancelShamarlyPagesDownloadRequest,
        onExit: _exitPagedMushafGate,
      );
    }

    const bottomBarReserve = 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: bottomBarReserve),
      child: Stack(
        children: [
          Positioned.fill(
            child: _ShamarlyPages(
              startPage: _shamarlyCurrentPage,
              pagesDirectoryPath: _shamarlyPagesDirectoryPath,
              initialZoomScale: _shamarlyZoomScale,
              onZoomScaleChanged: (zoomScale) {
                if ((zoomScale - _shamarlyZoomScale).abs() < 0.001) {
                  return;
                }
                _shamarlyZoomScale = zoomScale.clamp(1.0, 2.6);
                unawaited(_persistReaderPreferences());
              },
              onPageTap: _showPagedControlBar,
              onPageChanged: (pageNumber) {
                final pageSurahNumber = _resolveShamarlyVisibleSurahNumber(
                  pageNumber,
                );
                if (_isSwitchingToPagedMushaf) {
                  _updateState(() {
                    _isSwitchingToPagedMushaf = false;
                  });
                }
                _updateState(() {
                  _shamarlyCurrentPage = pageNumber;
                  final anchor = _resolveShamarlyAnchorForPage(pageNumber);
                  if (anchor != null) {
                    _selectedSurahNumber = anchor.surahNumber;
                    _selectedVerseNumber = anchor.verseNumber;
                  }
                  if (pageSurahNumber != null) {
                    _visibleSurahNumber = pageSurahNumber;
                  }
                });
                unawaited(_persistCurrentPosition());
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshMedinaFontsAvailability() async {
    if (!_useMedinaOnDemandDownload) {
      _updateState(() {
        _isCheckingMedinaFonts = false;
        _isMedinaFontsReady = true;
        _medinaFontsDownloadError = null;
      });
      return;
    }
    _updateState(() {
      _isCheckingMedinaFonts = true;
      _medinaFontsDownloadError = null;
    });
    try {
      final downloaded = await _medinaFontsDownloadService
          .countDownloadedPages();
      final isReady = await _medinaFontsDownloadService.isFullyDownloaded();
      if (!mounted) {
        return;
      }
      _updateState(() {
        _isMedinaFontsReady = isReady;
        _isCheckingMedinaFonts = false;
        _medinaFontsDownloadStatus = isReady
            ? 'تم تجهيز صفحات مصحف المدينة ($downloaded/${MedinaFontsDownloadConfig.totalPages}).'
            : null;
      });
      _logMedina('Availability: ready=$isReady, downloaded=$downloaded');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _updateState(() {
        _isMedinaFontsReady = false;
        _isCheckingMedinaFonts = false;
        _medinaFontsDownloadError = 'تعذر فحص ملفات مصحف المدينة.';
      });
      _logMedina('Availability check failed: $e');
    }
  }

  Future<void> _startMedinaFontsDownload() async {
    if (_isDownloadingMedinaFonts || !_useMedinaOnDemandDownload) {
      return;
    }
    if (_isDownloadingShamarlyPages) {
      _updateState(() {
        _medinaFontsDownloadError =
            'أوقف تنزيل مصحف الشمرلي أولًا ثم ابدأ تنزيل مصحف المدينة.';
      });
      return;
    }
    _cancelMedinaFontsDownload = false;
    _updateState(() {
      _isDownloadingMedinaFonts = true;
      _medinaFontsDownloadProgress = 0;
      _lastMedinaProgressLog = -1;
      _medinaFontsDownloadStatus = null;
      _medinaFontsDownloadError = null;
    });
    _logMedina('Download started');
    try {
      await _medinaFontsDownloadService.downloadAll(
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          final percent = (progress * 100).round();
          if (percent % 10 == 0 && percent != _lastMedinaProgressLog) {
            _lastMedinaProgressLog = percent;
            _logMedina('Download progress: $percent%');
          }
          _updateState(() {
            _medinaFontsDownloadProgress = progress;
            if (progress < 1) {
              _medinaFontsDownloadStatus =
                  'جارٍ تنزيل ملف مصحف المدينة... $percent%';
            }
          });
        },
        onStatus: (message) {
          if (!mounted) {
            return;
          }
          _logMedina('Status: $message');
          _updateState(() {
            _medinaFontsDownloadStatus = message;
          });
        },
        shouldCancel: () => _cancelMedinaFontsDownload,
      );
      if (!mounted) {
        return;
      }
      QuranFontsService.resetRuntimeCache();
      await _refreshMedinaFontsAvailability();
      _logMedina('Download finished');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _updateState(() {
        _medinaFontsDownloadError =
            'تعذر تنزيل مصحف المدينة. تحقق من الاتصال ثم حاول مرة أخرى.';
      });
      _logMedina('Download failed: $e');
    } finally {
      if (mounted) {
        _updateState(() {
          _isDownloadingMedinaFonts = false;
        });
      }
    }
  }

  void _cancelMedinaFontsDownloadRequest() {
    if (!_isDownloadingMedinaFonts) {
      return;
    }
    _updateState(() {
      _cancelMedinaFontsDownload = true;
      _isDownloadingMedinaFonts = false;
      _medinaFontsDownloadStatus = 'تم إيقاف التحميل.';
    });
  }

  Future<void> _refreshShamarlyPagesAvailability() async {
    if (!ShamarlyPagesDownloadConfig.enableOnDemandDownload) {
      _updateState(() {
        _isCheckingShamarlyPages = false;
        _isShamarlyPagesReady = true;
        _shamarlyPagesDownloadError = null;
      });
      return;
    }
    _updateState(() {
      _isCheckingShamarlyPages = true;
      _shamarlyPagesDownloadError = null;
    });
    try {
      final isReady = await _shamarlyPagesDownloadService.isReady();
      final pagesPath = await _shamarlyPagesDownloadService
          .pagesDirectoryPath();
      if (!mounted) {
        return;
      }
      _updateState(() {
        _isShamarlyPagesReady = isReady;
        _isCheckingShamarlyPages = false;
        _shamarlyPagesDirectoryPath = pagesPath;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      _updateState(() {
        _isShamarlyPagesReady = false;
        _isCheckingShamarlyPages = false;
        _shamarlyPagesDownloadError = 'تعذر فحص ملفات مصحف الشمرلي.';
      });
    }
  }

  Future<void> _startShamarlyPagesDownload() async {
    if (_isDownloadingShamarlyPages ||
        !ShamarlyPagesDownloadConfig.enableOnDemandDownload) {
      return;
    }
    if (_isDownloadingMedinaFonts) {
      _updateState(() {
        _shamarlyPagesDownloadError =
            'أوقف تنزيل مصحف المدينة أولًا ثم ابدأ تنزيل مصحف الشمرلي.';
      });
      return;
    }
    _cancelShamarlyPagesDownload = false;
    _updateState(() {
      _isDownloadingShamarlyPages = true;
      _shamarlyPagesDownloadProgress = 0;
      _shamarlyPagesDownloadStatus = null;
      _shamarlyPagesDownloadError = null;
    });
    try {
      await _shamarlyPagesDownloadService.downloadAndExtract(
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          final percent = (progress * 100).round();
          _updateState(() {
            _shamarlyPagesDownloadProgress = progress;
            if (progress < 1) {
              _shamarlyPagesDownloadStatus =
                  'جارٍ تنزيل ملف الشمرلي... $percent%';
            }
          });
        },
        onStatus: (message) {
          if (!mounted) {
            return;
          }
          _updateState(() {
            _shamarlyPagesDownloadStatus = message;
          });
        },
        shouldCancel: () => _cancelShamarlyPagesDownload,
      );
      if (!mounted) {
        return;
      }
      await _refreshShamarlyPagesAvailability();
    } catch (e) {
      if (!mounted) {
        return;
      }
      _updateState(() {
        _shamarlyPagesDownloadError =
            'تعذر تنزيل مصحف الشمرلي. تحقق من الاتصال ثم حاول مرة أخرى.';
      });
    } finally {
      if (mounted) {
        _updateState(() {
          _isDownloadingShamarlyPages = false;
        });
      }
    }
  }

  void _cancelShamarlyPagesDownloadRequest() {
    if (!_isDownloadingShamarlyPages) {
      return;
    }
    _updateState(() {
      _cancelShamarlyPagesDownload = true;
      _isDownloadingShamarlyPages = false;
      _shamarlyPagesDownloadStatus = 'تم إيقاف التحميل.';
    });
  }
}

class _ReaderTopJumpButton extends StatelessWidget {
  const _ReaderTopJumpButton({
    required this.label,
    required this.onTap,
    this.fontFamily,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w800,
    this.textColor = const Color(0xFF143A2A),
  });

  final String label;
  final VoidCallback onTap;
  final String? fontFamily;
  final double fontSize;
  final Color textColor;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        minimumSize: const Size(0, 22),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontWeight: fontWeight,
            fontSize: fontSize,
            fontFamily: fontFamily,
          ),
        ),
      ),
    );
  }
}
