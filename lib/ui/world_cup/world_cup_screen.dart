import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/world_cup_service.dart';
import '../../widgets/animated_gradient_border.dart';
import '../../core/theme.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<dynamic> _news = [];
  List<dynamic> _scorers = [];
  bool _isLoading = true;
  bool _isLoadingLive = true;
  bool _isLoadingNews = true;
  bool _isLoadingScorers = true;
  int _selectedDayOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _loadLiveSoccer();
    _loadNews();
    _loadScorers();
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

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);
    final news = await WorldCupService.fetchNews();
    if (mounted) {
      setState(() {
        _news = news;
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _loadScorers() async {
    setState(() => _isLoadingScorers = true);
    final scorers = await WorldCupService.fetchTopScorers();
    if (mounted) {
      setState(() {
        _scorers = scorers;
        _isLoadingScorers = false;
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
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black,
                        AppTheme.primaryGold.withOpacity(0.3),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryGold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.sports_soccer,
                                  color: AppTheme.primaryGold,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'FIFA World Cup',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '2026',
                                  style: TextStyle(
                                    color: AppTheme.primaryGold,
                                    fontSize: 42,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6,
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
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryGold,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                isScrollable: true,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'ڕاستەوخۆ'),
                  Tab(text: 'یارییەکان'),
                  Tab(text: 'گروپەکان'),
                  Tab(text: 'هەواڕەکان'),
                  Tab(text: 'گۆڵکاران'),
                ],
              ),
            ),
          ];
        },
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLiveSoccerTab(),
                _buildMatchesTab(),
                _buildGroupsTab(),
                _buildNewsTab(),
                _buildScorersTab(),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? LinearGradient(colors: [AppTheme.primaryGold, AppTheme.primaryGold.withOpacity(0.8)])
            : null,
          color: isSelected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : Colors.white.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: AppTheme.primaryGold.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 13,
            letterSpacing: 0.5,
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
    final state = type['state'] ?? 'pre';
    final displayClock = status['displayClock'] ?? '';
    final shortDetail = type['shortDetail'] ?? '';
    
    bool isLive = state == 'in';
    bool finished = state == 'post';

    String timeLabel = shortDetail;
    if (isLive && displayClock.isNotEmpty) {
      timeLabel = displayClock;
    } else if (state == 'pre' && event['date'] != null) {
      try {
        final dt = DateTime.parse(event['date']).toLocal();
        final hr = dt.hour.toString().padLeft(2, '0');
        final mn = dt.minute.toString().padLeft(2, '0');
        timeLabel = '$hr:$mn';
      } catch (_) {}
    }

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isLive 
                ? AppTheme.primaryGold.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLive 
              ? AppTheme.primaryGold 
              : Colors.white.withOpacity(0.1),
            width: isLive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive 
                ? AppTheme.primaryGold.withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
              blurRadius: isLive ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (event['name'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event['shortName'] ?? event['name'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (homeFlag.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              homeFlag,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.shield, color: Colors.white54),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield, color: Colors.white54),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          homeTeam,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          state == 'pre' ? 'VS' : '$homeScore - $awayScore',
                          style: TextStyle(
                            color: isLive ? AppTheme.primaryGold : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: finished 
                              ? Colors.white.withOpacity(0.1)
                              : (state == 'pre' 
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: finished 
                                ? Colors.white.withOpacity(0.2)
                                : (state == 'pre' 
                                    ? Colors.blue.withOpacity(0.5)
                                    : Colors.red.withOpacity(0.5)),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            timeLabel,
                            style: TextStyle(
                              color: finished 
                                ? Colors.white70
                                : (state == 'pre' 
                                    ? Colors.blueAccent
                                    : Colors.redAccent),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (awayFlag.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              awayFlag,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.shield, color: Colors.white54),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield, color: Colors.white54),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          awayTeam,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final groupName = group['name'] ?? 'Group';
        final teams = group['teams'] as List<dynamic>? ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGold.withOpacity(0.2), AppTheme.primaryGold.withOpacity(0.05)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        groupName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Group Standings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('Team', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('MP', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('D', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Pts', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
              ...teams.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final isTop = idx < 2; // Top 2 teams qualify
                return _buildTeamRow(t, isTop);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamRow(dynamic team, bool isTop) {
    final name = team['team_name_en'] ?? 'Unknown';
    final flag = team['team_flag'];
    final mp = team['mp'] ?? '0';
    final w = team['w'] ?? '0';
    final d = team['d'] ?? '0';
    final l = team['l'] ?? '0';
    final pts = team['pts'] ?? '0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isTop ? AppTheme.primaryGold.withOpacity(0.1) : Colors.transparent,
        border: isTop 
          ? Border(left: BorderSide(color: AppTheme.primaryGold, width: 3))
          : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4, 
            child: Row(
              children: [
                if (isTop)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.arrow_upward,
                      color: AppTheme.primaryGold,
                      size: 16,
                    ),
                  ),
                if (flag != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      flag, 
                      width: 28, 
                      height: 20, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 28,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.flag, color: Colors.white54, size: 14),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name, 
                    style: TextStyle(
                      color: isTop ? AppTheme.primaryGold : Colors.white,
                      fontWeight: isTop ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                    ), 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          ),
          Expanded(flex: 1, child: Text(mp.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Expanded(flex: 1, child: Text(w.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Expanded(flex: 1, child: Text(d.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Expanded(flex: 1, child: Text(l.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Expanded(
            flex: 1, 
            child: Text(
              pts.toString(), 
              textAlign: TextAlign.center, 
              style: TextStyle(
                color: isTop ? AppTheme.primaryGold : Colors.white,
                fontWeight: FontWeight.w900, 
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    if (_isLoadingNews) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    if (_news.isEmpty) return const Center(child: Text('هەواڕ بەردەست نییە', style: TextStyle(color: Colors.white70)));

    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: _news.length,
      itemBuilder: (context, index) {
        final article = _news[index];
        final headline = article['headline'] ?? '';
        final description = article['description'] ?? '';
        final images = article['images'] as List<dynamic>? ?? [];
        final imageUrl = images.isNotEmpty ? images.first['url'] : '';
        final link = article['links']?['web']?['href'];
        final published = article['published'] ?? '';

        return GestureDetector(
          onTap: () async {
            if (link != null) {
              final url = Uri.parse(link);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                            ),
                          ),
                          child: const Icon(Icons.article, color: Colors.white24, size: 48),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NEWS',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline, 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description, 
                        maxLines: 3, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6), 
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white38,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            published.isNotEmpty 
                              ? _formatNewsDate(published)
                              : 'Recently',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward,
                            color: AppTheme.primaryGold.withOpacity(0.7),
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatNewsDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (_) {
      return 'Recently';
    }
  }

  Widget _buildScorersTab() {
    if (_isLoadingScorers) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    if (_scorers.isEmpty) return const Center(child: Text('هیچ زانیارییەک بەردەست نییە', style: TextStyle(color: Colors.white70)));

    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: _scorers.length,
      itemBuilder: (context, index) {
        final scorer = _scorers[index];
        final athlete = scorer['athlete'] ?? {};
        final team = athlete['team'] ?? {};
        
        final name = athlete['displayName'] ?? 'Unknown';
        final headshot = athlete['headshot']?['href'] ?? '';
        final goals = scorer['value']?.toString() ?? '0';
        final teamLogo = team['logos'] != null && (team['logos'] as List).isNotEmpty ? team['logos'][0]['href'] : '';
        
        final isTop3 = index < 3;
        final rankColor = index == 0 
          ? AppTheme.primaryGold 
          : (index == 1 ? Colors.grey[400] : Colors.brown[400]);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isTop3
                ? [
                    rankColor!.withOpacity(0.2),
                    rankColor.withOpacity(0.05),
                  ]
                : [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTop3 
                ? rankColor!.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
              width: isTop3 ? 2 : 1,
            ),
            boxShadow: isTop3
              ? [
                  BoxShadow(
                    color: rankColor!.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isTop3 
                        ? [rankColor!, rankColor.withOpacity(0.6)]
                        : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTop3 ? rankColor! : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: isTop3 ? Colors.black : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Player Avatar
                if (headshot.isNotEmpty)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isTop3 ? rankColor! : Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        headshot,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white54),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.person, color: Colors.white54),
                  ),
                const SizedBox(width: 16),
                // Player Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name, 
                        style: TextStyle(
                          color: isTop3 ? rankColor : Colors.white,
                          fontSize: 16,
                          fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (teamLogo.isNotEmpty)
                        Row(
                          children: [
                            Image.network(
                              teamLogo,
                              height: 18,
                              errorBuilder: (c, e, s) => const SizedBox(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              team['displayName'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Goals
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryGold, AppTheme.primaryGold.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        goals,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Goals',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
