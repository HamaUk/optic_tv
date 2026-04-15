import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';

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
import './movie_details_screen.dart';
import 'package:lottie/lottie.dart';

/// Hidden admin portal password.
const String _kAdminPortalPassword = 'hamakoye99';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TmdbService _tmdb = TmdbService();
  int _adminLogoTaps = 0;
  Timer? _adminTapResetTimer;

  /// 0 Home, 1 Movies, 2 Sport, 3 Favorites, 4 Recent
  int _navIndex = 0;
  bool _searchOpen = false;
  bool _tvHomeActive = true; 
  final TextEditingController _searchController = TextEditingController();

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
      _showAdminPasswordDialog();
    }
  }

  void _showAdminPasswordDialog() {
    final s = AppStrings(ref.read(appLocaleProvider));
    final passwordController = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: Text(s.settingsTitle),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: s.password,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _tryAdminPassword(
              dialogContext,
              passwordController.text,
              passwordController,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Future.microtask(passwordController.dispose);
              },
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => _tryAdminPassword(
                dialogContext,
                passwordController.text,
                passwordController,
              ),
              child: Text(s.enter),
            ),
          ],
        );
      },
    );
  }

  void _tryAdminPassword(
    BuildContext dialogContext,
    String password,
    TextEditingController passwordController,
  ) {
    if (password == _kAdminPortalPassword) {
      Navigator.pop(dialogContext);
      Future.microtask(passwordController.dispose);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    } else {
      final s = AppStrings(ref.read(appLocaleProvider));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loginErrorInvalid)),
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
    final g = c.group.toLowerCase();
    final n = c.name.toLowerCase();
    
    // Exclude anything that explicitly marks itself as a Live stream
    if (g.contains('live') || n.contains(' live')) return false;
    
    // If it's a TV channel category, it's likely not VOD unless "movie" is in the name
    if (g.contains('tv') && !g.contains('movie') && !g.contains('cinema')) return false;

    final movieKeywords = [
      'movie', 'film', 'cinema', 'vod', 'box office', 'uhd', '4k', 'action',
      'comedy', 'horror', 'drama', 'thriller', 'animation', 'documentary'
    ];
    
    final isTagged = movieKeywords.any((kw) => g.contains(kw) || n.contains(kw));
    // Also explicitly include if the group is just "Movies" or "VOD"
    final isMovieGroup = g == 'movies' || g == 'vod' || g == 'cinema';
    
    return isTagged || isMovieGroup;
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
        return List<Channel>.from(recent);
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

        // Sport tab: show live scores widget instead of channel grid.
        if (_navIndex == 2) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundBlack,
            body: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.shellGradient(settings.gradientPreset),
              ),
              child: SafeArea(
                bottom: false,
                child: _buildDashboardShell(
                  context, s, 16.0, false, const SportScoresScreen(),
                ),
              ),
            ),
            bottomNavigationBar: portrait ? _buildBottomNav(s, MediaQuery.paddingOf(context).bottom) : null,
          );
        }

        final heroImage = filtered.isNotEmpty ? filtered.first.logo : null;

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
                                : _navIndex == 4
                                    ? s.noRecent
                                    : null,
                        subtitle: _navIndex == 1
                            ? 'Try adding movies or VOD content in the Admin Portal'
                            : _navIndex == 3
                                ? s.noFavoritesHint
                                : _navIndex == 4
                                    ? s.noRecentHint
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
              ),
            ),
          ),
          bottomNavigationBar: portrait ? _buildBottomNav(s, MediaQuery.paddingOf(context).bottom) : null,
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

    final contentDir = s.locale.languageCode == 'ckb' ? TextDirection.rtl : TextDirection.ltr;
    final bodyColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(context, s, pad, tv),
        const _GlobalAnnouncementTicker(),
        if (_searchOpen) _buildSearchField(s, pad),
        Expanded(child: expandedChild),
      ],
    );

    return Row(
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSideRail(s),
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
    );
  }

  Widget _buildSideRail(AppStrings s) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(6, 10, 6, math.max(bottom, 10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(s, icon: Icons.home_rounded, label: s.navHome, index: 0, sideRail: true),
          _navItem(s, icon: Icons.movie_rounded, label: s.navMovies, index: 1, sideRail: true),
          _navItem(s, icon: Icons.sports_soccer_rounded, label: s.navSport, index: 2, sideRail: true),
          _navItem(s, icon: Icons.star_rounded, label: s.navFavorites, index: 3, sideRail: true),
          _navItem(s, icon: Icons.history_rounded, label: s.navRecent, index: 4, sideRail: true),
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
    const tv = false;
    const crossCount = 4;
    final slideChannels = filteredFlat.take(5).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if ((_navIndex == 0 || _navIndex == 4) &&
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
            ),
          );
        }),
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
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
  ) {
    final isMovie = _navIndex == 1;
    const titleSize = 16.0;
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
    return Focus(
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return AnimatedContainer(
            duration: Duration(milliseconds: animMs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(
                color: focused ? _accent.withOpacity(0.9) : Colors.white.withOpacity(0.12),
                width: focused ? 1.5 : 1,
              ),
              color: focused
                  ? _accent.withOpacity(0.07)
                  : const Color(0xFF141A22).withOpacity(0.94),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(kTileRadius),
                onTap: () => _openPlayer(allChannels, channel),
                onLongPress: () => _showChannelSheet(s, allChannels, channel),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ChannelLogoImage(
                            logo: channel.logo,
                            width: logoSize * 2.65,
                            height: logoSize * 2.65,
                            fit: BoxFit.contain,
                            fallback: Icon(Icons.tv_rounded, color: Colors.white24, size: logoSize + 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        channel.name,
                        style: AppTheme.withRabarIfKurdish(
                          s.locale,
                          TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.78)),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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

    return Focus(
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return AnimatedContainer(
            duration: Duration(milliseconds: animMs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(
                color: focused ? _accent.withOpacity(0.9) : Colors.white.withOpacity(0.1),
                width: focused ? 2 : 1,
              ),
              color: const Color(0xFF141A22),
              boxShadow: [
                BoxShadow(
                  color: focused ? _accent.withOpacity(0.18) : Colors.black.withOpacity(0.25),
                  blurRadius: focused ? 16 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(kTileRadius),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kTileRadius - 1),
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
                                Colors.black.withOpacity(0.65),
                                Colors.black.withOpacity(0.92),
                              ],
                              stops: const [0, 0.45, 0.78, 1],
                            ),
                          ),
                        ),
                      ),
                      // Play icon center
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
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Text(
                          channel.name,
                          style: AppTheme.withRabarIfKurdish(
                            s.locale,
                            TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 6),
                              ],
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

  Widget _buildBottomNav(AppStrings s, double bottomInset) {
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
          _navItem(s, icon: Icons.home_rounded, label: s.navHome, index: 0),
          _navItem(s, icon: Icons.movie_rounded, label: s.navMovies, index: 1),
          _navItem(s, icon: Icons.sports_soccer_rounded, label: s.navSport, index: 2),
          _navItem(s, icon: Icons.star_rounded, label: s.navFavorites, index: 3),
          _navItem(s, icon: Icons.history_rounded, label: s.navRecent, index: 4),
        ],
      ),
    );
  }

  Widget _navItem(
    AppStrings s, {
    required IconData icon,
    required String label,
    required int index,
    bool sideRail = false,
  }) {
    final selected = _navIndex == index;
    final color = selected ? _accent : (sideRail ? Colors.white.withOpacity(0.52) : Colors.white38);

    if (!sideRail) {
      return InkWell(
        onTap: () => setState(() => _navIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Landscape rail: KRD-style — teal border + soft fill around **icon + label**, smaller glyphs.
    const railIcon = 20.0;
    const railRadius = 14.0;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: railIcon),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.withRabarIfKurdish(
            s.locale,
            TextStyle(
              color: color,
              fontSize: 8.5,
              height: 1.1,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: column,
    );

    final chip = selected
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(railRadius),
              border: Border.all(color: _accent.withOpacity(0.88), width: 1.5),
              color: _accent.withOpacity(0.13),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.18),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: padded,
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: column,
          );

    return InkWell(
      onTap: () => setState(() => _navIndex = index),
      borderRadius: BorderRadius.circular(railRadius),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 78),
          child: chip,
        ),
      ),
    );
  }
}

