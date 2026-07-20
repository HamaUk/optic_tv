import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
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
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.channel.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildBadge('4K CINEMATIC', const Color(0xFFD4AF37)),
                          const SizedBox(width: 8),
                          _buildBadge('VOD', Colors.redAccent),
                        ],
                      ),
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
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: const Color(0xFFD4AF37),
            inactiveTrackColor: Colors.white24,
            thumbColor: const Color(0xFFD4AF37),
            overlayColor: const Color(0xFFD4AF37).withOpacity(0.2),
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
        child: Container(
          padding: EdgeInsets.all(isLarge ? 24 : 12),
          decoration: isLarge ? BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 1.5),
          ) : null,
          child: Icon(icon, color: Colors.white, size: isLarge ? 56 : 30),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)), 
          borderRadius: BorderRadius.circular(12)
        ),
        child: Text(
          '${_playbackSpeed.toStringAsFixed(1)}x', 
          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)
        ),
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Allows custom rounded corner container
      builder: (context) => VideoSettingsModal(player: widget.player),
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

class VideoSettingsModal extends StatefulWidget {
  final OpticPlayer player;
  const VideoSettingsModal({Key? key, required this.player}) : super(key: key);

  @override
  State<VideoSettingsModal> createState() => _VideoSettingsModalState();
}

class _VideoSettingsModalState extends State<VideoSettingsModal> {
  // Mock states to manage UI selection
  String selectedQuality = 'Auto';
  String selectedSubtitle = 'English';
  String selectedAudio = 'English';
  double selectedSpeed = 1.0;

  List<String> _qualities = ['Auto'];

  final List<double> speedValues = [0.5, 0.75, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  Future<void> _fetchTracks() async {
    try {
      final tracks = await widget.player.getTracks();
      final heights = <int>{};
      for (var t in tracks) {
        if (t['height'] != null) {
          heights.add((t['height'] as num).toInt());
        }
      }
      
      final sortedHeights = heights.toList()..sort((a, b) => b.compareTo(a));
      if (mounted) {
        setState(() {
          _qualities = ['Auto', ...sortedHeights.map((h) => '${h}p')];
        });
      }
    } catch (e) {
      debugPrint('Failed to load real tracks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark modern theme style
    final cardColor = const Color(0xFF1E1E1E).withValues(alpha: 0.5);
    const textStyle = TextStyle(color: Colors.white, fontSize: 15);
    const titleStyle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181818).withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), width: 1.5)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // --- 1. VIDEO QUALITY CARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text('Video Quality', style: titleStyle),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._qualities.map((quality) => 
                    _buildSelectionRow(quality, selectedQuality == quality, () {
                      setState(() => selectedQuality = quality);
                      if (quality == 'Auto') {
                        widget.player.setMaxResolution(0);
                      } else {
                        final h = int.tryParse(quality.replaceAll('p', '')) ?? 0;
                        widget.player.setMaxResolution(h);
                      }
                    })
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. SUBTITLES & AUDIO CARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitles Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.subtitles, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text('Subtitles', style: titleStyle),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...['Off', 'English', 'Hindi', 'Spanish'].map((sub) => 
                          _buildSelectionRow(sub, selectedSubtitle == sub, () {
                            setState(() => selectedSubtitle = sub);
                          })
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(color: Colors.white12, width: 20),
                  // Audio Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volume_up, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text('Audio', style: titleStyle),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...['English', 'Hindi'].map((audio) => 
                          _buildSelectionRow(audio, selectedAudio == audio, () {
                            setState(() => selectedAudio = audio);
                          })
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 3. PLAYBACK SPEED CARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text('Playback Speed', style: titleStyle),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Custom Timeline Slider Layout
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      activeTrackColor: Colors.white38,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: selectedSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 4, // 5 distinct points: 0.5, 0.75, 1.0, 1.5, 2.0
                      onChanged: (value) {
                        setState(() => selectedSpeed = value);
                        widget.player.setRate(value); // Set engine speed
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bottom Labels Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: speedValues.map((val) {
                      final isSelected = val == selectedSpeed;
                      return Text(
                        val == 1.0 ? '1x' : '${val}x',
                        style: textStyle.copyWith(
                          fontSize: isSelected ? 14 : 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.white38,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable selector list item row
  Widget _buildSelectionRow(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Checkmark or placeholder spacer
            SizedBox(
              width: 24,
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

