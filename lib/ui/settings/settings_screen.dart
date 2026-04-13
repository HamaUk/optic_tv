import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/settings_service.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppSettingsData _data = const AppSettingsData();
  bool _loading = true;

  // Speed test state
  bool _testingSpeed = false;
  double? _lastSpeedMbps;
  double _testProgress = 0;

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

  Future<void> _confirmClearLibrary(
    AppStrings s, {
    required String dialogTitle,
    required String dialogBody,
    required Future<void> Function() onClear,
  }) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceElevated,
            title: Text(dialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dialogBody),
                const SizedBox(height: 8),
                Text(s.clearLibraryConfirmBody, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.clearButton),
              ),
            ],
          ),
        ) ??
        false;
    if (!go || !mounted) return;
    await onClear();
  }

  Future<void> _confirmLogout(AppStrings s) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceElevated,
            title: Text(s.logoutTitle),
            content: Text(s.logoutSub),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.logoutButton)),
            ],
          ),
        ) ??
        false;
    if (!go || !mounted) return;
    await ref.read(sessionProvider.notifier).logout();
    // MaterialApp switches home to LoginScreen; avoid extra pops.
  }

  Future<void> _runSpeedTest() async {
    if (_testingSpeed) return;
    setState(() {
      _testingSpeed = true;
      _testProgress = 0;
      _lastSpeedMbps = null;
    });

    final dio = Dio();
    // Use a reliable, high-speed dummy file for testing.
    // This is a 10MB test file from Cloudflare / Speedtest
    const testUrl = 'https://speed.cloudflare.com/__down?bytes=10485760';
    final startTime = DateTime.now();

    try {
      await dio.get(
        testUrl,
        onReceiveProgress: (count, total) {
          if (mounted) setState(() => _testProgress = count / 10485760);
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final endTime = DateTime.now();
      final durationMs = endTime.difference(startTime).inMilliseconds;
      final megabits = (10485760 * 8) / 1000000;
      final seconds = durationMs / 1000;
      final mbps = megabits / seconds;

      if (mounted) {
        setState(() {
          _lastSpeedMbps = mbps;
          _testingSpeed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _testingSpeed = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speed test failed. Check your connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(s.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.settingsBackdropGradient(_data.gradientPreset),
              ),
              child: ListView(
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
                Text(
                  s.sectionGradientTheme,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.gradientThemeCaption,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray.withOpacity(0.92),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      for (final preset in AppGradientPreset.values)
                        RadioListTile<AppGradientPreset>(
                          value: preset,
                          groupValue: _data.gradientPreset,
                          activeColor: AppTheme.primaryGold,
                          title: Text(_gradientPresetTitle(s, preset)),
                          secondary: _GradientPresetSwatch(preset: preset),
                          onChanged: (v) {
                            if (v != null) _apply(_data.copyWith(gradientPreset: v));
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionLanguage,
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
                    children: [
                      RadioListTile<String>(
                        value: 'ckb',
                        groupValue: uiLocale.languageCode,
                        activeColor: AppTheme.primaryGold,
                        title: Text(s.langKurdishSorani),
                        onChanged: (_) => ref.read(appLocaleProvider.notifier).setLocale(const Locale('ckb')),
                      ),
                      RadioListTile<String>(
                        value: 'en',
                        groupValue: uiLocale.languageCode,
                        activeColor: AppTheme.primaryGold,
                        title: Text(s.langEnglish),
                        onChanged: (_) => ref.read(appLocaleProvider.notifier).setLocale(const Locale('en')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                  s.sectionLibrary,
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
                    leading: const Icon(Icons.star_outline_rounded, color: AppTheme.primaryGold),
                    title: Text(s.clearFavoritesTitle),
                    subtitle: Text(s.clearFavoritesSub),
                    onTap: () => _confirmClearLibrary(
                      s,
                      dialogTitle: s.clearFavoritesTitle,
                      dialogBody: s.clearFavoritesSub,
                      onClear: () => ref.read(favoritesProvider.notifier).clearAll(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(Icons.history_rounded, color: Colors.white.withOpacity(0.85)),
                    title: Text(s.clearRecentTitle),
                    subtitle: Text(s.clearRecentSub),
                    onTap: () => _confirmClearLibrary(
                      s,
                      dialogTitle: s.clearRecentTitle,
                      dialogBody: s.clearRecentSub,
                      onClear: () => ref.read(recentChannelsProvider.notifier).clearAll(),
                    ),
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
                  'Network Diagnostics',
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
                    children: [
                      ListTile(
                        leading: const Icon(Icons.speed_rounded, color: AppTheme.accentTeal),
                        title: const Text('Internet Speed Test'),
                        subtitle: Text(
                          _lastSpeedMbps != null
                              ? 'Last result: ${_lastSpeedMbps!.toStringAsFixed(1)} Mbps'
                              : 'Test your connection speed for 4K/HD streaming',
                        ),
                        trailing: _testingSpeed
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: _testProgress,
                                  strokeWidth: 3,
                                  color: AppTheme.primaryGold,
                                ),
                              )
                            : TextButton(
                                onPressed: _runSpeedTest,
                                child: const Text('RUN TEST', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                              ),
                      ),
                      if (_testingSpeed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: LinearProgressIndicator(
                            value: _testProgress,
                            backgroundColor: Colors.white10,
                            color: AppTheme.primaryGold,
                            minHeight: 2,
                          ),
                        ),
                    ],
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
            ),
    );
  }
}

String _gradientPresetTitle(AppStrings s, AppGradientPreset p) {
  return switch (p) {
    AppGradientPreset.classic => s.gradientClassic,
    AppGradientPreset.oceanAbyss => s.gradientOcean,
    AppGradientPreset.goldSunset => s.gradientGold,
    AppGradientPreset.violetHaze => s.gradientViolet,
    AppGradientPreset.emberGlow => s.gradientEmber,
  };
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
