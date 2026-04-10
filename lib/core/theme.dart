import 'package:flutter/material.dart';

/// Premium dark theme — gold accent.
/// Rabar is applied only to body text styles when `uiLocale` is Kurdish (`ckb`),
/// so titles / app chrome keep the default font and Material icons stay unaffected.
class AppTheme {
  static const String rabarFontFamily = 'Rabar';

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color primaryGoldDim = Color(0xFFB8922B);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color primaryBlue = Color(0xFF38BDF8);
  static const Color primaryPurple = Color(0xFFA78BFA);
  static const Color backgroundBlack = Color(0xFF0B0F14);
  static const Color surfaceGray = Color(0xFF151B24);
  static const Color surfaceElevated = Color(0xFF1C2430);

  static ThemeData darkThemeForUi(Locale uiLocale) {
    const base = TextStyle(color: Colors.white);
    final useRabarBody = uiLocale.languageCode == 'ckb';
    final bodyFont = useRabarBody ? const TextStyle(fontFamily: rabarFontFamily) : const TextStyle();
    return ThemeData(
      // Explicit icon colors so AppBar/leading icons stay visible with custom text font.
      iconTheme: const IconThemeData(color: Colors.white),
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
        bodyLarge: base.copyWith(fontSize: 16, color: Colors.white70).merge(bodyFont),
        bodyMedium: base.copyWith(fontSize: 14, color: Colors.white70).merge(bodyFont),
        bodySmall: base.copyWith(fontSize: 12, color: Colors.white54).merge(bodyFont),
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
        iconTheme: IconThemeData(color: Colors.white, size: 24),
      ),
      // Avoid default filled inputs (grey blocks) on screens that only set border/hint.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// English UI — no Rabar on body (system / default Latin UI font).
  static ThemeData get darkTheme => darkThemeForUi(const Locale('en'));
}
