import 'package:flutter/material.dart';
import '../../services/world_cup_service.dart';

class WorldCupScreen extends StatefulWidget {
  const WorldCupScreen({super.key});

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _games = [];
  List<dynamic> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final games = await WorldCupService.fetchGames();
    final groups = await WorldCupService.fetchGroups();
    
    if (mounted) {
      setState(() {
        _games = games;
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'World Cup 2026',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'MATCHES'),
            Tab(text: 'GROUPS'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildMatchesTab(),
              _buildGroupsTab(),
            ],
          ),
    );
  }

  Widget _buildMatchesTab() {
    if (_games.isEmpty) {
      return const Center(child: Text('No matches found.', style: TextStyle(color: Colors.white70)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
        return _buildMatchCard(game);
      },
    );
  }

  Widget _buildMatchCard(dynamic game) {
    final homeTeam = game['home_team_name_en'] ?? 'Unknown';
    final awayTeam = game['away_team_name_en'] ?? 'Unknown';
    final homeScore = game['home_score']?.toString() ?? '0';
    final awayScore = game['away_score']?.toString() ?? '0';
    final time = game['time_elapsed'] ?? '';
    final finished = game['finished'] == 'TRUE';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              homeTeam,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '$homeScore - $awayScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  finished ? 'FT' : (time.isEmpty ? 'Upcoming' : time),
                  style: TextStyle(
                    color: finished ? Colors.white54 : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              awayTeam,
              textAlign: TextAlign.start,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    if (_groups.isEmpty) {
      return const Center(child: Text('No groups found.', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final groupName = group['group_name'] ?? 'Group';
        final teams = group['teams'] as List<dynamic>? ?? [];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  groupName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // Table header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Team', style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(flex: 1, child: Text('MP', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(flex: 1, child: Text('D', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(flex: 1, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(flex: 1, child: Text('Pts', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              ...teams.map((t) => _buildTeamRow(t)).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamRow(dynamic team) {
    final name = team['team_name_en'] ?? 'Unknown';
    final mp = team['matches_played'] ?? '0';
    final w = team['won'] ?? '0';
    final d = team['drawn'] ?? '0';
    final l = team['lost'] ?? '0';
    final pts = team['points'] ?? '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text(mp.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 1, child: Text(w.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 1, child: Text(d.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 1, child: Text(l.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 1, child: Text(pts.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
