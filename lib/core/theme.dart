import 'package:flutter/material.dart';

/// Premium dark theme — gold accent.
/// When `uiLocale` is Kurdish (`ckb`), **Rabar** is applied across [TextTheme] (KRD-style full UI
/// script). [ThemeData.fontFamily] is never set globally so **Material icons** stay on the icon font.
class AppTheme {
  static const String rabarFontFamily = 'Rabar';

  /// For widgets that use a raw [TextStyle] instead of [ThemeData.textTheme].
  static TextStyle withRabarIfKurdish(Locale ui, TextStyle style) {
    if (ui.languageCode != 'ckb') return style;
    return style.merge(const TextStyle(fontFamily: rabarFontFamily));
  }

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
    final useRabar = uiLocale.languageCode == 'ckb';
    final rabar = useRabar ? const TextStyle(fontFamily: rabarFontFamily) : const TextStyle();
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
        displayLarge: base.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white).merge(rabar),
        displayMedium: base.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white).merge(rabar),
        headlineSmall: base.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white).merge(rabar),
        titleLarge: base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white).merge(rabar),
        titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white).merge(rabar),
        titleSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white).merge(rabar),
        bodyLarge: base.copyWith(fontSize: 16, color: Colors.white70).merge(rabar),
        bodyMedium: base.copyWith(fontSize: 14, color: Colors.white70).merge(rabar),
        bodySmall: base.copyWith(fontSize: 12, color: Colors.white54).merge(rabar),
        labelLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600).merge(rabar),
        labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w600).merge(rabar),
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: useRabar ? rabarFontFamily : null,
        ),
        toolbarTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: useRabar ? rabarFontFamily : null,
        ),
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

  /// English UI — typography uses the default platform / Material font.
  static ThemeData get darkTheme => darkThemeForUi(const Locale('en'));
}
