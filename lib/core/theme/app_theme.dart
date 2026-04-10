import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const cream = Color(0xFFF7F1E3);
  const sand = Color(0xFFE9DEC3);
  const forest = Color(0xFF143A2A);
  const gold = Color(0xFFD4A63A);
  const ink = Color(0xFF1A1A1A);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: forest,
        brightness: Brightness.light,
      ).copyWith(
        primary: forest,
        secondary: gold,
        surface: Colors.white,
        onSurface: ink,
      );

  return ThemeData(
    useMaterial3: false,
    colorScheme: scheme,
    scaffoldBackgroundColor: cream,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: forest,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: sand,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: forest.withValues(alpha: 0.55)),
      prefixIconColor: forest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: forest,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: forest,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: forest,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: forest,
      ),
      bodyLarge: TextStyle(fontSize: 24, height: 2.0, color: ink),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Color(0xFF5C655F),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: Colors.white,
    ),
  );
}

ThemeData buildDarkAppTheme() {
  const forest = Color(0xFF143A2A);
  const gold = Color(0xFFD4A63A);
  const deep = Color(0xFF0D1417);
  const card = Color(0xFF152127);
  const ink = Color(0xFFECE6D8);
  const muted = Color(0xFFB7C1BC);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: forest,
        brightness: Brightness.dark,
      ).copyWith(
        primary: gold,
        secondary: const Color(0xFFE6C16A),
        surface: card,
        onSurface: ink,
      );

  return ThemeData(
    useMaterial3: false,
    colorScheme: scheme,
    scaffoldBackgroundColor: deep,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF101A1E),
      foregroundColor: Color(0xFFF6E7BF),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFFF6E7BF),
      ),
      iconTheme: IconThemeData(color: Color(0xFFF6E7BF)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF101A1E),
      indicatorColor: const Color(0x332F8A72),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A252A),
      hintStyle: const TextStyle(color: muted),
      prefixIconColor: const Color(0xFFF6E7BF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: Color(0xFFF3EEE1),
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF3EEE1),
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF3EEE1),
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF3EEE1),
      ),
      bodyLarge: TextStyle(fontSize: 24, height: 2.0, color: Color(0xFFECE6D8)),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: muted,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: card,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF1A252A),
      contentTextStyle: TextStyle(color: Color(0xFFF3EEE1)),
    ),
  );
}
