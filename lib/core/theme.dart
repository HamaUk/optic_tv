import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Force Refresh: 2026-04-09 23:37
class AppTheme {
  // Ultra-Premium Dark Color Palette
  static const Color primaryBlue = Color(0xFF00D2FF);
  static const Color primaryPurple = Color(0xFF928DFF);
  static const Color backgroundBlack = Color(0xFF0A0B10);
  static const Color surfaceGray = Color(0xFF1A1C24);
  static const Color accentCyan = Color(0xFF00F5FF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryPurple,
        surface: surfaceGray,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
