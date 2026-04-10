import 'package:flutter/material.dart';

import '../../services/quran_store.dart';
import 'bookmarks_page.dart';
import 'index_page.dart';
import 'surah_list_page.dart';

class QuranSectionShell extends StatefulWidget {
  const QuranSectionShell({
    super.key,
    required this.store,
    this.initialIndex = 0,
    this.initialSurahNumber,
    this.initialJuzNumber,
  });

  final QuranStore store;
  final int initialIndex;
  final int? initialSurahNumber;
  final int? initialJuzNumber;

  @override
  State<QuranSectionShell> createState() => _QuranSectionShellState();
}

class _QuranSectionShellState extends State<QuranSectionShell> {
  late int _currentIndex = widget.initialIndex.clamp(0, 2);

  @override
  Widget build(BuildContext context) {
    final pages = [
      SurahListPage(
        store: widget.store,
        initialSurahNumber: widget.initialSurahNumber,
      ),
      IndexPage(store: widget.store, initialJuzNumber: widget.initialJuzNumber),
      BookmarksPage(store: widget.store),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('\u0627\u0644\u0645\u0635\u062d\u0641'),
        backgroundColor: const Color(0xFF143A2A),
        foregroundColor: Colors.white,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: const NavigationBarThemeData(
          height: 72,
          iconTheme: WidgetStatePropertyAll(
            IconThemeData(size: 24),
          ),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_rounded),
              label: '\u0627\u0644\u0633\u0648\u0631',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: '\u0627\u0644\u0623\u062c\u0632\u0627\u0621',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_rounded),
              label: '\u0627\u0644\u0639\u0644\u0627\u0645\u0627\u062a',
            ),
          ],
          onDestinationSelected: (value) {
            setState(() {
              _currentIndex = value;
            });
          },
        ),
      ),
    );
  }
}
