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
import 'package:animations/animations.dart';
import 'package:optic_tv/widgets/tv_fluid_focusable.dart';
import 'fullscreen_player_page.dart';

import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';
import '../../widgets/player_control_button.dart';
import '../../widgets/optic_wordmark.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/monitor_service.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/tv_focus_wrapper.dart';
import '../settings/settings_screen.dart';
import '../../services/subtitle_service.dart';
import '../../services/tmdb_service.dart';

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
  BoxFit _viewFit = BoxFit.contain;
  final FocusNode _playerFocus = FocusNode();
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
  
  // Subtitle System
  final SubtitleService _subtitleService = SubtitleService();
  final TmdbService _tmdbService = TmdbService();
  List<SubtitleResult> _availableSubtitles = [];
  bool _isSearchingSubtitles = false;
  bool _showSubtitlePrompt = false;

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
    // Balanced Hardware Acceleration for Stability & 4K Performance
    if (_player?.platform is NativePlayer) {
      final native = _player!.platform as NativePlayer;
      Future<void> set(String k, String v) async {
        try { await native.setProperty(k, v); } catch (_) {}
      }
      set('hwdec', 'auto-safe');         // Use safest hardware decoding mode
      set('cache', 'yes');               // Enable caching
      set('demuxer-max-bytes', '16777216'); // 16MB demuxer cache (balanced)
      set('vd-lavc-threads', '0');       // Auto-detect optimal threads
      // Removed vo-gpu and opengl to prevent driver crashes on some Android devices
    }
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

    _viewFit = _settings.videoFit;
    _configureNativePlayer(); // Apply stable properties
    await p.open(Media(_current.url));
    
    // Hide engine splash only after video attempts to start
    Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showEngineSplash = false);
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

  @override
  void dispose() {
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
    
    // Clear old subtitles
    setState(() {
      _availableSubtitles = [];
      _showSubtitlePrompt = false;
    });

    await p.open(Media(_current.url));
    
    // Start subtitle search if it's a movie
    if (_isMovie) {
      _searchSubtitles();
    }
  }

  bool get _isMovie {
    final g = _current.group.toLowerCase();
    return g.contains('movie') || g.contains('film') || g.contains('cinema');
  }

  Future<void> _searchSubtitles() async {
    if (!_subtitleService.hasApiKey) return;
    
    setState(() => _isSearchingSubtitles = true);
    
    try {
      // 1. Find movie on TMDB to get IMDb ID
      final movie = await _tmdbService.findMovie(_current.name);
      
      // 2. Search OpenSubtitles
      final results = await _subtitleService.search(
        imdbId: movie?.imdbId,
        query: movie?.title ?? _current.name,
      );
      
      if (mounted && results.isNotEmpty) {
        setState(() {
          _availableSubtitles = results;
          _showSubtitlePrompt = true;
          _isSearchingSubtitles = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingSubtitles = false);
    }
  }

  Future<void> _applySubtitle(SubtitleResult sub) async {
    final url = await _subtitleService.getDownloadUrl(sub.id);
    if (url != null && _player != null) {
      await _player!.setSubtitleTrack(SubtitleTrack.uri(url));
      if (mounted) setState(() => _showSubtitlePrompt = false);
    }
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) return; // Should not happen in this flow if we navigate away

    if (_player == null || _controller == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenPlayerPage(
          player: _player!,
          controller: _controller!,
          channels: widget.channels,
          initialIndex: _index,
          uiLocale: ref.read(appLocaleProvider),
          strings: AppStrings(ref.read(appLocaleProvider)),
        ),
      ),
    );

    // When returning from fullscreen, we might need to update the local index if it changed
    if (result is int && mounted) {
      setState(() {
        _index = result;
        _selectedGroup = widget.channels[_index].group;
      });
      // Stream is already opened in the FullscreenPage, but we sync local state here
    }
    
    // Ensure portrait orientation logic is solid on return
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
    if (_player == null || _controller == null) {
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoView(),
            _buildTvArchitectureOverhaul(s),
            if (_showSubtitlePrompt) _buildSubtitleChoicePrompt(uiLocale, s),
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
            
            if (_showSubtitlePrompt) _buildSubtitleChoicePrompt(uiLocale, s),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleChoicePrompt(Locale uiLocale, AppStrings s) {
    // Group subtitles by language
    final kurdish = _availableSubtitles.where((sub) => sub.language == 'ku' || sub.language == 'ckb').toList();
    final english = _availableSubtitles.where((sub) => sub.language == 'en').toList();

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.isEnglish ? 'Subtitle Options' : 'هەڵبژاردنی ژێرنووس',
                style: AppTheme.withRabarIfKurdish(
                  uiLocale,
                  const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.isEnglish ? 'Choose a language for this movie' : 'زمانێک هەڵبژێرە بۆ ئەم فیلمە',
                textAlign: TextAlign.center,
                style: AppTheme.withRabarIfKurdish(
                  uiLocale,
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              if (kurdish.isNotEmpty)
                _buildSubtitleChoiceButton(
                  label: 'KURDISH (سۆرانی)',
                  icon: Icons.translate_rounded,
                  color: _accent,
                  onTap: () => _applySubtitle(kurdish.first),
                ),
              if (english.isNotEmpty)
                _buildSubtitleChoiceButton(
                  label: 'ENGLISH',
                  icon: Icons.language_rounded,
                  color: Colors.blueAccent,
                  onTap: () => _applySubtitle(english.first),
                ),
              _buildSubtitleChoiceButton(
                label: s.isEnglish ? 'NONE' : 'بەبێ ژێرنووس',
                icon: Icons.close_rounded,
                color: Colors.white24,
                onTap: () => setState(() => _showSubtitlePrompt = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleChoiceButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Redundant Overlay Scaffold removed to fix layout issues

  Widget _buildVideoView() {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _playPause,
            child: _controller != null
                ? Video(
                    key: _videoKey,
                    controller: _controller!,
                    controls: NoVideoControls,
                    wakelock: _settings!.keepScreenOnWhilePlaying,
                    fit: _viewFit,
                    fill: const Color(0xFF000000),
                    filterQuality: FilterQuality.high,
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.white24)),
          ),
          // Fullscreen Toggle Icon (Bottom Right)
          if (!_isFullscreen)
            Positioned(
              bottom: 8,
              right: 8,
              child: Material(
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
        children: [
          // 1. Centered Status Indicators (Pause/Buffering)
          _buildTvPlaybackStatus(),

          // 2. The Sliding Panels (Progressbar / Playlist)
          Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder<_TvPanelType>(
              valueListenable: _activePanel,
              builder: (context, panel, _) => PageTransitionSwitcher(
                reverse: _reversePanelTransition,
                duration: const Duration(milliseconds: 500),
                layoutBuilder: (entries) => Stack(alignment: Alignment.bottomCenter, children: entries),
                transitionBuilder: (child, anim, secAnim) => SharedAxisTransition(
                  animation: anim,
                  secondaryAnimation: secAnim,
                  transitionType: SharedAxisTransitionType.vertical,
                  fillColor: Colors.transparent,
                  child: child,
                ),
                child: panel == _TvPanelType.none
                    ? _buildTvLiteProgressbar()
                    : panel == _TvPanelType.progressbar
                        ? _buildTvProgressPanel(s)
                        : _buildTvPlaylistPanel(s),
              ),
            ),
          ),
          
          // 3. Ghosten-Style Channel Info (Top Left)
          if (_activePanel.value != _TvPanelType.none)
            Positioned(
              top: 54,
              left: 72,
              child: _GhostenPlayerInfoView(channel: _current),
            ),
        ],
      ),
    );
  }

  Widget _buildTvPlaybackStatus() {
    return Center(
      child: StreamBuilder<bool>(
        stream: _player!.stream.buffering,
        builder: (context, bufferingSnap) {
          final buffering = bufferingSnap.data ?? false;
          if (buffering) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _accent, strokeWidth: 4),
                const SizedBox(height: 16),
                const Text('Buffering...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            );
          }
          return StreamBuilder<bool>(
            stream: _player!.stream.playing,
            builder: (context, playingSnap) {
              final playing = playingSnap.data ?? true;
              if (!playing) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(Icons.pause, size: 72, color: Colors.white),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildTvLiteProgressbar() {
    final progress = _duration.inSeconds > 0 ? (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: double.infinity,
      height: 4,
      alignment: Alignment.bottomLeft,
      color: Colors.black26,
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: _accent,
            boxShadow: [BoxShadow(color: _accent.withOpacity(0.5), blurRadius: 4)],
          ),
        ),
      ),
    );
  }

  Widget _buildTvProgressPanel(AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(72, 40, 72, 54),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTvTimeline(),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tvGhostenPlayerAction(Icons.skip_previous_rounded, () => _handlePrevious()),
              const SizedBox(width: 32),
              _tvGhostenPlayerAction(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                () => _isPlaying ? _player!.pause() : _player!.play(),
                isLarge: true,
              ),
              const SizedBox(width: 32),
              _tvGhostenPlayerAction(Icons.skip_next_rounded, () => _handleNext()),
              const Spacer(),
              _tvGhostenPlayerAction(Icons.format_list_bulleted_rounded, () {
                setState(() {
                  _reversePanelTransition = false;
                  _activePanel.value = _TvPanelType.playlist;
                });
              }),
              const SizedBox(width: 20),
              _tvGhostenPlayerAction(Icons.settings_outlined, () => _scaffoldKey.currentState?.openEndDrawer()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTvTimeline() {
    final pos = _position;
    final dur = _duration;
    final progress = dur.inSeconds > 0 ? (pos.inSeconds / dur.inSeconds).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(pos), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            Text(_formatDuration(dur), style: const TextStyle(color: Colors.white38, fontSize: 18, fontFamily: 'monospace')),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accent.withOpacity(0.6), _accent]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 10)],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTvPlaylistPanel(AppStrings s) {
    final groupChannels = _channelsInSelectedGroup;
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
            child: Text(
              _selectedGroup.toUpperCase(),
              style: TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: groupChannels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, i) {
                final ch = groupChannels[i];
                final active = ch.url == _current.url;
                return GhostenFocusable(
                  onTap: () {
                    final idx = widget.channels.indexOf(ch);
                    _selectChannelByIndex(idx);
                  },
                  backgroundColor: active ? _accent.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: ChannelLogoImage(logo: ch.logo, height: 72, width: 72),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ch.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.white70,
                            fontSize: 16,
                            fontWeight: active ? FontWeight.w900 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tvGhostenPlayerAction(IconData icon, VoidCallback onTap, {bool isLarge = false}) {
    return GhostenFocusable(
      onTap: onTap,
      backgroundColor: Colors.white.withOpacity(0.06),
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 18 : 14),
        child: Icon(icon, color: Colors.white, size: isLarge ? 36 : 28),
      ),
    );
  }

  KeyEventResult _onTvRootKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final key = event.logicalKey;

      if (_activePanel.value == _TvPanelType.none) {
        if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
          setState(() {
            _reversePanelTransition = false;
            _activePanel.value = _TvPanelType.progressbar;
          });
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          setState(() {
            _reversePanelTransition = false;
            _activePanel.value = _TvPanelType.playlist;
          });
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft) {
          _player!.seek(_position - const Duration(seconds: 15));
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          _player!.seek(_position + const Duration(seconds: 15));
          return KeyEventResult.handled;
        }
      } else {
        if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.browserBack) {
          setState(() {
            _reversePanelTransition = true;
            _activePanel.value = _TvPanelType.none;
          });
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown && _activePanel.value == _TvPanelType.progressbar) {
             setState(() {
                _reversePanelTransition = false;
                _activePanel.value = _TvPanelType.playlist;
             });
             return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp && _activePanel.value == _TvPanelType.playlist) {
             setState(() {
                _reversePanelTransition = true;
                _activePanel.value = _TvPanelType.progressbar;
             });
             return KeyEventResult.handled;
        }
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
          const OpticWordmark(height: 22),
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
          if (_isMovie)
            IconButton(
              icon: Icon(
                Icons.closed_caption_rounded,
                color: _availableSubtitles.isNotEmpty ? _accent : Colors.white24,
                size: 24,
              ),
              onPressed: () => _showSubtitleModal(uiLocale, s),
            ),
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

  void _showSubtitleModal(Locale uiLocale, AppStrings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: const Color(0xFF14171C),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(
              s.isEnglish ? 'Subtitles' : 'ژێرنووس',
              style: AppTheme.withRabarIfKurdish(
                uiLocale,
                const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _availableSubtitles.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return ListTile(
                      leading: const Icon(Icons.close_rounded, color: Colors.white60),
                      title: Text(s.isEnglish ? 'None' : 'بەبێ ژێرنووس', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onTap: () {
                        _player?.setSubtitleTrack(SubtitleTrack.no());
                        Navigator.pop(context);
                      },
                    );
                  }
                  final sub = _availableSubtitles[i - 1];
                  final isKur = sub.language == 'ku' || sub.language == 'ckb';
                  return ListTile(
                    leading: Icon(isKur ? Icons.translate_rounded : Icons.language_rounded, color: isKur ? _accent : Colors.blue),
                    title: Text(sub.fileName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    subtitle: Text(sub.language.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    trailing: const Icon(Icons.download_rounded, color: Colors.white24, size: 18),
                    onTap: () {
                      _applySubtitle(sub);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileVideoOverlay() {
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
          Center(
            child: StreamBuilder<bool>(
              stream: _player!.stream.buffering,
              builder: (context, snap) => (snap.data ?? false)
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
                        child: Container(
                          width: 32,
                          height: 32,
                          color: Colors.white.withOpacity(0.05),
                          child: ch.logo != null && ch.logo!.isNotEmpty
                              ? ChannelLogoImage(logo: ch.logo, width: 32, height: 32)
                              : Icon(Icons.tv_rounded, color: Colors.white12, size: 18),
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
              );
            },
          ),
        ),
      );
    }
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

