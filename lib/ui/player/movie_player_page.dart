import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../services/playlist_service.dart';

class MoviePlayerPage extends StatefulWidget {
  final Player player;
  final VideoController controller;
  final Channel channel;
  final Locale uiLocale;
  final AppStrings strings;

  const MoviePlayerPage({
    super.key,
    required this.player,
    required this.controller,
    required this.channel,
    required this.uiLocale,
    required this.strings,
  });

  @override
  State<MoviePlayerPage> createState() => _MoviePlayerPageState();
}

class _MoviePlayerPageState extends State<MoviePlayerPage> {
  bool _overlayVisible = true; // Starts visible for movies as requested
  Timer? _hideTimer;
  
  // HUD & Clock State
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  final List<StreamSubscription> _subscriptions = [];
  
  // Gesture OSD State
  double? _volumeValue;
  double? _brightnessValue;
  String? _osdLabel;
  Timer? _osdTimer;

  @override
  void initState() {
    super.initState();
    _position = widget.player.state.position;
    _duration = widget.player.state.duration;

    _subscriptions.add(widget.player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subscriptions.add(widget.player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    }));

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Set orientations
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_overlayVisible) {
      _hideTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _overlayVisible = false);
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _clockTimer?.cancel();
    _osdTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  Future<bool> _exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _exitFullscreen,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragUpdate: _handleVerticalDrag,
          onVerticalDragEnd: (_) => _hideOSD(),
          onHorizontalDragUpdate: _handleHorizontalDrag,
          onHorizontalDragEnd: (_) => _hideOSD(),
          onTap: () {
            setState(() {
              _overlayVisible = !_overlayVisible;
            });
            if (_overlayVisible) {
              _resetHideTimer();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Layer
              Video(
                controller: widget.controller,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),

              // 2. Ambient Clock
              if (_overlayVisible)
                Positioned(
                  top: 30,
                  right: 40,
                  child: _buildAmbientClock(),
                ),

              // 3. Gesture OSD Indicators
              if (_osdLabel != null)
                Center(child: _buildOSDIndicator()),

              // 4. Movie HUD (Immersive Controls Only)
              if (_overlayVisible)
                _buildMovieHUD(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovieHUD() {
    return Stack(
      children: [
        // Top Bar: Back, Title & Settings
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                _buildHUDAction(Icons.arrow_back_ios_new_rounded, () async {
                  await _exitFullscreen();
                  if (mounted) Navigator.pop(context);
                }),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.channel.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildBadge('4K CINEMATIC', Colors.red),
                    ],
                  ),
                ),
                _buildHUDAction(Icons.settings_outlined, _showSettingsModal),
              ],
            ),
          ),
        ),

        // Play/Pause Big Icon (Center)
        Center(
          child: _buildHUDAction(
            widget.player.state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            () => widget.player.playOrPause(),
            isLarge: true,
          ),
        ),

        // Bottom HUD
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(50, 20, 50, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSeekBar(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildHUDAction(Icons.replay_10_rounded, () => widget.player.seek(_position - const Duration(seconds: 10))),
                        const SizedBox(width: 20),
                        _buildHUDAction(Icons.forward_10_rounded, () => widget.player.seek(_position + const Duration(seconds: 10))),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHUDAction(Icons.closed_caption_rounded, _showSubtitleSelector),
                        const SizedBox(width: 24),
                        _buildSpeedButton(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeekBar() {
    final pos = _position.inSeconds.toDouble();
    final dur = _duration.inSeconds.toDouble().clamp(1.0, double.infinity);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.red,
          ),
          child: Slider(
            value: pos.clamp(0.0, dur),
            max: dur,
            onChanged: (v) {
              widget.player.seek(Duration(seconds: v.toInt()));
              _resetHideTimer();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace')),
              Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white30, fontSize: 13, fontFamily: 'monospace')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmbientClock() {
    final timeStr = DateFormat('HH:mm').format(_now);
    return Text(
      timeStr,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 42,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        shadows: [Shadow(color: Colors.black, blurRadius: 15)],
      ),
    );
  }

  Widget _buildHUDAction(IconData icon, VoidCallback onTap, {bool isLarge = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: isLarge ? 64 : 28),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSpeedButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _playbackSpeed = _playbackSpeed >= 3.0 ? 1.0 : _playbackSpeed + 0.5;
        });
        widget.player.setRate(_playbackSpeed);
        _resetHideTimer();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
        child: Text('${_playbackSpeed.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showSubtitleSelector() {
    final tracks = widget.player.state.tracks.subtitle;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Colors.black87, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("SUBTITLES", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            ...tracks.map((t) => ListTile(
              leading: Icon(Icons.subtitles, color: t == widget.player.state.track.subtitle ? Colors.red : Colors.white),
              title: Text(t.title ?? t.language ?? "Track ${t.id}", style: const TextStyle(color: Colors.white)),
              onTap: () { widget.player.setSubtitleTrack(t); Navigator.pop(context); },
            )),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: Colors.black87, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("VIDEO SETTINGS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: Colors.white),
              title: const Text("Resolution Info", style: TextStyle(color: Colors.white)),
              subtitle: Text("${widget.player.state.width}x${widget.player.state.height}", style: const TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  // OSD & Drag Handlers
  void _handleVerticalDrag(DragUpdateDetails d) {
    final side = d.localPosition.dx < MediaQuery.of(context).size.width / 2;
    if (side) {
      _brightnessValue = ((_brightnessValue ?? 0.5) - d.delta.dy / 300).clamp(0.0, 1.0);
      _osdLabel = "BRIGHTNESS";
    } else {
      _volumeValue = ((_volumeValue ?? 0.5) - d.delta.dy / 300).clamp(0.0, 1.0);
      widget.player.setVolume(_volumeValue! * 100.0);
      _osdLabel = "VOLUME";
    }
    setState(() {});
    _resetOSDTimer();
  }

  void _handleHorizontalDrag(DragUpdateDetails d) {
    final off = d.delta.dx * 10;
    widget.player.seek(_position + Duration(seconds: off.toInt()));
    _osdLabel = off > 0 ? "+${off.toInt()}s" : "${off.toInt()}s";
    setState(() {});
    _resetOSDTimer();
  }

  void _resetOSDTimer() {
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 1), () => setState(() => _osdLabel = null));
  }

  void _hideOSD() => _osdTimer = Timer(const Duration(milliseconds: 500), () => setState(() => _osdLabel = null));

  Widget _buildOSDIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
      child: Text(_osdLabel!, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$mm:$ss';
    return '$mm:$ss';
  }
}
