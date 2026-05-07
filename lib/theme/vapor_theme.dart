import 'package:flutter/material.dart';

class VaporTheme {
  // Water-inspired color palette
  static const Color primary = Color(0xFF5BB8F5);
  static const Color primaryLight = Color(0xFF8DD4FF);
  static const Color primaryDark = Color(0xFF2E9FE6);
  static const Color accent = Color(0xFF3DD6C0);
  static const Color background = Color(0xFFF7FBFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBlue = Color(0xFFEAF5FF);
  static const Color textPrimary = Color(0xFF1A2E42);
  static const Color textSecondary = Color(0xFF6B8EAD);
  static const Color textHint = Color(0xFFADC8E0);
  static const Color divider = Color(0xFFDCEEFA);
  static const Color ripple = Color(0x1A5BB8F5);

  // Card color variants (water tones)
  static const List<Color> cardColors = [
    Color(0xFFFFFFFF),
    Color(0xFFEBF6FF),
    Color(0xFFE0F4F0),
    Color(0xFFEEF0FF),
    Color(0xFFFFF5EB),
    Color(0xFFFFF0F5),
  ];

  static const List<Color> cardBorderColors = [
    Color(0xFFDCEEFA),
    Color(0xFFB8DEFF),
    Color(0xFFB0E4D8),
    Color(0xFFCED1FF),
    Color(0xFFFFDDB8),
    Color(0xFFFFCCDD),
  ];

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: primary,
          secondary: accent,
          background: background,
          surface: surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: textPrimary,
          onSurface: textPrimary,
        ),
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: textPrimary,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardTheme(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceBlue,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: textHint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: StadiumBorder(),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
          labelSmall: TextStyle(color: textHint, fontSize: 11),
        ),
      );
}
