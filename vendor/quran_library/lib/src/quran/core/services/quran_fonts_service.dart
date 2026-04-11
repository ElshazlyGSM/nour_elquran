part of '/quran.dart';

/// Ø®Ø¯Ù…Ø© ØªØ­Ù…ÙŠÙ„ ÙƒØ³ÙˆÙ„ (lazy) ÙˆØªØ³Ø¬ÙŠÙ„ Ø®Ø·ÙˆØ· QCF4 Ø§Ù„Ù…Ø¶ØºÙˆØ·Ø© (tajweed).
///
/// Ø§Ù„Ø®Ø·ÙˆØ· Ù…Ø®Ø²Ù‘Ù†Ø© ÙƒÙ…Ù„ÙØ§Øª `.ttf.gz` ÙÙŠ assets. Ø¹Ù†Ø¯ Ø§Ù„Ø­Ø§Ø¬Ø© ÙŠØªÙ… ÙÙƒ Ø¶ØºØ·Ù‡Ø§
/// ÙˆØªØ³Ø¬ÙŠÙ„Ù‡Ø§ Ø¹Ø¨Ø± [loadFontFromList]. ØªÙØ­ÙØ¸ Ø§Ù„Ù†Ø³Ø® Ø§Ù„Ù…ÙÙƒÙˆÙƒØ© Ø¹Ù„Ù‰ Ø§Ù„Ù‚Ø±Øµ
/// (Ø¹Ù„Ù‰ Ø§Ù„Ù…Ù†ØµØ§Øª ØºÙŠØ± Ø§Ù„ÙˆÙŠØ¨) Ù„ØªØ³Ø±ÙŠØ¹ Ø§Ù„ØªØ´ØºÙŠÙ„Ø§Øª Ø§Ù„Ù„Ø§Ø­Ù‚Ø©.
///
/// **Ø§Ù„ØªØ­Ù…ÙŠÙ„ Ø§Ù„ÙƒØ³ÙˆÙ„**: ØªÙØ­Ù…Ù‘Ù„ ÙÙ‚Ø· Ø§Ù„ØµÙØ­Ø§Øª Ø§Ù„Ù‚Ø±ÙŠØ¨Ø© Ù…Ù† Ø§Ù„ØµÙØ­Ø© Ø§Ù„Ø­Ø§Ù„ÙŠØ©ØŒ
/// Ø«Ù… ØªÙÙƒÙ…ÙŽÙ„ Ø¨Ù‚ÙŠØ© Ø§Ù„ØµÙØ­Ø§Øª ÙÙŠ Ø§Ù„Ø®Ù„ÙÙŠØ© ØªØ¯Ø±ÙŠØ¬ÙŠÙ‹Ø§.
class QuranFontsService {
  QuranFontsService._();

  static const int _totalPages = 604;

  /// Ø§Ù„ØµÙØ­Ø§Øª Ø§Ù„Ù…Ø­Ù…Ù‘Ù„Ø© ÙÙŠ Ù‡Ø°Ø§ Ø§Ù„ØªØ´ØºÙŠÙ„ (1-based).
  static final Set<int> _loadedPages = {};

  /// Futures Ù„Ù…Ù†Ø¹ ØªÙƒØ±Ø§Ø± ØªØ­Ù…ÙŠÙ„ Ù†ÙØ³ Ø§Ù„ØµÙØ­Ø© Ø¹Ù†Ø¯ Ø§Ù„Ø§Ø³ØªØ¯Ø¹Ø§Ø¡ Ø§Ù„Ù…ØªØ²Ø§Ù…Ù†.
  static final Map<int, Future<void>> _pageLoadFutures = {};

  /// Future ÙˆØ§Ø­Ø¯ Ù„ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø®Ù„ÙÙŠØ© Ù„Ù…Ù†Ø¹ Ø§Ù„ØªÙƒØ±Ø§Ø±.
  static Future<void>? _backgroundLoadFuture;

