import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppSettingsData _data = const AppSettingsData();
  bool _loading = true;

  static const _fitChoices = <BoxFit>[
    BoxFit.contain,
    BoxFit.cover,
    BoxFit.fill,
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AppSettingsData.load();
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  Future<void> _apply(AppSettingsData next) async {
    setState(() => _data = next);
    await next.persist();
    ref.invalidate(appUiSettingsProvider);
  }

  Future<void> _confirmLogout(AppStrings s) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceElevated,
            title: Text(s.logoutTitle),
            content: Text(s.logoutSub),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.isEnglish ? 'Cancel' : 'پاشگەزبوونەوە')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.logoutButton)),
            ],
          ),
        ) ??
        false;
    if (!go || !mounted) return;
    await ref.read(sessionActionsProvider).logout();
    // MaterialApp switches home to LoginScreen; avoid extra pops.
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(Localizations.localeOf(context));
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text(
                  s.sectionInterface,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(s.languageTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      RadioListTile<String>(
                        value: 'ckb',
                        groupValue: locale.languageCode,
                        activeColor: AppTheme.primaryGold,
                        title: Text(s.languageCkb),
                        onChanged: (_) async {
                          await ref.read(appLocaleProvider.notifier).setLocale(const Locale('ckb'));
                          if (mounted) setState(() {});
                        },
                      ),
                      RadioListTile<String>(
                        value: 'en',
                        groupValue: locale.languageCode,
                        activeColor: AppTheme.primaryGold,
                        title: Text(s.languageEn),
                        onChanged: (_) async {
                          await ref.read(appLocaleProvider.notifier).setLocale(const Locale('en'));
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: Text(s.tvLayoutTitle),
                    subtitle: Text(s.tvLayoutSub),
                    value: _data.tvFriendlyLayout,
                    activeTrackColor: AppTheme.primaryGold.withOpacity(0.45),
                    activeColor: AppTheme.primaryGold,
                    onChanged: (v) => _apply(_data.copyWith(tvFriendlyLayout: v)),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: Text(s.reduceMotionTitle),
                    subtitle: Text(s.reduceMotionSub),
                    value: _data.reduceMotion,
                    activeTrackColor: AppTheme.primaryGold.withOpacity(0.45),
                    activeColor: AppTheme.primaryGold,
                    onChanged: (v) => _apply(_data.copyWith(reduceMotion: v)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionPlayback,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: Text(s.keepScreenOnTitle),
                    subtitle: Text(s.keepScreenOnSub),
                    value: _data.keepScreenOnWhilePlaying,
                    activeTrackColor: AppTheme.primaryGold.withOpacity(0.45),
                    activeColor: AppTheme.primaryGold,
                    onChanged: (v) => _apply(_data.copyWith(keepScreenOnWhilePlaying: v)),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: Text(s.autoHideTitle),
                    subtitle: Text(s.autoHideSub),
                    value: _data.autoHidePlayerControls,
                    activeTrackColor: AppTheme.primaryGold.withOpacity(0.45),
                    activeColor: AppTheme.primaryGold,
                    onChanged: (v) => _apply(_data.copyWith(autoHidePlayerControls: v)),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: Text(s.clockTitle),
                    subtitle: Text(s.clockSub),
                    value: _data.showOnScreenClock,
                    activeTrackColor: AppTheme.primaryGold.withOpacity(0.45),
                    activeColor: AppTheme.primaryGold,
                    onChanged: (v) => _apply(_data.copyWith(showOnScreenClock: v)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionVideo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(s.videoFitCaption, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      for (final fit in _fitChoices)
                        RadioListTile<BoxFit>(
                          value: fit,
                          groupValue: _data.videoFit,
                          activeColor: AppTheme.primaryGold,
                          title: Text(s.fitLabel(fit)),
                          onChanged: (v) {
                            if (v != null) _apply(_data.copyWith(videoFit: v));
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionAccount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.orangeAccent),
                    title: Text(s.logoutTitle),
                    subtitle: Text(s.logoutSub),
                    onTap: () => _confirmLogout(s),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionAbout,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.white.withOpacity(0.7)),
                    title: Text(s.aboutTitle),
                    subtitle: Text(s.aboutSub),
                  ),
                ),
              ],
            ),
    );
  }
}
