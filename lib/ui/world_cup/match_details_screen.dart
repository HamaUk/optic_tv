import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../../services/world_cup_service.dart';
import '../../core/theme.dart';

class MatchDetailsScreen extends StatefulWidget {
  final String eventId;
  final String homeTeam;
  final String awayTeam;
  final String? homeFlag;
  final String? awayFlag;

  const MatchDetailsScreen({
    super.key,
    required this.eventId,
    required this.homeTeam,
    required this.awayTeam,
    this.homeFlag,
    this.awayFlag,
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _summary;
  Timer? _pollingTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    // Poll every 30 seconds for real-time updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData(isPolling: true));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool isPolling = false}) async {
    if (!isPolling) setState(() => _loading = true);
    final summary = await WorldCupService.fetchMatchSummary(widget.eventId);
    if (mounted) {
      setState(() {
        _summary = summary;
        _loading = false;
      });
    }
  }

  Widget _glassContainer({required Widget child, EdgeInsetsGeometry? padding, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  // --- SCOREBOARD HEADER ---
  Widget _buildScoreboardHeader() {
    final header = _summary?['header'];
    final competitions = header?['competitions'] as List<dynamic>? ?? [];
    Map<String, dynamic>? matchData;
    if (competitions.isNotEmpty) {
      matchData = competitions[0];
    }
    
    final status = matchData?['status']?['type']?['shortDetail'] ?? '';
    final competitors = matchData?['competitors'] as List<dynamic>? ?? [];

    Map<String, dynamic>? homeData;
    Map<String, dynamic>? awayData;
    
    for (var c in competitors) {
      if (c['homeAway'] == 'home') homeData = c;
      if (c['homeAway'] == 'away') awayData = c;
    }

    final homeScore = homeData?['score'] ?? '-';
    final awayScore = awayData?['score'] ?? '-';
    
    // Fallback to widget flags if API flags are missing
    final homeLogo = homeData?['team']?['logo'] ?? widget.homeFlag ?? '';
    final awayLogo = awayData?['team']?['logo'] ?? widget.awayFlag ?? '';
    final homeName = homeData?['team']?['shortDisplayName'] ?? widget.homeTeam;
    final awayName = awayData?['team']?['shortDisplayName'] ?? widget.awayTeam;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // HOME
              Expanded(
                child: Column(
                  children: [
                    if (homeLogo.isNotEmpty)
                      Image.network(homeLogo, height: 64, errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Colors.white54, size: 64)),
                    const SizedBox(height: 12),
                    Text(homeName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                ),
              ),
              // SCORE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(status, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text('$homeScore - $awayScore', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              // AWAY
              Expanded(
                child: Column(
                  children: [
                    if (awayLogo.isNotEmpty)
                      Image.network(awayLogo, height: 64, errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Colors.white54, size: 64)),
                    const SizedBox(height: 12),
                    Text(awayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB A: MATCH CENTER ---
  Widget _buildMatchCenterTab() {
    final gameInfo = _summary?['gameInfo'];
    final venue = gameInfo?['venue'];
    final keyEvents = _summary?['keyEvents'] as List<dynamic>? ?? [];

    if (venue == null && keyEvents.isEmpty) {
      return const Center(child: Text('هێشتا ڕووداوەکان بەردەست نین', style: TextStyle(color: Colors.white54)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (venue != null) ...[
            const Text('یاریگا (Stadium)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _glassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.stadium_rounded, color: AppTheme.primaryGold, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue['fullName'] ?? 'Unknown Stadium', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        if (venue['address'] != null)
                          Text('${venue['address']['city'] ?? ''}, ${venue['address']['country'] ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (keyEvents.isNotEmpty) ...[
            const Text('ڕووداوەکان (Timeline)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _glassContainer(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keyEvents.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
                itemBuilder: (context, index) {
                  final event = keyEvents[index];
                  final text = event['text'] ?? '';
                  final time = event['clock']?['displayValue'] ?? event['time']?['displayValue'] ?? '';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(time, style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB B: STATISTICS ---
  Widget _buildStatRow(String label, String homeVal, String awayVal) {
    double hVal = double.tryParse(homeVal.replaceAll('%', '')) ?? 0;
    double aVal = double.tryParse(awayVal.replaceAll('%', '')) ?? 0;
    double total = hVal + aVal;
    if (total == 0) total = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(homeVal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              Text(awayVal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: (hVal * 100).toInt(),
                child: Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(3)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: (aVal * 100).toInt(),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final boxscore = _summary?['boxscore'];
    final teams = boxscore?['teams'] as List<dynamic>? ?? [];

    if (teams.length < 2) {
      return const Center(child: Text('ئامارەکان بەردەست نین', style: TextStyle(color: Colors.white54)));
    }

    Map<String, dynamic>? homeTeamStats;
    Map<String, dynamic>? awayTeamStats;

    for (var t in teams) {
      if (t['homeAway'] == 'home') homeTeamStats = t;
      if (t['homeAway'] == 'away') awayTeamStats = t;
    }

    if (homeTeamStats == null || awayTeamStats == null) {
       return const Center(child: Text('ئامارەکان بەردەست نین', style: TextStyle(color: Colors.white54)));
    }

    final homeStats = homeTeamStats['statistics'] as List<dynamic>? ?? [];
    final awayStats = awayTeamStats['statistics'] as List<dynamic>? ?? [];

    // Helper to find a stat by name
    String getStat(List<dynamic> stats, String name) {
      final stat = stats.firstWhere((s) => s['name'] == name, orElse: () => null);
      return stat?['displayValue'] ?? '0';
    }

    final List<Map<String, String>> statKeys = [
      {'name': 'possessionPct', 'label': 'Possession %'},
      {'name': 'totalShots', 'label': 'Total Shots'},
      {'name': 'shotsOnTarget', 'label': 'Shots on Target'},
      {'name': 'totalPasses', 'label': 'Passes'},
      {'name': 'wonCorners', 'label': 'Corners'},
      {'name': 'foulsCommitted', 'label': 'Fouls'},
      {'name': 'yellowCards', 'label': 'Yellow Cards'},
      {'name': 'redCards', 'label': 'Red Cards'},
      {'name': 'offsides', 'label': 'Offsides'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _glassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: statKeys.map((s) {
            return _buildStatRow(
              s['label']!,
              getStat(homeStats, s['name']!),
              getStat(awayStats, s['name']!),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- TAB C: LINEUPS ---
  Widget _buildLineupsTab() {
    final rosters = _summary?['rosters'] as List<dynamic>? ?? [];

    if (rosters.isEmpty) {
      return const Center(child: Text('پێکهاتەکان هێشتا بەردەست نین', style: TextStyle(color: Colors.white54)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rosters.map((teamRoster) {
          final roster = teamRoster['roster'] as List<dynamic>? ?? [];
          final formation = teamRoster['formation'] ?? '';
          final isHome = teamRoster['homeAway'] == 'home';
          final teamName = isHome ? widget.homeTeam : widget.awayTeam;

          final starters = roster.where((p) => p['starter'] == true).toList();
          final subs = roster.where((p) => p['starter'] == false).toList();

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isHome ? 8.0 : 0, left: isHome ? 0 : 8.0),
              child: _glassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teamName, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (formation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 4),
                        child: Text(formation, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    
                    const Text('Starters', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...starters.map((player) {
                      final pName = player['athlete']?['displayName'] ?? 'Unknown';
                      final jersey = player['jersey'] ?? '-';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              child: Text(jersey, style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pName, style: const TextStyle(color: Colors.white, fontSize: 13))),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 16),
                    const Text('Substitutes', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...subs.map((player) {
                      final pName = player['athlete']?['displayName'] ?? 'Unknown';
                      final jersey = player['jersey'] ?? '-';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.transparent,
                              child: Text(jersey, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- TAB D: HISTORY & FORM ---
  Widget _buildHistoryTab() {
    final formObj = _summary?['boxscore']?['form'] as List<dynamic>? ?? [];
    final h2h = _summary?['headToHeadGames'] as List<dynamic>? ?? [];

    if (formObj.isEmpty && h2h.isEmpty) {
      return const Center(child: Text('هیچ زانیارییەکی ڕابردوو بەردەست نییە', style: TextStyle(color: Colors.white54)));
    }

    // Helper for Form Badges
    Widget buildFormBadge(String result) {
      Color bg;
      if (result == 'W') bg = Colors.green;
      else if (result == 'L') bg = Colors.red;
      else bg = Colors.grey;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(result, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TEAM FORM
          if (formObj.isNotEmpty) ...[
            const Text('فۆڕمی تیمەکان (Last 5 Games)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _glassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: formObj.map((teamForm) {
                  final teamName = teamForm['team']?['displayName'] ?? 'Team';
                  final logo = teamForm['team']?['logo'] ?? '';
                  final events = teamForm['events'] as List<dynamic>? ?? [];

                  // Get W/D/L for last 5 games
                  List<String> results = events.map((e) => e['gameResult']?.toString() ?? '-').take(5).toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        if (logo.isNotEmpty) Image.network(logo, height: 24, errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Colors.white54, size: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(teamName, style: const TextStyle(color: Colors.white, fontSize: 16))),
                        Row(children: results.map((r) => buildFormBadge(r)).toList()),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // HEAD TO HEAD
          if (h2h.isNotEmpty) ...[
            const Text('ڕووبەڕووبوونەوەکان (Head to Head)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _glassContainer(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: h2h.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
                itemBuilder: (context, index) {
                  final game = h2h[index];
                  // The structure of headToHeadGames usually puts matches inside `events` array
                  final events = game['events'] as List<dynamic>? ?? [];
                  if (events.isEmpty) return const SizedBox();
                  
                  return Column(
                    children: events.map((event) {
                      final dateStr = event['gameDate'] ?? '';
                      DateTime? date;
                      if (dateStr.isNotEmpty) date = DateTime.tryParse(dateStr);
                      final formattedDate = date != null ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}' : '';
                      
                      final compName = event['competitionName'] ?? 'Match';
                      final homeName = event['homeTeamScore'] != null ? 'Home' : ''; // simplify name logic since ESPN API H2H structure varies
                      
                      // Actually ESPN gives opponent info in H2H but the format varies. Let's just use score line if available.
                      final score = event['score'] ?? '-';
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(compName, style: const TextStyle(color: Colors.white, fontSize: 14))),
                            Text(score, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        subtitle: Text(formattedDate, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _summary == null
              ? const Center(child: Text('Data not available', style: TextStyle(color: Colors.white)))
              : Column(
                  children: [
                    _buildScoreboardHeader(),
                    Container(
                      color: Colors.black,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppTheme.primaryGold,
                        labelColor: AppTheme.primaryGold,
                        unselectedLabelColor: Colors.white54,
                        tabs: const [
                          Tab(text: 'ڕووداوەکان'), // Events
                          Tab(text: 'ئامارەکان'),  // Stats
                          Tab(text: 'پێکهاتەکان'), // Lineups
                          Tab(text: 'ڕابردوو'),    // History
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMatchCenterTab(),
                          _buildStatisticsTab(),
                          _buildLineupsTab(),
                          _buildHistoryTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
