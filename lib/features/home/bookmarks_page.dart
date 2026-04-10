import 'package:flutter/material.dart';

import '../../core/utils/arabic_numbers.dart';
import '../../services/quran_store.dart';
import '../reader/reader_page.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key, required this.store});

  final QuranStore store;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarks = store.readerBookmarks;

    if (bookmarks.isEmpty) {
      return Center(
        child: Text(
          '\u0644\u0627 \u062a\u0648\u062c\u062f \u0639\u0644\u0627\u0645\u0627\u062a \u0645\u062d\u0641\u0648\u0638\u0629 \u062d\u0627\u0644\u064a\u064b\u0627.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: bookmarks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
                final color = bookmark.colorValue == null
                    ? const Color(0xFF143A2A)
                    : Color(bookmark.colorValue!);
                return Card(
                  color: isDark ? const Color(0xFF152127) : null,
                  child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: ReaderPage(
                      store: store,
                      surahNumber: bookmark.surahNumber,
                      initialVerse: bookmark.verseNumber,
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color,
                    child: const Icon(
                      Icons.bookmark_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bookmark.surahName} \u2022 \u0622\u064a\u0629 ${toArabicNumber(bookmark.verseNumber)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u062c\u0632\u0621 ${toArabicNumber(bookmark.juzNumber)} \u2022 \u0635\u0641\u062d\u0629 ${toArabicNumber(bookmark.pageNumber)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (bookmark.note?.isNotEmpty ?? false)
                              ? bookmark.note!
                              : bookmark.previewText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '\u062d\u0630\u0641',
                    onPressed: () async {
                      await store.removeReaderBookmark(bookmark.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
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
