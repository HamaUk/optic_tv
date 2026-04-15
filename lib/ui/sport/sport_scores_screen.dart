import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../services/shotmob_api_service.dart';

/// Embedded sport-scores widget upgraded to ShotMob Core API.
/// Supports real-time WebSocket updates and detailed match analytics.
class SportScoresScreen extends StatefulWidget {
  const SportScoresScreen({super.key});

  @override
  State<SportScoresScreen> createState() => _SportScoresScreenState();
}

class _SportScoresScreenState extends State<SportScoresScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = AppTheme.accentTeal;

  late final ShotMobApiService _api;
  StreamSubscription? _wsSubscription;

  late TabController _leagueTab;
  int _dateTab = 0; 

  static const _leagueKeys = ['Premier League', 'La Liga', 'Iraqi League'];
  final Map<String, List<ShotMatch>> _cache = {};
  final Map<String, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    _api = ShotMobApiService();
    
    _leagueTab = TabController(length: _leagueKeys.length, vsync: this);
    _leagueTab.addListener(() {
      if (!_leagueTab.indexIsChanging) {
        _fetch();
      }
    });

    // Listen for real-time WebSocket events (Goals, Match Status)
    _wsSubscription = _api.matchUpdates.listen((updatedMatch) {
      if (mounted) {
        _handleRealTimeUpdate(updatedMatch);
      }
    });

    _fetch();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _api.dispose();
    _leagueTab.dispose();
    super.dispose();
  }

  String get _currentLeague => _leagueKeys[_leagueTab.index];
  int get _currentLeagueId => ShotMobApiService.leagueIds[_currentLeague] ?? 7;

  Future<void> _fetch() async {
    final key = _currentLeague;
    final lid = _currentLeagueId;

    setState(() => _loading[key] = true);

    try {
      final list = await _api.getMatches(leagueId: lid);
      
      // Sort: Live first, then by dateTime
      list.sort((a, b) {
        if (a.isLive && !b.isLive) return -1;
        if (!a.isLive && b.isLive) return 1;
        return a.matchTime.compareTo(b.matchTime);
      });

      _cache[key] = list;
    } catch (_) {
      _cache[key] ??= [];
    } finally {
      if (mounted) setState(() => _loading[key] = false);
    }
  }

  void _handleRealTimeUpdate(ShotMatch update) {
    // Find and update the match in cache regardless of active league
    for (final league in _cache.keys) {
      final list = _cache[league]!;
      final index = list.indexWhere((m) => m.id == update.id);
      if (index != -1) {
        setState(() {
          _cache[league]![index] = update;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildLeagueTabs(),
        const SizedBox(height: 14),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildLeagueTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: TabBar(
          controller: _leagueTab,
          isScrollable: false,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: LinearGradient(colors: [
              _accent.withOpacity(0.45),
              AppTheme.primaryGold.withOpacity(0.25),
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          tabs: _leagueKeys.map((name) => Tab(text: name)).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final list = _cache[_currentLeague] ?? [];
    final loading = _loading[_currentLeague] == true;

    if (loading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 48, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 14),
            Text('No scheduled matches found', 
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildMatchCard(list[i]),
    );
  }

  Widget _buildMatchCard(ShotMatch m) {
    final live = m.isLive;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surfaceElevated,
        border: Border.all(
          color: live ? Colors.redAccent.withOpacity(0.4) : Colors.white.withOpacity(0.06),
          width: live ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusHeader(m),
          const SizedBox(height: 16),
          _buildTeamsRow(m),
          if (m.predictions != null) ...[
            const SizedBox(height: 18),
            _buildPredictionBar(m.predictions!),
          ],
          if (m.stadium != null) ...[
            const SizedBox(height: 12),
            Text(
              '🏟️ ${m.stadium}${m.attendance != null ? " • Att: ${m.attendance}" : ""}',
              style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 0.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ShotMatch m) {
    final live = m.isLive;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (live) ...[
          const _PulseDot(),
          const SizedBox(width: 8),
          const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(width: 12),
        ],
        Text(
          live ? 'Match in Progress' : m.isFinished ? 'Final Result' : 'Kickoff ${m.timeDisplay}',
          style: TextStyle(
            color: live ? Colors.redAccent : m.isFinished ? _accent : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsRow(ShotMatch m) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _teamLogo(m.homeLogo),
              const SizedBox(height: 8),
              Text(m.homeTeam, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            '${m.scoreHome} - ${m.scoreAway}',
            style: TextStyle(
              color: m.isLive ? Colors.white : Colors.white70,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _teamLogo(m.awayLogo),
              const SizedBox(height: 8),
              Text(m.awayTeam, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionBar(String raw) {
    // Expected format: "57% / 23% / 20%"
    final parts = raw.split('/').map((s) => double.tryParse(s.replaceAll('%', '').trim()) ?? 33.3).toList();
    if (parts.length < 3) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WIN PROBABILITY', style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(flex: parts[0].round(), child: Container(color: _accent)),
                const SizedBox(width: 1),
                Expanded(flex: parts[1].round(), child: Container(color: Colors.white24)),
                const SizedBox(width: 1),
                Expanded(flex: parts[2].round(), child: Container(color: AppTheme.primaryGold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${parts[0].round()}% Home', style: const TextStyle(color: _accent, fontSize: 9, fontWeight: FontWeight.bold)),
            Text('${parts[1].round()}% Draw', style: const TextStyle(color: Colors.white38, fontSize: 9)),
            Text('${parts[2].round()}% Away', style: const TextStyle(color: AppTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _teamLogo(String? url) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        shape: BoxShape.circle,
      ),
      child: url != null ? CachedNetworkImage(imageUrl: url, fit: BoxFit.contain) : const Icon(Icons.shield, color: Colors.white10),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _ctrl, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)));
  }
}
