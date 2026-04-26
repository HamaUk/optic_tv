import 'package:flutter/material.dart';

/// Backdrop style for dashboard shell, featured hero, and settings (persisted).
enum AppGradientPreset { classic, ocean, goldSunset, violetHaze, emberGlow }

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

  static const Color primaryGold = Color(0xFFD32F2F); // Deep Premium Red
  static const Color primaryGoldDim = Color(0xFF8B0000); // Dark Blood Red
  static const Color accentTeal = Color(0xFFB71C1C); 
  static const Color primaryBlue = Color(0xFFD32F2F); 
  static const Color primaryPurple = Color(0xFFB71C1C); 
  static const Color backgroundBlack = Color(0xFF000000); // Pure Matte Black
  static const Color surfaceGray = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF242424);

  static Color accentColor(AppGradientPreset p) {
    return switch (p) {
      AppGradientPreset.classic => const Color(0xFFE0E0E0), // Platinum / Silver
      AppGradientPreset.ocean => const Color(0xFF00D2FF),   // Electric Blue
      AppGradientPreset.goldSunset => const Color(0xFFFFD700), // Pure Gold
      AppGradientPreset.violetHaze => const Color(0xFFBF5AF2), // Neon Purple
      AppGradientPreset.emberGlow => const Color(0xFFFF3B30),  // Vivid Red
    };
  }

  static Color accentColorDim(AppGradientPreset p) {
    return accentColor(p).withOpacity(0.7);
  }

  static ThemeData darkThemeForUi(Locale uiLocale, AppGradientPreset preset) {
    final accent = accentColor(preset);
    const base = TextStyle(color: Colors.white);
    final useRabar = uiLocale.languageCode == 'ckb';
    final rabar = useRabar ? const TextStyle(fontFamily: rabarFontFamily) : const TextStyle();
    
    return ThemeData(
      iconTheme: IconThemeData(color: accent),
      brightness: Brightness.dark,
      primaryColor: accent,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        tertiary: accent,
        surface: surfaceGray,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: base.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white).merge(rabar),
        displayMedium: base.copyWith(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white).merge(rabar),
        headlineSmall: base.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white).merge(rabar),
        titleLarge: base.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white).merge(rabar),
        titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white).merge(rabar),
        titleSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white).merge(rabar),
        bodyLarge: base.copyWith(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500).merge(rabar),
        bodyMedium: base.copyWith(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500).merge(rabar),
        bodySmall: base.copyWith(fontSize: 12, color: Colors.white.withOpacity(0.7)).merge(rabar),
        labelLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w800).merge(rabar),
        labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w800).merge(rabar),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 8,
          shadowColor: accent.withOpacity(0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontFamily: useRabar ? rabarFontFamily : null,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
        ),
      ),
    );
  }

  /// English UI — typography uses the default platform / Material font.
  static ThemeData get darkTheme => darkThemeForUi(const Locale('en'), AppGradientPreset.emberGlow);

  /// Main dashboard / app shell behind content.
  static LinearGradient shellGradient(AppGradientPreset p) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF000000), Color(0xFF000000), Color(0xFF000000)],
    );
  }

  /// Featured spotlight card on the dashboard.
  static LinearGradient featuredHeroGradient(AppGradientPreset p) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accentColor(p).withOpacity(0.5),
        const Color(0xFF000000),
        accentColor(p).withOpacity(0.1),
      ],
    );
  }

  static LinearGradient settingsBackdropGradient(AppGradientPreset p) {
    final accent = accentColor(p);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF000000),
        accent.withOpacity(0.15),
        const Color(0xFF000000),
      ],
    );
  }
}
