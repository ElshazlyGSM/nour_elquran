import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as legacy_quran;

import '../../core/utils/arabic_numbers.dart';
import '../../features/reader/reader_page.dart';
import '../../services/current_quran_text_source.dart';
import '../../services/quran_store.dart';

const _surahListSource = currentQuranTextSource;

class _VerseSearchIndexEntry {
  const _VerseSearchIndexEntry({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
    required this.verseText,
    required this.normalizedText,
    required this.normalizedWords,
  });

  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final String verseText;
  final String normalizedText;
  final List<String> normalizedWords;
}

final List<_VerseSearchIndexEntry> _verseSearchCache = [
  for (var surah = 1; surah <= currentQuranTotalSurahCount; surah++)
    for (var verse = 1; verse <= _surahListSource.getVerseCount(surah); verse++)
      () {
        final verseText = _surahListSource.getVerseText(
          surah,
          verse,
          verseEndSymbol: false,
        );
        final normalizedText = _normalizeArabic(verseText);
        return _VerseSearchIndexEntry(
          surahNumber: surah,
          verseNumber: verse,
          surahName: _surahListSource.getSurahNameArabic(surah),
          verseText: verseText,
          normalizedText: normalizedText,
          normalizedWords: _tokenizeNormalizedText(normalizedText),
        );
      }(),
];

Map<String, List<_VerseSearchIndexEntry>> _buildVerseWordIndex() {
  final index = <String, List<_VerseSearchIndexEntry>>{};
  for (final entry in _verseSearchCache) {
    for (final word in entry.normalizedWords.toSet()) {
      index.putIfAbsent(word, () => []).add(entry);
    }
  }
  return index;
}

final Map<String, List<_VerseSearchIndexEntry>> _verseWordIndex =
    _buildVerseWordIndex();

List<_VerseSearchIndexEntry> _findVerseMatches(String normalizedQuery) {
  final tokens = _tokenizeNormalizedText(normalizedQuery);
  if (tokens.isEmpty) {
    return const [];
  }

  final candidateMap = <String, _VerseSearchIndexEntry>{};

  for (final token in tokens) {
    final direct = _verseWordIndex[token];
    if (direct != null) {
      for (final entry in direct) {
        candidateMap['${entry.surahNumber}:${entry.verseNumber}'] = entry;
      }
    }

    for (final indexedWord in _verseWordIndex.keys) {
      if (indexedWord.contains(token) || token.contains(indexedWord)) {
        for (final entry in _verseWordIndex[indexedWord]!) {
          candidateMap['${entry.surahNumber}:${entry.verseNumber}'] = entry;
        }
      }
    }
  }

  final source = candidateMap.isEmpty
      ? _verseSearchCache
      : candidateMap.values.toList();

  final results = source.where((entry) {
    return tokens.every((token) {
      return entry.normalizedText.contains(token) ||
          entry.normalizedWords.any((word) => word.contains(token));
    });
  }).toList();

  int score(_VerseSearchIndexEntry entry) {
    var total = 0;
    if (entry.normalizedText.contains(normalizedQuery)) {
      total += 10;
    }
    if (entry.normalizedText.startsWith(normalizedQuery)) {
      total += 6;
    }
    for (final token in tokens) {
      if (entry.normalizedWords.contains(token)) {
        total += 4;
      } else if (entry.normalizedText.contains(token)) {
        total += 2;
      }
    }
    return total;
  }

  results.sort((a, b) {
    final scoreCompare = score(b).compareTo(score(a));
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    final surahCompare = a.surahNumber.compareTo(b.surahNumber);
    if (surahCompare != 0) {
      return surahCompare;
    }
    return a.verseNumber.compareTo(b.verseNumber);
  });

  return results.take(250).toList();
}

class SurahListPage extends StatefulWidget {
  const SurahListPage({
    super.key,
    required this.store,
    this.initialSurahNumber,
  });

