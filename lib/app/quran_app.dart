import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/home/home_shell.dart';
import '../services/app_update_service.dart';
import '../services/quran_store.dart';

class QuranApp extends StatelessWidget {
  const QuranApp({super.key, required this.store});

  final QuranStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: AppUpdateService.navigatorKey,
          title: 'القرآن الكريم',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          locale: const Locale('ar'),
          theme: buildAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: switch (store.savedThemeMode) {
            'dark' => ThemeMode.dark,
            'system' => ThemeMode.system,
            _ => ThemeMode.light,
          },
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: HomeShell(store: store),
          ),
        );
      },
    );
  }
}


