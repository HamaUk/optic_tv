import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';
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

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Channel get _current => widget.channels[_index];

  /// Hide corner logo for live-style streams; keep for movies / VOD-style groups.
  bool get _hideChannelLogoOverlay {
    final g = _current.group.toLowerCase();
    final u = _current.url.toLowerCase();
    if (g.contains('movie') || g.contains('film') || g.contains('cinema')) return false;
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
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
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  tooltip: s.shareChannel,
                  icon: Icon(Icons.share_rounded, color: Colors.white.withValues(alpha: 0.85), size: 22),
                  onPressed: () => Share.share('${_current.name}\n${_current.url}', subject: _current.name),
                ),
                if (_settings.showOnScreenClock)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Text(
                      timeLabel,
                      style: TextStyle(
                        color: _accent.withValues(alpha: 0.95),
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
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0, 0.25, 0.65, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
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
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                    color: Colors.black.withValues(alpha: 0.45),
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
                    color: Colors.black.withValues(alpha: 0.45),
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
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
                                              style: TextStyle(
                                                color: selected ? _accent : Colors.white.withValues(alpha: 0.82),
                                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                                fontSize: 13,
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
                Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),
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
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad + 12),
                            itemCount: _channelsInSelectedGroup.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
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
                                            style: TextStyle(
                                              color: playing ? _accent : Colors.white.withValues(alpha: 0.88),
                                              fontWeight: playing ? FontWeight.w700 : FontWeight.w500,
                                              fontSize: 14,
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
}
