import 'package:flutter/material.dart';

class AppTheme {
  // Brand color scheme
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color surfaceCard = Color(0xFF151E2E);
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color accentCyan = Color(0xFF00E5FF);
  
  static const Color creditGreen = Color(0xFF10B981);
  static const Color debitRed = Color(0xFFEF4444);
  
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  
  static const Color vdPaysColor = Color(0xFFF59E0B);
  static const Color masterPayColor = Color(0xFF3B82F6);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryIndigo,
      colorScheme: const ColorScheme.dark(
        primary: primaryIndigo,
        secondary: accentCyan,
        error: debitRed,
        surface: surfaceCard,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard.withOpacity(0.5),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: debitRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }
}
