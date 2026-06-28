import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';

import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';
import '../../services/viewer_service.dart';
import '../../widgets/dynamic_background.dart';
import '../../widgets/tv/tv_focusable.dart';
import '../player/player_screen.dart';
import '../dashboard/movie_details_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/update_service.dart';
import '../../widgets/update_prompt_dialog.dart';
import '../player/fullscreen_player_page.dart';
import '../../services/optic_player.dart';

class TvPlayerLauncher extends ConsumerStatefulWidget {
  final List<Channel> channels;
  final int initialIndex;

  const TvPlayerLauncher({super.key, required this.channels, required this.initialIndex});

  @override
  ConsumerState<TvPlayerLauncher> createState() => _TvPlayerLauncherState();
}

class _TvPlayerLauncherState extends ConsumerState<TvPlayerLauncher> {
  late final OpticPlayer _player;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _player = OpticPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final c = widget.channels[widget.initialIndex];
    await _player.open(c.url, headers: {
      'User-Agent': c.userAgent ?? 'SmartIPTV',
      'X-Optic-Security-Token': 'k4k-secure-stream-99X'
    });
    await _player.play();
    if (mounted) {
      setState(() => _isInit = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }
    final sLoc = ref.watch(appLocaleProvider);
    return FullscreenPlayerPage(
      player: _player,
      channels: widget.channels,
      initialIndex: widget.initialIndex,
      activeServerIndex: 0,
      uiLocale: sLoc,
      strings: AppStrings(sLoc),
    );
  }
}


class TvDashboardScreen extends ConsumerStatefulWidget {
  final List<Channel> allChannels;
  final List<ChannelGroup> managedGroups;
  
  const TvDashboardScreen({super.key, required this.allChannels, required this.managedGroups});

  @override
  ConsumerState<TvDashboardScreen> createState() => _TvDashboardScreenState();
}

class _TvDashboardScreenState extends ConsumerState<TvDashboardScreen> {
  int _navIndex = 0; // 0=Live TV, 1=Movies, 2=Sports, 3=Favorites, 4=Settings
  Channel? _focusedChannel;
  bool _sidebarHasFocus = true;
  bool _hasPromptedUpdate = false;

  Color get _accent {
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    return AppTheme.accentColor(settings.gradientPreset);
  }

  bool _isMovieChannel(Channel c) {
    if (c.type == 'movie') return true;
    if (c.type == 'live') return false;
    final g = c.group.toLowerCase();
    final n = c.name.toLowerCase();
    if (g.contains('live tv') || g == 'live' || n.contains(' (live)')) return false;
    if (g.contains('tv') && !g.contains('movie') && !g.contains('cinema')) return false;
    if (g == 'movies' || g == 'vod' || g == 'cinema' || g == 'films') return true;
    final movieKeywords = ['vod', 'box office', 'uhd', '4k', 'action', 'comedy', 'horror', 'drama', 'thriller', 'animation', 'documentary'];
    return movieKeywords.any((kw) => n.contains(kw)) || g.contains('movie') || g.contains('film');
  }

  bool _isSportChannel(Channel c) {
    if (c.type == 'sport') return true;
    final g = c.group.toLowerCase();
    final n = c.name.toLowerCase();
    final sportKeywords = ['sport', 'bein', 'ad sports', 'ssc', 'eurospot', 'espn', 'arena', 'bt sport', 'sky sport', 'alkass'];
    return sportKeywords.any((kw) => g.contains(kw)) || sportKeywords.any((kw) => n.contains(kw));
  }

