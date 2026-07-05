import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_settings_page.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_strings.dart';
import '../../../providers/app_locale_provider.dart';
import '../../../providers/ui_settings_provider.dart';
import '../../../widgets/tv/tv_focusable.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);
    final uiSettings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();

    return BaseSettingsPage(
      title: s.sectionLanguage,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          glassCard(
            child: Column(
              children: [
                _buildLangTile(ref, 'ckb', s.langKurdishSorani, uiLocale, uiSettings),
                const Divider(color: Colors.white12, height: 1),
                _buildLangTile(ref, 'kmr', s.langKurdishKurmanji, uiLocale, uiSettings),
                const Divider(color: Colors.white12, height: 1),
                _buildLangTile(ref, 'ar', s.langArabic, uiLocale, uiSettings),
                const Divider(color: Colors.white12, height: 1),
                _buildLangTile(ref, 'en', s.langEnglish, uiLocale, uiSettings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangTile(WidgetRef ref, String code, String title, Locale currentLocale, AppSettingsData uiSettings) {
    final active = currentLocale.languageCode == code;
    return TVFocusable(
      showFocusBorder: true,
      focusScale: 1.02,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        title: Text(title, style: TextStyle(color: active ? AppTheme.accentColor(uiSettings.gradientPreset) : Colors.white)),
        trailing: active ? Icon(Icons.check_circle_rounded, color: AppTheme.accentColor(uiSettings.gradientPreset)) : null,
        onTap: () {
          ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
        },
      ),
    );
  }
}
