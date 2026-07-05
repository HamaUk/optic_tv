import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_settings_page.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_strings.dart';
import '../../../providers/app_locale_provider.dart';
import '../../../providers/ui_settings_provider.dart';
import '../../../widgets/tv/tv_focusable.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);
    final uiSettings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();

    return BaseSettingsPage(
      title: s.sectionInterface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            s.sectionGradientTheme,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor(uiSettings.gradientPreset),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            s.gradientThemeCaption,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 12),
          glassCard(
            child: Column(
              children: [
                for (final preset in AppGradientPreset.values)
                  TVFocusable(
                    showFocusBorder: true,
                    focusScale: 1.02,
                    borderRadius: BorderRadius.circular(16),
                    child: RadioListTile<AppGradientPreset>(
                      value: preset,
                      groupValue: uiSettings.gradientPreset,
                      activeColor: AppTheme.accentColor(uiSettings.gradientPreset),
                      title: Text(_gradientPresetTitle(s, preset), style: const TextStyle(color: Colors.white)),
                      secondary: _GradientPresetSwatch(preset: preset),
                      onChanged: (v) {
                        if (v != null) ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(gradientPreset: v));
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          glassCard(
            child: SwitchListTile(
              title: Text(s.reduceMotionTitle, style: const TextStyle(color: Colors.white)),
              subtitle: Text(s.reduceMotionSub, style: const TextStyle(color: Colors.white70)),
              value: uiSettings.reduceMotion,
              activeTrackColor: AppTheme.accentColor(uiSettings.gradientPreset).withOpacity(0.45),
              activeColor: AppTheme.accentColor(uiSettings.gradientPreset),
              onChanged: (v) => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(reduceMotion: v)),
            ),
          ),
        ],
      ),
    );
  }

  String _gradientPresetTitle(AppStrings s, AppGradientPreset preset) {
    return switch (preset) {
      AppGradientPreset.classic => 'Midnight (Silver/Gray)',
      AppGradientPreset.ocean => 'Ocean Abyss (Blue)',
      AppGradientPreset.goldSunset => 'Gold Sunset (Yellow/Orange)',
      AppGradientPreset.violetHaze => 'Violet Haze (Purple)',
      AppGradientPreset.emberGlow => 'Ember Glow (Red/Orange)',
    };
  }
}

class _GradientPresetSwatch extends StatelessWidget {
  const _GradientPresetSwatch({required this.preset});

  final AppGradientPreset preset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: AppTheme.shellGradient(preset),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
