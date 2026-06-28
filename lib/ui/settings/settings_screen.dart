import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/tv/tv_focusable.dart';
import '../../widgets/animated_gradient_border.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/settings_service.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/update_service.dart';
import '../../widgets/update_prompt_dialog.dart';

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

  // Storage Manager state
  bool _calculatingStorage = true;
  int _posterCacheBytes = 0;
  int _epgCacheBytes = 0;
  int _logsCacheBytes = 0;

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
      _calculateStorage();
    }
  }

  Future<void> _calculateStorage() async {
    if (!mounted) return;
    setState(() => _calculatingStorage = true);
    
    int posters = 0;
    int epg = 0;
    int logs = 0;
    
    try {
      final cacheDir = await getTemporaryDirectory();
      // Heuristic directories for the example
      final posterDir = Directory('${cacheDir.path}/libCachedImageData');
      final epgDir = Directory('${cacheDir.path}/epg_data');
      final logDir = Directory('${cacheDir.path}/logs');
      
      posters = await _getDirSize(posterDir);
      epg = await _getDirSize(epgDir);
      logs = await _getDirSize(logDir);
    } catch (_) {}
    
    if (mounted) {
      setState(() {
        _posterCacheBytes = posters;
        _epgCacheBytes = epg;
        _logsCacheBytes = logs;
        _calculatingStorage = false;
      });
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int total = 0;
    if (await dir.exists()) {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          total += await file.length();
        }
      }
    }
    return total;
  }

  Future<void> _clearSpecificCache(String type) async {
    final cacheDir = await getTemporaryDirectory();
    try {
      if (type == 'posters') {
        final dir = Directory('${cacheDir.path}/libCachedImageData');
        if (await dir.exists()) await dir.delete(recursive: true);
      } else if (type == 'epg') {
        final dir = Directory('${cacheDir.path}/epg_data');
        if (await dir.exists()) await dir.delete(recursive: true);
      } else if (type == 'logs') {
        final dir = Directory('${cacheDir.path}/logs');
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    } catch (_) {}
    await _calculateStorage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cleared \$type cache')));
    }
  }

  Future<void> _apply(AppSettingsData next) async {
    setState(() => _data = next);
    await ref.read(appUiSettingsProvider.notifier).apply(next);
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel, style: const TextStyle(color: Colors.white54))),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.clearButton.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              elevation: 0,
              title: Text(s.settingsTitle, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accentColor(_data.gradientPreset)))
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
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.sectionGradientTheme,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.gradientThemeCaption,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: Column(
                    children: [
                      for (final preset in AppGradientPreset.values)
                        TVFocusable(
                          showFocusBorder: true,
                          focusScale: 1.02,
                          borderRadius: BorderRadius.circular(16),
                          child: RadioListTile<AppGradientPreset>(
                          value: preset,
                          groupValue: _data.gradientPreset,
                          activeColor: AppTheme.accentColor(_data.gradientPreset),
                          title: Text(_gradientPresetTitle(s, preset)),
                          secondary: _GradientPresetSwatch(preset: preset),
                          onChanged: (v) {
                            if (v != null) _apply(_data.copyWith(gradientPreset: v));
                          },
                        ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionLanguage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: Column(
                    children: [
                      TVFocusable(
                        showFocusBorder: true,
                        focusScale: 1.02,
                        borderRadius: BorderRadius.circular(16),
                        child: RadioListTile<String>(
                          value: 'ckb',
                          groupValue: uiLocale.languageCode,
                          activeColor: AppTheme.accentColor(_data.gradientPreset),
                          title: Text(s.langKurdishSorani),
                          onChanged: (_) => ref.read(appLocaleProvider.notifier).setLocale(const Locale('ckb')),
                        ),
                      ),
                      TVFocusable(
                        showFocusBorder: true,
                        focusScale: 1.02,
                        borderRadius: BorderRadius.circular(16),
                        child: RadioListTile<String>(
                          value: 'kmr',
                          groupValue: uiLocale.languageCode,
                          activeColor: AppTheme.accentColor(_data.gradientPreset),
                          title: Text(s.langKurdishKurmanji),
                          onChanged: (_) => ref.read(appLocaleProvider.notifier).setLocale(const Locale('kmr')),
                        ),
                      ),
                      TVFocusable(
                        showFocusBorder: true,
                        focusScale: 1.02,
                        borderRadius: BorderRadius.circular(16),
                        child: RadioListTile<String>(
                          value: 'en',
                          groupValue: uiLocale.languageCode,
                          activeColor: AppTheme.accentColor(_data.gradientPreset),
                          title: Text(s.langEnglish),
                          onChanged: (_) => ref.read(appLocaleProvider.notifier).setLocale(const Locale('en')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _glassCard(
                  child: SwitchListTile(
                    title: Text(s.reduceMotionTitle),
                    subtitle: Text(s.reduceMotionSub),
                    value: _data.reduceMotion,
                    activeTrackColor: AppTheme.accentColor(_data.gradientPreset).withOpacity(0.45),
                    activeColor: AppTheme.accentColor(_data.gradientPreset),
                    onChanged: (v) => _apply(_data.copyWith(reduceMotion: v)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionPlayback,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: SwitchListTile(
                    title: Text(s.keepScreenOnTitle),
                    subtitle: Text(s.keepScreenOnSub),
                    value: _data.keepScreenOnWhilePlaying,
                    activeTrackColor: AppTheme.accentColor(_data.gradientPreset).withOpacity(0.45),
                    activeColor: AppTheme.accentColor(_data.gradientPreset),
                    onChanged: (v) => _apply(_data.copyWith(keepScreenOnWhilePlaying: v)),
                  ),
                ),
                const SizedBox(height: 8),
                _glassCard(
                  child: SwitchListTile(
                    title: Text(s.autoHideTitle),
                    subtitle: Text(s.autoHideSub),
                    value: _data.autoHidePlayerControls,
                    activeTrackColor: AppTheme.accentColor(_data.gradientPreset).withOpacity(0.45),
                    activeColor: AppTheme.accentColor(_data.gradientPreset),
                    onChanged: (v) => _apply(_data.copyWith(autoHidePlayerControls: v)),
                  ),
                ),
                const SizedBox(height: 8),
                _glassCard(
                  child: SwitchListTile(
                    title: Text(s.clockTitle),
                    subtitle: Text(s.clockSub),
                    value: _data.showOnScreenClock,
                    activeTrackColor: AppTheme.accentColor(_data.gradientPreset).withOpacity(0.45),
                    activeColor: AppTheme.accentColor(_data.gradientPreset),
                    onChanged: (v) => _apply(_data.copyWith(showOnScreenClock: v)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionStorage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.image_rounded, color: Colors.blueAccent),
                        title: Text(s.storagePosters),
                        subtitle: Text(_calculatingStorage ? s.calculating : "${(_posterCacheBytes / (1024 * 1024)).toStringAsFixed(1)} MB"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _clearSpecificCache('posters'),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      ListTile(
                        leading: const Icon(Icons.list_alt_rounded, color: Colors.greenAccent),
                        title: Text(s.storageEpg),
                        subtitle: Text(_calculatingStorage ? s.calculating : "${(_epgCacheBytes / (1024 * 1024)).toStringAsFixed(1)} MB"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _clearSpecificCache('epg'),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      ListTile(
                        leading: const Icon(Icons.bug_report_rounded, color: Colors.orangeAccent),
                        title: Text(s.storageLogs),
                        subtitle: Text(_calculatingStorage ? s.calculating : "${(_logsCacheBytes / (1024 * 1024)).toStringAsFixed(1)} MB"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _clearSpecificCache('logs'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionSubtitles,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(s.subtitleCaption, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                const SizedBox(height: 12),
                _glassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.subtitleFontSize),
                        Slider(
                          value: _data.subtitleFontSize,
                          min: 10,
                          max: 40,
                          activeColor: AppTheme.accentColor(_data.gradientPreset),
                          onChanged: (v) => _apply(_data.copyWith(subtitleFontSize: v)),
                        ),
                        const SizedBox(height: 16),
                        Text(s.subtitleColor),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _colorCircle(0xFFFFFFFF, _data.subtitleColor), // White
                            _colorCircle(0xFFFFFF00, _data.subtitleColor), // Yellow
                            _colorCircle(0xFF00FFFF, _data.subtitleColor), // Cyan
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(s.subtitleBgOpacity),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _bgCircle(0x00000000, _data.subtitleBgColor, s.subtitleBgOff), // Transparent
                            _bgCircle(0x73000000, _data.subtitleBgColor, s.subtitleBgSemi), // Semi
                            _bgCircle(0xFF000000, _data.subtitleBgColor, s.subtitleBgSolid), // Solid
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              color: Color(_data.subtitleBgColor),
                              child: Text(
                                s.subtitleSample,
                                style: TextStyle(
                                  color: Color(_data.subtitleColor),
                                  fontSize: _data.subtitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionVideo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(s.videoFitCaption, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                const SizedBox(height: 12),
                _glassCard(
                  child: Column(
                    children: [
                      for (final fit in _fitChoices)
                        TVFocusable(
                          showFocusBorder: true,
                          focusScale: 1.02,
                          borderRadius: BorderRadius.circular(16),
                          child: RadioListTile<BoxFit>(
                          value: fit,
                          groupValue: _data.videoFit,
                          activeColor: AppTheme.accentColor(_data.gradientPreset),
                          title: Text(s.fitLabel(fit)),
                          onChanged: (v) {
                            if (v != null) _apply(_data.copyWith(videoFit: v));
                          },
                        ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionPlaybackNetwork,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: SwitchListTile(
                    title: Text(s.hardwareAccel),
                    subtitle: Text(s.hardwareAccelSub),
                    value: _data.hardwareAcceleration,
                    activeTrackColor: AppTheme.accentColor(_data.gradientPreset).withOpacity(0.45),
                    activeColor: AppTheme.accentColor(_data.gradientPreset),
                    onChanged: (v) => _apply(_data.copyWith(hardwareAcceleration: v)),
                  ),
                ),
                const SizedBox(height: 8),
                _glassCard(
                  child: SwitchListTile(
                    title: Text(s.dataSaver),
                    subtitle: Text(s.dataSaverSub),
                    value: _data.dataSaverMode,
                    activeTrackColor: AppTheme.accentColor(_data.gradientPreset).withOpacity(0.45),
                    activeColor: AppTheme.accentColor(_data.gradientPreset),
                    onChanged: (v) => _apply(_data.copyWith(dataSaverMode: v)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionLibrary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: ListTile(
                    leading: Icon(Icons.star_outline_rounded, color: AppTheme.accentColor(_data.gradientPreset)),
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
                _glassCard(
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
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.orangeAccent),
                    title: Text(s.logoutTitle),
                    subtitle: Text(s.logoutSub),
                    onTap: () => _confirmLogout(s),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionDiagnostics,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: Column(
                    children: [
                      TVFocusable(
                        showFocusBorder: true,
                        focusScale: 1.02,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          leading: const Icon(Icons.tv_rounded, color: Colors.amberAccent),
                          title: Text(s.displayOutput),
                          subtitle: Builder(
                            builder: (ctx) {
                              final w = MediaQuery.sizeOf(ctx).width * MediaQuery.devicePixelRatioOf(ctx);
                              if (w >= 3800) return Text(s.display4k);
                              if (w >= 1900) return Text(s.display1080p);
                              return Text(s.display720p);
                            },
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      TVFocusable(
                        showFocusBorder: true,
                        focusScale: 1.02,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                        leading: const Icon(Icons.speed_rounded, color: AppTheme.accentTeal),
                        title: Text(s.speedTest),
                        subtitle: Text(
                          _lastSpeedMbps != null
                              ? s.speedTestResult(_lastSpeedMbps!.toStringAsFixed(1))
                              : s.speedTestSub,
                        ),
                        trailing: _testingSpeed
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: _testProgress,
                                  strokeWidth: 3,
                                  color: AppTheme.accentColor(_data.gradientPreset),
                                ),
                              )
                            : TextButton(
                                onPressed: _runSpeedTest,
                                child: Text(s.runTest, style: TextStyle(color: AppTheme.accentColor(_data.gradientPreset), fontWeight: FontWeight.bold)),
                              ),
                      ),
                      ),
                      if (_testingSpeed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: LinearProgressIndicator(
                            value: _testProgress,
                            backgroundColor: Colors.white10,
                            color: AppTheme.accentColor(_data.gradientPreset),
                            minHeight: 2,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.sectionSupport,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: ListTile(
                    leading: const Icon(Icons.update_rounded, color: Colors.greenAccent),
                    title: Text(s.checkUpdates),
                    subtitle: Text(s.checkUpdatesSub),
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
                ),
                const SizedBox(height: 8),
                _glassCard(
                  child: ListTile(
                    leading: const Icon(Icons.telegram_rounded, color: Colors.blueAccent),
                    title: Text(s.joinTelegram),
                    subtitle: Text(s.joinTelegramSub),
                    onTap: () async {
                      final url = Uri.parse('https://t.me/KOBANI4K');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),

                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor(_data.gradientPreset),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'KOBANI 4K',
                        style: const TextStyle(
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

                      Text(
                        '© 2026 KOBANI 4K. All rights reserved.',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
              ),
            ),
    );
  }

  Widget _changelogCard({required IconData icon, required Color color, required String title, required String subtitle}) {
    return _glassCard(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return AnimatedGradientBorder(
      borderWidth: 2,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: child,
          ),
        ),
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

  Widget _colorCircle(int colorValue, int activeColor) {
    final active = activeColor == colorValue;
    return GestureDetector(
      onTap: () => _apply(_data.copyWith(subtitleColor: colorValue)),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: active ? AppTheme.accentColor(_data.gradientPreset) : Colors.white24, width: active ? 3 : 1),
          boxShadow: active ? [BoxShadow(color: AppTheme.accentColor(_data.gradientPreset).withOpacity(0.5), blurRadius: 8)] : [],
        ),
      ),
    );
  }

  Widget _bgCircle(int colorValue, int activeColor, String label) {
    final active = activeColor == colorValue;
    return GestureDetector(
      onTap: () => _apply(_data.copyWith(subtitleBgColor: colorValue)),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
              border: Border.all(color: active ? AppTheme.accentColor(_data.gradientPreset) : Colors.white24, width: active ? 3 : 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.white54)),
        ],
      ),
    );
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
