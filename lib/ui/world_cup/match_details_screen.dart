import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/world_cup_service.dart';

class MatchDetailsScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends ConsumerState<MatchDetailsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _probabilities;
  Timer? _pollingTimer;
  int _activeTab = 0; // 0: Summary, 1: Stats, 2: Lineups, 3: H2H

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchSummary());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    final data = await WorldCupService.fetchMatchSummary(widget.eventId);
    final probs = await WorldCupService.fetchMatchProbabilities(widget.eventId);
    if (mounted) {
      setState(() {
        _summary = data;
        _probabilities = probs;
        _loading = false;
      });
    }
  }  @override
  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings(locale);
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _summary == null
              ? const Center(child: Text("Data not available", style: TextStyle(color: Colors.white)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeaderBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 20),
                    _buildScoreCard(),
                    const SizedBox(height: 20),
                    _buildTabs(),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: _buildActiveTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD4AF37), // Gold
            Colors.black,
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Column(
            children: [
              Text("FIFA World Cup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Match Details", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final boxscore = _summary?['boxscore'] ?? {};
    final teams = boxscore['teams'] as List<dynamic>? ?? [];
    
    Map<String, dynamic> homeTeamData = {};
    Map<String, dynamic> awayTeamData = {};
    
    for (var t in teams) {
      if (t['homeAway'] == 'home') homeTeamData = t;
      if (t['homeAway'] == 'away') awayTeamData = t;
    }

    final header = _summary?['header'] ?? {};
    final competitions = header['competitions'] as List<dynamic>? ?? [];
    String state = 'pre';
    String timeLabel = '';
    
    if (competitions.isNotEmpty) {
      final status = competitions[0]['status'] ?? {};
      final type = status['type'] ?? {};
      state = type['state'] ?? 'pre';
      timeLabel = status['displayClock'] ?? type['shortDetail'] ?? '';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTeamColumn(widget.homeTeam, widget.homeFlag),
          Column(
            children: [
              Text(
                state == 'pre' ? 'VS' : "${homeTeamData['score'] ?? '0'} - ${awayTeamData['score'] ?? '0'}",
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: state == 'in' ? Colors.redAccent.withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    color: state == 'in' ? Colors.redAccent : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          _buildTeamColumn(widget.awayTeam, widget.awayFlag),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(String name, String? flagUrl) {
    return Expanded(
      child: Column(
        children: [
          if (flagUrl != null && flagUrl.isNotEmpty)
            Image.network(flagUrl, width: 48, height: 48, errorBuilder: (_,__,___) => const Icon(Icons.flag, color: Colors.white54, size: 48))
          else
            const Icon(Icons.flag, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTab(0, s.wcSummary),
          _buildTab(1, s.wcTabScorers),
          _buildTab(2, "Lineups"),
          _buildTab(3, "H2H"),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0: return _buildSummaryTab(s);
      case 1: return _buildStatsTab(s);
      case 2: return _buildLineupsTab();
      case 3: return _buildH2HTab();
      default: return const SizedBox();
    }
  }

  // --- TAB CONTENTS ---

  Widget _buildSummaryTab(AppStrings s) {
    final gameInfo = _summary?['gameInfo'] ?? {};
    final venue = gameInfo['venue'] ?? {};
    final venueName = venue['fullName'] ?? 'Unknown Venue';
    
    final officials = gameInfo['officials'] as List<dynamic>? ?? [];
    String referee = 'Unknown Referee';
    if (officials.isNotEmpty) {
      referee = officials[0]['fullName'] ?? 'Unknown Referee';
    }

    final keyEvents = _summary?['keyEvents'] as List<dynamic>? ?? [];

    double homeProb = _probabilities?['homeWinPercentage'] ?? 0.0;
    double awayProb = _probabilities?['awayWinPercentage'] ?? 0.0;
    double drawProb = _probabilities?['tiePercentage'] ?? 0.0;
    
    // If we have actual probabilities, build the widget
    Widget winProbWidget = const SizedBox();
    if (homeProb > 0 || awayProb > 0) {
       homeProb = homeProb * 100;
       awayProb = awayProb * 100;
       drawProb = drawProb * 100;
       winProbWidget = Container(
         margin: const EdgeInsets.only(bottom: 24),
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFF1A1A1A),
           borderRadius: BorderRadius.circular(16),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(s.wcLiveWinProbability, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 12),
             Row(
               children: [
                 Expanded(flex: homeProb.toInt(), child: Container(height: 8, decoration: const BoxDecoration(color: Color(0xFF4F9A44), borderRadius: BorderRadius.horizontal(left: Radius.circular(4))))),
                 Expanded(flex: drawProb.toInt(), child: Container(height: 8, color: Colors.grey)),
                 Expanded(flex: awayProb.toInt(), child: Container(height: 8, decoration: const BoxDecoration(color: Color(0xFFD4AF37), borderRadius: BorderRadius.horizontal(right: Radius.circular(4))))),
               ],
             ),
             const SizedBox(height: 8),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("${homeProb.toStringAsFixed(1)}% (H)", style: const TextStyle(color: Color(0xFF4F9A44), fontSize: 12, fontWeight: FontWeight.bold)),
                 Text("${drawProb.toStringAsFixed(1)}% (Draw)", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                 Text("${awayProb.toStringAsFixed(1)}% (A)", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
               ],
             )
           ],
         ),
       );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        winProbWidget,
        Row(
          children: [
            Expanded(child: _buildInfoCard(Icons.stadium, "Venue", venueName)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard(Icons.sports, "Referee", referee)),
          ],
        ),
        const SizedBox(height: 24),
        const Text("Match Events", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (keyEvents.isEmpty)
          const Text("No events yet.", style: TextStyle(color: Colors.white54))
        else
          ...keyEvents.map((e) => _buildEventItem(e)).toList(),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEventItem(dynamic event) {
    final clock = event['clock']?['displayValue'] ?? '';
    final type = event['type']?['text'] ?? '';
    final detail = event['shortText'] ?? '';
    
    IconData icon = Icons.sports_soccer;
    Color iconColor = Colors.white;
    if (type.toString().toLowerCase().contains('goal')) {
      iconColor = const Color(0xFFD4AF37);
    } else if (type.toString().toLowerCase().contains('yellow')) {
      icon = Icons.style;
      iconColor = Colors.yellow;
    } else if (type.toString().toLowerCase().contains('red')) {
      icon = Icons.style;
      iconColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(clock, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ),
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(detail, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(AppStrings s) {
    final boxscore = _summary?['boxscore'] ?? {};
    final teams = boxscore['teams'] as List<dynamic>? ?? [];
    if (teams.length < 2) return const Center(child: Text("Stats not available", style: TextStyle(color: Colors.white54)));

    final team1 = teams[0];
    final team2 = teams[1];
    
    final t1Stats = team1['statistics'] as List<dynamic>? ?? [];
    final t2Stats = team2['statistics'] as List<dynamic>? ?? [];
    
    final team1Name = team1['team']?['shortDisplayName'] ?? '';
    final team2Name = team2['team']?['shortDisplayName'] ?? '';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(team1Name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const Text("VS", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            Expanded(child: Text(team2Name, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < t1Stats.length; i++)
          _buildStatRow(t1Stats[i], t2Stats.length > i ? t2Stats[i] : {}),
      ],
    );
  }

  Widget _buildStatRow(dynamic s1, dynamic s2) {
    final label = s1['label'] ?? '';
    final v1 = s1['displayValue'] ?? '0';
    final v2 = s2['displayValue'] ?? '0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(v1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(v2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: int.tryParse(v1.replaceAll('%', '')) ?? 1,
                child: Container(height: 6, decoration: const BoxDecoration(color: Color(0xFFD4AF37), borderRadius: BorderRadius.horizontal(left: Radius.circular(3)))),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: int.tryParse(v2.replaceAll('%', '')) ?? 1,
                child: Container(height: 6, decoration: const BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.horizontal(right: Radius.circular(3)))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineupsTab() {
    final rosters = _summary?['rosters'] as List<dynamic>? ?? [];
    if (rosters.isEmpty) return const Center(child: Text("Lineups not available", style: TextStyle(color: Colors.white54)));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rosters.map((roster) {
        final teamName = roster['team']?['shortDisplayName'] ?? '';
        final rosterList = roster['roster'] as List<dynamic>? ?? [];
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(teamName, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...rosterList.map((player) {
                final ath = player['athlete'] ?? {};
                final name = ath['shortName'] ?? ath['displayName'] ?? '';
                final jersey = ath['jersey'] ?? '';
                final isStarter = player['starter'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: Text(jersey, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: isStarter ? Colors.white : Colors.white70,
                            fontWeight: isStarter ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildH2HTab() {
    return const Center(
      child: Text("Head-to-Head data not available from this provider.", style: TextStyle(color: Colors.white54)),
    );
  }
}






