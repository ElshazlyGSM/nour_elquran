part of 'reader_page.dart';

const _readerSearchSource = currentQuranTextSource;

class _ReaderSearchIndexEntry {
  const _ReaderSearchIndexEntry({
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

final List<_ReaderSearchIndexEntry> _readerSearchCache = [
  for (var surah = 1; surah <= currentQuranTotalSurahCount; surah++)
    for (var verse = 1; verse <= _readerSearchSource.getVerseCount(surah); verse++)
      () {
        final verseText = _readerSearchSource.getVerseText(
          surah,
          verse,
          verseEndSymbol: false,
        );
        final normalizedText = _normalizeReaderSearch(verseText);
        return _ReaderSearchIndexEntry(
          surahNumber: surah,
          verseNumber: verse,
          surahName: _readerSearchSource.getSurahNameArabic(surah),
          verseText: verseText,
          normalizedText: normalizedText,
          normalizedWords: _tokenizeNormalizedText(normalizedText),
        );
      }(),
];

Map<String, List<_ReaderSearchIndexEntry>> _buildReaderWordIndex() {
  final index = <String, List<_ReaderSearchIndexEntry>>{};
  for (final entry in _readerSearchCache) {
    for (final word in entry.normalizedWords.toSet()) {
      index.putIfAbsent(word, () => []).add(entry);
    }
  }
  return index;
}

final Map<String, List<_ReaderSearchIndexEntry>> _readerWordIndex =
    _buildReaderWordIndex();

List<_ReaderSearchIndexEntry> _findReaderSearchMatches(String normalizedQuery) {
  final tokens = _tokenizeNormalizedText(normalizedQuery);
  if (tokens.isEmpty) {
    return const [];
  }

  final candidateMap = <String, _ReaderSearchIndexEntry>{};

  for (final token in tokens) {
    final direct = _readerWordIndex[token];
    if (direct != null) {
      for (final entry in direct) {
        candidateMap['${entry.surahNumber}:${entry.verseNumber}'] = entry;
      }
    }

    for (final indexedWord in _readerWordIndex.keys) {
      if (indexedWord.contains(token) || token.contains(indexedWord)) {
        for (final entry in _readerWordIndex[indexedWord]!) {
          candidateMap['${entry.surahNumber}:${entry.verseNumber}'] = entry;
        }
      }
    }
  }

  final source = candidateMap.isEmpty
      ? _readerSearchCache
      : candidateMap.values.toList();

  final results = source.where((entry) {
    return tokens.every((token) {
      return entry.normalizedText.contains(token) ||
          entry.normalizedWords.any((word) => word.contains(token));
    });
  }).toList();

  int score(_ReaderSearchIndexEntry entry) {
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

class _ReaderSearchHit {
  const _ReaderSearchHit({
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

class _ReaderSearchDelegate extends SearchDelegate<_ReaderSearchHit?> {
  @override
  String get searchFieldLabel =>
      '\u0627\u0628\u062d\u062b \u0641\u064a \u0627\u0644\u0645\u0635\u062d\u0641';

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
  Widget buildSuggestions(BuildContext context) =>
      _ReaderSearchResults(query: query, onOpenResult: (result) => close(context, result));

  @override
  Widget buildResults(BuildContext context) =>
      _ReaderSearchResults(query: query, onOpenResult: (result) => close(context, result));
}

class _ReaderSearchResults extends StatelessWidget {
  const _ReaderSearchResults({required this.query, required this.onOpenResult});

  final String query;
  final void Function(_ReaderSearchHit result) onOpenResult;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalizeReaderSearch(query);
    if (normalizedQuery.isEmpty) {
      return const Center(
        child: Text(
          '\u0627\u0643\u062a\u0628 \u0643\u0644\u0645\u0629 \u0623\u0648 \u0639\u0628\u0627\u0631\u0629',
        ),
      );
    }

    final matches = _findReaderSearchMatches(normalizedQuery)
        .map(
          (entry) => _ReaderSearchHit(
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
          '\u0644\u0627 \u062a\u0648\u062c\u062f \u0646\u062a\u0627\u0626\u062c',
        ),
      );
    }

    final groupedMatches = <int, List<_ReaderSearchHit>>{};
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surahName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: const Color(0xFF163C2D),
                  ),
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
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: const Color(0xFF3A2D14),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              text: _highlightedReaderSearchSnippet(
                                context,
                                _readerSearchSnippet(result.verseText, query),
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

String _normalizeReaderSearch(String input) {
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

List<String> _tokenizeNormalizedText(String text) =>
    text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && word.length > 1)
        .toList();

String _readerSearchSnippet(String verseText, String query) {
  final words = verseText.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) {
    return verseText;
  }

  final normalizedQuery = _normalizeReaderSearch(query);
  var start = 0;
  for (var i = 0; i < words.length; i++) {
    if (_normalizeReaderSearch(words[i]).contains(normalizedQuery)) {
      start = (i - 1).clamp(0, words.length - 1);
      break;
    }
  }

  final end = (start + 7).clamp(0, words.length);
  return words.sublist(start, end).join(' ');
}

TextSpan _highlightedReaderSearchSnippet(
  BuildContext context,
  String verseText,
  String query,
) {
  final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 15.5,
        height: 1.8,
        wordSpacing: 1.0,
        color: const Color(0xFF1E241F),
        fontWeight: FontWeight.w600,
      ) ??
      const TextStyle(
        fontSize: 15.5,
        height: 1.8,
        wordSpacing: 1.0,
        color: Color(0xFF1E241F),
        fontWeight: FontWeight.w600,
      );
  final highlightStyle = baseStyle.copyWith(
    backgroundColor: const Color(0xFFF6E3A8),
    fontWeight: FontWeight.w800,
    color: const Color(0xFF143A2A),
  );

  final normalizedQuery = _normalizeReaderSearch(query);
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
    final style = _normalizeReaderSearch(part).contains(normalizedQuery)
        ? highlightStyle
        : baseStyle;
    spans.add(TextSpan(text: part, style: style));
  }
  return TextSpan(children: spans, style: baseStyle);
}

