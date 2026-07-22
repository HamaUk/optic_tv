import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/native_player_view.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/optic_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../l10n/app_strings.dart';
import '../../services/playlist_service.dart';

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
  
  // New States
  bool _isLocked = false;
  bool _isMuted = false;
  Timer? _sleepCountdownTimer;
  bool _isFullscreen = true;
  
  // Gesture OSD State
  double? _volumeValue;
  double? _brightnessValue;
  String? _osdLabel;
  Timer? _osdTimer;

  // TMDB Service for metadata

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
    _sleepCountdownTimer?.cancel();
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
    
    if (!mounted) return true;
    // Smart reset: Only force portrait on exit for phones
    final isTv = MediaQuery.of(context).size.shortestSide >= 600;
    if (!isTv) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _exitFullscreen();
        if (shouldPop && context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragUpdate: _isLocked ? null : _handleVerticalDrag,
          onVerticalDragEnd: _isLocked ? null : (_) => _hideOSD(),
          onHorizontalDragUpdate: _isLocked ? null : _handleHorizontalDrag,
          onHorizontalDragEnd: _isLocked ? null : (_) => _hideOSD(),
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
              Positioned(
                top: 40,
                right: 40,
                child: AnimatedOpacity(
                  opacity: _overlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildAmbientClock(),
                ),
              ),

              // 3. Gesture OSD Indicators
              if (_osdLabel != null)
                Center(child: _buildOSDIndicator()),

              // 4. Movie HUD (Immersive Controls Only)
              if (!_isLocked)
                AnimatedOpacity(
                  opacity: _overlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_overlayVisible,
                    child: _buildMovieHUD(),
                  ),
                ),

              // 5. Locked Mode Unlock Button
              if (_isLocked)
                AnimatedOpacity(
                  opacity: _overlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_overlayVisible,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 40),
                        child: _buildHUDImageAsset('assets/images/flixy/ic_unlock.png', () {
                          setState(() {
                            _isLocked = false;
                            _resetHideTimer();
                          });
                        }),
                      ),
                    ),
                  ),
                ),
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
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                _buildHUDImageAsset('assets/images/flixy/ic_back.png', () async {
                  await _exitFullscreen();
                  if (mounted) Navigator.pop(context);
                }),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Right side icons
                _buildHUDImageAsset('assets/images/flixy/ic_time.png', () {
                  setState(() {
                    _playbackSpeed = _playbackSpeed >= 2.0 ? 0.5 : _playbackSpeed + 0.25;
                  });
                  widget.player.setRate(_playbackSpeed);
                  _resetHideTimer();
                }),
                const SizedBox(width: 12),
                _buildHUDImageAsset('assets/images/flixy/ic_clock_pause.png', _showSleepTimerDialog),
                const SizedBox(width: 12),
                _buildHUDImageAsset('assets/images/flixy/ic_subtitle.png', _showSettingsModal),
                const SizedBox(width: 12),
                _buildHUDAction(Icons.mic_none_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice Search / Audio Tracks...')));
                }),
                const SizedBox(width: 12),
                _buildHUDImageAsset('assets/images/flixy/ic_tv.png', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Searching for Cast devices...')));
                }),
                const SizedBox(width: 12),
                _buildHUDImageAsset('assets/images/flixy/ic_menu.png', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('More options coming soon.')));
                }),
              ],
            ),
          ),
        ),

        // Bottom HUD
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(40, 20, 40, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSeekBar(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Group
                    Row(
                      children: [
                        _buildHUDImageAsset('assets/images/flixy/ic_lock.png', () {
                          setState(() {
                            _isLocked = true;
                            _overlayVisible = false;
                          });
                        }),
                        const SizedBox(width: 20),
                        _buildHUDImageAsset(_isMuted ? 'assets/images/flixy/ic_mute.png' : 'assets/images/flixy/ic_unmute.png', () {
                          setState(() {
                            _isMuted = !_isMuted;
                            widget.player.setVolume(_isMuted ? 0.0 : 1.0);
                          });
                        }),
                      ],
                    ),
                    // Center Group
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHUDAction(Icons.replay_10_rounded, () => widget.player.seek(_position - const Duration(seconds: 10))),
                        const SizedBox(width: 24),
                        _buildHUDAction(Icons.skip_previous_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No previous episode available.')));
                        }),
                        const SizedBox(width: 24),
                        // Play Button
                        InkWell(
                          onTap: () {
                            widget.player.playOrPause();
                            _resetHideTimer();
                          },
                          child: Image.asset(
                            widget.player.isPlaying ? 'assets/images/flixy/ic_pause.png' : 'assets/images/flixy/ic_play.png',
                            color: Colors.white,
                            width: 52,
                            height: 52,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _buildHUDAction(Icons.skip_next_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No next episode available.')));
                        }),
                        const SizedBox(width: 24),
                        _buildHUDAction(Icons.forward_10_rounded, () => widget.player.seek(_position + const Duration(seconds: 10))),
                      ],
                    ),
                    // Right Group
                    Row(
                      children: [
                        _buildHUDImageAsset('assets/images/flixy/ic_download.png', () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to download queue.')));
                        }),
                        const SizedBox(width: 20),
                        _buildHUDImageAsset('assets/images/flixy/ic_fullscreen.png', () {
                          setState(() {
                            _isFullscreen = !_isFullscreen;
                          });
                          if (_isFullscreen) {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                          } else {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                            ]);
                          }
                        }),
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
    return Row(
      children: [
        Text(
          _formatDuration(_position), 
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Colors.red,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.red.withValues(alpha: 0.2),
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
        ),
        const SizedBox(width: 16),
        Text(
          _formatDuration(_duration), 
          style: const TextStyle(color: Colors.white70, fontSize: 14)
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
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
      ),
    );
  }

  Widget _buildHUDAction(IconData icon, VoidCallback onTap) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildHUDImageAsset(String assetPath, VoidCallback onTap) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Image.asset(assetPath, color: Colors.white, width: 28, height: 28),
          ),
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

  void _showSleepTimerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sleep Timer', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Off', style: TextStyle(color: Colors.white)),
              onTap: () {
                _sleepCountdownTimer?.cancel();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sleep timer disabled.')));
              },
            ),
            ListTile(
              title: const Text('15 Minutes', style: TextStyle(color: Colors.white)),
              onTap: () {
                _setSleepTimer(15);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('30 Minutes', style: TextStyle(color: Colors.white)),
              onTap: () {
                _setSleepTimer(30);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('1 Hour', style: TextStyle(color: Colors.white)),
              onTap: () {
                _setSleepTimer(60);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setSleepTimer(int minutes) {
    _sleepCountdownTimer?.cancel();
    _sleepCountdownTimer = Timer(Duration(minutes: minutes), () {
      if (mounted) Navigator.pop(context); // Close player
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sleep timer set for $minutes minutes')));
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
    final isVolume = _osdLabel == "VOLUME";
    final isBrightness = _osdLabel == "BRIGHTNESS";
    final value = isVolume ? (_volumeValue ?? 0.5) : (isBrightness ? (_brightnessValue ?? 0.5) : null);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVolume 
                  ? (value! > 0.5 ? Icons.volume_up_rounded : (value > 0 ? Icons.volume_down_rounded : Icons.volume_mute_rounded))
                  : (isBrightness ? Icons.brightness_6_rounded : Icons.fast_forward_rounded),
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 16),
              if (value != null)
                SizedBox(
                  width: 100,
                  height: 4,
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                Text(_osdLabel!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      ),
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
  const VideoSettingsModal({super.key, required this.player});

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

