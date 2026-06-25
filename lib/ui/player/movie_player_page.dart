import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/native_player_view.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/optic_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../services/playlist_service.dart';
import '../../services/subtitle_service.dart';
import '../../services/tmdb_service.dart';
import '../dashboard/movie_details_screen.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/settings_service.dart';

class MoviePlayerPage extends ConsumerStatefulWidget {
  final OpticPlayer player;
  final Channel channel;
  final Locale uiLocale;
  final AppStrings strings;

  const MoviePlayerPage({
    super.key,
    required this.player,
    required this.channel,
    required this.uiLocale,
    required this.strings,
  });

  @override
  ConsumerState<MoviePlayerPage> createState() => _MoviePlayerPageState();
}

class _MoviePlayerPageState extends ConsumerState<MoviePlayerPage> {
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

  // TMDB Service for metadata
  final TmdbService _tmdbService = TmdbService();

  @override
  void initState() {
    super.initState();
    _position = widget.player.currentPosition;
    _duration = widget.player.totalDuration;

    _subscriptions.add(widget.player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subscriptions.add(widget.player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    }));

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Set orientations based on device type
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isTv = MediaQuery.of(context).size.shortestSide >= 600;
      if (!isTv) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });

    _resetHideTimer();
    
    // Enable wakelock to prevent screen sleep
    WakelockPlus.enable();

    _configureEngine();
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
    WakelockPlus.disable();
    _hideTimer?.cancel();
    _clockTimer?.cancel();
    _osdTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    // STOP AUDIO LEAK: Explicitly dispose the player engine
    widget.player.dispose();
    super.dispose();
  }

  void _configureEngine() {
    // ExoPlayer (video_player plugin) handles hardware decode automatically.
    // No mpv-specific configuration needed.
  }

  Future<bool> _exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Smart reset: Only force portrait on exit for phones
    final isTv = MediaQuery.of(context).size.shortestSide >= 600;
    if (!isTv) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appUiSettingsProvider);
    final settings = settingsAsync.asData?.value ?? AppSettingsData();
    final ctrl = null; // Native ExoPlayer — no Flutter controller needed
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
            if (_overlayVisible) _resetHideTimer();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Layer — Native ExoPlayer via PlatformView
              NativePlayerView(player: widget.player),

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
            widget.player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
            const ListTile(
              leading: Icon(Icons.info_outline_rounded, color: Colors.white),
              title: Text("Engine", style: TextStyle(color: Colors.white)),
              subtitle: Text('Native ExoPlayer (Media3)', style: TextStyle(color: Colors.white54)),
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
      widget.player.setVolume((_volumeValue! * 100.0));
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
