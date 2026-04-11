import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/football_api_service.dart';

/// Embedded sport-scores widget shown when the user selects the Sport nav tab.
class SportScoresScreen extends StatefulWidget {
  const SportScoresScreen({super.key});

  @override
  State<SportScoresScreen> createState() => _SportScoresScreenState();
}

class _SportScoresScreenState extends State<SportScoresScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = AppTheme.accentTeal;

  final _api = FootballApiService();

  late TabController _leagueTab;
  int _dateTab = 1; // 0 = Live, 1 = Today, 2 = Tomorrow

  /// League keys in display order.
  static const _leagueKeys = ['Premier League', 'La Liga', 'Iraqi Stars League'];

  /// Cached data: leagueKey → dateTab → list.
  final Map<String, Map<int, List<MatchData>>> _cache = {};
  final Map<String, Map<int, bool>> _loading = {};
  Timer? _liveRefresh;

  @override
  void initState() {
    super.initState();
    _leagueTab = TabController(length: _leagueKeys.length, vsync: this);
    _leagueTab.addListener(() {
      if (!_leagueTab.indexIsChanging) {
        _fetchIfNeeded();
        setState(() {});
      }
    });
    _fetchIfNeeded();
    // Auto-refresh live tab every 60s.
    _liveRefresh = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_dateTab == 0) _fetch(force: true);
    });
  }

  @override
  void dispose() {
    _liveRefresh?.cancel();
    _leagueTab.dispose();
    super.dispose();
  }

  String get _currentLeague => _leagueKeys[_leagueTab.index];
  int get _currentLeagueId =>
      FootballApiService.leagueIds[_currentLeague] ?? 39;

  void _fetchIfNeeded() {
    final key = _currentLeague;
    if (_cache[key]?[_dateTab] != null) return;
    _fetch();
  }

  Future<void> _fetch({bool force = false}) async {
    final key = _currentLeague;
    final lid = _currentLeagueId;
    if (!force && _cache[key]?[_dateTab] != null) return;

    _loading.putIfAbsent(key, () => {});
    _loading[key]![_dateTab] = true;
    if (mounted) setState(() {});

    List<MatchData> list;
    switch (_dateTab) {
      case 0:
        list = await _api.getLiveMatches(lid);
        break;
      case 2:
        list = await _api.getTomorrowMatches(lid);
        break;
      default:
        list = await _api.getTodayMatches(lid);
    }

    _cache.putIfAbsent(key, () => {});
    _cache[key]![_dateTab] = list;
    _loading[key]![_dateTab] = false;
    if (mounted) setState(() {});
  }

  bool get _isLoading =>
      _loading[_currentLeague]?[_dateTab] == true;

  List<MatchData> get _matches =>
      _cache[_currentLeague]?[_dateTab] ?? [];

  // ────────────────────────── Build ──────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_api.isConfigured) return _buildSetupMessage();

    return Column(
      children: [
        const SizedBox(height: 10),
        _buildLeagueTabs(),
        const SizedBox(height: 10),
        _buildDateSubTabs(),
        const SizedBox(height: 8),
        Expanded(child: _buildBody()),
      ],
    );
  }

  // ─── Setup Required ───
  Widget _buildSetupMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded,
                size: 64, color: AppTheme.primaryGold.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            const Text(
              'Live Scores — Setup Required',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'To show live match scores, you need a free API key from api-football.com.\n\n'
              '1. Register at api-football.com (free)\n'
              '2. Copy your API key\n'
              '3. Paste it in:\n'
              '   lib/services/football_api_service.dart\n'
              '   (replace YOUR_API_KEY_HERE)',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── League Tabs ───
  Widget _buildLeagueTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TabBar(
          controller: _leagueTab,
          isScrollable: false,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: LinearGradient(colors: [
              _accent.withValues(alpha: 0.45),
              AppTheme.primaryGold.withValues(alpha: 0.25),
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          tabs: const [
            Tab(text: 'Premier League'),
            Tab(text: 'La Liga'),
            Tab(text: 'Iraqi Stars'),
          ],
        ),
      ),
    );
  }

  // ─── Date Sub-tabs ───
  Widget _buildDateSubTabs() {
    Widget chip(String label, int idx) {
      final sel = _dateTab == idx;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: sel,
          onSelected: (_) {
            setState(() => _dateTab = idx);
            _fetchIfNeeded();
          },
          selectedColor: _accent.withValues(alpha: 0.35),
          labelStyle: TextStyle(
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? Colors.white : Colors.white60,
            fontSize: 12,
          ),
          side: BorderSide(
            color: sel
                ? _accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
          backgroundColor: AppTheme.surfaceElevated,
          showCheckmark: false,
          avatar: idx == 0
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sel ? Colors.redAccent : Colors.red.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          chip('Live', 0),
          chip('Today', 1),
          chip('Tomorrow', 2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white38, size: 20),
            tooltip: 'Refresh',
            onPressed: () => _fetch(force: true),
          ),
        ],
      ),
    );
  }

  // ─── Body ───
  Widget _buildBody() {
    if (_isLoading && _matches.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _accent),
      );
    }
    if (_matches.isEmpty) {
      final msg = _dateTab == 0
          ? 'No live matches right now'
          : _dateTab == 1
              ? 'No matches today'
              : 'No matches tomorrow';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 14),
            Text(msg,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildMatchCard(_matches[i]),
    );
  }

  // ─── Match Card ───
  Widget _buildMatchCard(MatchData m) {
    final live = m.isLive;
    final finished = m.isFinished;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surfaceElevated,
        border: Border.all(
          color: live
              ? Colors.redAccent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.07),
          width: live ? 1.5 : 1,
        ),
        boxShadow: [
          if (live)
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 0,
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (live) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                live
                    ? m.statusDisplay
                    : finished
                        ? m.statusDisplay
                        : m.kickoffTime,
                style: TextStyle(
                  color: live
                      ? Colors.redAccent.withValues(alpha: 0.9)
                      : finished
                          ? _accent.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Teams row
          Row(
            children: [
              // Home team
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        m.homeTeam,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _teamLogo(m.homeLogo),
                  ],
                ),
              ),
              // Score
              Container(
                width: 70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: live
                      ? Colors.redAccent.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: live
                        ? Colors.redAccent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    m.isNotStarted
                        ? 'vs'
                        : '${m.homeGoals ?? 0} - ${m.awayGoals ?? 0}',
                    style: TextStyle(
                      color: live
                          ? Colors.white
                          : finished
                              ? _accent
                              : Colors.white70,
                      fontSize: m.isNotStarted ? 13 : 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: m.isNotStarted ? 0 : 2,
                    ),
                  ),
                ),
              ),
              // Away team
              Expanded(
                child: Row(
                  children: [
                    _teamLogo(m.awayLogo),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        m.awayTeam,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (m.venue != null && m.venue!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              m.venue!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamLogo(String? url) {
    const size = 30.0;
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.shield_rounded,
            size: 16, color: Colors.white.withValues(alpha: 0.25)),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: Colors.white.withValues(alpha: 0.06),
        ),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shield_rounded,
              size: 16, color: Colors.white.withValues(alpha: 0.25)),
        ),
      ),
    );
  }
}
