import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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

/// Hidden admin portal password.
const String _kAdminPortalPassword = 'hamakoye99';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _adminLogoTaps = 0;
  Timer? _adminTapResetTimer;

  /// 0 Home, 1 Movies, 2 Sport, 3 Favorites, 4 Recent
  int _navIndex = 0;
  bool _searchOpen = false;
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

  List<Channel> _channelsForNav(List<Channel> all, List<Channel> favorites, List<Channel> recent) {
    switch (_navIndex) {
      case 1:
        return all.where((c) {
          final g = c.group.toLowerCase();
          final n = c.name.toLowerCase();
          return g.contains('movie') ||
              g.contains('film') ||
              g.contains('cinema') ||
              n.contains('movie') ||
              n.contains('film');
        }).toList();
      case 2:
        return all.where((c) {
          final g = c.group.toLowerCase();
          return g.contains('sport');
        }).toList();
      case 3:
        return List<Channel>.from(favorites);
      case 4:
        return List<Channel>.from(recent);
      default:
        return all;
    }
  }

  Future<void> _showChannelSheet(AppStrings s, List<Channel> allChannels, Channel channel) async {
    final fav = ref.read(favoritesProvider.notifier).isFavorite(channel);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: AppTheme.primaryGold),
                title: Text(fav ? s.unfavoriteChannel : s.favoriteChannel),
                onTap: () {
                  ref.read(favoritesProvider.notifier).toggle(channel);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white70),
                title: Text(s.shareChannel),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Share.share('${channel.name}\n${channel.url}', subject: channel.name);
                },
              ),
            ],
          ),
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
    final favorites = ref.watch(favoritesProvider);
    final recent = ref.watch(recentChannelsProvider);
    final channelsAsync = ref.watch(channelsProvider);
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    final tv = settings.tvFriendlyLayout;
    final animMs = settings.reduceMotion ? 100 : 220;
    final pad = tv ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F14), Color(0xFF121820), Color(0xFF0B0F14)],
          ),
        ),
        child: SafeArea(
          child: channelsAsync.when(
            data: (channels) {
              if (channels.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(context, s, pad, tv),
                    if (_searchOpen) _buildSearchField(s, pad),
                    Expanded(
                      child: _buildEmptyState(
                        s,
                        title: s.noChannels,
                        subtitle: s.noChannelsHint,
                      ),
                    ),
                  ],
                );
              }

              final navScoped = _channelsForNav(channels, favorites, recent);
              final filtered = _applySearch(navScoped);
              final groups = _groupMap(filtered);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context, s, pad, tv),
                  if (_searchOpen) _buildSearchField(s, pad),
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(
                            s,
                            title: _navIndex == 3
                                ? s.noFavorites
                                : _navIndex == 4
                                    ? s.noRecent
                                    : null,
                            subtitle: _navIndex == 3
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
                            animMs,
                            pad,
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
            error: (e, _) => Center(
              child: Text(
                '${AppStrings(ref.watch(appLocaleProvider)).channelLoadError}: $e',
                style: AppTheme.withRabarIfKurdish(
                  ref.watch(appLocaleProvider),
                  const TextStyle(color: Colors.white70),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(s, MediaQuery.paddingOf(context).bottom),
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
            color: Colors.white.withValues(alpha: 0.06),
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
              color: Colors.white.withValues(alpha: 0.06),
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
            color: Colors.white.withValues(alpha: 0.06),
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
      color: Colors.white.withValues(alpha: opacity),
      fontSize: 16,
      fontFamily: isAndroid ? 'Roboto' : null,
    );
  }

  Widget _buildSearchField(AppStrings s, double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad * 0.5, 0, pad * 0.5, 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
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
            Icon(
              Icons.tv_off_rounded,
              size: 52,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.withRabarIfKurdish(
                s.locale,
                TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              ),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(
                sub,
                style: AppTheme.withRabarIfKurdish(
                  s.locale,
                  TextStyle(color: Colors.white.withValues(alpha: 0.22), fontSize: 13),
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
    final tv = settings.tvFriendlyLayout;
    final crossCount = tv ? 4 : 4;
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
                tv: tv,
                animMs: animMs,
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
              tv,
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
    bool tv,
    int animMs,
    double pad,
  ) {
    final titleSize = tv ? 18.0 : 16.0;
    return Padding(
      padding: EdgeInsets.only(left: pad, right: pad, top: tv ? 20 : 16, bottom: 8),
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
              crossAxisCount: crossCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: sectionChannels.length,
            itemBuilder: (context, index) =>
                _buildGridChannelTile(context, s, allChannels, sectionChannels[index], tv, animMs),
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
    bool tv,
    int animMs,
  ) {
    final logoSize = tv ? 28.0 : 24.0;
    return Focus(
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return AnimatedContainer(
            duration: Duration(milliseconds: animMs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused ? _accent : Colors.white.withValues(alpha: 0.1),
                width: focused ? 2 : 1,
              ),
              color: Colors.white.withValues(alpha: focused ? 0.08 : 0.04),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openPlayer(allChannels, channel),
                onLongPress: () => _showChannelSheet(s, allChannels, channel),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.07),
                                Colors.white.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                          child: Center(
                            child: ChannelLogoImage(
                              logo: channel.logo,
                              width: logoSize * 2.4,
                              height: logoSize * 2.4,
                              fit: BoxFit.contain,
                              fallback: Icon(Icons.tv_rounded, color: Colors.white24, size: logoSize),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        channel.name,
                        style: AppTheme.withRabarIfKurdish(
                          s.locale,
                          TextStyle(fontSize: tv ? 11 : 10, color: Colors.white.withValues(alpha: 0.75)),
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

  Widget _buildBottomNav(AppStrings s, double bottomInset) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1118),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, -4))],
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

  Widget _navItem(AppStrings s, {required IconData icon, required String label, required int index}) {
    final selected = _navIndex == index;
    final color = selected ? _accent : Colors.white38;
    return InkWell(
      onTap: () {
        setState(() => _navIndex = index);
      },
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
                TextStyle(color: color, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({
    required this.slides,
    required this.s,
    required this.tv,
    required this.animMs,
    required this.onWatch,
  });

  final List<Channel> slides;
  final AppStrings s;
  final bool tv;
  final int animMs;
  final void Function(Channel channel) onWatch;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  static const _autoAdvance = Duration(seconds: 5);

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
    final tv = widget.tv;
    final logoSize = tv ? 96.0 : 88.0;

    return Container(
      height: tv ? 248 : 238,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withValues(alpha: 0.35),
            const Color(0xFF1C2430),
            AppTheme.primaryGold.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: 28,
            child: Icon(Icons.live_tv_rounded, size: tv ? 88 : 100, color: Colors.black.withValues(alpha: 0.06)),
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            s.nowPlaying,
                            style: AppTheme.withRabarIfKurdish(
                              s.locale,
                              TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.bold,
                                fontSize: tv ? 12 : 11,
                              ),
                            ),
                          ),
                          SizedBox(height: tv ? 10 : 8),
                          ChannelLogoImage(
                            logo: ch.logo,
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            fallback: Icon(Icons.live_tv_rounded, color: Colors.white38, size: logoSize * 0.55),
                          ),
                          SizedBox(height: tv ? 10 : 8),
                          Text(
                            ch.name,
                            textAlign: TextAlign.center,
                            style: AppTheme.withRabarIfKurdish(
                              s.locale,
                              const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: tv ? 14 : 12),
                          FilledButton(
                            onPressed: () => widget.onWatch(ch),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accentTeal,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: tv ? 28 : 22, vertical: 12),
                            ),
                            child: Text(
                              s.watchNow,
                              style: AppTheme.withRabarIfKurdish(
                                s.locale,
                                const TextStyle(fontWeight: FontWeight.w700),
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
                padding: const EdgeInsets.only(bottom: 12, top: 4),
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
                            : Colors.white.withValues(alpha: 0.22),
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
