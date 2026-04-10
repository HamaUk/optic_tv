import 'package:flutter/material.dart';

/// Premium dark theme — gold accent, Rabar 021 typography (assets).
class AppTheme {
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color primaryGoldDim = Color(0xFFB8922B);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color primaryBlue = Color(0xFF38BDF8);
  static const Color primaryPurple = Color(0xFFA78BFA);
  static const Color backgroundBlack = Color(0xFF0B0F14);
  static const Color surfaceGray = Color(0xFF151B24);
  static const Color surfaceElevated = Color(0xFF1C2430);

  static ThemeData get darkTheme {
    const base = TextStyle(fontFamily: 'Rabar', color: Colors.white);
    return ThemeData(
      fontFamily: 'Rabar',
      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: accentTeal,
        tertiary: primaryBlue,
        surface: surfaceGray,
        onPrimary: Color(0xFF0B0F14),
        onSurface: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: base.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: base.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: base.copyWith(fontSize: 16, color: Colors.white70),
        bodyMedium: base.copyWith(fontSize: 14, color: Colors.white70),
        labelLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
