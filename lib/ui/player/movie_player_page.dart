import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../services/playlist_service.dart';
import '../../services/subtitle_service.dart';
import '../../services/tmdb_service.dart';
import '../dashboard/movie_details_screen.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/settings_service.dart';
import 'widgets/subtitle_studio.dart';

class MoviePlayerPage extends ConsumerStatefulWidget {
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

  // Subtitle & TMDB Services
  final SubtitleService _subtitleService = SubtitleService();
  final TmdbService _tmdbService = TmdbService();
  List<SubtitleResult> _availableSubtitles = [];
  bool _isSearchingSubtitles = false;
  bool _showSubtitlePrompt = false;

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

    // Set orientations based on device type
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Force landscape for all devices in fullscreen mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _resetHideTimer();
    
    _configureEngine();

    // Priority 1: Load manual subtitle from Admin Portal (URL or File)
    _loadManualSubtitle();

    // Priority 2: Auto-search for Kurdish (Sorani) subtitles as backup
    _searchSubtitles();
  }

  Future<void> _loadManualSubtitle() async {
    final subUrl = widget.channel.subtitleUrl;
    if (subUrl == null || subUrl.isEmpty) return;

    try {
      if (subUrl.startsWith('data:')) {
        // Enforce Local File: It's an encoded SRT/VTT file from the Admin Portal
        final parts = subUrl.split(';base64,');
        if (parts.length != 2) return;
        
        final bytes = base64Decode(parts[1]);
        final tempDir = await getTemporaryDirectory();
        final isVtt = subUrl.contains('text/vtt');
        final tempFile = File('${tempDir.path}/manual_sub_${DateTime.now().millisecondsSinceEpoch}.${isVtt ? 'vtt' : 'srt'}');
        
        await tempFile.writeAsBytes(bytes);
        await widget.player.setSubtitleTrack(SubtitleTrack.uri(tempFile.uri.toString()));
        debugPrint('Loaded local subtitle file: ${tempFile.path}');
      } else if (subUrl.startsWith('http')) {
        // Enforce URL: Direct web link
        await widget.player.setSubtitleTrack(SubtitleTrack.uri(subUrl));
        debugPrint('Loaded manual subtitle URL: $subUrl');
      }
    } catch (e) {
      debugPrint('Error loading manual subtitle: $e');
    }
  }

  Future<void> _searchSubtitles() async {
    if (!_subtitleService.hasApiKey) return;
    setState(() => _isSearchingSubtitles = true);
    
    try {
      final movie = await _tmdbService.findMovie(widget.channel.name);
      final results = await _subtitleService.search(
        imdbId: movie?.imdbId,
        query: movie?.title ?? widget.channel.name,
      );
      
      if (mounted && results.isNotEmpty) {
        setState(() {
          _availableSubtitles = results;
          // Sort to put Kurdish/Sorani at the top if found
          _availableSubtitles.sort((a, b) {
            final aIsKur = a.language == 'ku' || a.language == 'ckb';
            final bIsKur = b.language == 'ku' || b.language == 'ckb';
            if (aIsKur && !bIsKur) return -1;
            if (!aIsKur && bIsKur) return 1;
            return 0;
          });
          _isSearchingSubtitles = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingSubtitles = false);
    }
  }

  Future<void> _applySubtitle(SubtitleResult sub) async {
    final url = await _subtitleService.getDownloadUrl(sub.id);
    if (url != null) {
      await widget.player.setSubtitleTrack(SubtitleTrack.uri(url));
    }
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
    // STOP AUDIO LEAK: Explicitly dispose the player engine
    widget.player.dispose();
    super.dispose();
  }

  void _configureEngine() {
    if (widget.player.platform is NativePlayer) {
      final native = widget.player.platform as NativePlayer;
      Future<void> set(String k, String v) async {
        try { await native.setProperty(k, v); } catch (_) {}
      }
      
      set('hwdec', 'auto-safe');
      set('cache', 'yes');
      set('demuxer-max-bytes', '536870912'); // 512MB Buffer
      set('demuxer-readahead-secs', '15');   // 15s readahead for movies
      set('cache-secs', '30');               // Maintain 30s cache
      set('tcp-fastopen', 'yes');
      set('network-timeout', '15');
      set('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
    }
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
                fit: settings.videoFit,
                subtitleViewConfiguration: SubtitleViewConfiguration(
                  style: TextStyle(
                    fontSize: settings.subtitleFontSize,
                    color: Color(settings.subtitleColor),
                    fontWeight: FontWeight.bold,
                    backgroundColor: Color(settings.subtitleBgColor),
                  ),
                  padding: const EdgeInsets.all(24),
                ),
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
                        _buildHUDAction(Icons.closed_caption_rounded, () {
                          SubtitleStudioModal.show(context, widget.player);
                        }),
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
