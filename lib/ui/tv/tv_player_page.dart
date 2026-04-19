import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../core/theme.dart';
import '../../../services/playlist_service.dart';
import '../../../widgets/tv_fluid_focusable.dart';
import '../../../widgets/channel_logo_image.dart';

class TvPlayerPage extends ConsumerStatefulWidget {
  final List<Channel> channels;
  final int initialIndex;

  const TvPlayerPage({
    super.key,
    required this.channels,
    required this.initialIndex,
  });

  @override
  ConsumerState<TvPlayerPage> createState() => _TvPlayerPageState();
}

class _TvPlayerPageState extends ConsumerState<TvPlayerPage> {
  late VideoPlayerController _controller;
  late int _index;
  bool _overlayVisible = true;
  bool _zapListVisible = false;
  bool _settingsVisible = false;
  Timer? _hideTimer;
  bool _isInitialized = false;

  Channel get _current => widget.channels[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _initPlayer();
    _startHideTimer();
  }

  Future<void> _initPlayer() async {
    setState(() => _isInitialized = false);
    _controller = VideoPlayerController.networkUrl(Uri.parse(_current.url));
    
    try {
      await _controller.initialize();
      await _controller.play();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('TV ExoPlayer Error: $e');
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_zapListVisible && !_settingsVisible) setState(() => _overlayVisible = false);
    });
  }

  void _toggleOverlay() {
    setState(() {
      _overlayVisible = !_overlayVisible;
      if (_overlayVisible) _startHideTimer();
    });
  }

  Future<void> _changeChannel(int newIndex) async {
    if (newIndex >= 0 && newIndex < widget.channels.length) {
      setState(() {
        _index = newIndex;
        _zapListVisible = false;
        _settingsVisible = false;
      });
      await _controller.dispose();
      await _initPlayer();
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKey: (node, event) {
          if (event is RawKeyDownEvent && event.data.logicalKey == event.logicalKey) { // Simple debounce
            // Handle Zap List Toggle (OK/SELECT)
            if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
              setState(() {
                _zapListVisible = !_zapListVisible;
                _settingsVisible = false;
              });
              if (_zapListVisible) _overlayVisible = true;
              return KeyEventResult.handled;
            }
            // If overlay is hidden, any key shows it
            if (!_overlayVisible) {
              _toggleOverlay();
              return KeyEventResult.handled;
            }

            // D-Pad Navigation
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_zapListVisible || _settingsVisible) return KeyEventResult.ignored;
              setState(() {
                _settingsVisible = true;
                _zapListVisible = false;
              });
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (_zapListVisible || _settingsVisible) return KeyEventResult.ignored;
               _changeChannel((_index - 1) % widget.channels.length);
               return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
               if (_zapListVisible || _settingsVisible) return KeyEventResult.ignored;
               _changeChannel((_index + 1) % widget.channels.length);
               return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _toggleOverlay,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Player
              Center(
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(color: AppTheme.primaryGold),
              ),

              // 2. Cinematic HUD
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _overlayVisible ? 1 : 0,
                child: _buildHud(),
              ),

              // 3. Side Panels
              if (_zapListVisible) _buildQuickZap(),
              if (_settingsVisible) _buildLiveSettings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.transparent,
            Colors.black.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopPlayerBar(),
          const Spacer(),
          _buildBottomPlayerBar(),
        ],
      ),
    );
  }

  Widget _buildTopPlayerBar() {
    return Row(
      children: [
        ChannelLogoImage(logo: _current.logo, height: 80, width: 80),
        const SizedBox(width: 30),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _current.group.toUpperCase(),
                style: TextStyle(color: AppTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
              Text(
                _current.name,
                style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, height: 1.1),
              ),
            ],
          ),
        ),
        GhostenFocusable(
          onTap: () => setState(() => _settingsVisible = !_settingsVisible),
          child: _buildActionShortcut(Icons.settings_outlined, 'LIVE SETTINGS'),
        ),
        const SizedBox(width: 20),
        _buildActionShortcut(Icons.closed_caption_rounded, 'ENG'),
        const SizedBox(width: 20),
        _buildActionShortcut(Icons.audiotrack_rounded, 'AUTO'),
      ],
    );
  }

  Widget _buildBottomPlayerBar() {
    return Column(
      children: [
        // Progress Bar (Status of Live stream metadata if available)
        Container(
          height: 6,
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3)),
          child: Row(
            children: [
              Container(width: 2, decoration: BoxDecoration(color: AppTheme.primaryGold, borderRadius: BorderRadius.circular(3))),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildKeyHint(Icons.keyboard_arrow_up, 'LIVE SETTINGS'),
                const SizedBox(width: 40),
                _buildKeyHint(Icons.unfold_more_rounded, 'ZAP LIST'),
                const SizedBox(width: 40),
                _buildKeyHint(Icons.swap_horiz_rounded, 'PREV/NEXT'),
              ],
            ),
            Text('LIVE: OK', style: TextStyle(color: AppTheme.primaryGold.withOpacity(0.5), fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickZap() {
    return Positioned(
      top: 0,
      left: 0,
      bottom: 0,
      width: 450,
      child: _buildGlassPanel(
        title: 'QUICK ZAP',
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: widget.channels.length,
          itemBuilder: (context, idx) {
            final ch = widget.channels[idx];
            final isCurrent = idx == _index;
            return GhostenFocusable(
              onTap: () => _changeChannel(idx),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.primaryGold.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ChannelLogoImage(logo: ch.logo, height: 40, width: 40),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(ch.name, style: TextStyle(color: isCurrent ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveSettings() {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 450,
      child: _buildGlassPanel(
        title: 'LIVE SETTINGS',
        child: Column(
          children: [
            _buildSettingItem(Icons.star_border_rounded, 'Add to Favorites', 'Access this channel faster from Favorites'),
            _buildSettingItem(Icons.aspect_ratio_rounded, 'Aspect Ratio', 'Current: Original (Recommended)'),
            _buildSettingItem(Icons.sync_rounded, 'Audio Sync', 'Correct audio/video delay in milliseconds'),
            _buildSettingItem(Icons.speed_rounded, 'Stream Quality', 'Auto-adjusting based on your connection'),
            _buildSettingItem(Icons.refresh_rounded, 'Refresh Stream', 'Restart live link if buffering occurs'),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text('CHANNEL ID: ${_current.name.hashCode}', style: const TextStyle(color: Colors.white10, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassPanel({required String title, required Widget child}) {
    return GlassmorphicContainer(
      width: 450,
      height: double.infinity,
      borderRadius: 0,
      blur: 35,
      alignment: Alignment.center,
      border: 0,
      linearGradient: LinearGradient(colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.4)]),
      borderGradient: LinearGradient(colors: [Colors.white10, Colors.white10]),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 5)),
                GhostenFocusable(onTap: () => setState(() { _zapListVisible = false; _settingsVisible = false; }), child: const Icon(Icons.close_rounded, color: Colors.white24)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 40, indent: 40, endIndent: 40),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GhostenFocusable(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 24),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionShortcut(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [Icon(icon, color: Colors.white70, size: 20), const SizedBox(width: 12), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]),
    );
  }

  Widget _buildKeyHint(IconData icon, String label) {
    return Row(children: [Icon(icon, color: Colors.white30, size: 20), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 1.5))]);
  }
}
