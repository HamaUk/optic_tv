import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/world_cup_service.dart';
import '../../widgets/animated_gradient_border.dart';
import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'match_details_screen.dart';
import 'team_details_screen.dart';

class WorldCupScreen extends ConsumerStatefulWidget {
  const WorldCupScreen({super.key});

  @override
  ConsumerState<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends ConsumerState<WorldCupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime(2026, 6, 11);
  List<dynamic> _games = [];
  List<dynamic> _groups = [];
  List<dynamic> _liveSoccer = [];
  List<dynamic> _news = [];
  List<dynamic> _scorers = [];
  bool _isLoading = true;
  bool _isLoadingLive = true;
  bool _isLoadingNews = true;
  bool _isLoadingScorers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
    final data = await WorldCupService.fetchGames(); // Fallback for live
    if (mounted) {
      setState(() {
        _liveSoccer = data;
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
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings(locale);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${s.wcTitle} 2026',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: s.wcTabLive),
            Tab(text: s.wcTabMatches),
            Tab(text: s.wcTabGroups),
            Tab(text: s.wcTabNews),
            Tab(text: s.wcTabScorers),
            Tab(text: s.wcTabTeams),
            Tab(text: s.wcTabVenues),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveSoccerTab(s),
          _buildMatchesTab(s),
          _buildGroupsTab(s),
          _buildNewsTab(s),
          _buildScorersTab(s),
          _buildTeamsTab(s),
          _buildVenuesTab(s),
        ],
      ),
    );
  }

  // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Live Soccer Tab ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

  Widget _buildLiveSoccerTab(AppStrings s) {
    final startDate = DateTime(2026, 6, 11);
    final endDate = DateTime(2026, 7, 19);
    final List<DateTime> tournamentDates = [];
    for (var d = startDate; d.isBefore(endDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
      tournamentDates.add(d);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tournamentDates.length,
              itemBuilder: (context, index) {
                final date = tournamentDates[index];
                final isSelected = _selectedDate.year == date.year && _selectedDate.month == date.month && _selectedDate.day == date.day;
                final monthStr = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][date.month];

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8960E)])
                          : null,
                      color: isSelected ? null : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(monthStr, style: TextStyle(color: isSelected ? Colors.black54 : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(date.day.toString(), style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: _isLoadingLive
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _liveSoccer.isEmpty
                  ? Center(child: Text(s.wcNoMatches, style: const TextStyle(color: Colors.white54)))
                  : RefreshIndicator(
                      color: const Color(0xFFD4AF37),
                      backgroundColor: const Color(0xFF1A1A1A),
                      onRefresh: _loadLiveSoccer,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _liveSoccer.length,
                        itemBuilder: (context, index) {
                          return _buildEspnMatchCard(_liveSoccer[index], s);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEspnMatchCard(dynamic event, AppStrings s) {
    String homeTeam = '';
    String awayTeam = '';
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
          final name = team['shortDisplayName'] ?? team['name'] ?? '';
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

    final bool isLive = state == 'in';
    final bool finished = state == 'post';

    String timeLabel = shortDetail;
    if (isLive && displayClock.isNotEmpty) {
      timeLabel = displayClock;
    } else if (state == 'pre' && event['date'] != null) {
      try {
        final dt = DateTime.parse(event['date']).toLocal();
        final now = DateTime.now();
        final difference = dt.difference(now);
        if (difference.inDays == 0 && difference.inHours > 0) {
          timeLabel = 'In ${difference.inHours}h ${difference.inMinutes % 60}m';
        } else if (difference.inMinutes > 0 && difference.inMinutes < 60) {
          timeLabel = 'In ${difference.inMinutes}m';
        } else {
          timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
      } catch (_) {}
    }

    final Color badgeColor = finished
        ? Colors.white.withOpacity(0.18)
        : isLive
            ? const Color(0xFFD4AF37).withOpacity(0.2)
            : Colors.blue.withOpacity(0.18);
    final Color badgeBorder = finished
        ? Colors.white.withOpacity(0.25)
        : isLive
            ? const Color(0xFFD4AF37)
            : Colors.blueAccent.withOpacity(0.6);
    final Color badgeText = finished
        ? Colors.white60
        : isLive
            ? const Color(0xFFD4AF37)
            : Colors.blueAccent;

    return GestureDetector(
      onTap: () {
        if (event['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MatchDetailsScreen(
                eventId: event['id'],
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                homeFlag: homeFlag,
                awayFlag: awayFlag,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isLive
                  ? const Color(0xFFD4AF37).withOpacity(0.1)
                  : Colors.white.withOpacity(0.04),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLive
                ? const Color(0xFFD4AF37).withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
            width: isLive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? const Color(0xFFD4AF37).withOpacity(0.12)
                  : Colors.black.withOpacity(0.25),
              blurRadius: isLive ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // Top bar: LIVE badge + match name
              Row(
                children: [
                  if (isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.7),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4AF37),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.wcLive,
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (event['shortName'] != null || event['name'] != null)
                    Expanded(
                      child: Text(
                        event['shortName'] ?? event['name'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Teams row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Home team
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(homeFlag),
                        const SizedBox(height: 8),
                        Text(
                          homeTeam,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Score / VS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          state == 'pre'
                              ? 'VS'
                              : '$homeScore - $awayScore',
                          style: TextStyle(
                            color: isLive
                                ? const Color(0xFFD4AF37)
                                : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: badgeBorder, width: 1),
                          ),
                          child: Text(
                            finished
                                ? s.wcFinished
                                : isLive
                                    ? timeLabel
                                    : timeLabel,
                            style: TextStyle(
                              color: badgeText,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Away team
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(awayFlag),
                        const SizedBox(height: 8),
                        Text(
                          awayTeam,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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

  Widget _teamLogo(String url) {
    if (url.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.shield_rounded,
            color: Colors.white24, size: 24),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shield_rounded,
              color: Colors.white24, size: 24),
        ),
      ),
    );
  }

  // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Matches Tab (worldcup26.ir) ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

  Widget _buildMatchesTab(AppStrings s) {
    if (_games.isEmpty) {
      return Center(
        child: Text(s.wcNoMatchesFound,
            style: const TextStyle(color: Colors.white54)));
    }
    return RefreshIndicator(
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(_games[index], s);
        },
      ),
    );
  }

  Widget _buildMatchCard(dynamic game, AppStrings s) {
    final homeTeam =
        game['home_team_name_en'] ?? game['home_team_label'] ?? '';
    final awayTeam =
        game['away_team_name_en'] ?? game['away_team_label'] ?? '';
    final homeFlag = game['home_team_flag'];
    final awayFlag = game['away_team_flag'];
    final homeScore = game['home_score']?.toString() ?? '0';
    final awayScore = game['away_score']?.toString() ?? '0';
    final time = game['time_elapsed'] ?? '';
    final finished =
        game['finished'] == 'TRUE' || game['finished'] == true;
    final isLive = !finished && time != 'notstarted' && time.isNotEmpty;

    // Badge styling
    final Color badgeBg = finished
        ? Colors.white.withOpacity(0.1)
        : isLive
            ? const Color(0xFFD4AF37).withOpacity(0.15)
            : Colors.blue.withOpacity(0.15);
    final Color badgeText = finished
        ? Colors.white54
        : isLive
            ? const Color(0xFFD4AF37)
            : Colors.blueAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: AnimatedGradientBorder(
        borderWidth: 1.2,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: isLive
                ? const Color(0xFFD4AF37).withOpacity(0.05)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              // Home
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        homeTeam,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (homeFlag != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          homeFlag,
                          width: 30,
                          height: 22,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.flag_rounded,
                              color: Colors.white24,
                              size: 20),
                        ),
                      )
                    else
                      const SizedBox(width: 30),
                  ],
                ),
              ),
              // Score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      time == 'notstarted'
                          ? 'VS'
                          : '$homeScore - $awayScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        finished
                            ? s.wcFinished
                            : (time == 'notstarted'
                                ? s.wcUpcoming
                                : time),
                        style: TextStyle(
                          color: badgeText,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Away
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (awayFlag != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          awayFlag,
                          width: 30,
                          height: 22,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.flag_rounded,
                              color: Colors.white24,
                              size: 20),
                        ),
                      )
                    else
                      const SizedBox(width: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        awayTeam,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
        ),
      ),
    );
  }

  // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Groups Tab ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

  Widget _buildGroupsTab(AppStrings s) {
    if (_groups.isEmpty) {
      return Center(
          child: Text(s.wcNoGroups,
              style: const TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14).copyWith(bottom: 100),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final groupName = group['name'] ?? 'Group';
        final teams = group['teams'] as List<dynamic>? ?? [];
        return _buildGroupCard(groupName, teams, s);
      },
    );
  }

  Widget _buildGroupCard(
      String groupName, List<dynamic> teams, AppStrings s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.07),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.09), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.15),
                  const Color(0xFFD4AF37).withOpacity(0.04)
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFB8960E)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  s.wcGroupStandings,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04)),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text(s.wcTeam,
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 1,
                    child: Text('MP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 1,
                    child: Text('W',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 1,
                    child: Text('D',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 1,
                    child: Text('L',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 1,
                    child: Text('Pts',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 11,
                            fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          ...teams.asMap().entries.map((entry) {
            return _buildTeamRow(entry.value, entry.key < 2);
          }),
        ],
      ),
    );
  }

  Widget _buildTeamRow(dynamic team, bool isTop) {
    final name = team['team_name_en'] ?? '';
    final flag = team['team_flag'];
    final mp = team['mp'] ?? '0';
    final w = team['w'] ?? '0';
    final d = team['d'] ?? '0';
    final l = team['l'] ?? '0';
    final pts = team['pts'] ?? '0';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isTop
            ? const Color(0xFFD4AF37).withOpacity(0.08)
            : Colors.transparent,
        border: isTop
            ? const Border(
                left: BorderSide(color: Color(0xFFD4AF37), width: 3))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (isTop)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.arrow_upward_rounded,
                        color: Color(0xFFD4AF37), size: 14),
                  ),
                if (flag != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      flag,
                      width: 26,
                      height: 18,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.flag_rounded,
                          color: Colors.white24,
                          size: 16),
                    ),
                  )
                else
                  const SizedBox(width: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isTop
                          ? const Color(0xFFD4AF37)
                          : Colors.white,
                      fontWeight: isTop
                          ? FontWeight.w800
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              flex: 1,
              child: Text(mp.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13))),
          Expanded(
              flex: 1,
              child: Text(w.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13))),
          Expanded(
              flex: 1,
              child: Text(d.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13))),
          Expanded(
              flex: 1,
              child: Text(l.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13))),
          Expanded(
            flex: 1,
            child: Text(
              pts.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isTop ? const Color(0xFFD4AF37) : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ News Tab ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

  Widget _buildNewsTab(AppStrings s) {
    if (_isLoadingNews) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    if (_news.isEmpty) {
      return Center(
          child: Text(s.wcNoNews,
              style: const TextStyle(color: Colors.white54)));
    }
    return RefreshIndicator(
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(14).copyWith(bottom: 100),
        itemCount: _news.length,
        itemBuilder: (context, index) {
          return _buildNewsCard(_news[index], s);
        },
      ),
    );
  }

  Widget _buildNewsCard(dynamic article, AppStrings s) {
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
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.07),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 5)),
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
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.03)
                          ],
                        ),
                      ),
                      child: const Icon(Icons.article_rounded,
                          color: Colors.white12, size: 36),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFB8960E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        s.wcNewsLabel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: Colors.white30, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        published.isNotEmpty
                            ? _formatNewsDate(published, s)
                            : s.wcRecently,
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded,
                          color: const Color(0xFFD4AF37).withOpacity(0.6),
                          size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNewsDate(String dateStr, AppStrings s) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      return s.wcTimeAgo(diff.inMinutes);
    } catch (_) {
      return s.wcRecently;
    }
  }

  // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Scorers Tab ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

  Widget _buildScorersTab(AppStrings s) {
    if (_isLoadingScorers) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    if (_scorers.isEmpty) {
      return Center(
          child: Text(s.wcNoScorers,
              style: const TextStyle(color: Colors.white54)));
    }
    return RefreshIndicator(
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadScorers,
      child: ListView.builder(
        padding: const EdgeInsets.all(14).copyWith(bottom: 100),
        itemCount: _scorers.length,
        itemBuilder: (context, index) {
          return _buildScorerCard(_scorers[index], index, s);
        },
      ),
    );
  }

  Widget _buildScorerCard(
      dynamic scorer, int index, AppStrings s) {
    final athlete = scorer['athlete'] ?? {};
    final team = athlete['team'] ?? {};
    final name = athlete['displayName'] ?? '';
    final headshot = athlete['headshot']?['href'] ?? '';
    final goals = scorer['value']?.toString() ?? '0';
    final teamLogo =
        team['logos'] != null && (team['logos'] as List).isNotEmpty
            ? team['logos'][0]['href']
            : '';

    final isTop3 = index < 3;
    final Color rankColor = index == 0
        ? const Color(0xFFD4AF37)
        : (index == 1
            ? const Color(0xFFB0B0B0)
            : const Color(0xFFCD7F32));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTop3
              ? [rankColor.withOpacity(0.15), rankColor.withOpacity(0.04)]
              : [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02)
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTop3
              ? rankColor.withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
          width: isTop3 ? 1.5 : 1,
        ),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: rankColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Rank
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isTop3
                      ? [rankColor, rankColor.withOpacity(0.6)]
                      : [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.04)
                        ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: isTop3 ? Colors.black : Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTop3 ? rankColor : Colors.white.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: headshot.isNotEmpty
                    ? Image.network(
                        headshot,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white24),
                      )
                    : const Icon(Icons.person_rounded,
                        color: Colors.white24),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isTop3 ? rankColor : Colors.white,
                      fontSize: 15,
                      fontWeight: isTop3
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (teamLogo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.network(
                          teamLogo,
                          height: 16,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            team['displayName'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Goals badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFB8960E)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    goals,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    s.wcGoals,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTeamsTab(AppStrings s) {
    return FutureBuilder<List<dynamic>>(
      future: WorldCupService.fetchTeamsList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }
        final teams = snapshot.data ?? [];
        if (teams.isEmpty) return Center(child: Text(s.wcNoTeams, style: const TextStyle(color: Colors.white54)));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index]['team'] ?? {};
            final id = team['id'] ?? '';
            final name = team['shortDisplayName'] ?? '';
            final logo = team['logos'] != null && team['logos'].isNotEmpty ? team['logos'][0]['href'] : '';

            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailsScreen(
                  teamId: id, teamName: name, teamFlag: logo
                )));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'team_logo_$id',
                      child: logo.isNotEmpty 
                          ? Image.network(logo, width: 48, height: 48, errorBuilder: (_,__,___) => const Icon(Icons.flag, color: Colors.white54))
                          : const Icon(Icons.flag, color: Colors.white54, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVenuesTab(AppStrings s) {
    final venues = [
      {'name': 'Estadio Azteca', 'city': 'Mexico City', 'cap': '83,264', 'img': 'https://a.espncdn.com/i/venues/soccer/day/87.jpg'},
      {'name': 'MetLife Stadium', 'city': 'New York / New Jersey', 'cap': '82,500', 'img': 'https://a.espncdn.com/i/venues/soccer/day/259.jpg'},
      {'name': 'AT&T Stadium', 'city': 'Dallas', 'cap': '80,000', 'img': 'https://a.espncdn.com/i/venues/nfl/day/211.jpg'},
      {'name': 'Arrowhead Stadium', 'city': 'Kansas City', 'cap': '76,416', 'img': 'https://a.espncdn.com/i/venues/nfl/day/3494.jpg'},
      {'name': 'NRG Stadium', 'city': 'Houston', 'cap': '72,220', 'img': 'https://a.espncdn.com/i/venues/nfl/day/3482.jpg'},
      {'name': 'Mercedes-Benz Stadium', 'city': 'Atlanta', 'cap': '71,000', 'img': 'https://a.espncdn.com/i/venues/nfl/day/3482.jpg'},
      {'name': 'SoFi Stadium', 'city': 'Los Angeles', 'cap': '70,240', 'img': 'https://a.espncdn.com/i/venues/nfl/day/259.jpg'},
      {'name': 'Lincoln Financial Field', 'city': 'Philadelphia', 'cap': '69,796', 'img': 'https://a.espncdn.com/i/venues/nfl/day/3482.jpg'},
      {'name': 'Lumen Field', 'city': 'Seattle', 'cap': '69,000', 'img': 'https://a.espncdn.com/i/venues/nfl/day/3494.jpg'},
      {'name': "Levi's Stadium", 'city': 'San Francisco', 'cap': '68,500', 'img': 'https://a.espncdn.com/i/venues/nfl/day/259.jpg'},
      {'name': 'Gillette Stadium', 'city': 'Boston', 'cap': '65,878', 'img': 'https://a.espncdn.com/i/venues/nfl/day/3494.jpg'},
      {'name': 'Hard Rock Stadium', 'city': 'Miami', 'cap': '64,767', 'img': 'https://a.espncdn.com/i/venues/nfl/day/259.jpg'},
      {'name': 'BC Place', 'city': 'Vancouver', 'cap': '54,500', 'img': 'https://a.espncdn.com/i/venues/soccer/day/87.jpg'},
      {'name': 'Estadio BBVA', 'city': 'Monterrey', 'cap': '53,500', 'img': 'https://a.espncdn.com/i/venues/soccer/day/87.jpg'},
      {'name': 'Estadio Akron', 'city': 'Guadalajara', 'cap': '49,850', 'img': 'https://a.espncdn.com/i/venues/soccer/day/87.jpg'},
      {'name': 'BMO Field', 'city': 'Toronto', 'cap': '30,000', 'img': 'https://a.espncdn.com/i/venues/soccer/day/87.jpg'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: venues.length,
      itemBuilder: (context, index) {
        final v = venues[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
              image: NetworkImage(v['img']!),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
            ),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(v['city']!, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
              const SizedBox(height: 4),
              Text(v['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
              const SizedBox(height: 4),
              Text(s.wcCapacity + ": ${v['cap']}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}


