import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../settings/settings_screen.dart';
import '../sport/sport_scores_screen.dart';
import '../../services/tmdb_service.dart';
import '../../widgets/dynamic_background.dart';
import '../../widgets/tv_focus_wrapper.dart';
import './movie_details_screen.dart';
import 'package:lottie/lottie.dart';

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

  /// 0 Home, 1 Movies, 2 Sport, 3 Favorites, 4 About
  int _navIndex = 0;
  bool _searchOpen = false;
  bool _tvHomeActive = true; 
  final TextEditingController _searchController = TextEditingController();
  
  Channel? _focusedChannel; 
  bool _sidebarFocused = false;
  String? _selectedTvGroup; // Categorical selection for 3-pane TV layout

  static const _accent = AppTheme.accentTeal;

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

  List<Channel> _channelsForNav(List<Channel> all, List<Channel> favorites, List<Channel> recent) {
    switch (_navIndex) {
      case 1:
        return all.where(_isMovieChannel).toList();
      case 2:
        // Sport tab now shows the dedicated score screen; return empty.
        return [];
      case 3:
        return List<Channel>.from(favorites);
      case 4:
        // About tab: return empty, content is built in _AboutTab widget.
        return [];
      default:
        // Home: exclude movies so they only appear in the Movies tab.
        return all.where((c) => !_isMovieChannel(c)).toList();
    }
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

        // Sport or About tab: show dedicated screen instead of channel grid.
        if (_navIndex == 2 || _navIndex == 4) {
          final screen = _navIndex == 2 
              ? const SportScoresScreen() 
              : _AboutTab(settings: settings);

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
        final heroImage = _focusedChannel?.logo ?? (filtered.isNotEmpty ? filtered.first.logo : null);

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          body: DynamicBackground(
            imageUrl: heroImage,
            child: SafeArea(
              bottom: false,
              child: _buildDashboardShell(
                context,
                s,
                16.0,
                false,
                filtered.isEmpty
                    ? _buildEmptyState(
                        s,
                        title: _navIndex == 1
                            ? 'No movies found'
                            : _navIndex == 3
                                ? s.noFavorites
                                : null,
                        subtitle: _navIndex == 1
                            ? 'Try adding movies or VOD content in the Admin Portal'
                            : _navIndex == 3
                                ? s.noFavoritesHint
                                : null,
                      )
                    : _buildScrollableContent(
                        context,
                        s,
                        channels,
                        filtered,
                        groups,
                        settings,
                        settings.reduceMotion ? 100 : 220,
                        16.0,
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
        // Pane 1: Global Nav
        _buildSideRail(s, isTv, settings),
        
        if (isTv) ...[
          // Pane 2: Categorical Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: _buildTvCategoryRail(s),
          ),
          // Pane 3: Content Grid
          Expanded(
            child: Directionality(
              textDirection: contentDir,
              child: _buildTvChannelGrid(context, s, settings),
            ),
          ),
        ] else ...[
          if (!isTv)
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.white.withOpacity(0.08),
            ),
          Expanded(
            child: Directionality(
              textDirection: contentDir,
              child: bodyColumn,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSideRail(AppStrings s, bool isTv, AppSettingsData settings) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final railWidth = isTv ? 120.0 : 96.0;
    
    return Container(
      width: railWidth,
      decoration: BoxDecoration(
        color: isTv ? Colors.black.withOpacity(0.85) : const Color(0xFF0A0E14),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(isTv ? 0.12 : 0.06)),
        ),
        boxShadow: [
          if (isTv)
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(6, isTv ? 40 : 10, 6, math.max(bottom, 10)),
      child: Column(
        children: [
          if (isTv) ...[
            const OpticWordmark(height: 38),
            const SizedBox(height: 60),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: isTv ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(s, settings, icon: Icons.home_rounded, label: s.navHome, index: 0, sideRail: true, isTv: isTv),
                if (isTv) const SizedBox(height: 24),
                _navItem(s, settings, icon: Icons.movie_rounded, label: s.navMovies, index: 1, sideRail: true, isTv: isTv),
                if (isTv) const SizedBox(height: 24),
                _navItem(s, settings, icon: Icons.sports_soccer_rounded, label: s.navSport, index: 2, sideRail: true, isTv: isTv),
                if (isTv) const SizedBox(height: 24),
                _navItem(s, settings, icon: Icons.star_rounded, label: s.navFavorites, index: 3, sideRail: true, isTv: isTv),
                if (isTv) const SizedBox(height: 24),
                _navItem(s, settings, icon: Icons.info_outline_rounded, label: 'About', index: 4, sideRail: true, isTv: isTv),
              ],
            ),
          ),
          if (isTv) ...[
            _navItem(s, settings, icon: Icons.settings_rounded, label: 'Settings', index: -1, sideRail: true, isTv: isTv),
            const SizedBox(height: 20),
          ],
        ],
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
          Material(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              tooltip: s.settingsTooltip,
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: _openSettings,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _onLogoTapForAdminPortal,
                borderRadius: BorderRadius.circular(12),
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
          Material(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
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
      child: Material(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Colors.white54, size: 22),
              Expanded(
                child: CupertinoTextField(
                  controller: _searchController,
                  autofocus: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                  icon: const Icon(Icons.clear_rounded, color: Colors.white54),
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
  ) {
    final isTv = MediaQuery.sizeOf(context).width > 900;
    final crossCount = isTv ? 6 : 4;
    
    var slideChannels = allChannels.where((c) => c.featured).toList();
    if (slideChannels.isEmpty) {
      slideChannels = filteredFlat.take(5).toList();
    }

    final heroChannel = _focusedChannel ?? (filteredFlat.isNotEmpty ? filteredFlat.first : null);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [

        if (!isTv && (_navIndex == 0 || _navIndex == 4) &&
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
        ...groups.entries.map((entry) {
          return SliverToBoxAdapter(
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
            ),
          );
        }),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
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
              child: ListView.builder(
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
      onLongPress: () => _showChannelSheet(s, allChannels, channel),
      scale: 1.12,
      borderRadius: kTileRadius,
      child: Focus(
        onFocusChange: (f) {
           if (f && mounted) setState(() => _focusedChannel = channel);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: animMs),
          decoration: BoxDecoration(
            color: focused 
                ? _accent.withOpacity(0.12) 
                : const Color(0xFF141A22).withOpacity(0.94),
          ),
          child: Padding(
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
                    TextStyle(fontSize: isTv ? 14 : 10, color: Colors.white, fontWeight: focused ? FontWeight.w900 : FontWeight.w500),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
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
      onTap: () {
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
      onLongPress: () => _showChannelSheet(s, allChannels, channel),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1118),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8, top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(s, settings, icon: Icons.home_rounded, label: s.navHome, index: 0),
          _navItem(s, settings, icon: Icons.movie_rounded, label: s.navMovies, index: 1),
          _navItem(s, settings, icon: Icons.sports_soccer_rounded, label: s.navSport, index: 2),
          _navItem(s, settings, icon: Icons.star_rounded, label: s.navFavorites, index: 3),
          _navItem(s, settings, icon: Icons.info_outline_rounded, label: 'About', index: 4),
        ],
      ),
    );
  }

  Widget _navItem(
    AppStrings s,
    AppSettingsData settings, {
    required IconData icon,
    required String label,
    required int index,
    bool sideRail = false,
    bool isTv = false,
  }) {
    final selected = _navIndex == index;
    final accent = AppTheme.accentColor(settings.gradientPreset);
    final color = selected ? accent : (sideRail ? Colors.white.withOpacity(0.52) : Colors.white38);

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
            color: selected ? accent.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
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

    return InkWell(
      onTap: () => setState(() => _navIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: sideRail ? 28 : 24),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.withRabarIfKurdish(
                s.locale,
                TextStyle(
                  color: color,
                  fontSize: sideRail ? 11 : 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              child: _buildSearchField(s, 0),
            ),
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

  Widget _tvCategoryItem(String name, int count, bool active, VoidCallback onTap) {
    return TvFocusWrapper(
      onTap: onTap,
      borderRadius: 14,
      scale: 1.04,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: active ? _accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? _accent.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white60,
                  fontSize: 16,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active ? _accent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: active ? _accent : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// High-density Channel Grid (Pane 3) for TV. No Hero section as requested.
  Widget _buildTvChannelGrid(BuildContext context, AppStrings s, AppSettingsData settings) {
    final channelsAsync = ref.watch(channelsProvider);
    return channelsAsync.when(
      data: (all) {
        final favorites = ref.watch(favoritesProvider);
        final base = _channelsForNav(all, favorites, []);
        final filtered = _applySearch(base);
        
        final displayChannels = _selectedTvGroup == null 
            ? filtered 
            : filtered.where((c) => c.group == _selectedTvGroup).toList();

        if (displayChannels.isEmpty) return _buildEmptyState(s);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 32,
            crossAxisSpacing: 32,
            childAspectRatio: 1.0,
          ),
          itemCount: displayChannels.length,
          itemBuilder: (context, idx) {
            final ch = displayChannels[idx];
            return _buildTvCinemaTile(s, all, ch);
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTvCinemaTile(AppStrings s, List<Channel> all, Channel ch) {
    return TvFocusWrapper(
      onTap: () => _openPlayer(all, ch),
      borderRadius: 18,
      scale: 1.12,
      child: Focus(
        onFocusChange: (f) {
           if (f && mounted) setState(() => _focusedChannel = ch);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ChannelLogoImage(
                  logo: ch.logo,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Text(
                  ch.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing channel logo
class _PulsingLogoBox extends StatefulWidget {
  const _PulsingLogoBox({
    required this.channel,
    required this.baseSize,
    required this.reduceMotion,
  });

  final Channel channel;
  final double baseSize;
  final bool reduceMotion;

  @override
  State<_PulsingLogoBox> createState() => _PulsingLogoBoxState();
}

class _PulsingLogoBoxState extends State<_PulsingLogoBox> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2800),
      )..repeat(reverse: true);
      _pulse!.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  double get _scale {
    if (_pulse == null) return 1.0;
    return 1.0 + 0.045 * Curves.easeInOut.transform(_pulse!.value);
  }

  double get _glow {
    if (_pulse == null) return 0.32;
    return 0.2 + 0.28 * Curves.easeInOut.transform(_pulse!.value);
  }

  @override
  Widget build(BuildContext context) {
    final pad = 10.0;
    final inner = widget.baseSize;
    return Transform.scale(
      scale: _scale,
      child: Container(
        width: inner + pad * 2,
        height: inner + pad * 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentTeal.withOpacity(0.45),
              Colors.white.withOpacity(0.1),
              AppTheme.primaryGold.withOpacity(0.35),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentTeal.withOpacity(_glow),
              blurRadius: 22,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(_glow * 0.35),
              blurRadius: 14,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: EdgeInsets.all(pad),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black.withOpacity(0.25),
          ),
          child: Center(
            child: ChannelLogoImage(
              logo: widget.channel.logo,
              width: inner,
              height: inner,
              fit: BoxFit.contain,
              fallback: Icon(Icons.live_tv_rounded, color: Colors.white38, size: inner * 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

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
  static const _autoAdvance = Duration(seconds: 10);

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
  void didUpdateWidget(covariant _FeaturedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameSlideOrder(oldWidget.slides, widget.slides)) {
      _autoTimer?.cancel();
      _index = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
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
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF0D1118),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
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

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Backdrop Image (or fallback)
                  if (hasBackdrop)
                    ChannelLogoImage(
                      logo: ch.backdrop,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      fallback: _heroFallback(ch),
                    )
                  else
                    _heroFallback(ch),

                  // Layer 2: Cinematic Gradient Overlays
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
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

                  // Layer 3: Content
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
                            TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              shadows: [
                                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: s.locale.languageCode == 'ckb' ? Alignment.centerLeft : Alignment.centerRight,
                          child: _glassButton(
                            label: s.watchNow,
                            icon: Icons.play_arrow_rounded,
                            onTap: () => widget.onWatch(ch),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (widget.slides.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
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
                      color: _index == i 
                          ? AppTheme.accentColor(widget.gradientPreset) 
                          : Colors.white24,
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

  Widget _heroFallback(Channel ch) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundBlack,
            const Color(0xFF1A222E),
            AppTheme.surfaceGray,
          ],
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

  Widget _glassButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