  void _openPlayer(Channel channel) {
    final i = widget.allChannels.indexOf(channel);
    if (_isMovieChannel(channel)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(allChannels: widget.allChannels, channel: channel)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TvPlayerLauncher(channels: widget.allChannels, initialIndex: i >= 0 ? i : 0)));
    }
  }

  Map<String, List<Channel>> _groupChannels(List<Channel> channels) {
    final groups = <String, List<Channel>>{};
    for (final c in channels) {
      groups.putIfAbsent(c.group, () => []).add(c);
    }
    return groups;
  }

  List<Channel> _getTabChannels() {
    final favorites = ref.watch(favoritesProvider);
    switch (_navIndex) {
      case 0: return widget.allChannels.where((c) => !_isMovieChannel(c) && !_isSportChannel(c)).toList(); // Live TV
      case 1: return widget.allChannels.where(_isMovieChannel).toList(); // Movies
      case 2: return widget.allChannels.where(_isSportChannel).toList(); // Sports
      case 3: return favorites; // Favorites
      default: return widget.allChannels.where((c) => !_isMovieChannel(c)).toList();
    }
  }

  Widget _buildSidebarItem(IconData icon, String label, int index, AppStrings s) {
    final isSelected = _navIndex == index;
    return TVFocusable(
      onSelect: () {
        if (index == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        } else {
          setState(() => _navIndex = index);
        }
      },
      onFocus: () => setState(() => _sidebarHasFocus = true),
      showFocusBorder: false,
      focusScale: 1.0,
      child: const SizedBox(),
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: _sidebarHasFocus ? 16 : 12),
          decoration: BoxDecoration(
            color: isFocused ? _accent.withOpacity(0.8) : (isSelected ? Colors.white10 : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isFocused ? [BoxShadow(color: _accent.withOpacity(0.5), blurRadius: 12)] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isFocused ? Colors.black : (isSelected ? _accent : Colors.white54), size: 28),
              if (_sidebarHasFocus) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: AppTheme.withRabarIfKurdish(
                    s.locale,
                    TextStyle(
                      color: isFocused ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(AppStrings s) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _sidebarHasFocus ? 260 : 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: DpadRegion(
            memoryKey: 'tv_sidebar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white70, size: 24),
                      if (_sidebarHasFocus) ...[
                        const SizedBox(width: 12),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            return Text(
                              intl.DateFormat('HH:mm').format(DateTime.now()),
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                _buildSidebarItem(Icons.live_tv_rounded, 'Live TV', 0, s),
                _buildSidebarItem(Icons.movie_creation_rounded, 'Movies', 1, s),
                _buildSidebarItem(Icons.sports_soccer_rounded, 'Sports', 2, s),
                _buildSidebarItem(Icons.star_rounded, 'Favorites', 3, s),
                const Spacer(),
                _buildSidebarItem(Icons.settings_rounded, 'Settings', 4, s),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCard(Channel channel, bool isMovie, AppStrings s, double cardWidth) {
    return TVFocusable(
      onSelect: () => _openPlayer(channel),
      onFocus: () {
        setState(() {
          _focusedChannel = channel;
          _sidebarHasFocus = false;
        });
      },
      showFocusBorder: false,
      focusScale: 1.1, // Increased scale
      child: const SizedBox(),
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8), // Give some margin for shadow
          width: cardWidth,
          transform: isFocused ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: isFocused ? _accent : Colors.white10, width: isFocused ? 3 : 1),
            boxShadow: isFocused ? [BoxShadow(color: _accent.withOpacity(0.8), blurRadius: 24, spreadRadius: 4)] : [],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), // Adjusted radius to fit border
                      child: Container(
                        color: Colors.black45,
                        padding: isMovie ? EdgeInsets.zero : const EdgeInsets.all(16),
                        child: CachedNetworkImage(
                          imageUrl: channel.logo ?? '',
                          fit: isMovie ? BoxFit.cover : BoxFit.contain,
                          errorWidget: (_, __, ___) => const Center(child: Icon(Icons.tv_off_rounded, color: Colors.white24, size: 48)),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                    ),
                    child: Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.withRabarIfKurdish(
                        s.locale,
                        TextStyle(color: isFocused ? _accent : Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isMovie && channel.type != 'vod') // Live Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentArea(AppStrings s) {
    final channels = _getTabChannels();
    if (channels.isEmpty) {
      return const Center(child: Text('No content available', style: TextStyle(color: Colors.white54, fontSize: 18)));
    }

    final groups = _groupChannels(channels);
    
    // Sort groups identically to the mobile dashboard
    final sortedGroups = groups.keys.toList()..sort((a, b) {
      final ga = widget.managedGroups.firstWhere((g) => g.name == a, orElse: () => ChannelGroup(key: '', name: a, order: 999999));
      final gb = widget.managedGroups.firstWhere((g) => g.name == b, orElse: () => ChannelGroup(key: '', name: b, order: 999999));
      if (ga.order != gb.order) return ga.order.compareTo(gb.order);
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    // We want exactly 5 items per row visible at a time.
    // Screen width - sidebar (either 260 or 80) - padding (20 left + some right)
    final availableWidth = MediaQuery.sizeOf(context).width - (_sidebarHasFocus ? 260 : 80) - 20;
    // We divide by 5.2 to allow 5 full items + a tiny peek of the 6th item to hint at scrolling
    final cardWidth = availableWidth / 5.2;

    return DpadRegion(
      memoryKey: 'tv_grid',
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 250, bottom: 50, left: 20),
      itemCount: sortedGroups.length,
      itemBuilder: (context, index) {
        final groupName = sortedGroups[index];
        final groupChannels = groups[groupName]!;
        final isMovieRow = groupChannels.any(_isMovieChannel);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                groupName.toUpperCase(),
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
            ),
            SizedBox(
              height: isMovieRow ? cardWidth * 1.5 : cardWidth * 0.9,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: groupChannels.length,
                itemBuilder: (context, idx) => _buildChannelCard(groupChannels[idx], isMovieRow, s, cardWidth),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      ),
    );
  }

  Widget _buildHeroBanner(AppStrings s) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 240,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.9),
              Colors.black,
            ],
            stops: const [0.0, 0.5, 0.8, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 10),
        child: _focusedChannel != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      _focusedChannel!.group.toUpperCase(),
                      style: AppTheme.withRabarIfKurdish(
                        s.locale,
                        const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _focusedChannel!.name,
                    style: AppTheme.withRabarIfKurdish(
                      s.locale,
                      const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 8)]),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : const SizedBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppUpdateData?>(updatePromptTriggerProvider, (previous, next) {
      if (next != null && !_hasPromptedUpdate) {
        _hasPromptedUpdate = true;
        UpdatePromptDialog.show(context, next, AppStrings(ref.read(appLocaleProvider)));
      }
    });

    final s = AppStrings(ref.watch(appLocaleProvider));
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          _buildSidebar(s),
          Expanded(
            child: DynamicBackground(
              preset: settings.gradientPreset,
              imageUrl: _focusedChannel?.logo,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeroBanner(s),
                  _buildContentArea(s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
