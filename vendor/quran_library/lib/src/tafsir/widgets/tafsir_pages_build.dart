part of '../tafsir.dart';

class TafsirPagesBuild extends StatefulWidget {
  final int pageIndex;
  final int ayahUQNumber;
  final TafsirStyle? tafsirStyle;
  final bool isDark;

  const TafsirPagesBuild({
    super.key,
    required this.pageIndex,
    required this.ayahUQNumber,
    this.tafsirStyle,
    required this.isDark,
  });

  @override
  State<TafsirPagesBuild> createState() => _TafsirPagesBuildState();
}

class _TafsirPagesBuildState extends State<TafsirPagesBuild> {
  final quranCtrl = QuranCtrl.instance;
  final tafsirCtrl = TafsirCtrl.instance;

  PageController? _pageController;
  int _currentPageIndex = 0;

  @override
  void didUpdateWidget(covariant TafsirPagesBuild oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex ||
        oldWidget.ayahUQNumber != widget.ayahUQNumber) {
      _pageController?.dispose();
      _pageController = null;
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _ensureController(int initialPage) {
    if (_pageController != null) {
      return;
    }
    _currentPageIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
  }

  Future<void> _jumpTo(int page) async {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) {
      return;
    }
    await controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.maybeOf(context)?.size.width ?? 400.0;
    final pageAyahs = quranCtrl.getPageAyahsByIndex(widget.pageIndex);
    final selectedAyahIndexInFullPage = pageAyahs
        .indexWhere((ayah) => ayah.ayahUQNumber == widget.ayahUQNumber);
    final safeInitialPage =
        selectedAyahIndexInFullPage >= 0 ? selectedAyahIndexInFullPage : 0;

    _ensureController(safeInitialPage);

    return FutureBuilder<void>(
      future: _initializeTafsirData(
        ayahUQNum: widget.ayahUQNumber,
        pageIndex: widget.pageIndex,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tafsirCtrl.tafseerList.isEmpty &&
            tafsirCtrl.translationList.isEmpty) {
          return const SizedBox.shrink();
        }

        final showPrev = _currentPageIndex > 0;
        final showNext = _currentPageIndex < pageAyahs.length - 1;

        return Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pageAyahs.length,
              onPageChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _currentPageIndex = value;
                });
              },
              itemBuilder: (context, i) {
                final ayahs = pageAyahs[i];
                final ayahIndex = ayahs.ayahUQNumber;
                final tafsir = tafsirCtrl.tafseerList.firstWhere(
                  (element) => element.id == ayahIndex,
                  orElse: () => const TafsirTableData(
                    id: 0,
                    tafsirText: '',
                    ayahNum: 0,
                    pageNum: 0,
                    surahNum: 0,
                  ),
                );
                final surahs =
                    QuranCtrl.instance.getCurrentSurahByPageNumber(ayahs.page);
                return Container(
                  width: width,
                  margin: EdgeInsets.symmetric(
                    vertical: widget.tafsirStyle?.verticalMargin ?? 8,
                    horizontal: widget.tafsirStyle?.horizontalMargin ?? 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.tafsirStyle?.tafsirBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color:
                            widget.tafsirStyle?.unSelectedTafsirBorderColor ??
                                (widget.tafsirStyle?.dividerColor ??
                                    Colors.grey.withValues(alpha: 0.3)),
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: GetBuilder<TafsirCtrl>(
                      id: 'change_font_size',
                      builder: (tafsirCtrl) => ActualTafsirWidget(
                        isDark: widget.isDark,
                        tafsirStyle: widget.tafsirStyle ??
                            TafsirStyle.defaults(
                              isDark: widget.isDark,
                              context: context,
                            ),
                        context: context,
                        ayahIndex: ayahIndex,
                        tafsir: tafsir,
                        ayahs: ayahs,
                        surahs: surahs,
                        pageIndex: widget.pageIndex,
                        isTafsir: tafsirCtrl.selectedTafsir.isTafsir,
                        translationList: tafsirCtrl.translationList,
                        fontSizeArabic: tafsirCtrl.fontSizeArabic.value,
                        language: tafsirCtrl
                            .tafsirAndTranslationsItems[
                                tafsirCtrl.radioValue.value]
                            .name,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              right: 2,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  onPressed:
                      showPrev ? () => _jumpTo(_currentPageIndex - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              ),
            ),
            Positioned(
              left: 2,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  onPressed:
                      showNext ? () => _jumpTo(_currentPageIndex + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