  final QuranStore store;
  final int? initialSurahNumber;

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController;
  final Map<int, GlobalKey> _surahKeys = {};
  String _query = '';
  bool _initialJumpDone = false;
  int _initialJumpAttempts = 0;
  static const int _maxInitialJumpAttempts = 12;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _estimatedInitialOffsetForSurah(
        widget.initialSurahNumber,
      ),
    );
    for (var surah = 1; surah <= currentQuranTotalSurahCount; surah++) {
      _surahKeys[surah] = GlobalKey();
    }
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialSurah());
  }

  @override
  void didUpdateWidget(covariant SurahListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSurahNumber != widget.initialSurahNumber) {
      _initialJumpDone = false;
      _initialJumpAttempts = 0;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jumpToInitialSurah(),
      );
    }
  }

  double _estimatedInitialOffsetForSurah(int? surahNumber) {
    if (surahNumber == null || surahNumber <= 1) {
      return 0;
    }
    const headerExtent = 190.0;
    const tileExtent = 108.0;
    final index = surahNumber - 1;
    return headerExtent + (index * tileExtent);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<int> get _filteredSurahs {
    final normalizedQuery = _query.toLowerCase();
    return List<int>.generate(
      currentQuranTotalSurahCount,
      (index) => index + 1,
    ).where((surahNumber) {
      if (normalizedQuery.isEmpty) {
        return true;
      }

      final arabic = _surahListSource.getSurahNameArabic(surahNumber);
      final english = _surahListSource
          .getSurahNameEnglish(surahNumber)
          .toLowerCase();
      return arabic.contains(_query) ||
          english.contains(normalizedQuery) ||
          surahNumber.toString().contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth > 920
        ? ((screenWidth - 920) / 2) + 20
        : 20.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0D1417), Color(0xFF101A1E)]
              : const [Color(0xFFE9DFC5), Color(0xFFF7F1E3)],
        ),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '\u0627\u0644\u0642\u0631\u0622\u0646 \u0627\u0644\u0643\u0631\u064a\u0645',
                                style: theme.textTheme.headlineMedium,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _openVerseSearch,
                              icon: const Icon(Icons.search_rounded, size: 18),
                              label: const Text('بحث'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 4),
                        _HeroPanel(store: widget.store),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText:
                                '\u0627\u0628\u062d\u062b \u0628\u0627\u0633\u0645 \u0627\u0644\u0633\u0648\u0631\u0629 \u0623\u0648 \u0631\u0642\u0645\u0647\u0627',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    24,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _filteredSurahs.length,
                    itemBuilder: (context, index) {
                      final surahNumber = _filteredSurahs[index];
                      final verseCount = _surahListSource.getVerseCount(
                        surahNumber,
                      );
                      final place = _surahListSource.getPlaceOfRevelationArabic(
                        surahNumber,
                      );
                      final pages = _surahListSource.getSurahPages(surahNumber);

                      return _SurahTile(
                        key: _surahKeys.putIfAbsent(surahNumber, GlobalKey.new),
                        surahNumber: surahNumber,
                        title: _surahListSource.getSurahNameArabic(surahNumber),
                        subtitle:
                            '$place \u2022 ${toArabicNumber(verseCount)} \u0622\u064a\u0629 \u2022 \u0635 ${toArabicNumber(pages.first)} - ${toArabicNumber(pages.last)}',
                        onTap: () => _openReader(
                          surahNumber: surahNumber,
                          initialVerse: 1,
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openReader({
    required int surahNumber,
    required int initialVerse,
    String? highlightQuery,
    double? initialAlignment,
    bool replace = true,
  }) async {
    final route = MaterialPageRoute<void>(
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ReaderPage(
          store: widget.store,
          surahNumber: surahNumber,
          initialVerse: initialVerse,
          highlightQuery: highlightQuery,
          initialVerseAlignment: initialAlignment ?? 0.18,
        ),
      ),
    );
    if (replace) {
      await Navigator.of(context).pushReplacement(route);
      return;
    }
    await Navigator.of(context).push(route);
  }

  Future<void> _openReaderFromSearch({
    required int surahNumber,
    required int initialVerse,
    String? highlightQuery,
    double? initialAlignment,
  }) async {
    await _openReader(
      surahNumber: surahNumber,
      initialVerse: initialVerse,
      highlightQuery: highlightQuery,
      initialAlignment: initialAlignment,
      replace: false,
    );
  }

  Future<void> _openVerseSearch() async {
    await showSearch<_VerseSearchHit?>(
      context: context,
      delegate: _QuranVerseSearchDelegate(
        onOpenResult: (result, query) => _openReaderFromSearch(
          surahNumber: result.surahNumber,
          initialVerse: result.verseNumber,
          highlightQuery: query,
          initialAlignment: 0.5,
        ),
      ),
    );
  }

  void _jumpToInitialSurah() {
    if (_initialJumpDone) {
      return;
    }
    final target = widget.initialSurahNumber;
    if (target == null || !_scrollController.hasClients) {
      return;
    }
    if (target < 1 || target > currentQuranTotalSurahCount) {
      _initialJumpDone = true;
      return;
    }
    final targetContext = _surahKeys[target]?.currentContext;
    if (targetContext == null) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      final ratio =
          (target - 1) / (currentQuranTotalSurahCount - 1).clamp(1, 1000);
      final estimatedOffset = maxExtent * ratio.clamp(0.0, 1.0);
      _scrollController.jumpTo(estimatedOffset.clamp(0.0, maxExtent));
      _initialJumpAttempts++;
      if (_initialJumpAttempts >= _maxInitialJumpAttempts) {
        // Stop forcing scroll so user interaction does not feel blocked.
        _initialJumpDone = true;
        return;
      }
      Future<void>.delayed(
        const Duration(milliseconds: 80),
        _jumpToInitialSurah,
      );
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.24,
      duration: Duration.zero,
    );
    _initialJumpDone = true;
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (mounted && targetContext.mounted) {
        Scrollable.ensureVisible(
          targetContext,
          alignment: 0.24,
          duration: Duration.zero,
        );
      }
    });
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.store});

  final QuranStore store;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lastRead = store.lastRead;
    final canResume = lastRead != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? const [Color(0xFF16262D), Color(0xFF21414C)]
              : const [Color(0xFF143A2A), Color(0xFF2F6A53)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (canResume)
                  Expanded(
                    child: Column(
                      children: [
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            foregroundColor: const Color(0xFF143A2A),
                            backgroundColor: const Color(0xFFF8E7AF),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: ReaderPage(
                                    store: store,
                                    surahNumber: lastRead.surahNumber,
                                    initialVerse: lastRead.verseNumber,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text('متابعة القراءة'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${lastRead.surahName} \u2022 \u0627\u0644\u0622\u064a\u0629 ${toArabicNumber(lastRead.verseNumber)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u0635\u0641\u062d\u0629 ${toArabicNumber(lastRead.pageNumber)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (canResume) const SizedBox(width: 10),
                Expanded(
                  child: canResume
                      ? Column(
                          children: [
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                foregroundColor: const Color(0xFF143A2A),
                                backgroundColor: const Color(0xFFF8E7AF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const _QuranInfoPage(),
                                  ),
                                );
                              },
                              child: const Text('معلومات عن القرآن'),
                            ),
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.menu_book,
                              color: Colors.white,
                              size: 50,
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.center,
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            child: Column(
                              children: [
                                FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    foregroundColor: const Color(0xFF143A2A),
                                    backgroundColor: const Color(0xFFF8E7AF),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const _QuranInfoPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('معلومات عن القرآن'),
                                ),
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.menu_book,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranInfoPage extends StatelessWidget {
  const _QuranInfoPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: isDark ? const Color(0xFFF2ECDF) : const Color(0xFF143A2A),
    );
    final bodyStyle = TextStyle(
      fontSize: 16,
      height: 1.7,
      color: isDark ? const Color(0xFFD4CEC1) : const Color(0xFF4B3A24),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('معلومات عن القرآن')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('معلومات عن القرآن', style: titleStyle),
                const SizedBox(height: 10),
                Text('''عدد سور القرآن الكريم = 114 سورة .
- عدد آيات القرآن الكريم = 6.236 آية .
- عدد أجزاء القرآن الكريم = 30 جزءاً .
- عدد أحزاب القرآن الكريم = 60 حزباً .
- عدد نقاط القرآن الكريم = 1.015.030 نقطة تقريباً .
- عدد حروف القرآن الكريم = 323.670 حرف .
- عدد كلمات القرآن الكريم = 77.934 كلمة .
- عدد سور القرآن الكريم = 87 منها مكية و27 منها مدنية .
- عدد مرات ورود لفظ الجلالة في القرآن الكريم = 2.707 مرة .. في حالة الرفع = 980 حالة .. وفي حالة النصب = 592 حالة .. وفي حالة الجر = 1.135 حالة .
- السورة التي لا تبدأ بالبسملة = سورة التوبة .
- السورة التي فيها بسملتان = سورة النمل .
- عدد السور التي تحمل أسماء أنبياء = 7 سور .. وهي (يونس / هود / يوسف / إبراهيم / طه / محمد / نوح)
- أطول سورة في القرآن الكريم = سورة البقرة .. عدد آياتها = 286 آية .
- أقصر سورة في القرآن الكريم = سورة الكوثر .. عدد آياتها = 3 آيات .
- أول سورة في القرآن الكريم = سورة الفاتحة .
- آخر سورة في القرآن الكريم = سورة الناس .
- أول سورة نزلت على النبي صلى الله عليه وسلم = سورة العلق .
- آخر سورة نزلت على النبي صلى الله عليه وسلم = سورة النصر .
- الكلمة التي تتوسط القرآن الكريم هي = وليتلطّف .. وحرف "التاء" فيها تتوسط حروفها .
- عدد أسماء سورة الفاتحة = 20 اسم .. ومنها (الفاتحة / أم الكتاب / السبع المثاني / الكنز / الوافية / الكافية / الشافية وغير ذلك... )
- أقصر آية في القرآن الكريم = يس في سورة يس - وقيل = مدهامتان في سورة الرحمن .
- أطول آية في القرآن الكريم = الثانية والثمانون بعد المائتين من سورة البقرة .
- عدد السور التي بدأت بحروف مقطعة = 29 سورة .
- عدد السور التي بدأت (الحمد لـ...) = 5 سور .. وهي (الفاتحة / الأنعام / الكهف / سبأ / فاطر)
- عدد السور التي بدأت بـ(سبح / يسبح / سبحان) = 7 سور .. وهي (الإسراء / الأعلى / التغابن / الجمعة / الصف / الحشر / الحديد)
- عدد السور التي بدأت بـ﴿يا أيّها النبي﴾ = 3 سور .. وهي (الأحزاب / الطلاق / التحريم)
- عدد السور التي بدأت بـ﴿يا أيّها المزمّل﴾ و ﴿يا أيّها المدثّر﴾ = سورتان .. وهما (المزمل / المدثر)
- عدد السور التي بدأت بـ﴿يا أيّها الذين آمنوا﴾ = 3 سور .. وهي (المائدة / الحجرات / الممتحنة )
- عدد السور التي بدأت بـ﴿قل﴾ = 5 سور .. وهي (الجن / الكافرون / الإخلاص / الفلق / الناس)
- عدد السور التي بدأت بـ﴿يا أيّها الناس﴾ = سورتان .. وهما (النساء / الحج)
- عدد السور التي بدأت بـ﴿إنّا﴾ = 4 سور .. وهي (الفتح / نوح / القدر / الكوثر)
- عدد السور التي بدأت بـصيغة القسم = 15 سورة .. وهي (الذاريات / الطور / النجم / المرسلات / النازعات / البروج / الطارق / الفجر / الشمس / الليل / الضحى / التين / العاديات / العصر / الصافات)
- عدد السور التي تحتوي على سجدة = 15 سورة .. وهي (فصلت / السجدة / النجم / العلق /الأعراف / النحل / مريم / الحج (سجدتان) / النّمل / الانشقاق / الرّعد / الإسراء / الفرقان / ص)
أسماء القرآن الكريم :
(الفرقان / الكتاب / النور / التنزيل / الكلام / الحديث / الموعظة / الهادي / الحق / البيان / المنير / الشفاء / العظيم / الكريم / المجيد / العزيز / النعمة / الرحمة / الروح / الحبل / القصص / المهيمن / الحكم / الذّكر / السراج / البشير / النذير / التبيان / العدل / المنادي / الشافي / الذكرى / الحكيم) .
وقالوا أسماء أخرى للقرآن الكريم منها (الميزان / أحسن الحديث / الكتاب المتشابه / المثاني / حق اليقين / التذكرة / الكتاب الحكيم / القيم / أبلغ الوعّاظ) .
القصص القرآنية :
أشار القرآن الكريم إلى قصص الأنبياء عليهم السلام وأقوامهم بهدف العبرة والعظة .. وقد ذكر الكتاب العزيز أسماء = 25 نبياً مع قصصهم وهم : 
(محمد / آدم / إبراهيم / إسماعيل / إلياس / إدريس / أيوب / عيسى / موسى / نوح / لوط / يوسف / يعقوب / يوشع / هود / يونس / صالح / شعيب / داوود / يحيى / زكريا / ذو الكفل / سليمان / هارون / إسماعيل) . 
وصف القرآن الكريم :
- سورة البقرة = ﴿هدىً للمتقين﴾ الآية (2) .
- سورة البقرة = ﴿قل من كانَ عدواً لجبريلَ فإنّه نزّله على قلبَك بإذن الله مصدّقاً لما بين يديه وهدىً وبشرى للمؤمنين﴾ الآية (97) .
- سورة آل عمران = ﴿هذا بيانٌ للناس وهدىً وموعظةٌ للمتقين﴾ الآية (138) .
- سورة إبراهيم = ﴿آلر كتاب أنزلناهُ إليك لتخرجَ النّاس من الظّلمات إلى النّور بإذن ربهمْ إلى صراط العزيز الحميد﴾ الآية (1) . 
- سورة طه = ﴿طه . ما أنزلنا عليك القرآن لتشقى إلاّ تذكرةً لمن يخشى﴾ الآيات (1-3) .
- سورة القلم = ﴿وما هو إلا ذكر للعالمين﴾ الآية الأخيرة .
- سورة الزمر = ﴿اللهُ نزّلَ أحسنَ الحديث كتاباً متشابهاً مثانيَ تقشعرّ منهُ جُلود الذين يخشونَ ربّهم ثم تلين جلودُهُم وقلوبهُم إلى ذكر الله ذلك هدى الله يهدي به من يشاءُ ومن يُضلل اللهُ فما لهُ من هاد﴾ الآية (23) . 
- سورة يونس = ﴿قلْ بفضلِ اللهِ وبرحمته فبذلك فليفرحوا هو خيرٌ مما يَجمعون﴾ الآية (58) . 
- سورة فصلت = ﴿ولو جعلناه قرآناً أعجمياً لقالوا لولا فُصّلت آياته أأعجمي وعربي قل هو للذينَ آمنوا هدىً وشفاء﴾ الآية (44) .
المواضيع القرآنية وآيات القرآن الكريم :
تناول القرآن الكريم في آياته الشريفة مواضيع كثيرة ، وقد توصلت بعض الإحصاءات إلى تصنيف المواضيع في الآيات على الشكل التالي : 
- العقائد = 1.443 آية .
- التوحيد = 1.102 آية .
- التوراة = 1.025 آية .
- العبادات = 4.110 آية .
- النظام الاجتماعي = 848 آية .
- الدين = 826 آية .
- تهذيب الأخلاق = 803 آية . 
- تتحدث عن سيدنا محمد صلى الله عليه وسلم = 405 آية .
- التبليغ = 400 آية .
- القرآن الكريم = 390 آية .
- ما وراء الطبيعة = 219 آية .
- النصارى = 161 آية .
- بني إسرائيل = 110 آية .
- النصر = 71 آية . 
- الشريعة = 29 آية .
- التاريخ = 27 آية .
- التجارب = 9 آيات .
أسماء الحيوانات الواردة في القرآن الكريم :
(البعير / البقر / الثعبان / الجراد / الجوارح / الحمولة / الحية / الخنازير / القردَة / القمّل / المعز / الناقة / النحل / الهدهد / الأبابيل / الأنعام / البحيرة / البعوضة / الدابّة / الذباب / الصافنات / الطائر / البغال / الجمال / الجياد / الحمار / الحوت / الفيل / القسورة / الكلب / الموريات / النعجة / النمل / الوسيلة / الإبل / البُدن / الخيل / الذئب / دابّة الأرض / السائبة / الضأن / العاديات / العجل / العشار / الغنم / العرم / العنكبوت / الغراب / الفراش) .
أسماء الملابس في القرآن الكريم :
(الإستبرق / الثياب / الحرير / السندس / القميص / الجلابيب / العبقري / كسوة ) .
أسماء السّلع في القرآن الكريم :
(الآنية / الأثاث / الأقلام / الأوتاد / الجفان / الخياط / الدِّهان / السراج / السرُر / صحاف / الفخّار / القدور / القلائد / الكأس / المسد / المهد / الموازين / الأباريق / الأقفال / الأكواب / الأوعية / الجواب / الدّلو / الرّفرف / السرادق / السُّلّم / الصواع / العصا / الغطاء / الفراش / القسطاس / القوارير / الكرسي / الماعون / المصباح / المنسأة / النمارق) .
أسماء أعضاء بدن الإنسان في القرآن الكريم :
(الآذان / الأذقان / الأرحام / الأصلاب / الأعناق / الأفئدة / الأمعاء / الأنف / البدن / البنان / الجلود / حبل الوريد / الحناجر / الدم / الرأس / السوءات / الأصابع / الصدر / الظهر / العطف / القلب / اللحم / المضغة / الوتين / الأرجل / الأخاب / الأعين / الأفواه / الأنامل / الأيدي / البطن / الجيد / الحلقوم / الخُرطوم / الرّقاب / الظفر / العضد / العظام / العُتق / الشّفة / الكعبين / الوريد ) .
أسماء الألوان في القرآن الكريم:
(الأبيض / الأخضر / الأحوى (الأسود المائل للخضرة) / الأسود / الأصفر / مدهامتان (الأخضر القريب من السواد)) . 
أسماء وصفات الرسول صلى الله عليه وسلم في القرآن الكريم :
(أحمد / الأمين / أول المؤمنين / أول المسلمين / أول العابدين / البرهان / البشير / خاتم النبيين / داعياً إلى الله / رحمة للعالمين / رحيم / رسول / رسول الله / رسول أمين / رسول مبين / رسول كريم / رؤوف / سراجاً منيراً / شاهد / شهيد / صاحب / طه / عبد الله / مبشّر / محمد / المدثِّر / المزمِّل / مذكّر / منذر / ناصح أمين / النبي / النبي الأمي / نذير / النذير المبين / وليّ / يس ) .
بعض أسماء وصفات يوم القيامة في القرآن الكريم :
(الآخرة / الخافضة / الحاقّة / الرّاجفة / الرّادفة / الرّافعة / الساعة / الصاخّة / الغاشية / القارعة / المعاد / الواقعة / اليوم الآخر / يوم البعث / يوم تُبلى السرائر / يوم التغابن / يوم التّلاق / يوم الجمع / يوم الحساب / يوم الحسرة / يوم الحق / يوم الخروج / يوم الخلود / يوم الدين / يوم عسير / يوم عظيم / يوم عقيم / يوم الفتح / يوم الفصل / يوم القيامة / يوم كبير / يوم محيط / يوم مشهود / يوم معلوم / يوم موعود / يوم الوعيد / يوم الجزاء / يوم النّدامة / يوم الشهادة / يوم النشور / يوم لا ينفع مال ولا بنون إلا من أتى الله بقلب سليم) .
بعض أسماء وأنواع الجنان في القرآن الكريم :
(جنات عدن / جنات الفردوس / جنّات المأوى / جنات النعيم / جنّة الخلد / جنة عالية / دار السلام / دار القرار / دار المتقين / دار المقامة / روضات الجنّات / الدار الآخرة / الحسنى / الفضل) .
بعض أسماء وألقاب جهنم في القرآن الكريم :
(الهاوية / الشّوى / اللظى / النار / السموم / الساهرة / الحُطمة / الجحيم / بئس المصير / بئس القرار / بئس المهاد / بئس الورد المورود / جهنّم / الحافرة / دار البوار / دار الفاسقينَ / السّقر / السّعير / سوء الدار) .
أسماء الملائكة المصرّح بها في القرآن الكريم :
(جبريل (روح الأمين)/ ميكال / مالك) .''', style: bodyStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    super.key,
    required this.surahNumber,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int surahNumber;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF152127) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF143A2A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  toArabicNumber(surahNumber),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'SurahNames-font',
                        fontSize: 22,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: isDark ? const Color(0xFFD4CEC1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseSearchHit {
  const _VerseSearchHit({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
    required this.verseText,
  });

  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final String verseText;
}

class _QuranVerseSearchDelegate extends SearchDelegate<_VerseSearchHit?> {
  _QuranVerseSearchDelegate({required this.onOpenResult});

  final Future<void> Function(_VerseSearchHit result, String query)
  onOpenResult;

  @override
  String get searchFieldLabel => 'اكتب كلمه لبدء البحث';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.close_rounded),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => _SearchResults(
    query: query,
    onOpenResult: (result) async {
      await onOpenResult(result, query);
    },
  );

  @override
  Widget buildResults(BuildContext context) => _SearchResults(
    query: query,
    onOpenResult: (result) async {
      await onOpenResult(result, query);
    },
  );
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.query, required this.onOpenResult});

  final String query;
  final Future<void> Function(_VerseSearchHit result) onOpenResult;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalizeArabic(query);
    if (normalizedQuery.isEmpty) {
      return const Center(
        child: Text(
          '\u0627\u0643\u062a\u0628 \u0627\u0644\u0643\u0644\u0645\u0629 \u0623\u0648 \u0627\u0644\u0639\u0628\u0627\u0631\u0629 \u0644\u0644\u0628\u062f\u0621',
        ),
      );
    }

    final matches = _findVerseMatches(normalizedQuery)
        .map(
          (entry) => _VerseSearchHit(
            surahNumber: entry.surahNumber,
            verseNumber: entry.verseNumber,
            surahName: entry.surahName,
            verseText: entry.verseText,
          ),
        )
        .toList();

    if (matches.isEmpty) {
      return const Center(
        child: Text(
          '\u0644\u0645 \u064a\u062a\u0645 \u0627\u0644\u0639\u062b\u0648\u0631 \u0639\u0644\u0649 \u0646\u062a\u0627\u0626\u062c',
        ),
      );
    }

    final groupedMatches = <int, List<_VerseSearchHit>>{};
    for (final match in matches) {
      groupedMatches.putIfAbsent(match.surahNumber, () => []).add(match);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      itemCount: groupedMatches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final surahNumber = groupedMatches.keys.elementAt(index);
        final surahMatches = groupedMatches[surahNumber]!;
        final surahName = surahMatches.first.surahName;

        return Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF152127)
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surahName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                for (final result in surahMatches) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onOpenResult(result),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toArabicNumber(result.verseNumber),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.justify,
                              textWidthBasis: TextWidthBasis.parent,
                              softWrap: true,
                              text: _highlightedSearchSnippet(
                                context,
                                _searchSnippet(
                                  _displayVerseText(result),
                                  query,
                                ),
                                query,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (result != surahMatches.last)
                    const Divider(height: 8, thickness: 0.6),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String _normalizeArabic(String input) {
  const diacriticsPattern = r'[\u064B-\u065F\u0670\u06D6-\u06ED]';
  return input
      .replaceAll(RegExp(diacriticsPattern), '')
      .replaceAll(RegExp(r'[^\u0600-\u06FF0-9\s]'), ' ')
      .replaceAll('\u0671', '\u0627')
      .replaceAll('\u0623', '\u0627')
      .replaceAll('\u0625', '\u0627')
      .replaceAll('\u0622', '\u0627')
      .replaceAll('\u0649', '\u064a')
      .replaceAll('\u0624', '\u0648')
      .replaceAll('\u0626', '\u064a')
      .replaceAll('\u0629', '\u0647')
      .replaceAll('\u0640', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _tokenizeNormalizedText(String text) => text
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty && word.length > 1)
    .toList();

String _searchSnippet(String verseText, String query) {
  final words = verseText.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) {
    return verseText;
  }

  final normalizedQuery = _normalizeArabic(query);
  var start = 0;
  for (var i = 0; i < words.length; i++) {
    if (_normalizeArabic(words[i]).contains(normalizedQuery)) {
      start = (i - 1).clamp(0, words.length - 1);
      break;
    }
  }

  final end = (start + 7).clamp(0, words.length);
  return words.sublist(start, end).join(' ');
}

String _displayVerseText(_VerseSearchHit hit) {
  try {
    final legacy = legacy_quran.getVerse(
      hit.surahNumber,
      hit.verseNumber,
      verseEndSymbol: false,
    );
    if (legacy.isNotEmpty) {
      return _normalizeDisplaySpacing(legacy);
    }
  } catch (_) {}
  return _normalizeDisplaySpacing(hit.verseText);
}

String _normalizeDisplaySpacing(String text) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return normalized;
  }
  final words = normalized.split(' ');
  if (words.length <= 1) {
    return normalized;
  }
  // Break joining at word boundaries to avoid ligature-stuck words.
  return words.map((word) => '\u200C$word\u200C').join(' ');
}

TextSpan _highlightedSearchSnippet(
  BuildContext context,
  String verseText,
  String query,
) {
  final baseStyle =
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 17,
        height: 1.8,
        wordSpacing: 1.0,
        letterSpacing: 0.0,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE0DBD1)
            : const Color(0xFF213128),
      ) ??
      TextStyle(
        fontSize: 17,
        height: 1.8,
        wordSpacing: 1.0,
        letterSpacing: 0.0,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFE0DBD1)
            : const Color(0xFF213128),
      );
  final highlightStyle = baseStyle.copyWith(
    backgroundColor: const Color(0xFFF6E3A8),
    fontWeight: FontWeight.w800,
    color: const Color(0xFF143A2A),
  );

  final normalizedQuery = _normalizeArabic(query);
  if (normalizedQuery.isEmpty) {
    return TextSpan(text: verseText, style: baseStyle);
  }

  final words = verseText.split(RegExp(r'(\s+)'));
  final spans = <InlineSpan>[];
  for (final part in words) {
    if (part.trim().isEmpty) {
      spans.add(TextSpan(text: part, style: baseStyle));
      continue;
    }
    final style = _normalizeArabic(part).contains(normalizedQuery)
        ? highlightStyle
        : baseStyle;
    spans.add(TextSpan(text: part, style: style));
  }
  return TextSpan(children: spans, style: baseStyle);
}
