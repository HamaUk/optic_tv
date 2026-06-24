import 'dart:async';
import 'dart:math' as math;
import '../../services/viewer_service.dart';

import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../widgets/native_player_view.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'dart:ui' show ImageFilter;
import 'package:animations/animations.dart';
import 'package:optic_tv/widgets/tv_fluid_focusable.dart';
import '../../widgets/tv/tv_focusable.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'fullscreen_player_page.dart';
import '../../services/optic_player.dart';

import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';
import '../../widgets/player_control_button.dart';
import '../../widgets/kobani_wordmark.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/monitor_service.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/tv_focus_wrapper.dart';
import '../settings/settings_screen.dart';

enum _TvPanelType { none, progressbar, playlist }

class PlayerScreen extends ConsumerStatefulWidget {
  final List<Channel> channels;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.channels,
    required this.initialIndex,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  Color get _accent => AppTheme.accentColor(_settings.gradientPreset);


  // OpticPlayer (ExoPlayer backend)
  OpticPlayer? _player;
  
  late int _index;
  late String _selectedGroup;
  int _activeServerIndex = 0;
  AppSettingsData _settings = const AppSettingsData();
  Timer? _clockTimer;
  bool _muted = false;
  bool _showEngineSplash = true;
  /// Full-screen loading overlay only after sustained stalls (avoids flicker on fast joins).
  bool _showBufferingOverlay = false;
  Timer? _bufferingOverlayTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isPlaying = true; 
  BoxFit _viewFit = BoxFit.fill;
  final FocusNode _playerFocus = FocusNode();
  final FocusNode _playPauseFocusNode = FocusNode();
  bool _isFullscreen = false;
  bool _fullscreenOverlayVisible = false;
  Timer? _fullscreenOverlayTimer;

  // TV Overhaul State
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showLeftDrawer = false;
  bool _showRightDrawer = false;
  String? _selectedTvGroup;
  
  // Ghosten Panel Architecture
  final ValueNotifier<_TvPanelType> _activePanel = ValueNotifier(_TvPanelType.none);
  bool _tvOverlayVisible = false;
  Timer? _tvHideTimer;
  bool _reversePanelTransition = false;
  Timer? _panelTimer;
  
  // Technical Media Info
  String _bitrate = "0 kbps";
  String _fps = "-";
  String _codec = "-";
  String _resolution = "-";
  Timer? _mediaInfoTimer;
  StreamSubscription? _techInfoSubscription;
  int _retryCount = 0;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  
  // Movie / Subtitle System removed (Logic moved to MoviePlayerPage)

  Channel get _current => widget.channels[_index];

  /// Hide corner logo for live-style streams; keep for movies / VOD-style groups.
  bool get _hideChannelLogoOverlay {
    final g = _current.group.toLowerCase();
    final u = _current.url.toLowerCase();
    if (g.contains('live')) return true;
    if (u.contains('.m3u8')) return true;
    return false;
  }

