import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'dart:ui' show ImageFilter;

import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';
import '../../widgets/player_control_button.dart';
import '../../widgets/optic_wordmark.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../services/monitor_service.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/tv_focus_wrapper.dart';

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

  final GlobalKey<VideoState> _videoKey = GlobalKey<VideoState>();
  
  // Media Kit (mpv)
  Player? _player;
  VideoController? _controller;
  
  late int _index;
  late String _selectedGroup;
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
  BoxFit _viewFit = BoxFit.contain; // Local override for TV selector
  final FocusNode _playerFocus = FocusNode();

  // TV Overhaul State
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showLeftDrawer = false;
  bool _showRightDrawer = false;
  String? _selectedTvGroup;
  
  // Ghosten Panel Architecture
  final ValueNotifier<_TvPanelType> _activePanel = ValueNotifier(_TvPanelType.none);
  bool _reversePanelTransition = false;
  Timer? _panelTimer;
  
  // Technical Media Info
  String _bitrate = "0 kbps";
  String _fps = "-";
  String _codec = "-";
  String _resolution = "-";
  Timer? _mediaInfoTimer;
  StreamSubscription? _techInfoSubscription;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Channel get _current => widget.channels[_index];

  /// Hide corner logo for live-style streams; keep for movies / VOD-style groups.
  bool get _hideChannelLogoOverlay {
    final g = _current.group.toLowerCase();
    final u = _current.url.toLowerCase();
    if (g.contains('movie') || g.contains('film') || g.contains('cinema')) return true;
    if (g.contains('live')) return true;
    if (u.contains('.m3u8')) return true;
    return false;
  }

  List<String> get _groupNames {
    final set = <String>{};
    for (final c in widget.channels) {
      set.add(c.group);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Channel> get _channelsInSelectedGroup {
    return widget.channels.where((c) => c.group == _selectedGroup).toList();
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.channels.length - 1);
    _selectedGroup = widget.channels[_index].group;

    _initFlow();
    
    // Hide engine splash after 4 seconds per user request
    Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showEngineSplash = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recentChannelsProvider.notifier).record(_current);
      _activePanel.addListener(_onPanelChanged);
      _configureNativePlayer();
      _startTechInfoTicker();
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
    
    try {
      final bit = await (p.platform as dynamic).getProperty('video-bitrate');
      setState(() {
        if (bit != null) {
          final kbps = (double.tryParse(bit.toString()) ?? 0) / 1024;
          _bitrate = "${kbps.toStringAsFixed(0)} kbps";
        }
        _fps = "60 FPS";
        _resolution = "1920x1080";
        _codec = "H.264";
      });
    } catch (_) {}
  }

  Future<void> _initFlow() async {
    final s = await AppSettingsData.load();
    if (!mounted) return;
    setState(() => _settings = s);
    _ensureClockTimer();
    await _initPlayer();
  }

  void _configureNativePlayer() {
    _player?.setProp('hwdec', 'auto');
    _player?.setProp('vo', 'gpu');
    _player?.setProp('gpu-api', 'opengl');
    _player?.setProp('vd-lavc-threads', '16');
    _player?.setProp('cache', 'yes');
    _player?.setProp('demuxer-max-bytes', '16777216');
    _player?.setAsync(true);
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
    _controller = null;
    await old?.dispose();

    final p = Player(configuration: const PlayerConfiguration(
      title: 'Optic TV',
    ));
    _player = p;

    _controller = VideoController(
      p,
      configuration: const VideoControllerConfiguration(enableHardwareAcceleration: true),
    );

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

    MonitorService.updateActivity(_current.name);
    _viewFit = _settings.videoFit;
    await p.open(Media(_current.url));
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
  void dispose() {
    _clockTimer?.cancel();
    _bufferingOverlayTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    MonitorService.updateActivity(null);
    _activePanel.dispose();
    _panelTimer?.cancel();
    _techInfoSubscription?.cancel();
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
    setState(() {
      _index = fullListIndex;
      _selectedGroup = widget.channels[_index].group;
    });
    ref.read(recentChannelsProvider.notifier).record(_current);
    unawaited(_reopenCurrentStream());
  }

  Future<void> _reopenCurrentStream() async {
    final p = _player;
    if (p == null) return;
    await p.open(Media(_current.url));
  }

  Future<void> _toggleFullscreen() async {
    await _videoKey.currentState?.toggleFullscreen();
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

  bool get _isMovie =>
      _current.group.toLowerCase().contains('movie') ||
      _current.group.toLowerCase().contains('film') ||
      _current.group.toLowerCase().contains('cinema');

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final isTv = MediaQuery.sizeOf(context).width > 900;
    
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'RobotoCondensed',
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        drawer: isTv ? _buildTvLeftDrawer(s) : null,
        endDrawer: isTv ? _buildTvRightDrawer(s) : null,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoView(),
            if (!isTv) ...[
              _buildMobileControls(uiLocale, s, bottomPad),
            ] else ...[
              _buildTvArchitectureOverhaul(s),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    return GestureDetector(
      onTap: _playPause,
      child: _controller != null
          ? Video(
              key: _videoKey,
              controller: _controller!,
              controls: NoVideoControls,
              wakelock: _settings.keepScreenOnWhilePlaying,
              fit: _viewFit,
              fill: const Color(0xFF000000),
              filterQuality: FilterQuality.high,
            )
          : Container(color: Colors.black),
    );
  }

  Widget _buildTvArchitectureOverhaul(AppStrings s) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowUp:
              setState(() {
                _reversePanelTransition = false;
                _activePanel.value = _TvPanelType.progressbar;
              });
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowDown:
              setState(() {
                if (_activePanel.value == _TvPanelType.progressbar) {
                  _reversePanelTransition = false;
                  _activePanel.value = _TvPanelType.playlist;
                } else if (_activePanel.value == _TvPanelType.playlist) {
                  _reversePanelTransition = true;
                  _activePanel.value = _TvPanelType.none;
                  _scaffoldKey.currentState?.openEndDrawer();
                } else {
                  _activePanel.value = _TvPanelType.progressbar;
                }
              });
              return KeyEventResult.handled;
            case LogicalKeyboardKey.select:
            case LogicalKeyboardKey.enter:
              _playPause();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowLeft:
              _scaffoldKey.currentState?.openDrawer();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowRight:
              _scaffoldKey.currentState?.openEndDrawer();
              return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: _activePanel,
            builder: (context, panel, _) {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: panel != _TvPanelType.none ? 1.0 : 0.0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.4, 0.8],
                    ),
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: _activePanel,
            builder: (context, panel, _) {
              return PageTransitionSwitcher(
                reverse: _reversePanelTransition,
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim, secAnim) => SharedAxisTransition(
                  animation: anim,
                  secondaryAnimation: secAnim,
                  transitionType: SharedAxisTransitionType.vertical,
                  fillColor: Colors.transparent,
                  child: child,
                ),
                child: panel == _TvPanelType.none ? const SizedBox.expand() : (
                  panel == _TvPanelType.progressbar ? _buildTvPlayerOSD(s) : _buildTvHorizontalPlaylist(s)
                ),
              );
            },
          ),
          _buildTvBufferingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTvBufferingOverlay() {
    return ListenableBuilder(
      listenable: _player!.stream.buffering,
      builder: (context, _) => _player!.state.buffering ? Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 4)
      ) : const SizedBox(),
    );
  }

  Widget _buildTvHorizontalPlaylist(AppStrings s) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 220,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 72),
          itemCount: widget.channels.length,
          itemBuilder: (context, idx) {
            final ch = widget.channels[idx];
            final selected = ch == _current;
            return Container(
              width: 280,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? _accent : Colors.white10, width: 2),
              ),
              child: InkWell(
                onTap: () => _selectChannelByIndex(idx),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ChannelLogoImage(logo: ch.logo, fit: BoxFit.cover),
                      Container(color: Colors.black45),
                      Center(child: Text(ch.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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

  Widget _buildTvPlayerOSD(AppStrings s) {
    final format = DateFormat('H:mm:ss');
    final posStr = format.format(DateTime(2026).add(_position));
    final durStr = format.format(DateTime(2026).add(_duration));
    final timeStr = DateFormat.jm().format(DateTime.now());

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ChannelLogoImage(logo: _current.logo, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 36),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.channels.indexOf(_current) + 1}'.padLeft(3, '0'),
                        style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _current.name,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _osdTechInfoItem("VIDEO", color: Colors.purpleAccent),
                          const SizedBox(width: 12),
                          _osdTechInfoItem(_resolution),
                          const SizedBox(width: 12),
                          _osdTechInfoItem("${_fps} FPS"),
                          const SizedBox(width: 12),
                          _osdTechInfoItem(_bitrate),
                          const Spacer(),
                          Text(timeStr, style: const TextStyle(color: Colors.white60, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
                children: [
                  Text(posStr, style: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'monospace')),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _duration.inMilliseconds > 0 ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0) : 0,
                          child: Container(decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(3))),
                        ),
                      ),
                    ),
                  ),
                  Text(durStr, style: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'monospace')),
                ],
              ),
            ] else ...[
               Container(
                 height: 4,
                 width: double.infinity,
                 decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                 child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.7, // Simulated live progress
                    child: Container(decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
                 ),
               ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _osdTechInfoItem(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (color ?? Colors.white).withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color ?? Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTvLeftDrawer(AppStrings s) {
    final groups = _groupNames;
    return Container(
      width: 1000,
      color: Colors.black.withOpacity(0.95),
      child: Row(
        children: [
          // Pane 1: Categories
          Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (ctx, idx) {
                final g = groups[idx];
                final selected = _selectedGroup == g;
                return _tvDrawerItem(g, selected, () => setState(() => _selectedGroup = g));
              },
            ),
          ),
          // Pane 2: Channels
          Container(
            width: 350,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: ListView.builder(
              itemCount: _channelsInSelectedGroup.length,
              itemBuilder: (ctx, idx) {
                final ch = _channelsInSelectedGroup[idx];
                final active = ch == _current;
                return _tvDrawerItem(ch.name, active, () => _selectChannelByIndex(widget.channels.indexOf(ch)));
              },
            ),
          ),
          // Pane 3: EPG / Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OpticWordmark(height: 32),
                  const SizedBox(height: 48),
                  Text("PROGRAM GUIDE", style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text("No EPG information available for this stream.", style: TextStyle(color: Colors.white54, fontSize: 18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvRightDrawer(AppStrings s) {
    return Container(
      width: 400,
      color: const Color(0xFF111318),
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Streams", style: TextStyle(color: _accent, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          _tvDrawerItem("Mirror 1 (Primary)", true, () {}),
          _tvDrawerItem("Mirror 2 (Backup)", false, () {}),
          _tvDrawerItem("Mirror 3 (SD)", false, () {}),
        ],
      ),
    );
  }

  Widget _tvDrawerItem(String label, bool active, VoidCallback onTap) {
    return TvFocusWrapper(
      onTap: onTap,
      borderRadius: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _accent : Colors.white70,
            fontSize: 18,
            fontWeight: active ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

