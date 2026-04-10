import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text(
                  'Playback',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: const Text('Keep screen on while playing'),
                    subtitle: const Text('Prevents dimming during video'),
                    value: _data.keepScreenOnWhilePlaying,
                    activeTrackColor: AppTheme.primaryBlue.withOpacity(0.5),
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (v) => _apply(_data.copyWith(keepScreenOnWhilePlaying: v)),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: const Text('Auto-hide player controls'),
                    subtitle: const Text('Controls fade after a few seconds; tap video to show'),
                    value: _data.autoHidePlayerControls,
                    activeTrackColor: AppTheme.primaryBlue.withOpacity(0.5),
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (v) => _apply(_data.copyWith(autoHidePlayerControls: v)),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: const Text('Clock in player'),
                    subtitle: const Text('Show time in the top bar while watching'),
                    value: _data.showOnScreenClock,
                    activeTrackColor: AppTheme.primaryBlue.withOpacity(0.5),
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (v) => _apply(_data.copyWith(showOnScreenClock: v)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Video fit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'How the stream scales inside the player',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      for (var i = 0; i < _fitChoices.length; i++)
                        RadioListTile<BoxFit>(
                          value: _fitChoices[i],
                          groupValue: _data.videoFit,
                          activeColor: AppTheme.primaryBlue,
                          title: Text(AppSettingsData.labelForFit(_fitChoices[i])),
                          onChanged: (fit) {
                            if (fit != null) _apply(_data.copyWith(videoFit: fit));
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.surfaceGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.white70),
                    title: Text('Optic TV'),
                    subtitle: Text('Version 1.0.0 · Premium IPTV client'),
                  ),
                ),
              ],
            ),
    );
  }
}
