import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
    _player = Player();
    _controller = VideoController(_player);
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                if (_settings.showOnScreenClock)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Text(
                      timeLabel,
                      style: TextStyle(
                        color: _accent.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: _videoHeight(context),
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: _playPause,
                  child: Video(
                    key: _videoKey,
                    controller: _controller,
                    controls: NoVideoControls,
                    wakelock: _settings.keepScreenOnWhilePlaying,
                    fit: _settings.videoFit,
                    fill: const Color(0xFF000000),
                  ),
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
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Material(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                      if (!_hideChannelLogoOverlay && _current.logo != null && _current.logo!.isNotEmpty)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ChannelLogoImage(
                              logo: _current.logo,
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                              fallback: const Icon(Icons.tv_rounded, color: Colors.white54, size: 28),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Material(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _toggleMute,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Material(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _toggleFullscreen,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ),
                      if (_showEngineSplash) _buildEngineSplash(),
                      if (_buffering) _buildBufferingIndicator(),
                      if (_isMovie) _buildMovieControlsOverlay(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
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
                                            color: selected ? _accent : Colors.transparent,
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
                                            color: selected ? _accent : Colors.white54,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              g,
                                              style: AppTheme.withRabarIfKurdish(
                                                uiLocale,
                                                TextStyle(
                                                  color: selected ? _accent : Colors.white.withOpacity(0.82),
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
                                                color: playing ? _accent : Colors.white.withOpacity(0.88),
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
                                            decoration: const BoxDecoration(
                                              color: _accent,
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
