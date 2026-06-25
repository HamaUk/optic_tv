import 'package:flutter/material.dart';
import '../../services/world_cup_service.dart';
import '../../widgets/animated_gradient_border.dart';
import 'match_details_screen.dart';

class WorldCupScreen extends StatefulWidget {
  const WorldCupScreen({super.key});

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _games = [];
  List<dynamic> _groups = [];
  List<dynamic> _liveSoccer = [];
  bool _isLoading = true;
  bool _isLoadingLive = true;
  int _selectedDayOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _loadLiveSoccer();
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

  Future<void> _loadLiveSoccer() async {
    setState(() => _isLoadingLive = true);
    final targetDate = DateTime.now().add(Duration(days: _selectedDayOffset));
    final liveSoccer = await WorldCupService.fetchLiveSoccerForDate(targetDate);
    
    if (mounted) {
      setState(() {
        _liveSoccer = liveSoccer;
        _isLoadingLive = false;
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
          'جامی جیهانی 2026',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'ڕاستەوخۆ'),
            Tab(text: 'یارییەکان'),
            Tab(text: 'گروپەکان'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildLiveSoccerTab(),
              _buildMatchesTab(),
              _buildGroupsTab(),
            ],
          ),
    );
  }

  Widget _buildLiveSoccerTab() {
    return Column(
      children: [
        // Date Selector Toggle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDateToggle(0, 'ئەمڕۆ (Today)'),
              const SizedBox(width: 8),
              _buildDateToggle(1, 'سبەی (Tomorrow)'),
              const SizedBox(width: 8),
              _buildDateToggle(2, 'دواتر (Next)'),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoadingLive
              ? const Center(child: CircularProgressIndicator())
              : _liveSoccer.isEmpty
                  ? const Center(child: Text('هیچ یارییەک نییە لەم بەروارەدا', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _liveSoccer.length,
                      itemBuilder: (context, index) {
                        final event = _liveSoccer[index];
                        return _buildEspnMatchCard(event);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDateToggle(int offset, String label) {
    final isSelected = _selectedDayOffset == offset;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _selectedDayOffset = offset);
          _loadLiveSoccer();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEspnMatchCard(dynamic event) {
    String homeTeam = 'Unknown';
    String awayTeam = 'Unknown';
    String homeFlag = '';
    String awayFlag = '';
    String homeScore = '0';
    String awayScore = '0';

    try {
      final competitions = event['competitions'] as List<dynamic>? ?? [];
      if (competitions.isNotEmpty) {
        final competitors = competitions[0]['competitors'] as List<dynamic>? ?? [];
        for (var c in competitors) {
          final isHome = c['homeAway'] == 'home';
          final team = c['team'] ?? {};
          final name = team['shortDisplayName'] ?? team['name'] ?? 'Unknown';
          final logo = team['logo'] ?? '';
          final score = c['score'] ?? '0';
          
          if (isHome) {
            homeTeam = name;
            homeFlag = logo;
            homeScore = score;
          } else {
            awayTeam = name;
            awayFlag = logo;
            awayScore = score;
          }
        }
      }
    } catch (_) {}

    final status = event['status'] ?? {};
    final type = status['type'] ?? {};
    final state = type['state'] ?? 'pre'; // pre, in, post
    final displayClock = status['displayClock'] ?? '';
    final shortDetail = type['shortDetail'] ?? '';
    
    bool isLive = state == 'in';
    bool finished = state == 'post';

    String timeLabel = shortDetail;
    if (isLive && displayClock.isNotEmpty) timeLabel = displayClock;

    return GestureDetector(
      onTap: () {
        if (event['id'] != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MatchDetailsScreen(
              eventId: event['id'],
              homeTeam: homeTeam,
              awayTeam: awayTeam,
              homeFlag: homeFlag,
              awayFlag: awayFlag,
            ),
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedGradientBorder(
          borderWidth: isLive ? 3.0 : 1.5,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
          if (event['name'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                event['shortName'] ?? event['name'],
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        homeTeam,
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (homeFlag.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(homeFlag, width: 32, height: 32, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: Colors.white54),
                        ),
                      )
                    else
                      const SizedBox(width: 32),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      state == 'pre' ? 'VS' : '$homeScore - $awayScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: finished ? Colors.white24 : (state == 'pre' ? Colors.blueAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeLabel,
                        style: TextStyle(
                          color: finished ? Colors.white : (state == 'pre' ? Colors.blueAccent : Colors.redAccent),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (awayFlag.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(awayFlag, width: 32, height: 32, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: Colors.white54),
                        ),
                      )
                    else
                      const SizedBox(width: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        awayTeam,
                        textAlign: TextAlign.start,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
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
    final homeTeam = game['home_team_name_en'] ?? game['home_team_label'] ?? 'Unknown';
    final awayTeam = game['away_team_name_en'] ?? game['away_team_label'] ?? 'Unknown';
    final homeFlag = game['home_team_flag'];
    final awayFlag = game['away_team_flag'];
    final homeScore = game['home_score']?.toString() ?? '0';
    final awayScore = game['away_score']?.toString() ?? '0';
    final time = game['time_elapsed'] ?? '';
    final finished = game['finished'] == 'TRUE' || game['finished'] == true;

    return GestureDetector(
      onTap: () {
        // worldcup26.ir doesn't have a reliable match summary endpoint in ESPN, 
        // but if we had the ESPN ID here, we could pass it. 
        // For now, we will just open the MatchDetailsScreen which might say "Data not available" if eventId isn't found in ESPN.
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedGradientBorder(
          borderWidth: 1.5,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    homeTeam,
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                if (homeFlag != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(homeFlag, width: 32, height: 24, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, color: Colors.white54),
                    ),
                  )
                else
                  const SizedBox(width: 32),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  time == 'notstarted' ? 'VS' : '$homeScore - $awayScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: finished ? Colors.white24 : (time == 'notstarted' ? Colors.blueAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    finished ? 'FT' : (time == 'notstarted' ? 'Upcoming' : time),
                    style: TextStyle(
                      color: finished ? Colors.white : (time == 'notstarted' ? Colors.blueAccent : Colors.redAccent),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (awayFlag != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(awayFlag, width: 32, height: 24, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, color: Colors.white54),
                    ),
                  )
                else
                  const SizedBox(width: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    awayTeam,
                    textAlign: TextAlign.start,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
              ],
            ),
          ),
        ),
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
        final groupName = group['name'] ?? 'Group';
        final teams = group['teams'] as List<dynamic>? ?? [];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Group $groupName',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // Table header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text('Team', style: TextStyle(color: Colors.white54, fontSize: 13))),
                    Expanded(flex: 1, child: Text('MP', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13))),
                    Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13))),
                    Expanded(flex: 1, child: Text('D', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13))),
                    Expanded(flex: 1, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13))),
                    Expanded(flex: 1, child: Text('Pts', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold))),
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
    final flag = team['team_flag'];
    final mp = team['mp'] ?? '0';
    final w = team['w'] ?? '0';
    final d = team['d'] ?? '0';
    final l = team['l'] ?? '0';
    final pts = team['pts'] ?? '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4, 
            child: Row(
              children: [
                if (flag != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(flag, width: 24, height: 16, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, color: Colors.white54, size: 16),
                    ),
                  )
                else
                  const SizedBox(width: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                ),
              ],
            )
          ),
          Expanded(flex: 1, child: Text(mp.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 1, child: Text(w.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 1, child: Text(d.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 1, child: Text(l.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 1, child: Text(pts.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
    );
  }
}
