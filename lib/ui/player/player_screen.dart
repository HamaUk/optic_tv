import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:flutter_cast_video/flutter_cast_video.dart';

import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';
import '../../widgets/player_control_button.dart';
import '../../widgets/optic_wordmark.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';

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
  static const _accent = AppTheme.accentTeal;

  final GlobalKey<VideoState> _videoKey = GlobalKey<VideoState>();
  
  // Media Kit (mpv)
  Player? _player;
  VideoController? _controller;
  
  late int _index;
  late String _selectedGroup;
  AppSettingsData _settings = const AppSettingsData();
  Timer? _clockTimer;
  bool _muted = false;
  bool _showMiniGuide = false;
  late final VideoController _videoKey = VideoController();
  bool _showEngineSplash = true;
  bool _buffering = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isPlaying = true; // Most streams auto-play upon open

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
    });
  }

  Future<void> _initFlow() async {
    final s = await AppSettingsData.load();
    if (!mounted) return;
    setState(() => _settings = s);
    _ensureClockTimer();
    await _initPlayer();
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

    if (p.platform is NativePlayer) {
      final native = p.platform as NativePlayer;
      // PERFORMANCE & QUALITY UPGRADES
      await native.setProperty('hwdec', 'mediacodec'); // Hardware acceleration
      await native.setProperty('profile', 'high-quality'); // Premium scaling/rendering
      await native.setProperty('cache', 'yes'); // Enable caching
      await native.setProperty('demuxer-max-bytes', '1000MiB'); // Buffer 1GB for stability
      await native.setProperty('demuxer-max-back-bytes', '200MiB');
      await native.setProperty('demuxer-readahead-secs', '45'); // Pre-buffer 45s
      await native.setProperty('cache-secs', '60'); // Keep 60s in RAM
      await native.setProperty('vd-lavc-threads', '4'); // Multi-threaded video decoding
      await native.setProperty('ad-lavc-threads', '2'); // Multi-threaded audio
      await native.setProperty('opengl-pbo', 'yes'); // Fast pixel buffer transfers
      await native.setProperty('hr-seek', 'yes'); // High-resolution seeking
      await native.setProperty('video-sync', 'display-resample');
    }

    _controller = VideoController(
      p,
      configuration: const VideoControllerConfiguration(enableHardwareAcceleration: true),
    );

    _subscriptions.add(p.stream.volume.listen((v) {
      if (mounted && v > 0 && _muted) setState(() => _muted = false);
      if (mounted && v == 0 && !_muted) setState(() => _muted = true);
    }));
    _subscriptions.add(p.stream.buffering.listen((b) {
      if (mounted) setState(() => _buffering = b);
    }));
    _subscriptions.add(p.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    }));
    _subscriptions.add(p.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    }));
    _subscriptions.add(p.stream.playing.listen((pl) {
      if (mounted) setState(() => _isPlaying = pl);
    }));

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
    for (final s in _subscriptions) {
      s.cancel();
    }
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
      _buffering = true;
    });
    
    _player?.open(Media(_current.url));
    ref.read(recentChannelsProvider.notifier).record(_current);
  }

  Future<void> _toggleFullscreen() async {
    await _videoKey.currentState?.toggleFullscreen();
  }

  Future<void> _playPause() async {
    await _player?.playOrPause();
    _showControls();
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _seekTo(Duration absolute) async {
    await _player?.seek(absolute);
  }

  Future<void> _seekRelative(Duration offset) async {
    final target = _position + offset;
    final clamped = target < Duration.zero ? Duration.zero : (target > _duration ? _duration : target);
    await _seekTo(clamped);
  }

  void _zapNext() {
    final list = _channelsInSelectedGroup.isEmpty ? widget.channels : _channelsInSelectedGroup;
    final currentIndexInList = list.indexWhere((c) => c.url == _current.url);
    if (currentIndexInList == -1) return;
    
    final nextIndex = (currentIndexInList + 1) % list.length;
    _selectChannelByIndex(widget.channels.indexOf(list[nextIndex]));
    _showControls();
  }

  void _zapPrevious() {
    final list = _channelsInSelectedGroup.isEmpty ? widget.channels : _channelsInSelectedGroup;
    final currentIndexInList = list.indexWhere((c) => c.url == _current.url);
    if (currentIndexInList == -1) return;
    
    final prevIndex = (currentIndexInList - 1 + list.length) % list.length;
    _selectChannelByIndex(widget.channels.indexOf(list[prevIndex]));
    _showControls();
  }

  Future<void> _enterPiP() async {
    SimplePip().enterPipMode();
  }

  Future<void> _showTrackSelection(bool isAudio) async {
    final s = AppStrings(ref.read(appLocaleProvider));
    if (_player == null) return;

    final tracks = isAudio ? _player!.state.tracks.audio : _player!.state.tracks.subtitle;
    final current = isAudio ? _player!.state.track.audio : _player!.state.track.subtitle;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAudio ? 'Audio tracks' : 'Subtitles',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tracks.length,
                  itemBuilder: (context, i) {
                    final t = tracks[i];
                    final selected = t.id == current.id;
                    return ListTile(
                      leading: Icon(
                        isAudio ? Icons.audiotrack_rounded : Icons.closed_caption_rounded,
                        color: selected ? AppTheme.accentTeal : Colors.white30,
                      ),
                      title: Text(
                        '${t.title ?? t.language ?? (isAudio ? 'Audio' : 'Sub')} ${t.id}',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppTheme.accentTeal) : null,
                      onTap: () {
                        if (isAudio) {
                          _player!.setAudioTrack(t);
                        } else {
                          _player!.setSubtitleTrack(t);
                        }
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _isMovie =>
      _current.group.toLowerCase().contains('movie') ||
      _current.group.toLowerCase().contains('film') ||
      _current.group.toLowerCase().contains('cinema');

  double _videoHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.38).clamp(168.0, 340.0);
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.any((e) => e.url == _current.url);
    final s = AppStrings(uiLocale);
    // `intl` has no Sorani clock patterns; keep Latin digits for time.
    final timeLabel = DateFormat.jm('en').format(DateTime.now());
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _current.name,
                    style: AppTheme.withRabarIfKurdish(
                      uiLocale,
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PlayerControlButton(
                  icon: isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  tooltip: isFav ? s.unfavoriteChannel : s.favoriteChannel,
                  color: AppTheme.primaryGold,
                  onTap: () => ref.read(favoritesProvider.notifier).toggle(_current),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ChromeCastButton(
                    onButtonCreated: (controller) {
                      controller.addSessionListener(ChromeCastSessionListener(
                        onSessionStarted: () => controller.loadMedia(_current.url),
                      ));
                    },
                    onSessionStarted: (controller) => controller.loadMedia(_current.url),
                  ),
                ),
                const SizedBox(width: 8),
                PlayerControlButton(
                  icon: Icons.picture_in_picture_alt_rounded,
                  tooltip: 'Picture-in-Picture',
                  onTap: _enterPiP,
                ),
                const SizedBox(width: 8),
                PlayerControlButton(
                  icon: Icons.audiotrack_rounded,
                  tooltip: 'Audio Tracks',
                  onTap: () => _showTrackSelection(true),
                ),
                const SizedBox(width: 8),
                PlayerControlButton(
                  icon: Icons.closed_caption_rounded,
                  tooltip: 'Subtitles',
                  onTap: () => _showTrackSelection(false),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () {
                    _playPause();
                    _showControls();
                  },
                  onDoubleTap: _toggleFullscreen,
                  child: _controller != null
                      ? Video(
                          key: _videoKey,
                          controller: _controller!,
                          controls: NoVideoControls,
                          wakelock: _settings.keepScreenOnWhilePlaying,
                          fit: _settings.videoFit,
                          fill: const Color(0xFF000000),
                          filterQuality: FilterQuality.high,
                        )
                      : const SizedBox.shrink(),
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0, 0.25, 0.65, 1],
                      ),
                    ),
                  ),
                ),
                
                // Shared Overlays
                if (_showEngineSplash) _buildEngineSplash(),
                if (_buffering) _buildBufferingIndicator(),
                
                // Dynamic Overlays
                if (_isMovie) 
                  _buildMovieControlsOverlay()
                else 
                  _buildLiveTvControlsOverlay(),

                if (_showMiniGuide) _buildMiniGuideOverlay(),

                // Back Button
                if (_controlsVisible)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: PlayerControlButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                
                // Secondary Controls (Top Right)
                if (_controlsVisible)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerControlButton(
                          icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          isToggle: true,
                          toggled: _muted,
                          onTap: () => setState(() => _muted = !_muted),
                        ),
                        const SizedBox(width: 12),
                        PlayerControlButton(
                          icon: Icons.fullscreen_rounded,
                          onTap: _toggleFullscreen,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isMovie
                ? _buildRelatedMovies(uiLocale, s, bottomPad)
                : _buildMobileChannelLists(uiLocale, s, bottomPad),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileChannelLists(Locale uiLocale, AppStrings s, double bottomPad) {
    final accent = AppTheme.accentTeal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: Container(
            color: const Color(0xFF0E131A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Text(
                    s.categoriesTitle,
                    style: AppTheme.withRabarIfKurdish(
                      uiLocale,
                      TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: _groupNames.length,
                    itemBuilder: (context, i) {
                      final g = _groupNames[i];
                      final selected = g == _selectedGroup;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Material(
                          color: selected ? const Color(0xFF15252A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _selectedGroup = g),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: BorderDirectional(
                                  end: BorderSide(
                                    color: selected ? accent : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 18,
                                    color: selected ? accent : Colors.white54,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      g,
                                      style: AppTheme.withRabarIfKurdish(
                                        uiLocale,
                                        TextStyle(
                                          color: selected ? accent : Colors.white.withOpacity(0.82),
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(width: 1, color: Colors.white.withOpacity(0.06)),
        Expanded(
          flex: 14,
          child: Container(
            color: AppTheme.backgroundBlack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Center(
                    child: Text(
                      s.channelListTitle,
                      style: AppTheme.withRabarIfKurdish(
                        uiLocale,
                        TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad + 12),
                    itemCount: _channelsInSelectedGroup.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                    itemBuilder: (context, i) {
                      final ch = _channelsInSelectedGroup[i];
                      final fullIdx = widget.channels.indexOf(ch);
                      final playing = fullIdx == _index;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectChannelByIndex(fullIdx),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ch.name,
                                    style: AppTheme.withRabarIfKurdish(
                                      uiLocale,
                                      TextStyle(
                                        color: playing ? accent : Colors.white.withOpacity(0.88),
                                        fontWeight: playing ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (playing)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
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
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildBufferingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryGold,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Loading stream...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineSplash() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OpticWordmark(height: 48),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PREMIUM ENGINE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieControlsOverlay() {
    final format = DateFormat('H:mm:ss');
    final posStr = format.format(DateTime(2024).add(_position));
    final durStr = format.format(DateTime(2024).add(_duration));

    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          // Bottom bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
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
                  // Progress
                  Row(
                    children: [
                      Text(posStr, style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'monospace')),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppTheme.primaryGold,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: AppTheme.primaryGold,
                          ),
                          child: Slider(
                            value: _position.inMilliseconds.toDouble(),
                            max: math.max(_duration.inMilliseconds.toDouble(), 1.0),
                            onChanged: (v) {
                              _seekTo(Duration(milliseconds: v.toInt()));
                            },
                          ),
                        ),
                      ),
                      Text(durStr, style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Buttons (Strictly LTR for playback logic)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PlayerControlButton(
                          icon: Icons.replay_10_rounded,
                          size: 48,
                          onTap: () => _seekRelative(const Duration(seconds: -10)),
                        ),
                        const SizedBox(width: 32),
                        // Premium Play/Pause Toggle
                        PlayerControlButton(
                          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 64,
                          color: Colors.black,
                          onTap: _playPause,
                          isToggle: true,
                          toggled: _isPlaying,
                        ),
                        const SizedBox(width: 32),
                        PlayerControlButton(
                          icon: Icons.forward_10_rounded,
                          size: 48,
                          onTap: () => _seekRelative(const Duration(seconds: 10)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Title at top
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Text(
                _current.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTvControlsOverlay() {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          // Header: Channel Info
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _current.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: Zap Buttons
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayerControlButton(
                  icon: Icons.keyboard_arrow_left_rounded,
                  size: 60,
                  onTap: _zapPrevious,
                  tooltip: 'Previous Channel',
                ),
                const SizedBox(width: 60),
                PlayerControlButton(
                  icon: Icons.keyboard_arrow_right_rounded,
                  size: 60,
                  onTap: _zapNext,
                  tooltip: 'Next Channel',
                ),
              ],
            ),
          ),

          // Bottom Bar: Program Info
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.primaryGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Now Playing',
                          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _current.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PlayerControlButton(
                    icon: Icons.list_alt_rounded,
                    isToggle: true,
                    toggled: _showMiniGuide,
                    onTap: () => setState(() => _showMiniGuide = !_showMiniGuide),
                    tooltip: 'Mini Guide',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGuideOverlay() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: 260,
      child: Material(
        color: Colors.black.withOpacity(0.85),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.list_rounded, color: AppTheme.primaryGold, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Guide',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => setState(() => _showMiniGuide = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _channelsInSelectedGroup.length,
                    itemBuilder: (context, i) {
                      final c = _channelsInSelectedGroup[i];
                      final selected = c.url == _current.url;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: AppTheme.primaryGold.withOpacity(0.1),
                        leading: selected 
                          ? const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryGold)
                          : const SizedBox(width: 24),
                        title: Text(
                          c.name,
                          style: TextStyle(
                            color: selected ? AppTheme.primaryGold : Colors.white70,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _selectChannelByIndex(widget.channels.indexOf(c));
                          setState(() => _showMiniGuide = false);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedMovies(Locale uiLocale, AppStrings s, double bottomPad) {
    final related = _channelsInSelectedGroup.where((c) => c.url != _current.url).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              const Icon(Icons.movie_rounded, color: AppTheme.primaryGold, size: 20),
              const SizedBox(width: 10),
              Text(
                'Related in ${_current.group}',
                style: AppTheme.withRabarIfKurdish(
                  uiLocale,
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: related.isEmpty
              ? Center(
                  child: Text(
                    'No other movies in this category',
                    style: TextStyle(color: Colors.white.withOpacity(0.35)),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
                  itemCount: related.length,
                  itemBuilder: (context, i) {
                    final movie = related[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: AspectRatio(
                        aspectRatio: 0.68,
                        child: Material(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _selectChannelByIndex(widget.channels.indexOf(movie)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (movie.logo != null && movie.logo!.isNotEmpty)
                                  ChannelLogoImage(
                                    logo: movie.logo,
                                    fit: BoxFit.cover,
                                    fallback: const Center(child: Icon(Icons.movie_outlined, color: Colors.white24)),
                                  )
                                else
                                  const Center(child: Icon(Icons.movie_outlined, color: Colors.white24, size: 32)),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 10,
                                  right: 10,
                                  child: Text(
                                    movie.name,
                                    style: AppTheme.withRabarIfKurdish(
                                      uiLocale,
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

}