  /// ÙƒØ§Ø´ Ù…Ø¬Ù„Ø¯ Ø§Ù„Ø®Ø·ÙˆØ· Ø§Ù„Ù…ÙÙƒÙˆÙƒØ© (ÙŠÙÙ‡ÙŠÙ‘Ø£ Ù…Ø±Ø© ÙˆØ§Ø­Ø¯Ø©).
  static Directory? _cacheDir;
  static bool _cacheDirInitialized = false;

  /// Ù‡Ù„ Ø§Ù„ØµÙØ­Ø© Ø§Ù„Ù…Ø­Ø¯Ø¯Ø© Ø¬Ø§Ù‡Ø²Ø© Ù„Ù„Ø¹Ø±Ø¶ØŸ (1-based)
  static bool isPageReady(int page) => _loadedPages.contains(page);

  /// Ø¹Ø¯Ø¯ Ø§Ù„ØµÙØ­Ø§Øª Ø§Ù„Ù…Ø­Ù…Ù‘Ù„Ø© Ø­ØªÙ‰ Ø§Ù„Ø¢Ù†.
  static int get loadedCount => _loadedPages.length;

  /// Ù‡Ù„ ØªÙ… ØªØ­Ù…ÙŠÙ„ Ø¬Ù…ÙŠØ¹ Ø§Ù„ØµÙØ­Ø§ØªØŸ
  static bool get allLoaded => _loadedPages.length >= _totalPages;

  /// Reset only in-memory caches so newly downloaded font files are picked up
  /// without deleting the cached TTF files on disk.
  static void resetRuntimeCache() {
    _loadedPages.clear();
    _pageLoadFutures.clear();
    _backgroundLoadFuture = null;
  }

  /// Ø§Ø³Ù… Ø¹Ø§Ø¦Ù„Ø© Ø§Ù„Ø®Ø· Ù„Ù„ØµÙØ­Ø© Ø§Ù„Ù…Ø­Ø¯Ø¯Ø© (page1 .. page604).
  static String getFontFamily(int pageIndex) => 'page${pageIndex + 1}';

  /// Ø§Ø³Ù… Ø¹Ø§Ø¦Ù„Ø© Ø§Ù„Ø®Ø· Ø§Ù„Ø¯Ø§ÙƒÙ† Ù„Ù„ØµÙØ­Ø© Ø§Ù„Ù…Ø­Ø¯Ø¯Ø© (page1d .. page604d).
  static String getDarkFontFamily(int pageIndex) => 'page${pageIndex + 1}d';

  /// Ø§Ø³Ù… Ø¹Ø§Ø¦Ù„Ø© Ø§Ù„Ø®Ø· Ø¨Ø¯ÙˆÙ† ØªØ¬ÙˆÙŠØ¯ ÙØ§ØªØ­ (page1n .. page604n).
  static String getNoTajweedFontFamily(int pageIndex) =>
      'page${pageIndex + 1}n';

  /// Ø§Ø³Ù… Ø¹Ø§Ø¦Ù„Ø© Ø§Ù„Ø®Ø· Ø¨Ø¯ÙˆÙ† ØªØ¬ÙˆÙŠØ¯ Ø¯Ø§ÙƒÙ† (page1nd .. page604nd).
  static String getNoTajweedDarkFontFamily(int pageIndex) =>
      'page${pageIndex + 1}nd';

  /// Ø§Ø³Ù… Ø¹Ø§Ø¦Ù„Ø© Ø§Ù„Ø®Ø· Ø§Ù„Ø£Ø­Ù…Ø± Ù„Ù„Ø®Ù„Ø§Ù (page1nr .. page604nr).
  static String getRedFontFamily(int pageIndex) => 'page${pageIndex + 1}nr';

