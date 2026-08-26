import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Emerald / Teal as primary (Stripe/Shopify vibe)
  static const Color primary = Color(0xFF0F766E); // Emerald-700
  static const Color primaryLight = Color(0xFF14B8A6); // Emerald-500

  // Dark Navy for shell and text
  static const Color navy = Color(0xFF0F172A); // Slate-900
  static const Color navyLight = Color(0xFF1E293B); // Slate-800

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Text Colors
  static const Color darkText = Color(0xFF0F172A);
  static const Color mutedText = Color(0xFF64748B); // Slate-500

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: primaryLight,
      surface: surface,
      onSurface: darkText,
      error: error,
    ),
    fontFamily: 'Inter', // Assuming Inter or similar standard font
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: navy),
      titleTextStyle: TextStyle(
        color: navy,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate-200
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(color: mutedText),
      hintStyle: const TextStyle(color: mutedText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
    ),
  );

  // Common BoxShadow for floating glass elements
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: navy.withValues(alpha: 0.04),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
}
