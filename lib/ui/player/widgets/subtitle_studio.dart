import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../../core/theme.dart';
import '../../../providers/ui_settings_provider.dart';
import '../../../services/settings_service.dart';

class SubtitleStudioModal extends ConsumerStatefulWidget {
  final Player player;
  const SubtitleStudioModal({super.key, required this.player});

  static Future<void> show(BuildContext context, Player player) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SubtitleStudioModal(player: player),
    );
  }

  @override
  ConsumerState<SubtitleStudioModal> createState() => _SubtitleStudioModalState();
}

class _SubtitleStudioModalState extends ConsumerState<SubtitleStudioModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appUiSettingsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // 1. Header & Live Preview
          _buildHeader(context),
          _buildLivePreview(settingsAsync.asData?.value ?? const AppSettingsData()),
          
          // 2. Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accentTeal,
            dividerColor: Colors.white10,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            tabs: const [
              Tab(text: 'TRACKS & LANGUAGES'),
              Tab(text: 'APPEARANCE & STYLE'),
            ],
          ),
          
          // 3. Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrackList(),
                _buildAppearanceSettings(settingsAsync.asData?.value ?? const AppSettingsData()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUBTITLE STUDIO',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              Text(
                'Customize your cinematic experience',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview(AppSettingsData settings) {
    return Container(
      margin: const EdgeInsets.all(24),
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('Video Preview Background', style: TextStyle(color: Colors.white10, fontSize: 10)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(settings.subtitleBgColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Sample Subtitle Preview Text',
              style: TextStyle(
                color: Color(settings.subtitleColor),
                fontSize: settings.subtitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList() {
    final tracks = widget.player.state.tracks.subtitle;
    final current = widget.player.state.track.subtitle;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (tracks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text('No subtitle tracks found for this content', style: TextStyle(color: Colors.white38)),
            ),
          ),
        ...tracks.map((t) {
          final active = t == current;
          return _buildSettingsOption(
            title: t.title ?? t.language ?? (t.uri != null ? 'Manual File' : 'Track ${t.id}'),
            icon: Icons.subtitles_rounded,
            active: active,
            onTap: () {
              widget.player.setSubtitleTrack(t);
              setState(() {});
            },
          );
        }),
        const SizedBox(height: 12),
        _buildSettingsOption(
          title: 'None (Off)',
          icon: Icons.subtitles_off_rounded,
          active: current == SubtitleTrack.no(),
          onTap: () {
            widget.player.setSubtitleTrack(SubtitleTrack.no());
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings(AppSettingsData settings) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // FONT SIZE
        const Text('FONT SIZE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        Slider(
          value: settings.subtitleFontSize,
          min: 12,
          max: 48,
          activeColor: AppTheme.accentTeal,
          onChanged: (v) => _updateSettings(settings.copyWith(subtitleFontSize: v)),
        ),
        
        const SizedBox(height: 32),
        
        // BACKGROUND STYLE
        const Text('BACKGROUND STYLE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStyleChip(
              'Transparent',
              active: settings.subtitleBgColor == 0x00000000,
              onTap: () => _updateSettings(settings.copyWith(subtitleBgColor: 0x00000000)),
            ),
            const SizedBox(width: 12),
            _buildStyleChip(
              'Cinematic Black',
              active: settings.subtitleBgColor == 0xFF000000,
              onTap: () => _updateSettings(settings.copyWith(subtitleBgColor: 0xFF000000)),
            ),
             const SizedBox(width: 12),
            _buildStyleChip(
              'Semi-Transparent',
              active: settings.subtitleBgColor == 0x73000000,
              onTap: () => _updateSettings(settings.copyWith(subtitleBgColor: 0x73000000)),
            ),
          ],
        ),

        const SizedBox(height: 32),
        
        // TEXT COLOR
        const Text('TEXT COLOR', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildColorCircle(0xFFFFFFFF, active: settings.subtitleColor == 0xFFFFFFFF),
            _buildColorCircle(0xFFFFFF00, active: settings.subtitleColor == 0xFFFFFF00),
            _buildColorCircle(0xFF00FFFF, active: settings.subtitleColor == 0xFF00FFFF),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleChip(String label, {required bool active, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.accentTeal.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppTheme.accentTeal : Colors.white10),
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppTheme.accentTeal : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorCircle(int colorVal, {required bool active}) {
    return GestureDetector(
      onTap: () {
        final settings = ref.read(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
        _updateSettings(settings.copyWith(subtitleColor: colorVal));
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Color(colorVal),
          shape: BoxShape.circle,
          border: Border.all(color: active ? AppTheme.accentTeal : Colors.white10, width: active ? 3 : 1),
        ),
        child: active ? const Icon(Icons.check, color: Colors.black54) : null,
      ),
    );
  }

  Widget _buildSettingsOption({required String title, required IconData icon, required bool active, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? AppTheme.accentTeal.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: active ? AppTheme.accentTeal : Colors.white38),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: active ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
                if (active) const Icon(Icons.check_circle_rounded, color: AppTheme.accentTeal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateSettings(AppSettingsData newSettings) async {
    await newSettings.persist();
    ref.invalidate(appUiSettingsProvider);
  }
}
