import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
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

  /// 0 Home, 1 Movies, 2 Sport
  int _navIndex = 0;
  String? _groupFilter;
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
    _adminTapResetTimer = Timer(const Duration(seconds: 2), () {
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
    final s = AppStrings(Localizations.localeOf(context));
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
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
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
              child: Text(s.isEnglish ? 'Cancel' : 'پاشگەزبوونەوە'),
            ),
            FilledButton(
              onPressed: () => _tryAdminPassword(
                dialogContext,
                passwordController.text,
                passwordController,
              ),
              child: Text(s.isEnglish ? 'Enter' : 'بچۆ ژوورەوە'),
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
      final s = AppStrings(Localizations.localeOf(context));
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

  List<Channel> _channelsForNav(List<Channel> all) {
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
      default:
        return all;
    }
  }

  List<Channel> _applySearchAndGroup(List<Channel> base) {
    var list = base;
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) || c.group.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_groupFilter != null) {
      list = list.where((c) => c.group == _groupFilter).toList();
    }
    return list;
  }

  Map<String, List<Channel>> _groupMap(List<Channel> channels) {
    final groups = <String, List<Channel>>{};
    for (final channel in channels) {
      groups.putIfAbsent(channel.group, () => []).add(channel);
    }
    return groups;
  }

  List<String> _sortedGroupKeys(List<Channel> navFiltered) {
    final keys = _groupMap(navFiltered).keys.toList()..sort();
    return keys;
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
    final s = AppStrings(Localizations.localeOf(context));
    final channelsAsync = ref.watch(channelsProvider);
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    final tv = settings.tvFriendlyLayout;
    final animMs = settings.reduceMotion ? 100 : 220;
    final pad = tv ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      drawer: Drawer(
        backgroundColor: const Color(0xFF151B24),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04)),
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Text(
                    s.appBrand,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.white70),
                title: Text(s.settingsTitle, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _openSettings();
                },
              ),
            ],
          ),
        ),
      ),
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
                    _buildTopBar(context, s, pad, tv, const <String>[]),
                    if (_searchOpen) _buildSearchField(s, pad),
                    Expanded(child: _buildEmptyState(s, entireLibraryEmpty: true)),
                  ],
                );
              }

              final navScoped = _channelsForNav(channels);
              final tabDropdownGroups = _sortedGroupKeys(navScoped);
              final filtered = _applySearchAndGroup(navScoped);
              final groups = _groupMap(filtered);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context, s, pad, tv, tabDropdownGroups),
                  if (_searchOpen) _buildSearchField(s, pad),
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(s, entireLibraryEmpty: false)
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
                '${AppStrings(Localizations.localeOf(context)).channelLoadError}: $e',
                style: const TextStyle(color: Colors.white70),
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
    List<String> dropdownGroups,
  ) {
    final filterLabel = _groupFilter ?? s.filterAll;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad * 0.5, pad * 0.75, pad * 0.5, 8),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => Material(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _onLogoTapForAdminPortal,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  s.appBrand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tv ? 17 : 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String?>(
            tooltip: s.filterAll,
            color: const Color(0xFF1C2430),
            onSelected: (v) => setState(() => _groupFilter = v),
            itemBuilder: (context) => [
              PopupMenuItem<String?>(
                value: null,
                child: Text(s.filterAll, style: const TextStyle(color: Colors.white)),
              ),
              ...dropdownGroups.map(
                (g) => PopupMenuItem<String?>(
                  value: g,
                  child: Text(g, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view_rounded, color: _accent, size: 20),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 72),
                    child: Text(
                      filterLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: Colors.white.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
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

  Widget _buildSearchField(AppStrings s, double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad * 0.5, 0, pad * 0.5, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        cursorColor: _accent,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: s.searchHint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s, {required bool entireLibraryEmpty}) {
    final message = entireLibraryEmpty ? s.noChannels : s.noChannelsInSection;
    final sub = entireLibraryEmpty ? s.noChannelsHint : null;
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(
                sub,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.22), fontSize: 13),
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
    final featured = filteredFlat.isNotEmpty ? filteredFlat.first : allChannels.first;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (_navIndex == 0 && _groupFilter == null && _searchController.text.trim().isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 16),
              child: _buildHeroCard(context, s, allChannels, featured, tv, animMs),
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

  Widget _buildHeroCard(
    BuildContext context,
    AppStrings s,
    List<Channel> channels,
    Channel featured,
    bool tv,
    int animMs,
  ) {
    return Container(
      height: tv ? 200 : 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.35),
            const Color(0xFF1C2430),
            AppTheme.primaryGold.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(Icons.live_tv_rounded, size: tv ? 88 : 100, color: Colors.black.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.nowPlaying,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.bold,
                    fontSize: tv ? 12 : 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  featured.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {
                    final i = channels.indexOf(featured);
                    _openPlayer(channels, channels[i >= 0 ? i : 0]);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: tv ? 26 : 20, vertical: 12),
                  ),
                  child: Text(s.watchNow, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: Colors.white),
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
                _buildGridChannelTile(context, allChannels, sectionChannels[index], tv, animMs),
          ),
        ],
      ),
    );
  }

  Widget _buildGridChannelTile(
    BuildContext context,
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
                            child: channel.logo != null
                                ? Image.network(
                                    channel.logo!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.tv_rounded, color: Colors.white24, size: logoSize),
                                  )
                                : Icon(Icons.tv_rounded, color: Colors.white24, size: logoSize),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        channel.name,
                        style: TextStyle(fontSize: tv ? 11 : 10, color: Colors.white.withValues(alpha: 0.75)),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.home_rounded, label: s.navHome, index: 0),
          _navItem(icon: Icons.movie_rounded, label: s.navMovies, index: 1),
          _navItem(icon: Icons.sports_soccer_rounded, label: s.navSport, index: 2),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final selected = _navIndex == index;
    final color = selected ? _accent : Colors.white38;
    return InkWell(
      onTap: () {
        setState(() {
          _navIndex = index;
          _groupFilter = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
