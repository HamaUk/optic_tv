import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';

class PlayerScreen extends StatefulWidget {
  final List<Channel> channels;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.channels,
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final GlobalKey<VideoState> _videoKey = GlobalKey<VideoState>();
  late final Player _player;
  late final VideoController _controller;
  late int _index;
  AppSettingsData _settings = const AppSettingsData();
  bool _chromeVisible = true;
  Timer? _hideChromeTimer;
  Timer? _clockTimer;
  bool _playing = false;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Channel get _current => widget.channels[_index];

  bool get _canGoPrev => _index > 0;
  bool get _canGoNext => _index < widget.channels.length - 1;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.channels.length - 1);
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(_current.url));
    _subscriptions.add(
      _player.stream.playing.listen((v) {
        if (mounted) setState(() => _playing = v);
      }),
    );
    AppSettingsData.load().then((s) {
      if (!mounted) return;
      setState(() => _settings = s);
      _scheduleAutoHideChrome();
      _ensureClockTimer();
    });
  }

  void _ensureClockTimer() {
    _clockTimer?.cancel();
    if (_settings.showOnScreenClock) {
      _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _scheduleAutoHideChrome() {
    _hideChromeTimer?.cancel();
    if (!_settings.autoHidePlayerControls || !_chromeVisible) return;
    _hideChromeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  void _onChromeInteraction() {
    if (!_settings.autoHidePlayerControls) return;
    setState(() => _chromeVisible = true);
    _scheduleAutoHideChrome();
  }

  void _toggleChromeFromVideo() {
    if (!_settings.autoHidePlayerControls) return;
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) _scheduleAutoHideChrome();
  }

  @override
  void dispose() {
    _hideChromeTimer?.cancel();
    _clockTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  void _goRelative(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.channels.length) return;
    _onChromeInteraction();
    setState(() => _index = next);
    _player.open(Media(_current.url));
  }

  Future<void> _toggleFullscreen() async {
    _onChromeInteraction();
    await _videoKey.currentState?.toggleFullscreen();
  }

  Future<void> _playPause() async {
    _onChromeInteraction();
    await _player.playOrPause();
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 52,
  }) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.white.withOpacity(disabled ? 0.06 : 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: disabled ? Colors.white24 : Colors.white, size: size * 0.42),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat.jm().format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleChromeFromVideo,
            child: Center(
              child: Video(
                key: _videoKey,
                controller: _controller,
                controls: NoVideoControls,
                wakelock: _settings.keepScreenOnWhilePlaying,
                fit: _settings.videoFit,
                fill: const Color(0xFF000000),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0, 0.22, 0.72, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: Column(
                  children: [
                    _buildTopBar(context, timeLabel),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleChromeFromVideo,
                      ),
                    ),
                    _buildBottomBar(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String timeLabel) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 8, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.88), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _current.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _current.group,
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
              ],
            ),
          ),
          if (_settings.showOnScreenClock)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                timeLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Fullscreen',
            icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.paddingOf(context).bottom + 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.92), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(
                icon: Icons.skip_previous_rounded,
                onPressed: _canGoPrev ? () => _goRelative(-1) : null,
                size: 54,
              ),
              const SizedBox(width: 20),
              Material(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _playPause,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppTheme.primaryBlue,
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _circleButton(
                icon: Icons.skip_next_rounded,
                onPressed: _canGoNext ? () => _goRelative(1) : null,
                size: 54,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${_index + 1} / ${widget.channels.length}',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
