import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color primary = Color(0xFF1A1A2E);   // deep navy
  static const Color accent = Color(0xFFE94560);    // punchy red-pink
  static const Color surface = Color(0xFF16213E);   // card background
  static const Color cardFg = Color(0xFFEAEAEA);    // card text
  static const Color mutedText = Color(0xFF8892A4); // secondary text

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          surface: surface,
        ),
        cardTheme: const CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            color: cardFg,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.45,
            letterSpacing: 0.3,
          ),
          bodySmall: TextStyle(color: mutedText, fontSize: 13),
        ),
        iconTheme: const IconThemeData(color: cardFg),
      );
}
