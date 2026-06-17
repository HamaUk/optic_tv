import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
import '../../widgets/optic_wordmark.dart';
import '../../widgets/tv/tv_focusable.dart';
import '../player/player_screen.dart';
import '../dashboard/movie_details_screen.dart';

class TvDashboardScreen extends ConsumerStatefulWidget {
  final List<Channel> allChannels;
  
  const TvDashboardScreen({super.key, required this.allChannels});

  @override
  ConsumerState<TvDashboardScreen> createState() => _TvDashboardScreenState();
}

class _TvDashboardScreenState extends ConsumerState<TvDashboardScreen> {
  int _navIndex = 0; // 0=Home, 1=Live TV, 2=Movies, 3=Sports, 4=Favorites, 5=Settings
  Channel? _focusedChannel;
  bool _sidebarHasFocus = true;

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
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channels: widget.allChannels, initialIndex: i >= 0 ? i : 0)));
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
      case 1: return widget.allChannels.where((c) => !_isMovieChannel(c) && !_isSportChannel(c)).toList(); // Live TV
      case 2: return widget.allChannels.where(_isMovieChannel).toList(); // Movies
      case 3: return widget.allChannels.where(_isSportChannel).toList(); // Sports
      case 4: return favorites; // Favorites
      case 0: // Home (Featured/Trending)
      default:
        // Show a mix of Live TV and Sports
        return widget.allChannels.where((c) => !_isMovieChannel(c)).toList();
    }
  }

  Widget _buildSidebarItem(IconData icon, String label, int index, AppStrings s) {
    final isSelected = _navIndex == index;
    return TVFocusable(
      onSelect: () => setState(() => _navIndex = index),
      onFocus: () => setState(() => _sidebarHasFocus = true),
      child: const SizedBox(),
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: _sidebarHasFocus ? 16 : 12),
          decoration: BoxDecoration(
            color: isFocused ? _accent : (isSelected ? Colors.white10 : Colors.transparent),
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
        color: Colors.black.withOpacity(0.8),
        border: const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                OpticWordmark(height: 32),
                if (_sidebarHasFocus) ...[
                  const SizedBox(width: 12),
                  const Text('OPTIC TV', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ]
              ],
            ),
          ),
          const SizedBox(height: 50),
          _buildSidebarItem(Icons.home_rounded, 'Home', 0, s),
          _buildSidebarItem(Icons.live_tv_rounded, 'Live TV', 1, s),
          _buildSidebarItem(Icons.movie_creation_rounded, 'Movies', 2, s),
          _buildSidebarItem(Icons.sports_soccer_rounded, 'Sports', 3, s),
          _buildSidebarItem(Icons.star_rounded, 'Favorites', 4, s),
          const Spacer(),
          _buildSidebarItem(Icons.settings_rounded, 'Settings', 5, s),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChannelCard(Channel channel, bool isMovie, AppStrings s) {
    return TVFocusable(
      onSelect: () => _openPlayer(channel),
      onFocus: () {
        setState(() {
          _focusedChannel = channel;
          _sidebarHasFocus = false;
        });
      },
      child: const SizedBox(),
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          width: isMovie ? 160 : 200,
          transform: isFocused ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: isFocused ? _accent : Colors.white10, width: isFocused ? 3 : 1),
            boxShadow: isFocused ? [BoxShadow(color: _accent.withOpacity(0.5), blurRadius: 20)] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: channel.logo ?? '',
                        fit: isMovie ? BoxFit.cover : BoxFit.contain,
                        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.tv_off_rounded, color: Colors.white24)),
                      ),
                      if (!isMovie)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Consumer(
                            builder: (context, ref, child) {
                              final count = ref.watch(channelViewersProvider(channel.url)).value ?? 0;
                              if (count == 0) return const SizedBox();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      intl.NumberFormat.compact().format(count),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.withRabarIfKurdish(
                    s.locale,
                    TextStyle(color: isFocused ? _accent : Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
    final sortedGroups = groups.keys.toList()..sort();

    return ListView.builder(
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
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Text(
                groupName.toUpperCase(),
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
            ),
            SizedBox(
              height: isMovieRow ? 260 : 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: groupChannels.length,
                itemBuilder: (context, idx) => _buildChannelCard(groupChannels[idx], isMovieRow, s),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildHeroBanner(AppStrings s) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 400,
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
        padding: const EdgeInsets.fromLTRB(40, 60, 40, 20),
        child: _focusedChannel != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _focusedChannel!.group.toUpperCase(),
                      style: AppTheme.withRabarIfKurdish(
                        s.locale,
                        const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _focusedChannel!.name,
                    style: AppTheme.withRabarIfKurdish(
                      s.locale,
                      const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
                    ),
                  ),
                ],
              )
            : const SizedBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildContentArea(s),
                  _buildHeroBanner(s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
