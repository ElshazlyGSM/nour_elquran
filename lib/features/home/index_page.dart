import 'package:flutter/material.dart';

import '../../core/utils/arabic_numbers.dart';
import '../../models/reading_reference.dart';
import '../../services/quran_store.dart';
import '../reader/reader_page.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key, required this.store, this.initialJuzNumber});

  final QuranStore store;
  final int? initialJuzNumber;

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الأجزاء', style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
              Expanded(
                child: _ReferenceList(
                  references: _buildJuzReferences(),
                  store: widget.store,
                  initialIndex: (widget.initialJuzNumber ?? 1) - 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceList extends StatefulWidget {
  const _ReferenceList({
    required this.references,
    required this.store,
    this.initialIndex,
  });

  final List<ReadingReference> references;
  final QuranStore store;
  final int? initialIndex;

  @override
  State<_ReferenceList> createState() => _ReferenceListState();
}

class _ReferenceListState extends State<_ReferenceList> {
  late final ScrollController _scrollController;
  final Map<int, GlobalKey> _itemKeys = {};
  bool _initialJumpDone = false;
  int _initialJumpAttempts = 0;
  static const int _maxInitialJumpAttempts = 12;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _estimatedInitialOffset(widget.initialIndex),
    );
    for (var index = 0; index < widget.references.length; index++) {
      _itemKeys[index] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialIndex());
  }

  @override
  void didUpdateWidget(covariant _ReferenceList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _initialJumpDone = false;
      _initialJumpAttempts = 0;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jumpToInitialIndex(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToInitialIndex() {
    if (_initialJumpDone) {
      return;
    }
    final target = widget.initialIndex;
    if (target == null || !_scrollController.hasClients) {
      return;
    }
    if (target < 0 || target >= widget.references.length) {
      _initialJumpDone = true;
      return;
    }
    final targetContext = _itemKeys[target]?.currentContext;
    if (targetContext == null) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      final ratio = target / (widget.references.length - 1).clamp(1, 1000);
      final estimatedOffset = maxExtent * ratio.clamp(0.0, 1.0);
      _scrollController.jumpTo(estimatedOffset.clamp(0.0, maxExtent));
      _initialJumpAttempts++;
      if (_initialJumpAttempts >= _maxInitialJumpAttempts) {
        _initialJumpDone = true;
        return;
      }
      Future<void>.delayed(
        const Duration(milliseconds: 80),
        _jumpToInitialIndex,
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

  double _estimatedInitialOffset(int? index) {
    if (index == null || index <= 0) {
      return 0;
    }
    const tileExtent = 102.0;
    return index * tileExtent;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: widget.references.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final reference = widget.references[index];

        return Card(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF152127)
              : null,
          key: _itemKeys.putIfAbsent(index, GlobalKey.new),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: ReaderPage(
                      store: widget.store,
                      surahNumber: reference.surahNumber,
                      initialVerse: reference.verseNumber,
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                      toArabicNumber(reference.index),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reference.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontFamily: 'Ajzaa-ALQuran-font',
                                fontSize: 28,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reference.startLabel} \u2022 \u0635\u0641\u062d\u0629 ${toArabicNumber(reference.pageNumber)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFD4CEC1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

List<ReadingReference> _buildJuzReferences() {
  final references = <ReadingReference>[];
  for (var juzNumber = 1; juzNumber <= 30; juzNumber++) {
    final verses = readingReferenceQuranSource.getSurahAndVersesFromJuz(
      juzNumber,
    );
    final firstSurah = verses.keys.first;
    final firstVerse = verses[firstSurah]!.first;
    references.add(JuzReference(juzNumber, firstSurah, firstVerse));
  }
  return references;
}
