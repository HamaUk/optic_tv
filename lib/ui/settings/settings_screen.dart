import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/ui_settings_provider.dart';

import 'pages/theme_settings_page.dart';
import 'pages/language_settings_page.dart';
import 'pages/playback_settings_page.dart';
import 'pages/storage_settings_page.dart';
import 'pages/diagnostic_settings_page.dart';
import 'pages/about_settings_page.dart';

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
              backgroundColor: Colors.black.withOpacity(0.5),
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
              BigUserCard(
                backgroundColor: AppTheme.accentColor(uiSettings.gradientPreset).withOpacity(0.9),
                userName: "KOBANI VIP",
                
                userProfilePic: const AssetImage("assets/images/logo.png"),
                cardActionWidget: SettingsItem(
                  icons: Icons.star_rounded,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.yellow[700],
                  ),
                  title: s.subscriptionActiveTitle,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  subtitle: s.subscriptionActiveSub,
                  subtitleStyle: const TextStyle(color: Colors.white70),
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 16),
              
              SettingsGroup(
                backgroundColor: Colors.black.withOpacity(0.35),
                items: [
                  SettingsItem(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsPage())),
                    icons: Icons.palette_rounded,
                    iconStyle: IconStyle(backgroundColor: Colors.purpleAccent),
                    title: s.sectionInterface,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    subtitle: s.sectionInterfaceSub,
                    subtitleStyle: const TextStyle(color: Colors.white54),
                  ),
                  SettingsItem(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsPage())),
                    icons: Icons.language_rounded,
                    iconStyle: IconStyle(backgroundColor: Colors.blueAccent),
                    title: s.sectionLanguage,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    subtitle: uiLocale.languageCode.toUpperCase(),
                    subtitleStyle: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),

              SettingsGroup(
                backgroundColor: Colors.black.withOpacity(0.35),
                items: [
                  SettingsItem(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaybackSettingsPage())),
                    icons: Icons.play_circle_fill_rounded,
                    iconStyle: IconStyle(backgroundColor: Colors.orangeAccent),
                    title: s.sectionPlayback,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    subtitle: s.sectionPlaybackSub,
                    subtitleStyle: const TextStyle(color: Colors.white54),
                  ),
                  SettingsItem(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorageSettingsPage())),
                    icons: Icons.storage_rounded,
                    iconStyle: IconStyle(backgroundColor: Colors.teal),
                    title: s.sectionStorage,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    subtitle: s.sectionStorageSub,
                    subtitleStyle: const TextStyle(color: Colors.white54),
                  ),
                  SettingsItem(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticSettingsPage())),
                    icons: Icons.analytics_rounded,
                    iconStyle: IconStyle(backgroundColor: Colors.indigoAccent),
                    title: s.sectionDiagnostics,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    subtitle: s.sectionDiagnosticsSub,
                    subtitleStyle: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),

              SettingsGroup(
                backgroundColor: Colors.black.withOpacity(0.35),
                items: [
                  SettingsItem(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutSettingsPage())),
                    icons: Icons.info_rounded,
                    iconStyle: IconStyle(backgroundColor: Colors.green),
                    title: s.sectionSupport,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    subtitle: s.sectionSupportSub,
                    subtitleStyle: const TextStyle(color: Colors.white54),
                  ),
                  SettingsItem(
                    onTap: () => _confirmLogout(context, ref, s),
                    icons: Icons.logout_rounded,
                    iconStyle: IconStyle(backgroundColor: Colors.redAccent),
                    title: s.logoutTitle,
                    titleStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    subtitle: s.logoutSub,
                    subtitleStyle: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