/// Pulsing channel logo for the featured hero (respects [reduceMotion]).
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
    const logoBlock = 78.0;
    final textDir = s.locale.languageCode == 'ckb' ? TextDirection.rtl : TextDirection.ltr;

    return Container(
      height: 196,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.featuredHeroGradient(widget.gradientPreset),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: 20,
            child: Icon(Icons.live_tv_rounded, size: 108, color: Colors.black.withOpacity(0.07)),
          ),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.slides.length,
                  itemBuilder: (context, i) {
                    final ch = widget.slides[i];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(12, 10, 14, 4),
                      child: Row(
                        textDirection: TextDirection.ltr,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: _PulsingLogoBox(
                              channel: ch,
                              baseSize: logoBlock,
                              reduceMotion: widget.reduceMotion,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Directionality(
                              textDirection: textDir,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.nowPlaying,
                                    style: AppTheme.withRabarIfKurdish(
                                      s.locale,
                                      TextStyle(
                                        color: Colors.white.withOpacity(0.58),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10.5,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    s.featuredNewHint,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.withRabarIfKurdish(
                                      s.locale,
                                      TextStyle(
                                        color: Colors.white.withOpacity(0.72),
                                        fontSize: 11.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ch.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.withRabarIfKurdish(
                                      s.locale,
                                      TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton(
                                      onPressed: () => widget.onWatch(ch),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.accentTeal,
                                        foregroundColor: Colors.black,
                                        elevation: 2,
                                        shadowColor: AppTheme.accentTeal.withOpacity(0.5),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        s.watchNow,
                                        style: AppTheme.withRabarIfKurdish(
                                          s.locale,
                                          const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: widget.animMs.clamp(120, 400)),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: active
                            ? AppTheme.accentTeal
                            : Colors.white.withOpacity(0.22),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlobalAnnouncementTicker extends StatelessWidget {
  const _GlobalAnnouncementTicker();

  @override
  Widget build(BuildContext context) {
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
            color: AppTheme.primaryGold.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: AppTheme.primaryGold.withOpacity(0.15), width: 0.5),
            ),
          ),
          child: _MarqueeText(text: text),
        );
      },
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  const _MarqueeText({required this.text});

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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGold,
              letterSpacing: 0.2,
            ),
          ),
        ),
        // Add huge padding to simulate clean wrap around for long texts
        SizedBox(width: MediaQuery.sizeOf(context).width),
        Center(
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGold,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
