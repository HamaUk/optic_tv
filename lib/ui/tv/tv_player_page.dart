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
      if (mounted && !_zapListVisible) setState(() => _overlayVisible = false);
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
          if (event is RawKeyDownEvent) {
            // Handle Zap List Toggle
            if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
              setState(() => _zapListVisible = !_zapListVisible);
              if (_zapListVisible) _overlayVisible = true;
              return KeyEventResult.handled;
            }
            // If overlay is hidden, any key shows it
            if (!_overlayVisible) {
              _toggleOverlay();
              return KeyEventResult.handled;
            }
            // Zapping
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _changeChannel((_index - 1) % widget.channels.length);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _changeChannel((_index + 1) % widget.channels.length);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
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

            // 3. Side Quick Zap List
            if (_zapListVisible) _buildQuickZap(),
          ],
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
        _buildActionShortcut(Icons.closed_caption_rounded, 'ENG'),
        const SizedBox(width: 20),
        _buildActionShortcut(Icons.audiotrack_rounded, 'AUTO'),
      ],
    );
  }

  Widget _buildBottomPlayerBar() {
    return Column(
      children: [
        // Progress Bar
        Container(
          height: 6,
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3)),
          child: Row(
            children: [
              Container(width: 150, decoration: BoxDecoration(color: AppTheme.primaryGold, borderRadius: BorderRadius.circular(3))),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildKeyHint(Icons.unfold_more_rounded, 'ZAP LIST'),
                const SizedBox(width: 40),
                _buildKeyHint(Icons.swap_vert_rounded, 'CHANGE CH'),
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
      right: 0,
      bottom: 0,
      width: 450,
      child: GlassmorphicContainer(
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
            Text('QUICK ZAP', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 5)),
            const Divider(color: Colors.white10, height: 40, indent: 40, endIndent: 40),
            Expanded(
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionShortcut(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(icon, color: Colors.white70, size: 20), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildKeyHint(IconData icon, String label) {
    return Row(children: [Icon(icon, color: Colors.white30, size: 20), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 1.5))]);
  }
}
