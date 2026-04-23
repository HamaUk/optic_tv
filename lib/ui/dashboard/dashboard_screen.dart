import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';
import '../../widgets/optic_wordmark.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/channel_library_provider.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';
import '../admin/admin_screen.dart';
import '../player/player_screen.dart';
import '../player/movie_player_page.dart';
import '../settings/settings_screen.dart';
import 'movie_details_screen.dart';
import '../settings/settings_screen.dart';

import '../../services/tmdb_service.dart';
import '../../widgets/dynamic_background.dart';
import '../../widgets/tv_focus_wrapper.dart';
import './movie_details_screen.dart';
import '../../widgets/tv_fluid_focusable.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

 // Admin portal is handled via AdminScreen with Firebase Auth.

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TmdbService _tmdb = TmdbService();
  int _adminLogoTaps = 0;
  Timer? _adminTapResetTimer;

  /// 0 Home, 1 Movies, 2 Sport, 3 About
  int _navIndex = 0;
  bool _searchOpen = false;
  bool _tvHomeActive = true; 
  final TextEditingController _searchController = TextEditingController();
  
  Channel? _focusedChannel;
  bool _sidebarFocused = false;
  String? _selectedTvGroup;
  String? _movieCategoryFilter;
  String? _movieYearFilter;

  // Professional TV State
  final GlobalKey<ScaffoldState> _tvScaffoldKey = GlobalKey<ScaffoldState>();
  int _tvTabIndex = 0;
  bool _tvTabReverse = false;

  Color get _accent {
    final settings = ref.read(appUiSettingsProvider);
    return settings.when(
      data: (data) => AppTheme.accentColor(data.gradientPreset),
      loading: () => AppTheme.accentColor(AppGradientPreset.classic),
      error: (_, __) => AppTheme.accentColor(AppGradientPreset.classic),
    );
  }

  @override
  void dispose() {
    _adminTapResetTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onLogoTapForAdminPortal() {
    _adminTapResetTimer?.cancel();
    _adminTapResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _adminLogoTaps = 0);
    });
    setState(() => _adminLogoTaps++);
    if (_adminLogoTaps >= 7) {
      _adminTapResetTimer?.cancel();
      setState(() => _adminLogoTaps = 0);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (mounted) ref.invalidate(appUiSettingsProvider);
  }

  bool _isMovieChannel(Channel c) {
    // Priority 1: Use explicit 'type' field set by the admin
    if (c.type == 'movie') return true;
    if (c.type == 'live') return false;

    final g = c.group.toLowerCase();
    final n = c.name.toLowerCase();
    
    // Exclude anything that explicitly marks itself as a Live stream
    if (g.contains('live tv') || g == 'live' || n.contains(' (live)')) return false;
    
    // If it's a TV channel category, it's likely not VOD unless "movie" is in the name
    if (g.contains('tv') && !g.contains('movie') && !g.contains('cinema')) return false;

    // Fixed Group detection
    if (g == 'movies' || g == 'vod' || g == 'cinema' || g == 'films') return true;

    // Use name heuristics ONLY if other indicators are absent
    final movieKeywords = [
      'vod', 'box office', 'uhd', '4k', 'action',
      'comedy', 'horror', 'drama', 'thriller', 'animation', 'documentary'
    ];
    
    // We intentionally removed 'movie' and 'film' from name keywords 
    // to avoid false positives for channels like 'AVA Movies'
    final isTaggedName = movieKeywords.any((kw) => n.contains(kw));
    
    return isTaggedName || g.contains('movie') || g.contains('film');
  }

  bool _isSportChannel(Channel c) {
    // Priority 1: Admin set type
    if (c.type == 'sport') return true;

    final g = c.group.toLowerCase();
    final n = c.name.toLowerCase();

    // Common sports category keywords
    final sportKeywords = [
      'sport', 'bein', 'ad sports', 'ssc', 'eurospot', 'espn', 
      'arena', 'bt sport', 'sky sport', 'alkass', 'starzplay sports'
    ];

    return sportKeywords.any((kw) => g.contains(kw)) || 
           sportKeywords.any((kw) => n.contains(kw));
  }

  List<Channel> _channelsForNav(List<Channel> all, List<Channel> favorites, List<Channel> recent) {
    switch (_navIndex) {
      case 1:
        var movies = all.where(_isMovieChannel).toList();
        if (_movieCategoryFilter != null) {
          movies = movies.where((c) => c.group == _movieCategoryFilter).toList();
        }
        if (_movieYearFilter != null) {
          movies = movies.where((c) => c.name.contains(_movieYearFilter!)).toList();
        }
        return movies;
      case 2:
        // Sport tab: show only channels that are identified as Sport
        return all.where(_isSportChannel).toList();
      case 3:
        // About tab: return empty, content is built in _AboutTab widget.
        return [];
      default:
        // Home: ONLY show live tv, strictly exclude movies and sports.
        return all.where((c) => !_isMovieChannel(c) && c.type != 'movie' && !_isSportChannel(c)).toList();
    }
  }

  Widget _buildMovieLibraryContent(BuildContext context, AppStrings s, List<Channel> all, AppSettingsData settings) {
    var movies = all.where(_isMovieChannel).toList();
    
    // Apply Filters
    if (_movieCategoryFilter != null) {
      movies = movies.where((m) => m.group == _movieCategoryFilter).toList();
    }
    if (_movieYearFilter != null) {
      movies = movies.where((m) => m.name.contains(_movieYearFilter!)).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      movies = movies.where((m) => m.name.toLowerCase().contains(query)).toList();
    }

    final groups = _groupMap(movies);
    final sortedCategories = groups.keys.toList()..sort();

    return Column(
      children: [
        _buildMovieCinematicHeader(s, _groupMap(all.where(_isMovieChannel).toList()).keys.toList(), 16.0),
        Expanded(
          child: movies.isEmpty 
            ? _buildEmptyState(s, title: 'No movies found', subtitle: 'Try a different filter or search term')
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 40),
                itemCount: sortedCategories.length,
                itemBuilder: (context, i) {
                  final cat = sortedCategories[i];
                  final catMovies = groups[cat] ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          cat.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: settings.reduceMotion 
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: catMovies.length,
                              itemBuilder: (context, idx) => _buildVerticalMovieCard(catMovies[idx]),
                            )
                          : AnimationLimiter(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: catMovies.length,
                                itemBuilder: (context, idx) {
                                  final m = catMovies[idx];
                                  return AnimationConfiguration.staggeredList(
                                    position: idx,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      horizontalOffset: 80.0,
                                      child: ScaleAnimation(
                                        scale: 0.9,
                                        child: FadeInAnimation(
                                          child: _buildVerticalMovieCard(m),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildVerticalMovieCard(Channel m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          final channels = ref.read(channelsProvider).asData?.value ?? [];
          _openPlayer(channels, m);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: 130, // 2:3 Aspect ratio approx (140:210)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: m.logo ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Colors.white.withOpacity(0.05),
                    child: const Center(child: Icon(Icons.movie_outlined, color: Colors.white24)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 130,
              child: Text(
                m.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChannelSheet(AppStrings s, List<Channel> allChannels, Channel channel) async {
    final fav = ref.read(favoritesProvider.notifier).isFavorite(channel);
    final isMovie = _isMovieChannel(channel);

    // Enrichment disabled per user request to avoid "random" images.
    const TmdbMovie? movieInfo = null;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: movieInfo != null ? 0.6 : 0.35,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        if (isMovie) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieDetailsScreen(
                                    allChannels: allChannels,
                                    channel: channel,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info_outline_rounded, size: 18),
                            label: const Text('More Details', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.accentTeal),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (movieInfo != null && movieInfo.posterUrl != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(movieInfo.posterUrl!, height: 180, fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    channel.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (movieInfo != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.primaryGold, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          movieInfo.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                        ),
                        if (movieInfo.releaseDate != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            movieInfo.releaseDate!.split('-').first,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      movieInfo.overview,
                      style: const TextStyle(height: 1.5, color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ListTile(
                    leading: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: AppTheme.primaryGold),
                    title: Text(fav ? s.unfavoriteChannel : s.favoriteChannel),
                    onTap: () {
                      ref.read(favoritesProvider.notifier).toggle(channel);
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.accentTeal),
                    title: const Text('Play Now'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openPlayer(allChannels, channel);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Channel> _applySearch(List<Channel> base) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base
        .where(
          (c) => c.name.toLowerCase().contains(q) || c.group.toLowerCase().contains(q),
        )
        .toList();
  }

  Map<String, List<Channel>> _groupMap(List<Channel> channels) {
    final groups = <String, List<Channel>>{};
    for (final channel in channels) {
      groups.putIfAbsent(channel.group, () => []).add(channel);
    }
    return groups;
  }

  void _openPlayer(List<Channel> allFlat, Channel channel) {
    final i = allFlat.indexOf(channel);
    final uiLocale = ref.read(appLocaleProvider);
    final s = AppStrings(uiLocale);

    if (_isMovieChannel(channel)) {
      // GO TO DESCRIPTION PAGE (Netflix style)
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => MovieDetailsScreen(
            allChannels: allFlat,
            channel: channel,
          ),
        ),
      );
    } else {
      // STANDARD TV PLAYER: Includes Guide & Sidebar
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => PlayerScreen(
            channels: allFlat,
            initialIndex: i >= 0 ? i : 0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(ref.watch(appLocaleProvider));
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final channelsAsync = ref.watch(channelsProvider);

    return channelsAsync.when(
      data: (channels) {
        final favorites = ref.watch(favoritesProvider);
        final recent = ref.watch(recentChannelsProvider);
        
        final filteredForNav = _channelsForNav(channels, favorites, recent);
        final filtered = _applySearch(filteredForNav);
        final groups = _groupMap(filtered);
        final managedGroups = ref.watch(groupsProvider).asData?.value ?? [];

        final sortedGroupEntries = groups.entries.toList()
          ..sort((a, b) {
            final ga = managedGroups.firstWhere((g) => g.name == a.key, orElse: () => ChannelGroup(key: '', name: a.key, order: 999999));
            final gb = managedGroups.firstWhere((g) => g.name == b.key, orElse: () => ChannelGroup(key: '', name: b.key, order: 999999));
            if (ga.order != gb.order) return ga.order.compareTo(gb.order);
            return a.key.toLowerCase().compareTo(b.key.toLowerCase());
          });

        // About tab: show dedicated screen instead of channel grid.
        if (_navIndex == 3) {
          final screen = _AboutTab(settings: settings);

          return Scaffold(
            backgroundColor: AppTheme.backgroundBlack,
            body: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.shellGradient(settings.gradientPreset),
              ),
              child: SafeArea(
                bottom: false,
                child: _buildDashboardShell(
                  context, s, 16.0, false, screen, settings,
                ),
              ),
            ),
            bottomNavigationBar: portrait ? _buildBottomNav(s, MediaQuery.paddingOf(context).bottom, settings) : null,
          );
        }

        final isTv = MediaQuery.sizeOf(context).width > 900;

        if (isTv) {
          return Theme(
            data: ThemeData(
              brightness: Brightness.dark,
              fontFamily: 'RobotoCondensed',
              scaffoldBackgroundColor: Colors.black,
              colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: Brightness.dark),
            ),
            child: channelsAsync.when(
              data: (all) {
                final favorites = ref.watch(favoritesProvider);
                return Scaffold(
                  key: _tvScaffoldKey,
                  backgroundColor: Colors.black,
                  endDrawer: _buildTvSettingsDrawer(s),
                  appBar: _buildTvTopAppbar(s, settings),
                  body: PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
                      animation: primary,
                      secondaryAnimation: secondary,
                      transitionType: SharedAxisTransitionType.horizontal,
                      fillColor: Colors.transparent,
                      child: child,
                    ),
                    child: switch (_tvTabIndex) {
                      0 => _buildTvLiveTvTab(s, all, favorites, settings),
                      1 => _buildTvMoviesTab(s, all, favorites, settings),
                      2 => _buildTvFavoritesTab(s, favorites, settings),
                      _ => const SizedBox(),
                    },
                  ),
                );
              },
              loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator())),
              error: (e, _) => Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Error: $e'))),
            ),
          );
        }

        final heroImage = _focusedChannel?.logo ?? (filtered.isNotEmpty ? filtered.first.logo : null);

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          body: DynamicBackground(
            preset: settings.gradientPreset,
            imageUrl: heroImage,
            child: SafeArea(
              bottom: false,
                child: _buildDashboardShell(
                  context,
                  s,
                  16.0,
                  false,
                  _navIndex == 1
                      ? _buildMovieLibraryContent(context, s, channels, settings)
                      : filtered.isEmpty
                          ? _buildEmptyState(s)
                          : _buildScrollableContent(
                              context,
                              s,
                              channels,
                              filtered,
                              groups,
                              settings,
                              settings.reduceMotion ? 100 : 220,
                              16.0,
                              managedGroups,
                            ),
                  settings,
                ),
            ),
          ),
          bottomNavigationBar: portrait ? _buildBottomNav(s, MediaQuery.paddingOf(context).bottom, settings) : null,
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OpticWordmark(height: 46),
              const SizedBox(height: 40),
              Container(
                width: 220,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentTeal.withOpacity(0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Loading your entertainment...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '${s.channelLoadError}: $e',
              style: AppTheme.withRabarIfKurdish(
                s.locale,
                const TextStyle(color: Colors.white70),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Combined column/shell.
  Widget _buildDashboardShell(
    BuildContext context,
    AppStrings s,
    double pad,
    bool tv,
    Widget expandedChild,
    AppSettingsData settings,
  ) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    if (!landscape) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(context, s, pad, tv),
          const _GlobalAnnouncementTicker(),
          if (_searchOpen) _buildSearchField(s, pad),
          Expanded(child: expandedChild),
        ],
      );
    }

    final isTv = landscape && MediaQuery.sizeOf(context).width > 900;
    final contentDir = s.locale.languageCode == 'ckb' ? TextDirection.rtl : TextDirection.ltr;
    final bodyColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isTv) _buildTopBar(context, s, pad, tv),
        const _GlobalAnnouncementTicker(),
        if (_searchOpen) _buildSearchField(s, pad),
        Expanded(child: expandedChild),
      ],
    );

    return Row(
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSideRail(s, false, settings),
        Expanded(
          child: Directionality(
            textDirection: contentDir,
            child: bodyColumn,
          ),
        ),
      ],
    );
  }

  Widget _buildSideRail(AppStrings s, bool isTv, AppSettingsData settings) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final railWidth = 100.0;
    
    return Container(
      width: railWidth,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: _glassContainer(
        borderRadius: BorderRadius.circular(28),
        blur: 20,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 30, 6, math.max(bottom, 20)),
          child: Column(
            children: [
              const OpticWordmark(height: 24),
              const SizedBox(height: 60),
               _railItem(s, 0, Icons.grid_view_rounded, s.navHome, _navIndex == 0),
               const SizedBox(height: 16),
               _railItem(s, 1, Icons.movie_creation_rounded, s.navMovies, _navIndex == 1),
               const SizedBox(height: 16),
               _railItem(s, 2, Icons.sports_basketball_rounded, s.navSport, _navIndex == 2),
               const SizedBox(height: 16),
               _railItem(s, 3, Icons.person_pin_rounded, s.sectionAbout, _navIndex == 3),
               const Spacer(),
               _railItem(s, -1, Icons.settings_suggest_rounded, s.settingsTooltip, false, onTap: _openSettings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _railItem(AppStrings s, int index, IconData icon, String label, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _navIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? _accent.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: selected ? _accent : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected ? [
            BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 20, spreadRadius: -2),
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: selected ? _accent : Colors.white.withOpacity(0.4), 
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withOpacity(0.3),
                fontSize: 9,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppStrings s,
    double pad,
    bool tv,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad * 0.5, pad * 0.75, pad * 0.5, 8),
      child: Row(
        children: [
          // Glass Menu Button
          _glassContainer(
            borderRadius: BorderRadius.circular(14),
            child: IconButton(
              tooltip: s.settingsTooltip,
              icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 22),
              onPressed: _openSettings,
            ),
          ),
          const SizedBox(width: 8),
          // Glass Logo Container
          Expanded(
            child: _glassContainer(
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _onLogoTapForAdminPortal,
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: tv ? 48 : 44,
                  child: Center(
                    child: OpticWordmark(height: tv ? 30 : 26),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Glass Search Toggle
          _glassContainer(
            borderRadius: BorderRadius.circular(14),
            child: IconButton(
              icon: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: _searchOpen ? _accent : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) _searchController.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Utility for consistent glassmorphism
  Widget _glassContainer({required Widget child, required BorderRadius borderRadius, double blur = 12}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  TextStyle _searchFieldStyle(BuildContext context, {required double opacity}) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return TextStyle(
      color: Colors.white.withOpacity(opacity),
      fontSize: 16,
      fontFamily: isAndroid ? 'Roboto' : null,
    );
  }

  Widget _buildSearchField(AppStrings s, double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad * 0.5, 0, pad * 0.5, 8),
      child: _glassContainer(
        borderRadius: BorderRadius.circular(16),
        blur: 15,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: _accent.withOpacity(0.7), size: 22),
              Expanded(
                child: CupertinoTextField(
                  controller: _searchController,
                  autofocus: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  style: _searchFieldStyle(context, opacity: 1),
                  placeholder: s.searchHint,
                  placeholderStyle: _searchFieldStyle(context, opacity: 0.4),
                  cursorColor: _accent,
                  selectionControls: materialTextSelectionControls,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s, {String? title, String? subtitle}) {
    final message = title ?? s.noChannelsInSection;
    final sub = subtitle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://lottie.host/e2b6a5b8-5c4d-4467-b50e-3b2d71c4639a/y8ZUr3K4M3.json',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTheme.withRabarIfKurdish(
                s.locale,
                TextStyle(color: Colors.white.withOpacity(0.45)),
              ),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(
                sub,
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 13),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent(
    BuildContext context,
    AppStrings s,
    List<Channel> allChannels,
    List<Channel> filteredFlat,
    Map<String, List<Channel>> groups,
    AppSettingsData settings,
    int animMs,
    double pad,
    List<ChannelGroup> managedGroups,
  ) {
    final isTv = MediaQuery.sizeOf(context).width > 900;
    final crossCount = isTv ? 6 : 4;
    
    final featured = allChannels.where((c) => c.featured).toList();
    
    // Sort by custom featured order defined in Admin Portal
    featured.sort((a, b) => a.featuredOrder.compareTo(b.featuredOrder));

    // Show up to 5 featured items
    final slideChannels = featured.take(5).toList();

    // Prepare sorted groups based on Admin preference
    final sortedGroupEntries = groups.entries.toList()..sort((a, b) {
      final ga = managedGroups.firstWhere((g) => g.name == a.key, orElse: () => ChannelGroup(key: '', name: a.key, order: 999999));
      final gb = managedGroups.firstWhere((g) => g.name == b.key, orElse: () => ChannelGroup(key: '', name: b.key, order: 999999));
      if (ga.order != gb.order) return ga.order.compareTo(gb.order);
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });

    final heroChannel = _focusedChannel ?? (filteredFlat.isNotEmpty ? filteredFlat.first : null);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (_navIndex == 1) // Movies Tab Cinematic Header
          SliverToBoxAdapter(
            child: _buildMovieCinematicHeader(s, groups.keys.toList(), pad),
          ),
        
        if (_navIndex == 2) // Sport Tab Header
          SliverToBoxAdapter(
            child: _buildSportHeader(s, pad),
          ),

        if (!isTv && (_navIndex == 0 || _navIndex == 3) &&
            _searchController.text.trim().isEmpty &&
            slideChannels.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 16),
              child: _FeaturedCarousel(
                slides: slideChannels,
                s: s,
                animMs: animMs,
                gradientPreset: settings.gradientPreset,
                reduceMotion: settings.reduceMotion,
                onWatch: (c) => _openPlayer(allChannels, c),
              ),
            ),
          ),
        ...sortedGroupEntries.asMap().entries.map((groupEntry) {
          final i = groupEntry.key;
          final entry = groupEntry.value;
          return SliverToBoxAdapter(
            child: _StaggeredEntrance(
              index: i,
              reduceMotion: settings.reduceMotion,
              child: _buildGroupSection(
                context,
                s,
                allChannels,
                entry.key,
                entry.value,
                crossCount,
                animMs,
                pad,
                isTv,
                settings,
              ),
            ),
          );
        }),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildSportHeader(AppStrings s, double pad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.navSport.toUpperCase(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Live Sports Channels',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCinematicHeader(AppStrings s, List<String> categories, double pad) {
    final years = ['2026', '2025', '2024', '2023', '2022', '2021'];
    final sortedCats = categories.where((c) => c.toLowerCase() != 'general' && c.toLowerCase() != 'live tv').toList()..sort();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                s.navMovies.toUpperCase(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
              ),
              const Spacer(),
              if (_movieCategoryFilter != null || _movieYearFilter != null || _searchController.text.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => setState(() { 
                    _movieCategoryFilter = null; 
                    _movieYearFilter = null; 
                    _searchController.clear();
                  }),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Filters and Search Row
          Row(
            children: [
              _buildFilterDropdown(
                label: _movieYearFilter ?? 'Year',
                icon: Icons.calendar_today_rounded,
                onTap: () => _showFilterSheet('Release Year', ['Any Year', ...years], _movieYearFilter ?? 'Any Year', (v) {
                  setState(() => _movieYearFilter = v == 'Any Year' ? null : v);
                }),
              ),
              const SizedBox(width: 8),
              _buildFilterDropdown(
                label: _movieCategoryFilter ?? 'Category',
                icon: Icons.movie_creation_rounded,
                onTap: () => _showFilterSheet('Categories', ['All Movies', ...sortedCats], _movieCategoryFilter ?? 'All Movies', (v) {
                  setState(() => _movieCategoryFilter = v == 'All Movies' ? null : v);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _glassContainer(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 44,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search_rounded, color: AppTheme.primaryGold, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() {}),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'SEARCH MOVIES...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, letterSpacing: 1),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                            onPressed: () => setState(() => _searchController.clear()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(String title, List<String> items, String selected, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == selected;
                        return ListTile(
                          title: Text(item, style: TextStyle(color: isSelected ? _accent : Colors.white)),
                          trailing: isSelected ? Icon(Icons.check_rounded, color: _accent) : null,
                          onTap: () {
                            Navigator.pop(context);
                            onSelected(item);
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
      },
    );
  }

  Widget _buildFilterDropdown({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 60),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTvHeroSection(BuildContext context, AppStrings s, List<Channel> allChannels, Channel ch) {
    return Container(
      height: 380,
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
          )
        ],
      ),
      child: Stack(
        children: [
          // Background Mood Glow
          Positioned.fill(
             child: Opacity(
               opacity: 0.15,
               child: ChannelLogoImage(
                  logo: ch.logo,
                  fit: BoxFit.cover,
               ),
             ),
          ),
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _accent.withOpacity(0.3)),
                        ),
                        child: Text(
                          ch.group.toUpperCase(),
                          style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        ch.name,
                        style: AppTheme.withRabarIfKurdish(
                          s.locale,
                          const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TvFocusWrapper(
                        onTap: () => _openPlayer(allChannels, ch),
                        borderRadius: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                s.watchNow,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240, maxWidth: 240),
                      child: ChannelLogoImage(
                        logo: ch.logo,
                        fit: BoxFit.contain,
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

  Widget _buildGroupSection(
    BuildContext context,
    AppStrings s,
    List<Channel> allChannels,
    String title,
    List<Channel> sectionChannels,
    int crossCount,
    int animMs,
    double pad,
    bool isTv,
    AppSettingsData settings,
  ) {
    final isMovie = _navIndex == 1;
    final titleSize = isTv ? 22.0 : 16.0;
    
    if (isTv) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: pad + 8, bottom: 20),
              child: Text(
                title.toUpperCase(),
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: isMovie ? 320 : 180,
              child: settings.reduceMotion
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(left: pad),
                    itemCount: sectionChannels.length,
                    itemBuilder: (context, index) {
                      final ch = sectionChannels[index];
                      return Container(
                        width: isMovie ? 220 : 150,
                        margin: const EdgeInsets.only(right: 20),
                        child: isMovie
                            ? _buildMovieTile(context, s, allChannels, ch, animMs)
                            : _buildGridChannelTile(context, s, allChannels, ch, animMs),
                      );
                    },
                  )
                : AnimationLimiter(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: pad),
                      itemCount: sectionChannels.length,
                      itemBuilder: (context, index) {
                        final ch = sectionChannels[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: 80.0,
                            child: ScaleAnimation(
                              scale: 0.9,
                              child: FadeInAnimation(
                              child: Container(
                                width: isMovie ? 220 : 150,
                                margin: const EdgeInsets.only(right: 20),
                                child: isMovie
                                    ? _buildMovieTile(context, s, allChannels, ch, animMs)
                                    : _buildGridChannelTile(context, s, allChannels, ch, animMs),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: pad, right: pad, top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$title |',
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMovie ? 2 : crossCount,
              crossAxisSpacing: isMovie ? 14 : 10,
              mainAxisSpacing: isMovie ? 16 : 12,
              childAspectRatio: isMovie ? 0.62 : 0.72,
            ),
            itemCount: sectionChannels.length,
            itemBuilder: (context, index) => isMovie
                ? _buildMovieTile(context, s, allChannels, sectionChannels[index], animMs)
                : _buildGridChannelTile(context, s, allChannels, sectionChannels[index], animMs),
          ),
        ],
      ),
    );
  }

  Widget _buildGridChannelTile(
    BuildContext context,
    AppStrings s,
    List<Channel> allChannels,
    Channel channel,
    int animMs,
  ) {
    const logoSize = 22.0;
    const kTileRadius = 16.0;
    final focused = _focusedChannel == channel;
    final isTv = MediaQuery.sizeOf(context).width > 900;
    
    return TvFocusWrapper(
      onTap: () => _openPlayer(allChannels, channel),
      onLongPress: () => _openPlayer(allChannels, channel),
      scale: 1.12,
      borderRadius: kTileRadius,
      child: Focus(
        onFocusChange: (f) {
           if (f && mounted) setState(() => _focusedChannel = channel);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: animMs),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kTileRadius),
            color: focused 
                ? _accent.withOpacity(0.2) 
                : const Color(0xFF141A22).withOpacity(0.8),
            border: Border.all(
              color: focused ? _accent.withOpacity(0.8) : Colors.white.withOpacity(0.05),
              width: focused ? 2.5 : 1.0,
            ),
            boxShadow: focused ? [
              BoxShadow(
                color: _accent.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kTileRadius),
            child: Stack(
              children: [
                if (focused)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(isTv ? 14 : 10),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ChannelLogoImage(
                            logo: channel.logo,
                            width: isTv ? 80 : logoSize * 2.65,
                            height: isTv ? 80 : logoSize * 2.65,
                            fit: BoxFit.contain,
                            fallback: Icon(Icons.tv_rounded, color: Colors.white24, size: isTv ? 40 : logoSize + 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        channel.name,
                        style: AppTheme.withRabarIfKurdish(
                          s.locale,
                          TextStyle(
                            fontSize: isTv ? 14 : 10, 
                            color: focused ? Colors.white : Colors.white70, 
                            fontWeight: focused ? FontWeight.w900 : FontWeight.w600,
                            letterSpacing: focused ? 0.5 : 0,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
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

  /// Larger poster-style tile for Movies. The logo/poster fills
  /// the card and the title sits on a gradient strip at the bottom.
  Widget _buildMovieTile(
    BuildContext context,
    AppStrings s,
    List<Channel> allChannels,
    Channel channel,
    int animMs,
  ) {
    const kTileRadius = 18.0;

    final isTv = MediaQuery.sizeOf(context).width > 900;
    final focused = _focusedChannel == channel;

    return TvFocusWrapper(
      onTap: () => _openPlayer(allChannels, channel),
      onLongPress: () => _openPlayer(allChannels, channel),
      scale: 1.10,
      borderRadius: kTileRadius,
      child: Focus(
        onFocusChange: (f) {
          if (f && mounted) setState(() => _focusedChannel = channel);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster: Use channel logo directly (no TMDB override)
            if (channel.logo != null && channel.logo!.isNotEmpty)
              ChannelLogoImage(
                logo: channel.logo,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                fallback: _movieFallback(),
              )
            else
              _movieFallback(),
            // Gradient overlay bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(isTv ? 0.4 : 0.65),
                      Colors.black.withOpacity(isTv ? 0.8 : 0.92),
                    ],
                    stops: const [0, 0.45, 0.78, 1],
                  ),
                ),
              ),
            ),
            // Play icon center: hide on TV focus for cleaner look
            if (!isTv)
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white.withOpacity(0.85),
                    size: 22,
                  ),
                ),
              ),
            // Title
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                channel.name,
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  TextStyle(
                    fontSize: isTv ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 6),
                    ],
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _movieFallback() {
    return Container(
      color: const Color(0xFF1C2430),
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 40,
          color: AppTheme.primaryGold.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppStrings s, double bottomInset, AppSettingsData settings) {
    final accent = AppTheme.accentColor(settings.gradientPreset);
    final isKurdish = s.locale.languageCode == 'ckb';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? bottomInset : 16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E14).withOpacity(0.75),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(s, settings, iconActive: Icons.grid_view_rounded, iconInactive: Icons.grid_view_outlined, label: s.navHome, index: 0),
                  _navItem(s, settings, iconActive: Icons.movie_creation_rounded, iconInactive: Icons.movie_creation_outlined, label: s.navMovies, index: 1),
                  _navItem(s, settings, iconActive: Icons.sports_basketball_rounded, iconInactive: Icons.sports_basketball_outlined, label: s.navSport, index: 2),
                  _navItem(s, settings, iconActive: Icons.person_pin_rounded, iconInactive: Icons.person_pin_outlined, label: 'Profile', index: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    AppStrings s,
    AppSettingsData settings, {
    required IconData iconActive,
    required IconData iconInactive,
    required String label,
    required int index,
    bool sideRail = false,
    bool isTv = false,
  }) {
    final selected = _navIndex == index;
    final accent = AppTheme.accentColor(settings.gradientPreset);
    final color = selected ? accent : (sideRail ? Colors.white.withOpacity(0.52) : Colors.white38);
    final icon = selected ? iconActive : iconInactive;

    if (isTv) {
      return TvFocusWrapper(
        onTap: () {
          if (index == -1) {
            _openSettings();
          } else {
            setState(() => _navIndex = index);
          }
        },
        borderRadius: 14,
        scale: 1.15,
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected ? [
              BoxShadow(color: accent.withOpacity(0.3), blurRadius: 15),
            ] : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon with Scale & Color
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()..scale(selected ? 1.2 : 1.0),
              transformAlignment: Alignment.center,
              child: Icon(
                icon,
                color: color,
                size: sideRail ? 28 : 26,
                shadows: selected ? [
                  Shadow(color: accent.withOpacity(0.5), blurRadius: 15),
                ] : [],
              ),
            ),
            const SizedBox(height: 4),
            // Animated Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTheme.withRabarIfKurdish(
                s.locale,
                TextStyle(
                  color: color,
                  fontSize: selected ? 11 : 10,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                  letterSpacing: selected ? 0.5 : 0,
                ),
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 4),
            // Mova-style indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              width: selected ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Category Sidebar (Pane 2) specifically for TV.
  Widget _buildTvCategoryRail(AppStrings s) {
    final channelsAsync = ref.watch(channelsProvider);
    return channelsAsync.when(
      data: (all) {
        final favorites = ref.watch(favoritesProvider);
        final toGroup = _channelsForNav(all, favorites, []);
        final groups = _groupMap(toGroup);
        final sortedKeys = groups.keys.toList()..sort();
        final selected = _selectedTvGroup;

        return Column(
          children: [
            const SizedBox(height: 48),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _tvCategoryItem('All', toGroup.length, selected == null, () {
                    setState(() => _selectedTvGroup = null);
                  }),
                  const SizedBox(height: 8),
                  for (final g in sortedKeys) ...[
                    _tvCategoryItem(g, groups[g]?.length ?? 0, selected == g, () {
                      setState(() => _selectedTvGroup = g);
                    }),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }


  // ── TV-only methods — Ghosten-Player exact layout ──────────────────────────

  PreferredSizeWidget _buildTvTopAppbar(AppStrings s, AppSettingsData settings) {
    return _GhostenTvAppBar(
      activeIndex: _tvTabIndex,
      tabs: const ['Live TV', 'Movies', 'Favorites'],
      onTabChange: (i) {
        setState(() {
          _tvTabReverse = i < _tvTabIndex;
          _tvTabIndex = i;
          _selectedTvGroup = null;
        });
      },
      onSearchTap: () {
        setState(() => _searchOpen = !_searchOpen);
      },
      onSettingsTap: () => _tvScaffoldKey.currentState?.openEndDrawer(),
    );
  }

  Widget _buildTvLiveTvTab(AppStrings s, List<Channel> all, List<Channel> favs, AppSettingsData settings) {
    final live = all.where((c) => !_isMovieChannel(c)).toList();
    return _buildTvDualPaneView(s, live, settings);
  }

  Widget _buildTvMoviesTab(AppStrings s, List<Channel> all, List<Channel> favs, AppSettingsData settings) {
    return _buildMovieLibraryContent(context, s, all, settings);
  }

  Widget _buildTvFavoritesTab(AppStrings s, List<Channel> favs, AppSettingsData settings) {
    return _buildTvDualPaneView(s, favs, settings);
  }

  /// Ghosten-exact dual-pane: left groups (flex 2) + right channel grid (flex 3)
  Widget _buildTvDualPaneView(AppStrings s, List<Channel> channels, AppSettingsData settings) {
    final groups = _groupMap(channels);
    final sortedKeys = groups.keys.toList()..sort();
    final displayChannels = _selectedTvGroup == null
        ? channels
        : groups[_selectedTvGroup] ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left pane: group list (Ghosten flex:2) ──
        Flexible(
          flex: 2,
          child: Material(
            type: MaterialType.transparency,
            clipBehavior: Clip.hardEdge,
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 36, right: 12, top: 80, bottom: 60),
              itemCount: sortedKeys.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "All" entry
                  return _tvGhostenGroupTile(
                    label: 'All channels',
                    count: channels.length,
                    selected: _selectedTvGroup == null,
                    autofocus: true,
                    onTap: () => setState(() => _selectedTvGroup = null),
                  );
                }
                final g = sortedKeys[index - 1];
                return _tvGhostenGroupTile(
                  label: g,
                  count: groups[g]?.length ?? 0,
                  selected: _selectedTvGroup == g,
                  onTap: () => setState(() => _selectedTvGroup = g),
                );
              },
            ),
          ),
        ),
        // ── Right pane: channel grid (Ghosten flex:3, maxCrossAxisExtent 198) ──
        if (channels.isNotEmpty)
          Flexible(
            flex: 3,
            child: displayChannels.isEmpty
                ? _buildEmptyState(s)
                : settings.reduceMotion
                  ? ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context),
                      child: GridView.builder(
                        padding: const EdgeInsets.only(left: 8, right: 48, top: 80, bottom: 60),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 198,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: displayChannels.length,
                        itemBuilder: (context, idx) => _tvGhostenChannelCard(channels, displayChannels[idx]),
                      ),
                    )
                  : AnimationLimiter(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context),
                        child: GridView.builder(
                          padding: const EdgeInsets.only(left: 8, right: 48, top: 80, bottom: 60),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 198,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: displayChannels.length,
                          itemBuilder: (context, idx) {
                            final ch = displayChannels[idx];
                            return AnimationConfiguration.staggeredGrid(
                              position: idx,
                              duration: const Duration(milliseconds: 375),
                              columnCount: 4, // Estimate or dynamic
                              child: ScaleAnimation(
                                child: FadeInAnimation(
                                  child: _tvGhostenChannelCard(channels, ch),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
          ),
      ],
    );
  }

  /// Ghosten-exact group item (SlidableSettingItem port)
  Widget _tvGhostenGroupTile({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    bool autofocus = false,
  }) {
    return GhostenFocusable(
      autofocus: autofocus,
      selected: selected,
      onTap: onTap,
      selectedBackgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        visualDensity: VisualDensity.compact,
        title: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Text(
          count.toString(),
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.outline,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Ghosten-exact channel card (FocusableImage port)
  Widget _tvGhostenChannelCard(List<Channel> all, Channel ch) {
    return GhostenFocusable(
      onTap: () => _openPlayer(all, ch),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Logo centered with padding 36 (exact Ghosten)
          ch.logo != null && ch.logo!.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(36),
                  child: ChannelLogoImage(
                    logo: ch.logo,
                    fit: BoxFit.contain,
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.live_tv_outlined,
                    size: 50,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                ),
          // Title + group at bottom-left (exact Ghosten)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  ch.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ch.group.isNotEmpty)
                  Text(
                    ch.group,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvSettingsDrawer(AppStrings s) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 80, 48, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OpticWordmark(height: 32),
                    const SizedBox(height: 40),
                    Text(
                      'SETTINGS',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CONFIGURE YOUR EXPERIENCE',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _tvGhostenSettingsItem(Icons.palette_rounded, 'APPEARANCE', 'Theme & Gradients', _openSettings),
                    _tvGhostenSettingsItem(Icons.tune_rounded, 'VIDEO ENGINE', 'Codec & Buffering', () {}),
                    _tvGhostenSettingsItem(Icons.dns_rounded, 'SERVER STATUS', 'Database Connection', () {}),
                    _tvGhostenSettingsItem(Icons.shield_rounded, 'PRIVACY', 'Security & Access', () {}),
                    _tvGhostenSettingsItem(Icons.info_rounded, 'ABOUT', 'Version 2.0.4 Premium', () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tvGhostenSettingsItem(IconData icon, String label, String subtitle, VoidCallback onTap) {
    final focusNode = FocusNode();
    return GhostenFluidFocusable(
      focusNode: focusNode,
      backgroundColor: Colors.transparent,
      child: ListTile(
        focusNode: focusNode,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        visualDensity: VisualDensity.compact,
        onTap: onTap,
      ),
    );
  }

  Widget _buildTvCinemaTile(AppStrings s, List<Channel> all, Channel ch) =>
      _tvGhostenChannelCard(all, ch);

  Widget _tvCategoryItem(String label, int count, bool active, VoidCallback onTap) =>
      _tvGhostenGroupTile(label: label, count: count, selected: active, onTap: onTap);

  Widget _buildTvMenuItem(IconData icon, String label, String subtitle, VoidCallback onTap) =>
      _tvGhostenSettingsItem(icon, label, subtitle, onTap);
}

// ── Ghosten-exact auto-hiding TV AppBar ─────────────────────────────────────
class _GhostenTvAppBar extends StatefulWidget implements PreferredSizeWidget {
  const _GhostenTvAppBar({
    required this.activeIndex,
    required this.tabs,
    required this.onTabChange,
    required this.onSearchTap,
    required this.onSettingsTap,
  });

  final int activeIndex;
  final List<String> tabs;
  final ValueChanged<int> onTabChange;
  final VoidCallback onSearchTap;
  final VoidCallback onSettingsTap;

  @override
  State<_GhostenTvAppBar> createState() => _GhostenTvAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GhostenTvAppBarState extends State<_GhostenTvAppBar> {
  bool _show = true;
  ScrollNotificationObserverState? _scrollObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollObserver?.removeListener(_handleScroll);
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && (scaffoldState.isDrawerOpen || scaffoldState.isEndDrawerOpen)) return;
    _scrollObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollObserver?.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollObserver?.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll(ScrollNotification note) {
    if (note is ScrollUpdateNotification && !(Scaffold.maybeOf(context)?.isEndDrawerOpen ?? false)) {
      final oldShow = _show;
      final metrics = note.metrics;
      switch (metrics.axisDirection) {
        case AxisDirection.up:
        case AxisDirection.down:
          _show = metrics.extentBefore < 100;
          break;
        default:
          break;
      }
      if (_show != oldShow) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      reverse: _show,
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation, secondaryAnimation) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      child: _show
          ? Padding(
              padding: const EdgeInsets.only(left: 36, right: 48),
              child: Row(
                children: [
                  // Search button (Ghosten-exact: TextButton.icon)
                  TextButton.icon(
                    label: const Text('Search'),
                    onPressed: widget.onSearchTap,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 60),
                  // Tabs — Ghosten-exact animated underline
                  _TvTabs(
                    activeIndex: widget.activeIndex,
                    tabs: widget.tabs,
                    onTabChange: widget.onTabChange,
                  ),
                  const Spacer(),
                  // Settings icon (Ghosten-exact TVIconButton port)
                  _GhostenTvIconButton(
                    onPressed: widget.onSettingsTap,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  const SizedBox(width: 12),
                  // Clock
                  const _TvClock(),
                ],
              ),
            )
          : const SizedBox(),
    );
  }
}

// ── Ghosten TVIconButton port — focus border on focus ────────────────────────
class _GhostenTvIconButton extends StatefulWidget {
  const _GhostenTvIconButton({required this.onPressed, required this.icon});
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  State<_GhostenTvIconButton> createState() => _GhostenTvIconButtonState();
}

class _GhostenTvIconButtonState extends State<_GhostenTvIconButton> {
  bool _focused = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focused != _focusNode.hasFocus) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onPressed,
      icon: widget.icon,
      focusNode: _focusNode,
      style: IconButton.styleFrom(
        side: _focused
            ? BorderSide(
                width: 4,
                color: Theme.of(context).colorScheme.inverseSurface,
                strokeAlign: 2,
              )
            : null,
      ),
    );
  }
}

// ── Restored _FeaturedCarousel (mobile use only) ─────────────────────────────
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({
    required this.slides,
    required this.s,
    required this.animMs,
    required this.gradientPreset,
    required this.reduceMotion,
    required this.onWatch,
  });

  final List<Channel> slides;
  final AppStrings s;
  final int animMs;
  final AppGradientPreset gradientPreset;
  final bool reduceMotion;
  final void Function(Channel channel) onWatch;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  static const _autoAdvance = Duration(seconds: 8);
  late final PageController _pageController;
  Timer? _autoTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _armAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant _FeaturedCarousel old) {
    super.didUpdateWidget(old);
    if (!_sameSlideOrder(old.slides, widget.slides)) {
      _autoTimer?.cancel();
      _index = 0;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      setState(() {});
      _armAutoAdvance();
    }
  }

  bool _sameSlideOrder(List<Channel> a, List<Channel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].url != b[i].url) return false;
    }
    return true;
  }

  void _armAutoAdvance() {
    _autoTimer?.cancel();
    if (widget.slides.length <= 1) return;
    _autoTimer = Timer.periodic(_autoAdvance, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_index + 1) % widget.slides.length;
      _pageController.animateToPage(
        next,
        duration: Duration(milliseconds: widget.animMs.clamp(200, 500)),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _armAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF0D1118),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.slides.length,
            itemBuilder: (context, i) {
              final ch = widget.slides[i];
              final hasBackdrop = ch.backdrop != null && ch.backdrop!.isNotEmpty;
              
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = 0.0;
                  if (_pageController.position.haveDimensions) {
                    page = _pageController.page ?? 0.0;
                  }
                  
                  final diff = i - page;
                  final scale = (1.0 - (diff.abs() * 0.18)).clamp(0.75, 1.0);
                  final opacity = (1.0 - (diff.abs() * 0.5)).clamp(0.0, 1.0);
                  
                  // Clean Flat Transformation
                  final matrix = Matrix4.identity()
                    ..scale(scale);
                  
                  return Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor(widget.gradientPreset).withOpacity(0.15),
                        blurRadius: 25,
                        spreadRadius: -5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasBackdrop)
                        ChannelLogoImage(
                          logo: ch.backdrop,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          fallback: _heroFallback(),
                        )
                      else
                        _heroFallback(),

                      // Border & Gradient Overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.95),
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                              stops: const [0.0, 0.45, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Text(
                              ch.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.withRabarIfKurdish(
                                s.locale,
                                const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: s.locale.languageCode == 'ckb' ? Alignment.centerLeft : Alignment.centerRight,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => widget.onWatch(ch),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.15),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
                                        const SizedBox(width: 10),
                                        Text(
                                          s.watchNow, 
                                          style: const TextStyle(
                                            color: Colors.white, 
                                            fontSize: 15, 
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (widget.slides.length > 1)
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _index == i ? 24 : 8,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _index == i ? AppTheme.accentColor(widget.gradientPreset) : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.backgroundBlack, const Color(0xFF1A222E), AppTheme.surfaceGray],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.05,
          child: Icon(Icons.live_tv_rounded, size: 200, color: Colors.white),
        ),
      ),
    );
  }
}




class _GlobalAnnouncementTicker extends ConsumerWidget {
  const _GlobalAnnouncementTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    final accent = AppTheme.accentColor(settings.gradientPreset);
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('sync/global/announcement').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.snapshot.value;
        if (data is! Map) return const SizedBox.shrink();

        final active = data['active'] == true;
        final text = '${data['text'] ?? ''}';

        if (!active || text.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 34,
          width: double.infinity,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: accent.withOpacity(0.15), width: 0.5),
            ),
          ),
          child: _MarqueeText(text: text, accent: accent),
        );
      },
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final Color accent;
  const _MarqueeText({required this.text, required this.accent});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late double _scrollPosition = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scrollPosition = 0;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  void _startScrolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        if (max > 0) {
          _scrollPosition += 1.0;
          if (_scrollPosition >= max) {
            _scrollPosition = -MediaQuery.sizeOf(context).width;
          }
          _scrollController.jumpTo(_scrollPosition.clamp(0.0, max));
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.accent,
              letterSpacing: 0.2,
            ),
          ),
        ),
        // Add huge padding to simulate clean wrap around for long texts
        SizedBox(width: MediaQuery.sizeOf(context).width),
        Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.accent,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  final AppSettingsData settings;
  const _AboutTab({required this.settings});

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final ref = FirebaseDatabase.instance.ref('sync/global/settings/updateUrl');
    final snapshot = await ref.get();
    final url = snapshot.value as String?;

    if (url != null && url.isNotEmpty) {
      await _launchUrl(url);
    } else {
      if (context.mounted) {
        // High-visibility snackbar with theme accent
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'You are on the latest version',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.accentColor(settings.gradientPreset),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentColor(settings.gradientPreset);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const OpticWordmark(height: 60),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Text(
                  "ئەگەر تووشی هەر کێشەیەک بوویت یان پێویستت بە هاوکاری بوو، تکایە ڕاستەوخۆ لە تێلیگرام پەیوەندیم پێوە بکە. من لێرەم بۆ یارمەتیدانت!",
                  style: AppTheme.withRabarIfKurdish(
                    const Locale('ckb'),
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  "If you encounter any issues or require assistance, please reach out to me directly on Telegram. I am here to help!",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _launchUrl('https://t.me/Opt1c_gh0st'),
                    icon: const Icon(Icons.send_rounded, color: Colors.black),
                    label: const Text(
                      'OPT1C TELEGRAM',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                foregroundColor: accent,
              ),
              onPressed: () => _checkUpdate(context),
              icon: const Icon(Icons.system_update_rounded),
              label: const Text(
                'CHECK LATEST UPDATE',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: 64),
          Text(
            'Version 1.0.0+1',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 Optic TV. All rights reserved.',
            style: TextStyle(color: Colors.white10, fontSize: 10),
          ),
        ],
      ),
    );
  }
}



class _TvClock extends StatefulWidget {
  const _TvClock();

  @override
  State<_TvClock> createState() => _TvClockState();
}

class _TvClockState extends State<_TvClock> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (t) => setState(() {}));
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time ='${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Text(
      time,
      style: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
    );
  }
}

class _TvTabs extends StatefulWidget {
  const _TvTabs({
    required this.tabs,
    required this.onTabChange,
    required this.activeIndex,
    this.nextFocusNode,
  });
  final List<String> tabs;
  final ValueChanged<int> onTabChange;
  final int activeIndex;
  final FocusNode? nextFocusNode;

  @override
  State<_TvTabs> createState() => _TvTabsState();
}

class _TvTabsState extends State<_TvTabs> {
  double _lineWidth = 0;
  double _lineOffset = 0;
  bool _tabFocused = false;
  late int _active = widget.activeIndex;
  late final _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());

  @override
  void didUpdateWidget(covariant _TvTabs old) {
    super.didUpdateWidget(old);
    if (widget.activeIndex != _active) {
      _active = widget.activeIndex;
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(const Duration(milliseconds: 10)).then((_) {
      if (mounted && _tabKeys[_active].currentContext != null) {
        setState(() => _updateActiveLine(_tabKeys[_active].currentContext!));
      }
    });
  }

  void _updateActiveLine(BuildContext ctx) {
    final box = ctx.findRenderObject()! as RenderBox;
    final parentBox = box.parent?.parent?.parent?.parent as RenderBox?;
    if (parentBox == null) return;
    final offset = box.globalToLocal(Offset.zero, ancestor: parentBox);
    _lineWidth = box.size.width;
    _lineOffset = -offset.dx;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Focus(
      autofocus: true,
      onFocusChange: (f) => setState(() => _tabFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _active > 0) {
            _active -= 1;
            widget.onTabChange(_active);
            if (_tabKeys[_active].currentContext != null) {
              _updateActiveLine(_tabKeys[_active].currentContext!);
            }
            setState(() {});
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_active < widget.tabs.length - 1) {
              _active += 1;
              widget.onTabChange(_active);
              if (_tabKeys[_active].currentContext != null) {
                _updateActiveLine(_tabKeys[_active].currentContext!);
              }
              setState(() {});
            } else {
              final siblings = node.parent!.children.toList();
              final index = siblings.indexOf(node);
              if (index + 1 < siblings.length) siblings[index + 1].requestFocus();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.tabs.indexed.map((tab) {
                return GestureDetector(
                  onTap: () {
                    _active = tab.$1;
                    widget.onTabChange(_active);
                    if (_tabKeys[_active].currentContext != null) {
                      _updateActiveLine(_tabKeys[_active].currentContext!);
                    }
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: Text(
                      tab.$2,
                      key: _tabKeys[tab.$1],
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: tab.$1 == _active && _tabFocused ? color : Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_lineWidth > 0)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: _tabFocused ? _lineWidth : _lineWidth * 0.6,
                height: 2,
                margin: EdgeInsets.only(
                    left: _tabFocused ? _lineOffset : _lineOffset + _lineWidth * 0.2),
                decoration: BoxDecoration(
                  color: _tabFocused ? color : Colors.grey,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _StaggeredEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final bool reduceMotion;

  const _StaggeredEntrance({
    required this.child,
    required this.index,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 50).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
