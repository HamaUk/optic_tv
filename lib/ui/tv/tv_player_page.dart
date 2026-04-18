import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  void _toggleOverlay() {
    setState(() {
      _overlayVisible = !_overlayVisible;
      if (_overlayVisible) _startHideTimer();
    });
  }

  Future<void> _handleNext() async {
    if (_index < widget.channels.length - 1) {
      setState(() => _index++);
      await _controller.dispose();
      _initPlayer();
      _startHideTimer();
    }
  }

  Future<void> _handlePrev() async {
    if (_index > 0) {
      setState(() => _index--);
      await _controller.dispose();
      _initPlayer();
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
            if (!_overlayVisible) {
              _toggleOverlay();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _handleNext();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _handlePrev();
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
              // 1. Video Background
              Center(
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(color: AppTheme.primaryGold),
              ),

              // 2. Cinematic HUD Overlay
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _overlayVisible ? 1 : 0,
                child: _overlayVisible ? _buildHud() : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
            Colors.black.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.all(40),
            child: Row(
              children: [
                ChannelLogoImage(logo: _current.logo, height: 60, width: 60),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _current.group.toUpperCase(),
                      style: TextStyle(color: AppTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    Text(
                      _current.name,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          
          // Bottom Navigation Hint
          Padding(
            padding: const EdgeInsets.all(40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildKeyHint(Icons.arrow_back, 'PREVIOUS'),
                const SizedBox(width: 40),
                _buildKeyHint(Icons.arrow_forward, 'NEXT'),
                const SizedBox(width: 40),
                _buildKeyHint(Icons.keyboard_return, 'BACK TO GUIDE'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyHint(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white24, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white24, letterSpacing: 1, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
