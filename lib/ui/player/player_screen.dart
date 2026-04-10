import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
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

  int get _animMs => _settings.reduceMotion ? 120 : 240;

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
    _hideChromeTimer = Timer(Duration(seconds: _settings.reduceMotion ? 5 : 4), () {
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
    double size = 48,
  }) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.white.withOpacity(disabled ? 0.05 : 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: disabled ? Colors.white24 : Colors.white,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final s = AppStrings(locale);
    final timeLabel = DateFormat.jm(locale.toString()).format(DateTime.now());

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
                    Colors.black.withOpacity(0.58),
                    Colors.transparent,
                    Colors.transparent,
                    AppTheme.backgroundBlack.withOpacity(0.72),
                  ],
                  stops: const [0, 0.2, 0.75, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: Duration(milliseconds: _animMs),
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: Column(
                  children: [
                    _buildTopBar(context, s, timeLabel),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleChromeFromVideo,
                      ),
                    ),
                    _buildBottomBar(context, s),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppStrings s, String timeLabel) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 6, 4, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            iconSize: 22,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _current.group,
                  style: TextStyle(color: Colors.white.withOpacity(0.52), fontSize: 12),
                ),
              ],
            ),
          ),
          if (_settings.showOnScreenClock)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                timeLabel,
                style: TextStyle(color: AppTheme.primaryGold.withOpacity(0.9), fontSize: 12),
              ),
            ),
          IconButton(
            tooltip: s.fullscreenTooltip,
            iconSize: 24,
            icon: Icon(Icons.fullscreen_rounded, color: AppTheme.primaryGold.withOpacity(0.95)),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppStrings s) {
    final tv = _settings.tvFriendlyLayout;
    final sideSize = tv ? 52.0 : 46.0;
    final playSize = tv ? 76.0 : 68.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.paddingOf(context).bottom + 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.93), Colors.transparent],
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
                size: sideSize,
              ),
              SizedBox(width: tv ? 22 : 18),
              Material(
                color: AppTheme.primaryGold.withOpacity(0.18),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _playPause,
                  child: SizedBox(
                    width: playSize,
                    height: playSize,
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppTheme.primaryGold,
                      size: playSize * 0.48,
                    ),
                  ),
                ),
              ),
              SizedBox(width: tv ? 22 : 18),
              _circleButton(
                icon: Icons.skip_next_rounded,
                onPressed: _canGoNext ? () => _goRelative(1) : null,
                size: sideSize,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_index + 1} / ${widget.channels.length}',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