  /// Ù…Ø³Ø§Ø± Ø§Ù„Ù€ asset Ø§Ù„Ù…Ø¶ØºÙˆØ· Ù„Ù„ØµÙØ­Ø© (1-based).
  static String _assetPath(int page) {
    final padded = page.toString().padLeft(3, '0');
    return 'packages/quran_library/assets/fonts/quran_fonts_qfc4/'
        'QCF4_tajweed_$padded.ttf.gz';
  }

  // ---------------------------------------------------------------------------
  // ØªÙ‡ÙŠØ¦Ø© Ù…Ø¬Ù„Ø¯ Ø§Ù„ÙƒØ§Ø´
  // ---------------------------------------------------------------------------

  static Future<Directory?> _ensureCacheDir() async {
    if (_cacheDirInitialized) return _cacheDir;
    _cacheDirInitialized = true;
    if (kIsWeb) return null;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/quran_fonts_cache');
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      _cacheDir = dir;
    } catch (e) {
      log('QuranFontsService: failed to create cache dir: $e',
          name: 'QuranFontsService');
      _cacheDir = null;
    }
    return _cacheDir;
  }

  // ---------------------------------------------------------------------------
  // Ø§Ù„ØªØ­Ù…ÙŠÙ„ Ø§Ù„ÙƒØ³ÙˆÙ„: ØªØ­Ù…ÙŠÙ„ ØµÙØ­Ø§Øª Ù‚Ø±ÙŠØ¨Ø© ÙÙ‚Ø·
  // ---------------------------------------------------------------------------

  /// ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØµÙØ­Ø§Øª Ø§Ù„Ù‚Ø±ÙŠØ¨Ø© Ù…Ù† [centerPage] (1-based) Ø¨Ù†ØµÙ Ù‚Ø·Ø± [radius].
  ///
  /// Ù…Ø«Ø§Ù„: `ensurePagesLoaded(100, radius: 10)` ÙŠØ­Ù…Ù‘Ù„ Ø§Ù„ØµÙØ­Ø§Øª 90â€“110.
  /// ÙŠØªÙ… ØªØ®Ø·Ù‘ÙŠ Ø§Ù„ØµÙØ­Ø§Øª Ø§Ù„Ù…Ø­Ù…Ù‘Ù„Ø© Ù…Ø³Ø¨Ù‚Ù‹Ø§. ÙŠÙÙ†ØªØ¸Ø± Ø­ØªÙ‰ Ø§Ù†ØªÙ‡Ø§Ø¡ Ø§Ù„ØªØ­Ù…ÙŠÙ„.
  static Future<void> ensurePagesLoaded(
    int centerPage, {
    int radius = 10,
  }) async {
    final cacheDir = await _ensureCacheDir();
    final start = (centerPage - radius).clamp(1, _totalPages);
    final end = (centerPage + radius).clamp(1, _totalPages);

    final futures = <Future<void>>[];
    for (int p = start; p <= end; p++) {
      if (!_loadedPages.contains(p)) {
        futures.add(_loadSinglePage(p, cacheDir));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// ØªØ­Ù…ÙŠÙ„ Ø¨Ù‚ÙŠØ© Ø§Ù„ØµÙØ­Ø§Øª ÙÙŠ Ø§Ù„Ø®Ù„ÙÙŠØ© Ø¨ØªØ±ØªÙŠØ¨ ÙŠØ¨Ø¯Ø£ Ù…Ù† [startNearPage].
  ///
  /// ØªÙØ­Ø¯Ù‘Ø« [progress] (0.0â€“1.0) Ùˆ[ready] Ø¹Ù†Ø¯ Ø§Ù„Ø§Ù†ØªÙ‡Ø§Ø¡ Ø§Ù„ÙƒØ§Ù…Ù„.
  /// Ù„Ø§ ØªÙÙ†ØªØ¸Ø± â€” ØªØ¹Ù…Ù„ Ø¨Ø´ÙƒÙ„ ØºÙŠØ± Ù…ØªØ²Ø§Ù…Ù†.
  static Future<void> loadRemainingInBackground({
    required int startNearPage,
    required RxDouble progress,
    required RxBool ready,
  }) {
    if (allLoaded) {
      progress.value = 1.0;
      ready.value = true;
      return Future.value();
    }
    // Ù…Ù†Ø¹ Ø§Ù„ØªÙƒØ±Ø§Ø±
    _backgroundLoadFuture ??= _doLoadRemaining(
      startNearPage: startNearPage,
      progress: progress,
      ready: ready,
    );
    return _backgroundLoadFuture!;
  }

  static Future<void> _doLoadRemaining({
    required int startNearPage,
    required RxDouble progress,
    required RxBool ready,
  }) async {
    final cacheDir = await _ensureCacheDir();
    final loadOrder = _buildLoadOrder(startNearPage);

    for (final page in loadOrder) {
      if (_loadedPages.contains(page)) continue;
      await _loadSinglePage(page, cacheDir);
      progress.value = _loadedPages.length / _totalPages;
    }

    progress.value = 1.0;
    ready.value = true;
  }

  /// Ø¨Ù†Ø§Ø¡ ØªØ±ØªÙŠØ¨ Ø§Ù„ØªØ­Ù…ÙŠÙ„: ÙŠØ¨Ø¯Ø£ Ù…Ù† [startPage] ÙˆÙŠØªÙˆØ³Ø¹ Ù„Ù„Ø®Ø§Ø±Ø¬.
  ///
  /// Ù…Ø«Ù„Ø§Ù‹ Ù„Ùˆ startPage=100: 100ØŒ 101ØŒ 99ØŒ 102ØŒ 98ØŒ 103ØŒ 97 ...
  static List<int> _buildLoadOrder(int startPage) {
    final order = <int>[];
    final start = startPage.clamp(1, _totalPages);
    order.add(start);

    for (int delta = 1; delta < _totalPages; delta++) {
      final after = start + delta;
      final before = start - delta;
      if (after <= _totalPages) order.add(after);
      if (before >= 1) order.add(before);
    }

    return order;
  }

  // ---------------------------------------------------------------------------
  // ØªØ­Ù…ÙŠÙ„ ØµÙØ­Ø© ÙˆØ§Ø­Ø¯Ø© Ù…Ø¹ ÙƒÙ„ Ø§Ù„Ù…ØªØºÙŠØ±Ø§Øª (4 Ø®Ø·ÙˆØ·)
  // ---------------------------------------------------------------------------

  /// ØªØ­Ù…ÙŠÙ„ ØµÙØ­Ø© ÙˆØ§Ø­Ø¯Ø© (1-based) Ù…Ø¹ Ù…ØªØºÙŠØ±Ø§ØªÙ‡Ø§ Ø§Ù„Ø£Ø±Ø¨Ø¹Ø©.
  ///
  /// - `page{N}` â€” ÙØ§ØªØ­ Ù…Ø¹ ØªØ¬ÙˆÙŠØ¯
  /// - `page{N}d` â€” Ø¯Ø§ÙƒÙ† Ù…Ø¹ ØªØ¬ÙˆÙŠØ¯ (CPAL: Ø£Ø³ÙˆØ¯â†’Ø£Ø¨ÙŠØ¶)
  /// - `page{N}n` â€” ÙØ§ØªØ­ Ø¨Ø¯ÙˆÙ† ØªØ¬ÙˆÙŠØ¯ (CPAL: ÙƒÙ„ Ø§Ù„Ø£Ù„ÙˆØ§Ù†â†’Ø£Ø³ÙˆØ¯)
  /// - `page{N}nd` â€” Ø¯Ø§ÙƒÙ† Ø¨Ø¯ÙˆÙ† ØªØ¬ÙˆÙŠØ¯ (CPAL: ÙƒÙ„ Ø§Ù„Ø£Ù„ÙˆØ§Ù†â†’Ø£Ø¨ÙŠØ¶)
  static Future<void> _loadSinglePage(int page, Directory? cacheDir) {
    // Ù…Ù†Ø¹ Ø§Ù„ØªÙƒØ±Ø§Ø± Ø¹Ù†Ø¯ Ø§Ù„Ø§Ø³ØªØ¯Ø¹Ø§Ø¡ Ø§Ù„Ù…ØªØ²Ø§Ù…Ù† Ù„Ù†ÙØ³ Ø§Ù„ØµÙØ­Ø©
    return _pageLoadFutures.putIfAbsent(page, () async {
      try {
        Uint8List fontBytes;
        final familyName = 'page$page';

        // Ø¬Ø±Ù‘Ø¨ Ù‚Ø±Ø§Ø¡Ø© Ø§Ù„ÙƒØ§Ø´ Ø£ÙˆÙ„Ø§Ù‹
        if (cacheDir != null) {
          final cachedFile = File('${cacheDir.path}/$familyName.ttf');
          if (cachedFile.existsSync()) {
            fontBytes = await cachedFile.readAsBytes();
          } else {
            fontBytes = await _decompressFromAsset(page);
            try {
              await cachedFile.writeAsBytes(fontBytes, flush: true);
            } catch (e) {
              log('QuranFontsService: cache write failed for page $page: $e',
                  name: 'QuranFontsService');
            }
          }
        } else {
          fontBytes = await _decompressFromAsset(page);
        }

        // 1. Ø®Ø· ÙØ§ØªØ­ Ø£ØµÙ„ÙŠ
        await loadFontFromList(fontBytes, fontFamily: familyName);

        // 2. Ø®Ø· Ø¯Ø§ÙƒÙ†: CPAL Ø£Ø³ÙˆØ¯ â†’ Ø£Ø¨ÙŠØ¶
        final darkBytes = _modifyCpalBaseColor(
          Uint8List.fromList(fontBytes),
          const Color(0xFFFFFFFF),
        );
        await loadFontFromList(darkBytes, fontFamily: '${familyName}d');

        // 3. Ø¨Ø¯ÙˆÙ† ØªØ¬ÙˆÙŠØ¯ ÙØ§ØªØ­: ÙƒÙ„ Ø§Ù„Ø£Ù„ÙˆØ§Ù† â†’ Ø£Ø³ÙˆØ¯
        final ntBytes = _modifyCpalAllColors(
          Uint8List.fromList(fontBytes),
          const Color(0xFF000000),
        );
        await loadFontFromList(ntBytes, fontFamily: '${familyName}n');

        // 4. Ø¨Ø¯ÙˆÙ† ØªØ¬ÙˆÙŠØ¯ Ø¯Ø§ÙƒÙ†: ÙƒÙ„ Ø§Ù„Ø£Ù„ÙˆØ§Ù† â†’ Ø£Ø¨ÙŠØ¶
        final ntdBytes = _modifyCpalAllColors(
          Uint8List.fromList(fontBytes),
          const Color(0xFFFFFFFF),
        );
        await loadFontFromList(ntdBytes, fontFamily: '${familyName}nd');

        // 5. Ø£Ø­Ù…Ø± Ù„Ù„Ø®Ù„Ø§Ù (Ø§Ù„Ù‚Ø±Ø§Ø¡Ø§Øª Ø§Ù„Ø¹Ø´Ø±): ÙƒÙ„ Ø§Ù„Ø£Ù„ÙˆØ§Ù† â†’ Ø£Ø­Ù…Ø±
        final nrBytes = _modifyCpalAllColors(
          Uint8List.fromList(fontBytes),
          const Color(0xFFFF0000),
        );
        await loadFontFromList(nrBytes, fontFamily: '${familyName}nr');

        _loadedPages.add(page);
      } catch (e, st) {
        log('QuranFontsService: failed to load font page $page: $e',
            name: 'QuranFontsService', stackTrace: st);
      } finally {
        _pageLoadFutures.remove(page);
      }
    });
  }

  /// ÙÙƒ Ø¶ØºØ· Ù…Ù„Ù `.ttf.gz` Ù…Ù† Ø§Ù„Ù€ assets.
  static Future<Uint8List> _decompressFromAsset(int page) async {
    final data = await rootBundle.load(_assetPath(page));
    final gzBytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final decompressed = const GZipDecoder().decodeBytes(gzBytes);
    return Uint8List.fromList(decompressed);
  }

  // ---------------------------------------------------------------------------
  // ØªØ¹Ø¯ÙŠÙ„ Ø¬Ø¯ÙˆÙ„ CPAL ÙÙŠ Ù…Ù„Ù TTF/OTF
  // ---------------------------------------------------------------------------

  /// ÙŠØ¨Ø­Ø« Ø¹Ù† Ø¬Ø¯ÙˆÙ„ `CPAL` ÙÙŠ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø®Ø· ÙˆÙŠØ³ØªØ¨Ø¯Ù„ Ø§Ù„Ù„ÙˆÙ† Ø§Ù„Ø£Ø³ÙˆØ¯ Ø§Ù„Ø£Ø³Ø§Ø³ÙŠ
  /// (Ø§Ù„Ø·Ø¨Ù‚Ø© Ø§Ù„Ø£Ø³Ø§Ø³ÙŠØ© Ù„Ù†Øµ Ø§Ù„Ù‚Ø±Ø¢Ù†) Ø¨Ù€ [newBaseColor].
  ///
  /// Ø£Ù„ÙˆØ§Ù† Ø§Ù„ØªØ¬ÙˆÙŠØ¯ (Ø£Ø­Ù…Ø±ØŒ Ø£Ø®Ø¶Ø±ØŒ Ø£Ø²Ø±Ù‚ØŒ Ø¥Ù„Ø®) ØªØ¨Ù‚Ù‰ ÙƒÙ…Ø§ Ù‡ÙŠ ØªÙ…Ø§Ù…Ø§Ù‹.
  /// Ø¥Ø°Ø§ Ù„Ù… ÙŠÙØ¹Ø«Ø± Ø¹Ù„Ù‰ Ø¬Ø¯ÙˆÙ„ CPALØŒ ØªÙØ±Ø¬Ø¹ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø¨Ø¯ÙˆÙ† ØªØ¹Ø¯ÙŠÙ„.
  static Uint8List _modifyCpalBaseColor(
      Uint8List fontBytes, Color newBaseColor) {
    final bd = ByteData.view(
        fontBytes.buffer, fontBytes.offsetInBytes, fontBytes.lengthInBytes);

    if (fontBytes.length < 12) return fontBytes;
    final numTables = bd.getUint16(4);

    int? cpalOffset;
    int? cpalLength;
    const cpalTag = 0x4350414C; // 'CPAL' in ASCII
    for (int t = 0; t < numTables; t++) {
      final recordOffset = 12 + t * 16;
      if (recordOffset + 16 > fontBytes.length) break;
      final tag = bd.getUint32(recordOffset);
      if (tag == cpalTag) {
        cpalOffset = bd.getUint32(recordOffset + 8);
        cpalLength = bd.getUint32(recordOffset + 12);
        break;
      }
    }

    if (cpalOffset == null || cpalLength == null) return fontBytes;
    if (cpalOffset + cpalLength > fontBytes.length) return fontBytes;

    if (cpalOffset + 12 > fontBytes.length) return fontBytes;
    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);

    final absColorRecordsOffset = cpalOffset + colorRecordsArrayOffset;

    final newR = (newBaseColor.r * 255).round();
    final newG = (newBaseColor.g * 255).round();
    final newB = (newBaseColor.b * 255).round();
    final newA = (newBaseColor.a * 255).round();

    for (int c = 0; c < numColorRecords; c++) {
      final colorOffset = absColorRecordsOffset + c * 4;
      if (colorOffset + 4 > fontBytes.length) break;

      final b = fontBytes[colorOffset];
      final g = fontBytes[colorOffset + 1];
      final r = fontBytes[colorOffset + 2];
      final a = fontBytes[colorOffset + 3];

      // Ø§ÙƒØªØ´Ø§Ù Ø§Ù„Ù„ÙˆÙ† Ø§Ù„Ø£Ø³ÙˆØ¯: RGB â‰¤ 30 Ùˆ Alpha â‰¥ 200
      if (r <= 30 && g <= 30 && b <= 30 && a >= 200) {
        fontBytes[colorOffset] = newB;
        fontBytes[colorOffset + 1] = newG;
        fontBytes[colorOffset + 2] = newR;
        fontBytes[colorOffset + 3] = newA;
      }
    }

    return fontBytes;
  }

  /// ÙŠØ³ØªØ¨Ø¯Ù„ **Ø¬Ù…ÙŠØ¹** Ø£Ù„ÙˆØ§Ù† CPAL Ø¨Ù„ÙˆÙ† ÙˆØ§Ø­Ø¯ Ù…ÙˆØ­Ù‘Ø¯.
  ///
  /// ÙŠÙØ³ØªØ®Ø¯Ù… Ù„Ø¥Ù†Ø´Ø§Ø¡ Ù†Ø³Ø®Ø© "Ø¨Ø¯ÙˆÙ† ØªØ¬ÙˆÙŠØ¯" Ø­ÙŠØ« ÙŠÙØ±Ø³Ù… ÙƒÙ„ Ø´ÙŠØ¡ Ø¨Ù„ÙˆÙ† ÙˆØ§Ø­Ø¯.
  static Uint8List _modifyCpalAllColors(Uint8List fontBytes, Color color) {
    final bd = ByteData.view(
        fontBytes.buffer, fontBytes.offsetInBytes, fontBytes.lengthInBytes);

    if (fontBytes.length < 12) return fontBytes;
    final numTables = bd.getUint16(4);

    int? cpalOffset;
    int? cpalLength;
    const cpalTag = 0x4350414C;
    for (int t = 0; t < numTables; t++) {
      final recordOffset = 12 + t * 16;
      if (recordOffset + 16 > fontBytes.length) break;
      final tag = bd.getUint32(recordOffset);
      if (tag == cpalTag) {
        cpalOffset = bd.getUint32(recordOffset + 8);
        cpalLength = bd.getUint32(recordOffset + 12);
        break;
      }
    }

    if (cpalOffset == null || cpalLength == null) return fontBytes;
    if (cpalOffset + cpalLength > fontBytes.length) return fontBytes;
    if (cpalOffset + 12 > fontBytes.length) return fontBytes;

    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);
    final absColorRecordsOffset = cpalOffset + colorRecordsArrayOffset;

    final newR = (color.r * 255).round();
    final newG = (color.g * 255).round();
    final newB = (color.b * 255).round();
    final newA = (color.a * 255).round();

    for (int c = 0; c < numColorRecords; c++) {
      final colorOffset = absColorRecordsOffset + c * 4;
      if (colorOffset + 4 > fontBytes.length) break;
      fontBytes[colorOffset] = newB;
      fontBytes[colorOffset + 1] = newG;
      fontBytes[colorOffset + 2] = newR;
      fontBytes[colorOffset + 3] = newA;
    }

    return fontBytes;
  }

  /// Ø­Ø°Ù ÙƒØ§Ø´ Ø§Ù„Ø®Ø·ÙˆØ· Ù…Ù† Ø§Ù„Ù‚Ø±Øµ.
  static Future<void> clearCache() async {
    if (kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/quran_fonts_cache');
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      log('QuranFontsService: clearCache failed: $e',
          name: 'QuranFontsService');
    }
    _loadedPages.clear();
    _pageLoadFutures.clear();
    _backgroundLoadFuture = null;
    _cacheDir = null;
    _cacheDirInitialized = false;
  }
}


