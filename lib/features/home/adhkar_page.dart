import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../core/utils/arabic_numbers.dart';
import '../../data/adhkar_data.dart';
import '../../services/quran_store.dart';
import '../reader/reader_page.dart';
import '../shared/khatm_quran_doa_page.dart';

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key, this.store});

  final QuranStore? store;

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  final Map<String, int> _remainingByKey = <String, int>{};
  final Map<String, GlobalKey> _tileKeys = <String, GlobalKey>{};
  final Set<String> _justCompletedKeys = <String>{};

  String _itemKey(int sectionIndex, int itemIndex) =>
      '$sectionIndex:$itemIndex';

  GlobalKey _tileKeyFor(int sectionIndex, int itemIndex) {
    final key = _itemKey(sectionIndex, itemIndex);
    return _tileKeys.putIfAbsent(key, GlobalKey.new);
  }

  int _remainingFor(int sectionIndex, int itemIndex, DhikrData item) {
    return _remainingByKey[_itemKey(sectionIndex, itemIndex)] ??
        (item.repeat ?? 0);
  }

  bool _isJustCompleted(int sectionIndex, int itemIndex) {
    return _justCompletedKeys.contains(_itemKey(sectionIndex, itemIndex));
  }

  void _decrementRemaining(int sectionIndex, int itemIndex, DhikrData item) {
    if (item.repeat == null || item.repeat == 0) {
      return;
    }
    final key = _itemKey(sectionIndex, itemIndex);
    final current = _remainingByKey[key] ?? item.repeat!;
    if (current == 0) {
      return;
    }
    final nextRemaining = current - 1;
    setState(() {
      _remainingByKey[key] = nextRemaining;
    });

    if (nextRemaining == 0) {
      _handleItemCompletion(sectionIndex, itemIndex);
    }
  }

  Future<void> _handleItemCompletion(int sectionIndex, int itemIndex) async {
    final key = _itemKey(sectionIndex, itemIndex);
    final canVibrate = await Vibration.hasVibrator();
    if (canVibrate == true) {
      await Vibration.vibrate(duration: 50, amplitude: 90);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _justCompletedKeys.add(key);
    });

    await Future<void>.delayed(const Duration(milliseconds: 420));

    if (!mounted) {
      return;
    }

    setState(() {
      _justCompletedKeys.remove(key);
    });

    _moveToNextItem(sectionIndex, itemIndex);
  }

  void _moveToNextItem(int sectionIndex, int itemIndex) {
    final section = adhkarSections[sectionIndex];
    final nextItemIndex = itemIndex + 1;
    if (nextItemIndex >= section.items.length) {
      return;
    }

    final nextKey = _tileKeyFor(sectionIndex, nextItemIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nextContext = nextKey.currentContext;
      if (nextContext == null || !mounted) {
        return;
      }
      Scrollable.ensureVisible(
        nextContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: adhkarSections.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأذكار'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: isDark ? const Color(0xFFF7F1E4) : Colors.white,
            unselectedLabelColor:
                (isDark ? const Color(0xFFF7F1E4) : Colors.white).withValues(
                  alpha: 0.72,
                ),
            indicatorColor: const Color(0xFFE6C16A),
            tabs: [
              for (final section in adhkarSections)
                Tab(icon: Icon(section.icon, size: 18), text: section.title),
              const Tab(text: 'دعاء ختم القرآن'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (
              var sectionIndex = 0;
              sectionIndex < adhkarSections.length;
              sectionIndex++
            )
              ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                itemCount: adhkarSections[sectionIndex].items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, itemIndex) {
                  final item = adhkarSections[sectionIndex].items[itemIndex];
                  return _DhikrTile(
                    key: _tileKeyFor(sectionIndex, itemIndex),
                    item: item,
                    store: widget.store,
                    remaining: _remainingFor(sectionIndex, itemIndex, item),
                    highlightCompleted: _isJustCompleted(sectionIndex, itemIndex),
                    onTap: () =>
                        _decrementRemaining(sectionIndex, itemIndex, item),
                  );
                },
              ),
            const _KhatmQuranDoaTab(),
          ],
        ),
      ),
    );
  }
}

class _KhatmQuranDoaTab extends StatelessWidget {
  const _KhatmQuranDoaTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152127) : const Color(0xFFF9F6EE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF26343B) : const Color(0xFFE6D8B7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                KhatmQuranDoaPage.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFFF2ECDF)
                      : const Color(0xFF143A2A),
                ),
              ),
              const SizedBox(height: 16),
              for (final paragraph in KhatmQuranDoaPage.paragraphs) ...[
                Text(
                  paragraph,
                  style: TextStyle(
                    fontSize: 18,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Color(0xFFD7D2C9) : Color(0xFF1E241F),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DhikrTile extends StatelessWidget {
  const _DhikrTile({
    super.key,
    required this.item,
    required this.store,
    required this.remaining,
    required this.highlightCompleted,
    required this.onTap,
  });

  final DhikrData item;
  final QuranStore? store;
  final int remaining;
  final bool highlightCompleted;
  final VoidCallback onTap;

  Future<void> _openTargetSurah(BuildContext context) async {
    final surahNumber = item.targetSurahNumber;
    final activeStore = store;
    if (surahNumber == null || activeStore == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: ReaderPage(
            store: activeStore,
            surahNumber: surahNumber,
            initialVerse: item.targetVerseNumber,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasRepeat = item.repeat != null && item.repeat! > 0;
    final completed = hasRepeat && remaining == 0;
    final showCompletionHighlight = completed || highlightCompleted;
    final baseCardColor = showCompletionHighlight
        ? (isDark ? const Color(0xFF1F352B) : const Color(0xFFE7F3EB))
        : (isDark ? const Color(0xFF152127) : const Color(0xFFF9F6EE));
    final baseBorderColor = showCompletionHighlight
        ? const Color(0xFF4F8E6A)
        : (isDark ? const Color(0xFF26343B) : const Color(0xFFE8DEC7));
    final dhikrPanelColor = showCompletionHighlight
        ? (isDark ? const Color(0xFF274637) : const Color(0xFFDFF0E4))
        : (isDark ? const Color(0xFF1E2D34) : const Color(0xFFCDE7DC));
    final dhikrBorderColor = showCompletionHighlight
        ? const Color(0xFF70B48C)
        : (isDark ? const Color(0xFF3C5C67) : const Color(0xFFCBE4D3));
    final dhikrTextColor = isDark
        ? const Color(0xFFF7F1E4)
        : const Color(0xFF143A2A);
    final secondaryTextColor = isDark
        ? const Color(0xFFA8A398)
        : const Color(0xFF8B877D);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: baseCardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: baseBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.note != null) ...[
              Text(
                item.note!,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: dhikrPanelColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dhikrBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.12)
                        : const Color(0xFF143A2A).withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  fontWeight: FontWeight.w900,
                  color: dhikrTextColor,
                ),
              ),
            ),
            if (item.targetSurahNumber != null && store != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openTargetSurah(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF143A2A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(
                    item.targetActionLabel ?? 'فتح في المصحف',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            if (hasRepeat) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(158, 85, 204, 158),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'التكرار ${toArabicNumber(item.repeat!)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFF2ECDF)
                            : const Color(0xFF143A2A),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    completed ? 'تم' : 'المتبقي ${toArabicNumber(remaining)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: completed
                          ? const Color(0xFF227648)
                          : const Color(0xFF9A6B18),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
