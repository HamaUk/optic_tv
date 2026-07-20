import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_settings_page.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_strings.dart';
import '../../../providers/app_locale_provider.dart';
import '../../../providers/ui_settings_provider.dart';

class PlaybackSettingsPage extends ConsumerWidget {
  const PlaybackSettingsPage({super.key});

  static const _fitChoices = <BoxFit>[
    BoxFit.contain,
    BoxFit.cover,
    BoxFit.fill,
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);
    final uiSettings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();

    return BaseSettingsPage(
      title: s.sectionPlayback,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          glassCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(s.keepScreenOnTitle, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.keepScreenOnSub, style: const TextStyle(color: Colors.white70)),
                  value: uiSettings.keepScreenOnWhilePlaying,
                  activeTrackColor: AppTheme.accentColor(uiSettings.gradientPreset).withValues(alpha: 0.45),
                  activeThumbColor: AppTheme.accentColor(uiSettings.gradientPreset),
                  onChanged: (v) => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(keepScreenOnWhilePlaying: v)),
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  title: Text(s.autoHideTitle, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.autoHideSub, style: const TextStyle(color: Colors.white70)),
                  value: uiSettings.autoHidePlayerControls,
                  activeTrackColor: AppTheme.accentColor(uiSettings.gradientPreset).withValues(alpha: 0.45),
                  activeThumbColor: AppTheme.accentColor(uiSettings.gradientPreset),
                  onChanged: (v) => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(autoHidePlayerControls: v)),
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  title: Text(s.clockTitle, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.clockSub, style: const TextStyle(color: Colors.white70)),
                  value: uiSettings.showOnScreenClock,
                  activeTrackColor: AppTheme.accentColor(uiSettings.gradientPreset).withValues(alpha: 0.45),
                  activeThumbColor: AppTheme.accentColor(uiSettings.gradientPreset),
                  onChanged: (v) => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(showOnScreenClock: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            s.sectionSubtitles,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor(uiSettings.gradientPreset),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(s.subtitleCaption, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
          const SizedBox(height: 12),
          glassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.subtitleFontSize, style: const TextStyle(color: Colors.white)),
                  Slider(
                    value: uiSettings.subtitleFontSize,
                    min: 10,
                    max: 40,
                    activeColor: AppTheme.accentColor(uiSettings.gradientPreset),
                    onChanged: (v) => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(subtitleFontSize: v)),
                  ),
                  const SizedBox(height: 16),
                  Text(s.subtitleColor, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _colorCircle(0xFFFFFFFF, uiSettings.subtitleColor, uiSettings, ref), // White
                      _colorCircle(0xFFFFFF00, uiSettings.subtitleColor, uiSettings, ref), // Yellow
                      _colorCircle(0xFF00FFFF, uiSettings.subtitleColor, uiSettings, ref), // Cyan
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(s.subtitleBgOpacity, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _bgCircle(0x00000000, uiSettings.subtitleBgColor, s.subtitleBgOff, uiSettings, ref), // Transparent
                      _bgCircle(0x73000000, uiSettings.subtitleBgColor, s.subtitleBgSemi, uiSettings, ref), // Semi
                      _bgCircle(0xFF000000, uiSettings.subtitleBgColor, s.subtitleBgSolid, uiSettings, ref), // Solid
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
                        color: Color(uiSettings.subtitleBgColor),
                        child: Text(
                          s.subtitleSample,
                          style: TextStyle(
                            color: Color(uiSettings.subtitleColor),
                            fontSize: uiSettings.subtitleFontSize,
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
                  color: AppTheme.accentColor(uiSettings.gradientPreset),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          glassCard(
            child: Column(
              children: [
                for (final fit in _fitChoices)
                  RadioListTile<BoxFit>(
                    value: fit,
                    groupValue: uiSettings.videoFit,
                    activeColor: AppTheme.accentColor(uiSettings.gradientPreset),
                    title: Text(s.fitLabel(fit), style: const TextStyle(color: Colors.white)),
                    onChanged: (v) {
                      if (v != null) ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(videoFit: v));
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            s.sectionPlaybackNetwork,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor(uiSettings.gradientPreset),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          glassCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(s.hardwareAccel, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.hardwareAccelSub, style: const TextStyle(color: Colors.white70)),
                  value: uiSettings.hardwareAcceleration,
                  activeTrackColor: AppTheme.accentColor(uiSettings.gradientPreset).withValues(alpha: 0.45),
                  activeThumbColor: AppTheme.accentColor(uiSettings.gradientPreset),
                  onChanged: (v) => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(hardwareAcceleration: v)),
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  title: Text(s.dataSaver, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.dataSaverSub, style: const TextStyle(color: Colors.white70)),
                  value: uiSettings.dataSaverMode,
                  activeTrackColor: AppTheme.accentColor(uiSettings.gradientPreset).withValues(alpha: 0.45),
                  activeThumbColor: AppTheme.accentColor(uiSettings.gradientPreset),
                  onChanged: (v) => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(dataSaverMode: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorCircle(int colorValue, int activeColor, AppSettingsData uiSettings, WidgetRef ref) {
    final active = activeColor == colorValue;
    return GestureDetector(
      onTap: () => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(subtitleColor: colorValue)),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: active ? AppTheme.accentColor(uiSettings.gradientPreset) : Colors.white24, width: active ? 3 : 1),
          boxShadow: active ? [BoxShadow(color: AppTheme.accentColor(uiSettings.gradientPreset).withValues(alpha: 0.5), blurRadius: 8)] : [],
        ),
      ),
    );
  }

  Widget _bgCircle(int colorValue, int activeColor, String label, AppSettingsData uiSettings, WidgetRef ref) {
    final active = activeColor == colorValue;
    return GestureDetector(
      onTap: () => ref.read(appUiSettingsProvider.notifier).apply(uiSettings.copyWith(subtitleBgColor: colorValue)),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
              border: Border.all(color: active ? AppTheme.accentColor(uiSettings.gradientPreset) : Colors.white24, width: active ? 3 : 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.white54)),
        ],
      ),
    );
  }
}
