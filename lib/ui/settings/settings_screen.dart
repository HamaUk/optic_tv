import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/ui_settings_provider.dart';

import 'pages/theme_settings_page.dart';
import 'pages/manual_sort_settings_page.dart';
import 'pages/language_settings_page.dart';
import 'pages/playback_settings_page.dart';
import 'pages/storage_settings_page.dart';
import 'pages/diagnostic_settings_page.dart';
import 'pages/about_settings_page.dart';

class CustomSettingsItem extends StatelessWidget {
  final VoidCallback onTap;
  final String iconAsset;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Color titleColor;

  const CustomSettingsItem({
    super.key,
    required this.onTap,
    required this.iconAsset,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.titleColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
          child: Image.asset(iconAsset, width: 22, height: 22, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref, AppStrings s) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceElevated,
            title: Text(s.logoutTitle, style: const TextStyle(color: Colors.white)),
            content: Text(s.logoutSub, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel, style: const TextStyle(color: Colors.white54))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true), 
                child: Text(s.logoutButton)
              ),
            ],
          ),
        ) ??
        false;
    if (!go) return;
    await ref.read(sessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);
    final uiSettings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              title: Text(s.settingsTitle, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.settingsBackdropGradient(uiSettings.gradientPreset),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    CustomSettingsItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsPage())),
                      iconAsset: 'assets/images/flixy/ic_mask.png',
                      iconBgColor: Colors.purpleAccent,
                      title: s.sectionInterface,
                      subtitle: s.sectionInterfaceSub,
                    ),
                    CustomSettingsItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualSortSettingsPage())),
                      iconAsset: 'assets/images/flixy/ic_menu.png',
                      iconBgColor: Colors.deepOrangeAccent,
                      title: s.manualSortTitle,
                      subtitle: s.manualSortSub,
                    ),
                    
                    CustomSettingsItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsPage())),
                      iconAsset: 'assets/images/flixy/ic_languages.png',
                      iconBgColor: Colors.blueAccent,
                      title: s.sectionLanguage,
                      subtitle: uiLocale.languageCode.toUpperCase(),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    CustomSettingsItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaybackSettingsPage())),
                      iconAsset: 'assets/images/flixy/ic_play.png',
                      iconBgColor: Colors.orangeAccent,
                      title: s.sectionPlayback,
                      subtitle: s.sectionPlaybackSub,
                    ),
                    CustomSettingsItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorageSettingsPage())),
                      iconAsset: 'assets/images/flixy/ic_download_box.png',
                      iconBgColor: Colors.teal,
                      title: s.sectionStorage,
                      subtitle: s.sectionStorageSub,
                    ),
                    CustomSettingsItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticSettingsPage())),
                      iconAsset: 'assets/images/flixy/ic_search.png',
                      iconBgColor: Colors.indigoAccent,
                      title: s.sectionDiagnostics,
                      subtitle: s.sectionDiagnosticsSub,
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    CustomSettingsItem(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutSettingsPage())),
                      iconAsset: 'assets/images/flixy/ic_email.png',
                      iconBgColor: Colors.green,
                      title: s.sectionSupport,
                      subtitle: s.sectionSupportSub,
                    ),
                    CustomSettingsItem(
                      onTap: () => _confirmLogout(context, ref, s),
                      iconAsset: 'assets/images/flixy/ic_logout.png',
                      iconBgColor: Colors.redAccent,
                      title: s.logoutTitle,
                      subtitle: s.logoutSub,
                      titleColor: Colors.redAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
