import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/settings_service.dart';
import '../../widgets/tv/tv_focusable.dart';

/// Professional TV Settings View ported from KoyaPlayer.
/// Isolated for TV use only.
class EliteTvSettingsView extends ConsumerWidget {
  const EliteTvSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiLocale = ref.watch(appLocaleProvider);
    final settingsAsync = ref.watch(appUiSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SYSTEM SETTINGS', style: TextStyle(color: AppTheme.primaryGold, letterSpacing: 4, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            settingsAsync.when(
              loading: () => const CircularProgressIndicator(color: AppTheme.primaryGold),
              error: (e, __) => Text('Error loading settings: $e', style: const TextStyle(color: Colors.red)),
              data: (settings) => Column(
                children: [
                  _buildSettingTile(
                    title: 'System Language',
                    value: uiLocale.languageCode == 'en' ? 'English' : 'Kurdish',
                    icon: Icons.language,
                    onTap: () {
                      final next = uiLocale.languageCode == 'en' ? 'ckb' : 'en';
                      ref.read(appLocaleProvider.notifier).setLocale(Locale(next));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    title: 'UI Accent Palette',
                    value: settings.gradientPreset.name.toUpperCase(),
                    icon: Icons.palette,
                    onTap: () {
                      final current = settings.gradientPreset;
                      final next = AppGradientPreset.values[(current.index + 1) % AppGradientPreset.values.length];
                      final newSettings = settings.copyWith(gradientPreset: next);
                      ref.read(appUiSettingsProvider.notifier).apply(newSettings);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({required String title, required String value, required IconData icon, required VoidCallback onTap}) {
    return TVFocusable(
      onSelect: onTap,
      showFocusBorder: true,
      builder: (context, isFocused, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isFocused ? Colors.white10 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isFocused ? AppTheme.primaryGold : Colors.white10),
          ),
          child: Row(
            children: [
              Icon(icon, color: isFocused ? AppTheme.primaryGold : Colors.white38),
              const SizedBox(width: 24),
              Expanded(
                child: Text(title, style: TextStyle(color: isFocused ? Colors.white : Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Text(value, style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
