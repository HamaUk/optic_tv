import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_settings_page.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_strings.dart';
import '../../../providers/app_locale_provider.dart';
import '../../../providers/ui_settings_provider.dart';

class DiagnosticSettingsPage extends ConsumerStatefulWidget {
  const DiagnosticSettingsPage({super.key});

  @override
  ConsumerState<DiagnosticSettingsPage> createState() => _DiagnosticSettingsPageState();
}

class _DiagnosticSettingsPageState extends ConsumerState<DiagnosticSettingsPage> {
  bool _testingSpeed = false;
  double? _lastSpeedMbps;
  double _testProgress = 0;

  Future<void> _runSpeedTest() async {
    if (_testingSpeed) return;
    setState(() {
      _testingSpeed = true;
      _testProgress = 0;
      _lastSpeedMbps = null;
    });

    final dio = Dio();
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
    final uiSettings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();

    return BaseSettingsPage(
      title: s.sectionDiagnostics,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          glassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tv_rounded, color: Colors.amberAccent),
                  title: Text(s.displayOutput, style: const TextStyle(color: Colors.white)),
                  subtitle: Builder(
                    builder: (ctx) {
                      final w = MediaQuery.sizeOf(ctx).width * MediaQuery.devicePixelRatioOf(ctx);
                      if (w >= 3800) return Text(s.display4k, style: const TextStyle(color: Colors.white70));
                      if (w >= 1900) return Text(s.display1080p, style: const TextStyle(color: Colors.white70));
                      return Text(s.display720p, style: const TextStyle(color: Colors.white70));
                    },
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.speed_rounded, color: AppTheme.accentTeal),
                  title: Text(s.speedTest, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    _lastSpeedMbps != null
                        ? s.speedTestResult(_lastSpeedMbps!.toStringAsFixed(1))
                        : s.speedTestSub,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: _testingSpeed
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: _testProgress,
                            strokeWidth: 3,
                            color: AppTheme.accentColor(uiSettings.gradientPreset),
                          ),
                        )
                      : TextButton(
                          onPressed: _runSpeedTest,
                          child: Text(s.runTest, style: TextStyle(color: AppTheme.accentColor(uiSettings.gradientPreset), fontWeight: FontWeight.bold)),
                        ),
                ),
                if (_testingSpeed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: LinearProgressIndicator(
                      value: _testProgress,
                      backgroundColor: Colors.white10,
                      color: AppTheme.accentColor(uiSettings.gradientPreset),
                      minHeight: 2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
