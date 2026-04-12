import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';
import '../../widgets/optic_wordmark.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';
import '../../providers/is_tv_provider.dart';

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
  late final Player _player;
  late final VideoController _controller;
  late int _index;
  late String _selectedGroup;
  AppSettingsData _settings = const AppSettingsData();
  Timer? _clockTimer;
  bool _muted = false;
  bool _buffering = true;
  bool _showEngineSplash = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _tvSidebarVisible = false;

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
    _player = Player(
      configuration: const PlayerConfiguration(),
    );

    // Apply native optimizations for Android TV clarity
    if (_player.platform is NativePlayer) {
      final native = _player.platform as NativePlayer;
      Future.microtask(() async {
        // Force native hardware decoding for sharpest resolution
        await native.setProperty('hwdec', 'mediacodec');
        // Prevent micro-stutter/jitter blurring
        await native.setProperty('video-sync', 'display-resample');
        // Enable high-quality scaling profile
        await native.setProperty('profile', 'high-quality');
        // Optimize demuxer for live streams on TV hardware
        await native.setProperty('demuxer-max-bytes', '500MiB');
        await native.setProperty('demuxer-max-back-bytes', '100MiB');
      });
    }

    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true, // Crucial for TV clarity
      ),
    );
    _player.open(Media(_current.url));
    _subscriptions.add(
      _player.stream.volume.listen((v) {
        if (mounted && v > 0 && _muted) setState(() => _muted = false);
        if (mounted && v == 0 && !_muted) setState(() => _muted = true);
      }),
    );
    _subscriptions.add(
      _player.stream.buffering.listen((b) {
        if (mounted) setState(() => _buffering = b);
      }),
    );
    _subscriptions.add(
      _player.stream.position.listen((p) {
        if (mounted) setState(() => _position = p);
      }),
    );
    _subscriptions.add(
      _player.stream.duration.listen((d) {
        if (mounted) setState(() => _duration = d);
      }),
    );
    // Hide engine splash after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showEngineSplash = false);
    });
    AppSettingsData.load().then((s) {
      if (!mounted) return;
      setState(() => _settings = s);
      _ensureClockTimer();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recentChannelsProvider.notifier).record(_current);
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
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleMute() async {
    if (_muted) {
      await _player.setVolume(100);
      setState(() => _muted = false);
    } else {
      await _player.setVolume(0);
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
    _player.open(Media(_current.url));
    ref.read(recentChannelsProvider.notifier).record(_current);
  }

  Future<void> _toggleFullscreen() async {
    await _videoKey.currentState?.toggleFullscreen();
  }

  Future<void> _playPause() async {
    await _player.playOrPause();
    _showControls();
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _seek(Duration offset) async {
    final target = _position + offset;
    final clamped = target < Duration.zero ? Duration.zero : (target > _duration ? _duration : target);
    await _player.seek(clamped);
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

    final isTv = ref.watch(isTvProvider).asData?.value ?? false;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (!isTv) return KeyEventResult.ignored;
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() => _tvSidebarVisible = !_tvSidebarVisible);
            return KeyEventResult.handled;
          }
          if (_tvSidebarVisible) {
            if (event.logicalKey == LogicalKeyboardKey.escape || 
                event.logicalKey == LogicalKeyboardKey.browserBack ||
                event.logicalKey == LogicalKeyboardKey.backspace) {
              setState(() => _tvSidebarVisible = false);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isTv) ...[
                  // Keep mobile header
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
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          tooltip: isFav ? s.unfavoriteChannel : s.favoriteChannel,
                          icon: Icon(
                            isFav ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppTheme.primaryGold,
                            size: 26,
                          ),
                          onPressed: () => ref.read(favoritesProvider.notifier).toggle(_current),
                        ),
                      ],
                    ),
                  ),
                ],
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
                        child: Video(
                          key: _videoKey,
                          controller: _controller,
                          controls: NoVideoControls,
                          wakelock: _settings.keepScreenOnWhilePlaying,
                          fit: _settings.videoFit,
                          fill: const Color(0xFF000000),
                        ),
                      ),
                      if (!isTv) // Mobile gradients/controls
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
                      
                      // Movie Controls (Bottom bar)
                      if (_isMovie) _buildMovieControlsOverlay(),

                      // Back Button (TV/Mobile friendly)
                      if (!isTv || _controlsVisible)
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Material(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isTv) // Mobile lists
                  Expanded(
                    child: _isMovie
                        ? _buildRelatedMovies(uiLocale, s, bottomPad)
                        : _buildMobileChannelLists(uiLocale, s, bottomPad),
                  ),
              ],
            ),

            // TV SIDEBAR OVERLAY
            if (isTv && _tvSidebarVisible)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _buildTvChannelSidebar(uiLocale, s),
              ),
          ],
        ),
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

  Widget _buildTvChannelSidebar(Locale uiLocale, AppStrings s) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: const Border(right: BorderSide(color: AppTheme.primaryGold, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Text(
              'LIVE CHANNELS',
              style: TextStyle(
                color: AppTheme.primaryGold,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: widget.channels.length,
              itemBuilder: (context, i) {
                final ch = widget.channels[i];
                final playing = i == _index;
                return Focus(
                  onFocusChange: (f) {
                    if (f) {
                      // Optionally update internal preview or UI
                    }
                  },
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && 
                        (event.logicalKey == LogicalKeyboardKey.enter || 
                         event.logicalKey == LogicalKeyboardKey.select)) {
                      _selectChannelByIndex(i);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Builder(
                    builder: (ctx) {
                      final hasFocus = Focus.of(ctx).hasFocus;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: hasFocus ? AppTheme.primaryGold : (playing ? AppTheme.primaryGold.withOpacity(0.1) : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              playing ? Icons.play_circle_filled_rounded : Icons.tv_rounded,
                              size: 18,
                              color: hasFocus ? Colors.black : (playing ? AppTheme.primaryGold : Colors.white54),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ch.name,
                                style: TextStyle(
                                  color: hasFocus ? Colors.black : (playing ? Colors.white : Colors.white70),
                                  fontSize: 14,
                                  fontWeight: playing || hasFocus ? FontWeight.w800 : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
                              _player.seek(Duration(milliseconds: v.toInt()));
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
                        _movieControlBtn(
                          icon: Icons.stop_rounded,
                          onPressed: () => Navigator.pop(context),
                          color: Colors.redAccent.withOpacity(0.8),
                        ),
                        const SizedBox(width: 20),
                        _movieControlBtn(
                          icon: Icons.replay_10_rounded,
                          onPressed: () => _seek(const Duration(seconds: -10)),
                        ),
                        const SizedBox(width: 24),
                        // Premium Play/Pause Toggle
                        GestureDetector(
                          onTap: _playPause,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.primaryGold, Color(0xFFC5A059)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGold.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: StreamBuilder<bool>(
                              stream: _player.stream.playing,
                              builder: (context, playing) {
                                return Icon(
                                  playing.data == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 28,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        _movieControlBtn(
                          icon: Icons.forward_10_rounded,
                          onPressed: () => _seek(const Duration(seconds: 10)),
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

  Widget _movieControlBtn({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: color.withOpacity(0.9), size: 22),
        ),
      ),
    );
  }

  Widget _playerIconBtn(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 30),
    );
  }
}
