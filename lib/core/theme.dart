import 'package:flutter/material.dart';

/// Backdrop style for dashboard shell, featured hero, and settings (persisted).
enum AppGradientPreset { classic, oceanAbyss, goldSunset, violetHaze, emberGlow }

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

  static const Color primaryGold = Color(0xFFFFB100); // Premium Amber Gold
  static const Color primaryGoldDim = Color(0xFFB8860B);
  static const Color accentTeal = Color(0xFFFFB100); 
  static const Color primaryBlue = Color(0xFFFFB100); 
  static const Color primaryPurple = Color(0xFFFFB100); 
  static const Color backgroundBlack = Color(0xFF000000); // Pure black
  static const Color surfaceGray = Color(0xFF101419);
  static const Color surfaceElevated = Color(0xFF161B22);

  static Color accentColor(AppGradientPreset p) {
    return switch (p) {
      AppGradientPreset.classic => const Color(0xFFFFB100),
      AppGradientPreset.oceanAbyss => const Color(0xFF0EA5E9),
      AppGradientPreset.goldSunset => const Color(0xFFF97316),
      AppGradientPreset.violetHaze => const Color(0xFFA855F7),
      AppGradientPreset.emberGlow => const Color(0xFFF43F5E),
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
      // Explicit icon colors so AppBar/leading icons stay visible with custom text font.
      iconTheme: IconThemeData(color: accent),
      brightness: Brightness.dark,
      primaryColor: accent,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        tertiary: accent,
        surface: surfaceGray,
        onPrimary: const Color(0xFF000000),
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
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
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
  static ThemeData get darkTheme => darkThemeForUi(const Locale('en'), AppGradientPreset.classic);

  /// Main dashboard / app shell behind content.
  static LinearGradient shellGradient(AppGradientPreset p) {
    return switch (p) {
      AppGradientPreset.classic => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0F14), Color(0xFF121820), Color(0xFF0B0F14)],
        ),
      AppGradientPreset.oceanAbyss => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050F18), Color(0xFF0C2434), Color(0xFF061A22)],
        ),
      AppGradientPreset.goldSunset => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF120C08), Color(0xFF1C140C), Color(0xFF0F0A06)],
        ),
      AppGradientPreset.violetHaze => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E0816), Color(0xFF181028), Color(0xFF0C0612)],
        ),
      AppGradientPreset.emberGlow => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF120608), Color(0xFF1C0C0C), Color(0xFF0E0606)],
        ),
    };
  }

  /// Featured spotlight card on the dashboard.
  static LinearGradient featuredHeroGradient(AppGradientPreset p) {
    return switch (p) {
      AppGradientPreset.classic => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentTeal.withOpacity(0.38),
            const Color(0xFF1C2430),
            primaryGold.withOpacity(0.22),
          ],
        ),
      AppGradientPreset.oceanAbyss => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0EA5E9).withOpacity(0.35),
            const Color(0xFF102030),
            accentTeal.withOpacity(0.28),
          ],
        ),
      AppGradientPreset.goldSunset => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGold.withOpacity(0.42),
            const Color(0xFF241A12),
            const Color(0xFFF97316).withOpacity(0.18),
          ],
        ),
      AppGradientPreset.violetHaze => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryPurple.withOpacity(0.4),
            const Color(0xFF1A1428),
            primaryBlue.withOpacity(0.2),
          ],
        ),
      AppGradientPreset.emberGlow => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF43F5E).withOpacity(0.32),
            const Color(0xFF1C1010),
            primaryGold.withOpacity(0.2),
          ],
        ),
    };
  }

  /// Soft wash behind settings lists.
  static LinearGradient settingsBackdropGradient(AppGradientPreset p) {
    return switch (p) {
      AppGradientPreset.classic => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundBlack,
            const Color(0xFF101620).withOpacity(0.92),
            backgroundBlack,
          ],
        ),
      AppGradientPreset.oceanAbyss => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF060F18),
            const Color(0xFF0C1C2A).withOpacity(0.95),
            backgroundBlack,
          ],
        ),
      AppGradientPreset.goldSunset => LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF140E0A),
            const Color(0xFF1A120C).withOpacity(0.96),
            backgroundBlack,
          ],
        ),
      AppGradientPreset.violetHaze => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF100818),
            const Color(0xFF160C22).withOpacity(0.94),
            backgroundBlack,
          ],
        ),
      AppGradientPreset.emberGlow => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF120608),
            const Color(0xFF180A0C).withOpacity(0.95),
            backgroundBlack,
          ],
        ),
    };
  }
}
