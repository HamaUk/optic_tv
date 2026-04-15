import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../services/shotmob_api_service.dart';

/// Upgraded Sport-Scores screen.
/// Removed hardcoded filters to show all dynamic content from ShotMob API.
class SportScoresScreen extends StatefulWidget {
  const SportScoresScreen({super.key});

  @override
  State<SportScoresScreen> createState() => _SportScoresScreenState();
}

class _SportScoresScreenState extends State<SportScoresScreen> {
  static const _accent = AppTheme.accentTeal;

  late final ShotMobApiService _api;
  StreamSubscription? _wsSubscription;

  List<ShotMatch> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = ShotMobApiService();
    
    // Listen for real-time WebSocket events
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
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);

    try {
      // Fetch matches without specific league filtering for a global view
      final list = await _api.getMatches();
      
      // Sort: Live first, then by matchTime
      list.sort((a, b) {
        if (a.isLive && !b.isLive) return -1;
        if (!a.isLive && b.isLive) return 1;
        return a.matchTime.compareTo(b.matchTime);
      });

      _matches = list;
    } catch (_) {
      _matches = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleRealTimeUpdate(ShotMatch update) {
    final index = _matches.indexWhere((m) => m.id == update.id);
    if (index != -1) {
      setState(() {
        _matches[index] = update;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: _accent, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'LIVE & UPCOMING',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
            onPressed: _fetch,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _matches.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 48, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 14),
            Text('No live matches found', 
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildMatchCard(_matches[i]),
    );
  }

  Widget _buildMatchCard(ShotMatch m) {
    final live = m.isLive;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.surfaceElevated,
        border: Border.all(
          color: live ? Colors.redAccent.withOpacity(0.4) : Colors.white.withOpacity(0.06),
          width: live ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLeagueBadge(m.leagueName),
              _buildStatusHeader(m),
            ],
          ),
          const SizedBox(height: 20),
          _buildTeamsRow(m),
          if (m.predictions != null) ...[
            const SizedBox(height: 20),
            _buildPredictionBar(m, m.predictions!),
          ],
          if (m.stadium != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, size: 10, color: Colors.white.withOpacity(0.15)),
                const SizedBox(width: 4),
                Text(
                  '${m.stadium}${m.attendance != null ? " • Att: ${m.attendance}" : ""}',
                  style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeagueBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ShotMatch m) {
    final live = m.isLive;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (live) ...[
          const _PulseDot(),
          const SizedBox(width: 6),
          const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900)),
        ] else
          Text(
            m.isFinished ? 'FINISHED' : m.timeDisplay,
            style: TextStyle(
              color: m.isFinished ? _accent.withOpacity(0.8) : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
              const SizedBox(height: 10),
              Text(m.homeTeam, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        _buildScoreBox(m),
        Expanded(
          child: Column(
            children: [
              _teamLogo(m.awayLogo),
              const SizedBox(height: 10),
              Text(m.awayTeam, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBox(ShotMatch m) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: m.isLive ? Colors.redAccent.withOpacity(0.08) : Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: m.isLive ? Colors.redAccent.withOpacity(0.2) : Colors.white10),
      ),
      child: Text(
        '${m.scoreHome} - ${m.scoreAway}',
        style: TextStyle(
          color: m.isLive ? Colors.white : Colors.white70,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildPredictionBar(ShotMatch m, String raw) {
    final parts = raw.split('/').map((s) => double.tryParse(s.replaceAll('%', '').trim()) ?? 33.3).toList();
    if (parts.length < 3) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('WIN PROBABILITY', style: TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const Spacer(),
              Text('${parts[0].round()}% - ${parts[1].round()}% - ${parts[2].round()}%', 
                style: const TextStyle(color: Colors.white12, fontSize: 8, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  Expanded(flex: parts[0].round(), child: Container(color: _accent)),
                  const SizedBox(width: 2),
                  Expanded(flex: parts[1].round(), child: Container(color: Colors.white12)),
                  const SizedBox(width: 2),
                  Expanded(flex: parts[2].round(), child: Container(color: AppTheme.primaryGold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(m.homeTeam.split(' ').last, style: const TextStyle(color: _accent, fontSize: 8, fontWeight: FontWeight.bold)),
              const Text('DRAW', style: TextStyle(color: Colors.white24, fontSize: 8)),
              Text(m.awayTeam.split(' ').last, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teamLogo(String? url) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url != null 
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ) 
          : const Icon(Icons.shield_rounded, color: Colors.white10, size: 24),
      ),
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
    return FadeTransition(opacity: _ctrl, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)));
  }
}
