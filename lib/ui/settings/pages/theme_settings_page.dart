import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_settings_page.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_strings.dart';
import '../../../providers/app_locale_provider.dart';
import '../../../providers/ui_settings_provider.dart';

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
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            s.gradientThemeCaption,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: AppGradientPreset.values.length,
            itemBuilder: (context, index) {
              final preset = AppGradientPreset.values[index];
              final isSelected = uiSettings.gradientPreset == preset;
              return _ThemeCard(
                preset: preset,
                title: _gradientPresetTitle(preset),
                isSelected: isSelected,
                onTap: () {
                  ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(gradientPreset: preset));
                },
              );
            },
          ),
          const SizedBox(height: 32),
          glassCard(
            child: SwitchListTile(
              title: Text(s.reduceMotionTitle, style: const TextStyle(color: Colors.white)),
              subtitle: Text(s.reduceMotionSub, style: const TextStyle(color: Colors.white70)),
              value: uiSettings.reduceMotion,
              activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.45),
              activeThumbColor: Theme.of(context).primaryColor,
              onChanged: (v) => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(reduceMotion: v)),
            ),
          ),
        ],
      ),
    );
  }

  String _gradientPresetTitle(AppGradientPreset preset) {
    return switch (preset) {
      AppGradientPreset.classic => 'Midnight',
      AppGradientPreset.ocean => 'Ocean Abyss',
      AppGradientPreset.goldSunset => 'Gold Sunset',
      AppGradientPreset.violetHaze => 'Violet Haze',
      AppGradientPreset.emberGlow => 'Ember Glow',
      AppGradientPreset.emeraldForest => 'Emerald Forest',
      AppGradientPreset.cyberpunk => 'Cyberpunk',
      AppGradientPreset.midnightBlue => 'Midnight Blue',
    };
  }
}

class _ThemeCard extends StatelessWidget {
  final AppGradientPreset preset;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.preset,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentColor(preset);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.shellGradient(preset),
          border: Border.all(
            color: isSelected ? accent : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative accent blob
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 6),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: accent, size: 24),
                    ],
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
