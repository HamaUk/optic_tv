import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'base_settings_page.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_strings.dart';
import '../../../providers/app_locale_provider.dart';
import '../../../services/update_service.dart';
import '../../../widgets/update_prompt_dialog.dart';

class AboutSettingsPage extends ConsumerWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);

    return BaseSettingsPage(
      title: s.sectionSupport,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          glassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.update_rounded, color: Colors.greenAccent),
                  title: Text(s.checkUpdates, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.checkUpdatesSub, style: const TextStyle(color: Colors.white70)),
                  onTap: () {
                    final updateData = ref.read(updateManagerProvider).asData?.value;
                    final localVersionCode = ref.read(appVersionCodeProvider).asData?.value ?? 0;
                    if (updateData != null && updateData.isActive && updateData.versionCode > localVersionCode) {
                      UpdatePromptDialog.show(context, updateData, s);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.locale.languageCode == 'kmr' ? 'Sepan nûjen e' : (s.locale.languageCode == 'ckb' ? 'ئەپەکە نوێکراوەتەوە' : 'App is up to date'))));
                    }
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.telegram_rounded, color: Colors.blueAccent),
                  title: Text(s.joinTelegram, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.joinTelegramSub, style: const TextStyle(color: Colors.white70)),
                  onTap: () async {
                    final url = Uri.parse('https://t.me/KOBANI4K');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          glassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'KOBANI 4K',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.2.0+14',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2026 KOBANI 4K. All rights reserved.',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
