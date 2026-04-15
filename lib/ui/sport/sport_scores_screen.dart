import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../services/shotmob_api_service.dart';

/// Professional ShotMob-style Sport UI.
/// Matches the provided Kurdish-localized screenshot exactly.
const _accent = Color(0xFF2ECC71); // ShotMob Green style

class SportScoresScreen extends StatefulWidget {
  const SportScoresScreen({super.key});

  @override
  State<SportScoresScreen> createState() => _SportScoresScreenState();
}

class _SportScoresScreenState extends State<SportScoresScreen> {

  late final ShotMobApiService _api;
  StreamSubscription? _wsSubscription;

  List<ShotMatch> _matches = [];
  bool _loading = true;

  // Date indexing
  int _selectedDateIndex = 1; // 1 = Today
  final List<DateTime> _dates = List.generate(7, (i) => DateTime.now().add(Duration(days: i - 1)));

  @override
  void initState() {
    super.initState();
    _api = ShotMobApiService();
    
    _wsSubscription = _api.matchUpdates.listen((updatedMatch) {
      if (mounted) _handleRealTimeUpdate(updatedMatch);
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
      final dateStr = DateFormat('yyyy-MM-dd').format(_dates[_selectedDateIndex]);
      final list = await _api.getMatches(date: dateStr);
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
      setState(() => _matches[index] = update);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl, // Set Kurdish RTL context
      child: Column(
        children: [
          _buildShotMobHeader(),
          _buildDateTabs(),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
          _buildBottomNavPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildShotMobHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'SHOTMOB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Row(
            children: [
              const _HeaderIcon(icon: Icons.search_rounded),
              const _HeaderIcon(icon: Icons.calendar_month_rounded),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTabs() {
    final KurdishLabels = ['دوێنێ', 'ئەمڕۆ', 'سبەی', 'دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە'];
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dates.length,
        itemBuilder: (context, i) {
          final active = _selectedDateIndex == i;
          return GestureDetector(
            onTap: () {
              if (_selectedDateIndex != i) {
                setState(() => _selectedDateIndex = i);
                _fetch();
              }
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    KurdishLabels[i],
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white30,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 6),
                    Container(width: 24, height: 2, color: Colors.white),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _matches.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    // Grouping logic by leagueName
    final Map<String, List<ShotMatch>> grouped = {};
    for (var m in _matches) {
      grouped.putIfAbsent(m.leagueName, () => []).add(m);
    }

    final leagues = grouped.keys.toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: leagues.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, lIdx) {
        final leagueName = leagues[lIdx];
        final matches = grouped[leagueName]!;

        return Column(
          children: [
            _buildLeagueHeader(leagueName),
            ...matches.map((m) => _buildMatchItem(m)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildLeagueHeader(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white24, size: 24),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Icon(Icons.shield_outlined, color: Colors.white24, size: 24),
        ],
      ),
    );
  }

  Widget _buildMatchItem(ShotMatch m) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withOpacity(0.5),
      ),
      child: Row(
        children: [
          // Away Team (Left)
          Expanded(
            child: Row(
              children: [
                _teamLogo(m.awayLogo, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(m.awayTeam, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          // Time/Score (Center)
          SizedBox(
            width: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(m.isLive ? '${m.scoreHome} - ${m.scoreAway}' : m.matchTime,
                  style: TextStyle(
                    color: m.isLive ? _accent : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('PM', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Home Team (Right)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(child: Text(m.homeTeam, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                _teamLogo(m.homeLogo, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamLogo(String? url, {double size = 30}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        shape: BoxShape.circle,
      ),
      child: url != null 
        ? CachedNetworkImage(imageUrl: url, fit: BoxFit.contain) 
        : const Icon(Icons.shield_rounded, color: Colors.white10, size: 14),
    );
  }

  Widget _buildBottomNavPlaceholder() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _BottomNavItem(icon: Icons.sports_soccer_rounded, label: 'یارییەکان', active: true),
          _BottomNavItem(icon: Icons.newspaper_rounded, label: 'هەواڵەکان'),
          _BottomNavItem(icon: Icons.emoji_events_rounded, label: 'خولەکان'),
          _BottomNavItem(icon: Icons.star_rounded, label: 'دڵخوازەکانم'),
          _BottomNavItem(icon: Icons.menu_rounded, label: 'زیاتر'),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Icon(icon, color: Colors.white70, size: 22),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _BottomNavItem({required this.icon, required this.label, this.active = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: active ? _accent : Colors.white24, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? _accent : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