  List<String> get _groupNames {
    final set = <String>{};
    for (final c in widget.channels) {
      final isMovie = c.type == 'movie' || 
                      c.group.toLowerCase().contains('movie') || 
                      c.group.toLowerCase().contains('cinema');
      if (!isMovie) {
        set.add(c.group);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Channel> get _channelsInSelectedGroup {
    return widget.channels.where((c) {
      final isMovie = c.type == 'movie' || 
                      c.group.toLowerCase().contains('movie') || 
                      c.group.toLowerCase().contains('cinema');
      return !isMovie && c.group == _selectedGroup;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.channels.length - 1);
    _selectedGroup = widget.channels[_index].group;

    // Enable wakelock to prevent screen sleep
    WakelockPlus.enable();

    _initFlow();
    

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recentChannelsProvider.notifier).record(_current);
      _activePanel.addListener(_onPanelChanged);
      _configureNativePlayer();
      _startTechInfoTicker();
      ref.read(viewerServiceProvider).joinChannel(_current.url, channelName: _current.name);
      MonitorService.updateActivity(_current.name);
    });
  }

  void _onPanelChanged() {
    _panelTimer?.cancel();
    if (_activePanel.value != _TvPanelType.none) {
      _panelTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _activePanel.value != _TvPanelType.none) {
          setState(() {
            _reversePanelTransition = true;
            _activePanel.value = _TvPanelType.none;
          });
        }
      });
    }
  }

  void _startTechInfoTicker() {
    _mediaInfoTimer?.cancel();
    _mediaInfoTimer = Timer.periodic(const Duration(seconds: 5), (t) => _extractMediaInfo());
  }

  Future<void> _extractMediaInfo() async {
    final p = _player;
    if (p == null || !mounted) return;
    
    // Native ExoPlayer — media info is not exposed via MethodChannel yet.
    // Show static values for now; future: add native event for video format info.
    setState(() {
      _bitrate = "— kbps";
      _fps = "— FPS";
      _resolution = "Native";
      _codec = "ExoPlayer";
    });
  }

  Future<void> _initFlow() async {
    final s = await AppSettingsData.load();
    if (!mounted) return;
    setState(() => _settings = s);
    _ensureClockTimer();
    await _initPlayer();
  }

  void _configureNativePlayer() {
    // ExoPlayer is configured automatically by video_player plugin — no-op.
    // Hardware decoding, adaptive HLS, and low-latency live TV are built in.
  }

  void _onPlayerBuffering(bool buffering) {
    _bufferingOverlayTimer?.cancel();
    if (!buffering) {
      if (_showBufferingOverlay && mounted) {
        setState(() => _showBufferingOverlay = false);
      }
      return;
    }
    _bufferingOverlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showBufferingOverlay = true);
    });
  }

  Future<void> _initPlayer() async {
    for (final s in _subscriptions) s.cancel();
    _subscriptions.clear();

    final old = _player;
    _player = null;
    await old?.dispose();

    final p = OpticPlayer();
    _player = p;
    await p.setMaxResolution(1080);

    _subscriptions.add(p.stream.volume.listen((v) {
      if (mounted && v > 0 && _muted) setState(() => _muted = false);
      if (mounted && v == 0 && !_muted) setState(() => _muted = true);
    }));
    _subscriptions.add(p.stream.buffering.listen(_onPlayerBuffering));
    _subscriptions.add(p.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    }));
    _subscriptions.add(p.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    }));
    _subscriptions.add(p.stream.playing.listen((pl) {
      if (mounted) setState(() => _isPlaying = pl);
    }));
    _subscriptions.add(p.stream.error.listen((err) {
      if (err != null) _handlePlayerError(err);
    }));

    _viewFit = _settings.videoFit;

    List<String> validUrls = [_current.url];
    if (_current.url2 != null && _current.url2!.trim().isNotEmpty) validUrls.add(_current.url2!);
    if (_current.url3 != null && _current.url3!.trim().isNotEmpty) validUrls.add(_current.url3!);

    if (_activeServerIndex >= validUrls.length) {
      _activeServerIndex = 0;
    }

    await p.open(
      validUrls[_activeServerIndex],
      headers: {
        'User-Agent': _current.userAgent ?? 'SmartIPTV',
        'X-Optic-Security-Token': 'k4k-secure-stream-99X',
      },
    );

    if (mounted) setState(() => _showEngineSplash = false);
  }

  void _ensureClockTimer() {
    _clockTimer?.cancel();
    if (_settings.showOnScreenClock) {
      _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void deactivate() {
    // Immediately stop playback when navigating away (prevents audio leak)
    _player?.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    ref.read(viewerServiceProvider).leaveChannel(_current.url);
    _clockTimer?.cancel();
    _bufferingOverlayTimer?.cancel();
    _fullscreenOverlayTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    MonitorService.updateActivity(null);
    _activePanel.dispose();
    _panelTimer?.cancel();
    _techInfoSubscription?.cancel();
    _mediaInfoTimer?.cancel();
    _hideTimer?.cancel();
    _playPauseFocusNode.dispose();
    _playerFocus.dispose();
    _player?.stop();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggleMute() async {
    if (_muted) {
      await _player?.setVolume(100);
      setState(() => _muted = false);
    } else {
      await _player?.setVolume(0);
      setState(() => _muted = true);
    }
  }

  void _selectChannelByIndex(int fullListIndex) {
    if (fullListIndex < 0 || fullListIndex >= widget.channels.length) return;
    final oldUrl = _current.url;
    setState(() {
      _index = fullListIndex;
      _selectedGroup = widget.channels[_index].group;
      _activeServerIndex = 0;
      _retryCount = 0;
    });
    final newUrl = _current.url;
    if (oldUrl != newUrl) {
      ref.read(viewerServiceProvider).leaveChannel(oldUrl);
      ref.read(viewerServiceProvider).joinChannel(newUrl, channelName: widget.channels[fullListIndex].name);
      MonitorService.updateActivity(widget.channels[fullListIndex].name);
    }
    ref.read(recentChannelsProvider.notifier).record(_current);
    unawaited(_reopenCurrentStream());
  }

  void _handlePlayerError(dynamic err) {
    if (!mounted) return;

    List<String> validUrls = [_current.url];
    if (_current.url2 != null && _current.url2!.trim().isNotEmpty) validUrls.add(_current.url2!);
    if (_current.url3 != null && _current.url3!.trim().isNotEmpty) validUrls.add(_current.url3!);

    if (_activeServerIndex + 1 < validUrls.length) {
      _activeServerIndex++;
      _retryCount = 0;
      debugPrint('Stream error: $err. Failing over to Server ${_activeServerIndex + 1}');
      _snack('Switching to Server ${_activeServerIndex + 1}...');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _reopenCurrentStream();
      });
      return;
    }

    if (_retryCount < 2) {
      _retryCount++;
      debugPrint('Stream error, retrying ($_retryCount / 2): $err');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _reopenCurrentStream();
      });
    } else {
      _snack('All servers failed. Stream connection timed out.', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _reopenCurrentStream() async {
    final p = _player;
    if (p == null) return;

    List<String> validUrls = [_current.url];
    if (_current.url2 != null && _current.url2!.trim().isNotEmpty) validUrls.add(_current.url2!);
    if (_current.url3 != null && _current.url3!.trim().isNotEmpty) validUrls.add(_current.url3!);

    if (_activeServerIndex >= validUrls.length) _activeServerIndex = 0;

    await p.open(
      validUrls[_activeServerIndex],
      headers: {'User-Agent': _current.userAgent ?? 'SmartIPTV'},
    );
  }

  // Subtitle search and VOD logic removed (Moved to MoviePlayerPage)

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) return;
    if (_player == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenPlayerPage(
          player: _player!,
          channels: widget.channels,
          initialIndex: _index,
          activeServerIndex: _activeServerIndex,
          uiLocale: ref.read(appLocaleProvider),
          strings: AppStrings(ref.read(appLocaleProvider)),
          onServerChanged: (newServerIndex) {
            if (mounted) {
              setState(() {
                _activeServerIndex = newServerIndex;
                _retryCount = 0;
              });
            }
          },
          onChannelChanged: (oldCh, newCh) {
            if (mounted) {
              setState(() {
                final idx = widget.channels.indexOf(newCh);
                if (idx >= 0) {
                  _index = idx;
                  _selectedGroup = newCh.group;
                }
              });
              ref.read(viewerServiceProvider).leaveChannel(oldCh.url);
              ref.read(viewerServiceProvider).joinChannel(newCh.url, channelName: newCh.name);
            }
          },
        ),
      ),
    );

    if (result is int && mounted) {
      setState(() {
        _index = result;
        _selectedGroup = widget.channels[_index].group;
      });
    }

    final isTv = MediaQuery.of(context).size.shortestSide >= 600;
    if (!isTv) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _playPause() async {
    await _player?.playOrPause();
  }

  Future<void> _seekTo(Duration absolute) async {
    await _player?.seek(absolute);
  }

  Future<void> _seekRelative(Duration offset) async {
    final target = _position + offset;
    final clamped = target < Duration.zero ? Duration.zero : (target > _duration ? _duration : target);
    await _seekTo(clamped);
  }

  Future<void> _enterPiP() async {
    SimplePip().enterPipMode();
  }


  @override
  Widget build(BuildContext context) {
    if (_player == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isTv = MediaQuery.of(context).size.width > 900;

    if (isTv) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        endDrawer: const Drawer(
          child: SettingsScreen(),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoView(),
            _buildTvArchitectureOverhaul(s),
          ],
        ),
      );
    }

    // New Simplified Mobile Architecture (Matches Picture 1 layout)
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header (Logo, Name, Settings)
            _buildMobileHeader(s, uiLocale),
            
            // 2. Video Area (Below Header)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildVideoView(),
            ),
            
            // 3. Channel Lists (Bottom)
            Expanded(
              child: Row(
                children: [
                  _buildMobileCategoryPane(s, uiLocale),
                  Container(width: 1, color: Colors.white.withOpacity(0.05)),
                  _buildMobileChannelPane(s, uiLocale, bottomPad),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Subtitle search and VOD logic removed (Moved to MoviePlayerPage)

  Widget _buildVideoView() {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _playPause,
            child: _player != null
                ? NativePlayerView(player: _player!)
                : const Center(child: CircularProgressIndicator(color: Colors.white24)),
          ),
          // Live Viewers (Top Left)
          if (!_isFullscreen)
            Positioned(
              top: 16,
              left: 16,
              child: StreamBuilder<int>(
                stream: ref.watch(viewerServiceProvider).getViewersStream(_current.url),
                builder: (context, snapshot) {
                  final viewers = snapshot.data ?? 0;
                  if (viewers == 0) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.remove_red_eye_rounded, color: Colors.redAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$viewers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          // Quality and Fullscreen (Bottom Right)
          if (!_isFullscreen)
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _toggleFullscreen,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildTvArchitectureOverhaul(AppStrings s) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onTvRootKeyEvent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: !_tvOverlayVisible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _tvOverlayVisible ? 1.0 : 0.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        // Top Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                          child: Row(
                            children: [
                              if (_current.logo != null && _current.logo!.isNotEmpty) ...[
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white10,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ChannelLogoImage(
                                      logo: _current.logo,
                                      channelName: _current.name,
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: Text(
                                  _current.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              StreamBuilder<int>(
                                stream: ref.watch(viewerServiceProvider).getViewersStream(_current.url),
                                builder: (context, snapshot) {
                                  final viewers = snapshot.data ?? 0;
                                  if (viewers == 0) return const SizedBox.shrink();
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.remove_red_eye_rounded, color: Colors.redAccent, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$viewers',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                  const Spacer(),

                  // Glassmorphism Banana HUD
                  GlassmorphicContainer(
                    width: 500,
                    height: 80,
                    borderRadius: 40,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 1,
                    linearGradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                    ),
                    borderGradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTvFocusIcon(
                          _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, 
                          () {
                            setState(() => _muted = !_muted);
                            _player?.setVolume(_muted ? 0.0 : 100.0);
                            _resetTvHideTimer();
                          }
                        ),
                        const SizedBox(width: 24),
                        _buildTvFocusIcon(Icons.settings_rounded, () {
                          _scaffoldKey.currentState?.openEndDrawer();
                          _resetTvHideTimer();
                        }),
                        const SizedBox(width: 24),
                        TVFocusable(
                          focusNode: _playPauseFocusNode,
                          showFocusBorder: false,
                          focusScale: 1.1,
                          onSelect: () {
                            _playPause();
                            _resetTvHideTimer();
                          },
                          child: const SizedBox(),
                          builder: (context, isFocused, child) => Container(
                            decoration: BoxDecoration(
                              color: isFocused ? _accent : Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: isFocused ? [BoxShadow(color: _accent.withOpacity(0.5), blurRadius: 10)] : [],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: isFocused ? Colors.black : Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        _buildTvFocusIcon(Icons.aspect_ratio_rounded, () {
                          _resetTvHideTimer();
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Channel Carousel
                  Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent || event is KeyRepeatEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            _playPauseFocusNode.requestFocus();
                            _resetTvHideTimer();
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        itemCount: widget.channels.length,
                        itemBuilder: (context, idx) => _buildTvChannelCarouselItem(idx, _accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
                ], // Closes 626 Stack children
              ), // Closes 624 Stack
            ), // Closes 621 AnimatedOpacity
          ), // Closes 619 IgnorePointer
        ], // Closes 618 Stack children
      ), // Closes 616 Stack
    ); // Closes 613 Focus
  }

  Widget _buildTvFocusIcon(IconData icon, VoidCallback onSelect) {
    return TVFocusable(
      showFocusBorder: false,
      focusScale: 1.15,
      onSelect: onSelect,
      child: const SizedBox(),
      builder: (context, isFocused, child) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFocused ? Colors.white24 : Colors.transparent,
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTvChannelCarouselItem(int index, Color accent) {
    final channel = widget.channels[index];
    final isSelected = index == _index;

    return TVFocusable(
      showFocusBorder: false,
      focusScale: 1.05,
      onSelect: () {
        _selectChannelByIndex(index);
        _resetTvHideTimer();
      },
      child: const SizedBox(),
      builder: (context, isFocused, child) => Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              height: 75,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused ? accent : (isSelected ? Colors.white : Colors.transparent),
                  width: 3,
                ),
                boxShadow: (isFocused || isSelected)
                    ? [
                        BoxShadow(
                          color: (isFocused ? accent : Colors.white).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ChannelLogoImage(
                    logo: channel.logo,
                    channelName: channel.name,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              channel.name.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _onTvRootKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final key = event.logicalKey;

      if (!_tvOverlayVisible) {
        if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
          setState(() {
            _tvOverlayVisible = true;
          });
          _resetTvHideTimer();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp) {
          _handlePrevious();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _handleNext();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
           setState(() {
            _tvOverlayVisible = true;
          });
          _resetTvHideTimer();
          return KeyEventResult.handled;
        }
      } else {
        if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.browserBack) {
          setState(() {
            _tvOverlayVisible = false;
          });
          _tvHideTimer?.cancel();
          return KeyEventResult.handled;
        }
        // Any other key press resets the timer so it doesn't hide while navigating
        _resetTvHideTimer();
      }
    }
    return KeyEventResult.ignored;
  }

  String _formatDuration(Duration d) {
    final hh = d.inHours;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hh > 0) return '$hh:$mm:$ss';
    return '$mm:$ss';
  }

  void _handlePrevious() {
    if (_index > 0) _selectChannelByIndex(_index - 1);
  }

  
  void _resetTvHideTimer() {
    _tvHideTimer?.cancel();
    if (_tvOverlayVisible) {
      _tvHideTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _tvOverlayVisible = false);
      });
    }
  }

  void _handleNext() {
    if (_index < widget.channels.length - 1) _selectChannelByIndex(_index + 1);
  }

  Widget _buildMobileScaffold(Locale uiLocale, AppStrings s, double bottomPad) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          _buildMobileHeader(s, uiLocale),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildVideoView(),
          ),
          Expanded(
            child: Row(
              children: [
                _buildMobileCategoryPane(s, uiLocale),
                Container(width: 1, color: _accent.withOpacity(0.1)),
                _buildMobileChannelPane(s, uiLocale, bottomPad),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(AppStrings s, Locale uiLocale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          const KobaniWordmark(height: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _current.name.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.withRabarIfKurdish(
                uiLocale,
                const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white.withOpacity(0.7), size: 22),
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (mounted) {
                final newSettings = await AppSettingsData.load();
                setState(() => _settings = newSettings);
              }
            },
          ),
        ],
      ),
    );
  }

  // Subtitle modal removed (Logic moved to MoviePlayerPage)

  Widget _buildMobileVideoOverlay() {
    final p = _player;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black45, Colors.transparent, Colors.black45],
        ),
      ),
      child: Stack(
        children: [
          if (p != null)
            Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: p.buffering,
                builder: (_, buf, __) => buf
                    ? CircularProgressIndicator(color: _accent, strokeWidth: 3)
                    : const SizedBox(),
              ),
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Material(
              color: Colors.black38,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _toggleFullscreen,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCategoryPane(AppStrings s, Locale uiLocale) {
    final groups = _groupNames;
    return Container(
      width: 100,
      color: const Color(0xFF0A0E14),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final g = groups[i];
          final selected = g == _selectedGroup;
          return GestureDetector(
            onTap: () => setState(() => _selectedGroup = g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? _accent.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    color: selected ? _accent : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selected
                        ? Icon(Icons.live_tv_rounded, color: _accent, size: 18, key: const ValueKey('active'))
                        : Icon(Icons.folder_outlined, color: Colors.white30, size: 16, key: const ValueKey('inactive')),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.withRabarIfKurdish(
                      uiLocale,
                      TextStyle(
                        color: selected ? _accent : Colors.white54,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileChannelPane(AppStrings s, Locale uiLocale, double bottomPad) {
    final channels = _channelsInSelectedGroup;
    return Expanded(
      child: Container(
        color: Colors.black,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(0, 8, 8, bottomPad + 20),
          itemCount: channels.length,
          separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04), height: 1),
          itemBuilder: (context, i) {
            final ch = channels[i];
            final fullIdx = widget.channels.indexOf(ch);
            final active = ch.url == _current.url;
            return Material(
              key: ValueKey('mobile_${ch.url}_$fullIdx'),
              color: active ? _accent.withOpacity(0.08) : Colors.transparent,
              child: InkWell(
                onTap: () => _selectChannelByIndex(fullIdx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Channel number
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${fullIdx + 1}',
                          style: TextStyle(
                            color: active ? _accent : Colors.white24,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Channel logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ChannelLogoImage(
                          logo: ch.logo,
                          channelName: ch.name,
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // TV Icon as requested
                      Icon(
                        Icons.live_tv_rounded,
                        size: 14,
                        color: active ? _accent.withOpacity(0.9) : Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      // Channel name
                      Expanded(
                        child: Text(
                          ch.name,
                          style: AppTheme.withRabarIfKurdish(
                            uiLocale,
                            TextStyle(
                              color: active ? _accent : Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Active indicator
                      if (active)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: _accent.withOpacity(0.5), blurRadius: 6)],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GhostenPlayerInfoView extends StatelessWidget {
  const _GhostenPlayerInfoView({required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 10)],
              ),
              child: const Text('LIVE', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 16),
            Text(
              channel.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                shadows: [Shadow(color: Colors.black, blurRadius: 15)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          channel.group.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

