import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/world_cup_service.dart';
import '../../widgets/animated_gradient_border.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:translator/translator.dart';
import 'match_details_screen.dart';
import '../../services/playlist_service.dart';
import '../player/movie_player_page.dart';
import '../../services/optic_player.dart';

class WorldCupScreen extends ConsumerStatefulWidget {
  const WorldCupScreen({super.key});

  @override
  ConsumerState<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends ConsumerState<WorldCupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayOffset = 0; // -1 = Yesterday, 0 = Today, 1 = Tomorrow
  List<dynamic> _groups = [];
  List<dynamic> _liveSoccer = [];
  List<dynamic> _news = [];
  List<dynamic> _scorers = [];
  List<dynamic> _highlights = [];
  bool _isLoading = true;
  bool _isLoadingLive = true;
  bool _isLoadingNews = true;
  bool _isLoadingScorers = true;
  bool _isLoadingHighlights = true;
  String _activeHighlightFilter = 'all'; // 'all', 'highlight', 'goal'

  @override
  void initState() {
    super.initState();
    // 5 Tabs: Matches (Combined), Highlights, Groups, News, Scorers (Stats)
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _loadLiveSoccerForOffset(_selectedDayOffset);
    _loadNews();
    _loadScorers();
    _loadHighlights();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final groups = await WorldCupService.fetchGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLiveSoccerForOffset(int offset) async {
    setState(() => _isLoadingLive = true);
    final targetDate = DateTime.now().add(Duration(days: offset));
    final data = await WorldCupService.fetchLiveSoccerForDate(targetDate);
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

  Future<void> _loadHighlights() async {
    setState(() => _isLoadingHighlights = true);
    final highlights = await WorldCupService.fetchEventVideos(page: 1, limit: 100);
    
    if (mounted) {
      setState(() {
        _highlights = highlights;
        _isLoadingHighlights = false;
      });
    }

    final locale = ref.read(appLocaleProvider);
    if (locale.languageCode == 'ku') {
       final translator = GoogleTranslator();
       for (var i = 0; i < highlights.length; i++) {
         final title = highlights[i]['title'];
         if (title != null && title is String && title.isNotEmpty) {
            translator.translate(title, to: 'ckb').then((t) {
               if (mounted) {
                  setState(() => _highlights[i]['title'] = t.text);
               }
            }).catchError((_) {
               translator.translate(title, to: 'ku').then((t2) {
                  if (mounted) {
                     setState(() => _highlights[i]['title'] = t2.text);
                  }
               }).catchError((_) {});
            });
         }
       }
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
          s.wcTitle,
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
            Tab(text: s.wcTabMatches),
            Tab(text: s.wcTabHighlights),
            Tab(text: s.wcTabGroups),
            Tab(text: s.wcTabNews),
            Tab(text: s.wcTabScorers),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchesTab(s),
          _buildHighlightsTab(s),
          _buildGroupsTab(s),
          _buildNewsTab(s),
          _buildScorersTab(s),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(AppStrings s) {
    return Column(
      children: [
        // Yesterday, Today, Tomorrow filters
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDateToggle(-1, s.wcYesterday),
              const SizedBox(width: 8),
              _buildDateToggle(0, s.wcToday),
              const SizedBox(width: 8),
              _buildDateToggle(1, s.wcTomorrow),
            ],
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
                      onRefresh: () => _loadLiveSoccerForOffset(_selectedDayOffset),
                      child: _buildMatchesList(s),
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
          _loadLiveSoccerForOffset(offset);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFAA8C2C)])
            : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
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

  Widget _buildMatchesList(AppStrings s) {
    // Separate live from other matches
    final liveMatches = _liveSoccer.where((event) {
      final state = event['status']?['type']?['state'] ?? 'pre';
      return state == 'in';
    }).toList();
    
    final otherMatches = _liveSoccer.where((event) {
      final state = event['status']?['type']?['state'] ?? 'pre';
      return state != 'in';
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (liveMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.live_tv_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  s.wcLive.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5
                  ),
                ),
              ],
            ),
          ),
          ...liveMatches.map((match) => _buildEspnMatchCard(match, s)),
          const Divider(color: Colors.white10, height: 24, thickness: 1, indent: 16, endIndent: 16),
        ],
        
        if (otherMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              s.wcTabMatches.toUpperCase(),
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5
              ),
            ),
          ),
          ...otherMatches.map((match) => _buildEspnMatchCard(match, s)),
        ],
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
    } catch (e) { debugPrint('Caught error in world_cup_screen.dart: $e'); }

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
      } catch (e) { debugPrint('Caught error in world_cup_screen.dart: $e'); }
    }

    // Exact Match Time (e.g. 18:00) to display in the middle instead of "VS"
    String matchTime = 'VS';
    if (event['date'] != null) {
      try {
        final dt = DateTime.parse(event['date']).toLocal();
        matchTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) { debugPrint('Caught error in world_cup_screen.dart: $e'); }
    }

    final Color badgeColor = finished
        ? Colors.white.withValues(alpha: 0.18)
        : isLive
            ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
            : Colors.blue.withValues(alpha: 0.18);
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
        child: AnimatedGradientBorder(
          borderWidth: isLive ? 1.5 : 1.2,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isLive
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.04),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isLive
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: isLive ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
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
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
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
                            _teamLogo(homeFlag, width: 30, height: 22),
                          ],
                        ),
                      ),
                      // Score or Match Time
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              state == 'pre' ? matchTime : '$homeScore - $awayScore',
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
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                finished 
                                    ? s.wcFinished 
                                    : (state == 'pre' ? s.wcUpcoming : timeLabel),
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
                            _teamLogo(awayFlag, width: 30, height: 22),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamLogo(String url, {double width = 48, double height = 48}) {
    final double radius = width > 30 ? 10 : 4;
    final double iconSize = width > 30 ? 24 : 20;

    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(Icons.shield_rounded, color: Colors.white24, size: iconSize),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Icon(Icons.shield_rounded, color: Colors.white24, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildGroupsTab(AppStrings s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    if (_groups.isEmpty) {
      return Center(
        child: Text(s.wcNoGroups, style: const TextStyle(color: Colors.white54))
      );
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

  Widget _buildGroupCard(String groupName, List<dynamic> teams, AppStrings s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFD4AF37).withValues(alpha: 0.12), const Color(0xFFD4AF37).withValues(alpha: 0.02)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(4.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.0),
              4: FlexColumnWidth(1.0),
              5: FlexColumnWidth(1.2),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                children: [
                  _tableHeaderCell('#', Alignment.center),
                  _tableHeaderCell(s.wcTeam, Alignment.centerLeft),
                  _tableHeaderCell('P', Alignment.center),
                  _tableHeaderCell('W', Alignment.center),
                  _tableHeaderCell('D', Alignment.center),
                  _tableHeaderCell('PTS', Alignment.center),
                ],
              ),
              ...teams.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final pos = idx + 1;
                final name = t['team_name_en'] ?? t['team_label'] ?? '';
                final flag = t['team_flag'];
                final p = t['played']?.toString() ?? '0';
                final w = t['wins']?.toString() ?? '0';
                final d = t['draws']?.toString() ?? '0';
                final pts = t['pts']?.toString() ?? '0';

                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: idx == teams.length - 1
                          ? BorderSide.none
                          : const BorderSide(color: Colors.white10),
                    ),
                  ),
                  children: [
                    TableCell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Text(
                          pos.toString(),
                          style: TextStyle(
                            color: pos <= 2 ? const Color(0xFFD4AF37) : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Row(
                        children: [
                          if (flag != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.network(flag, width: 22, height: 16, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.flag_rounded, color: Colors.white24, size: 14),
                              ),
                            )
                          else
                            const SizedBox(width: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _tableBodyCell(p),
                    _tableBodyCell(w),
                    _tableBodyCell(d),
                    TableCell(
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          pts,
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String label, Alignment alignment) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      alignment: alignment,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _tableBodyCell(String value) {
    return TableCell(
      child: Container(
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildNewsTab(AppStrings s) {
    if (_news.isEmpty) {
      return Center(
        child: Text(s.wcNoNews, style: const TextStyle(color: Colors.white54))
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: _news.length,
        itemBuilder: (context, index) {
          final item = _news[index];
          return _buildNewsCard(item, s);
        },
      ),
    );
  }

  Widget _buildNewsCard(dynamic item, AppStrings s) {
    final title = item['title'] ?? '';
    final description = item['description'] ?? '';
    final imageUrl = item['images'] != null && (item['images'] as List).isNotEmpty ? item['images'][0]['url'] : '';
    final link = item['links'] != null && item['links']['web'] != null ? item['links']['web']['href'] : '';
    final time = item['published'] ?? '';

    String relativeTime = '';
    if (time.isNotEmpty) {
      try {
        final dt = DateTime.parse(time).toLocal();
        final diff = DateTime.now().difference(dt);
        relativeTime = s.wcTimeAgo(diff.inMinutes);
      } catch (e) { debugPrint('Caught error in world_cup_screen.dart: $e'); }
    }

    return GestureDetector(
      onTap: () async {
        if (link.isNotEmpty) {
          final uri = Uri.parse(link);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.wcNewsLabel,
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (relativeTime.isNotEmpty)
                        Text(
                          relativeTime,
                          style: const TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorersTab(AppStrings s) {
    if (_isLoadingScorers) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    if (_scorers.isEmpty) {
      return Center(
        child: Text(s.wcNoScorers, style: const TextStyle(color: Colors.white54))
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadScorers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12).copyWith(bottom: 100),
        itemCount: _scorers.length,
        itemBuilder: (context, index) {
          final item = _scorers[index];
          final pos = index + 1;
          final name = item['athlete_name'] ?? '';
          final team = item['team_name'] ?? '';
          final logo = item['team_logo'] ?? '';
          final goals = item['goals']?.toString() ?? '0';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  alignment: Alignment.center,
                  child: Text(
                    pos.toString(),
                    style: TextStyle(
                      color: pos <= 3 ? const Color(0xFFD4AF37) : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (logo.isNotEmpty) ...[
                            Image.network(logo, width: 14, height: 14, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            team,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      goals,
                      style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    Text(
                      s.wcGoals,
                      style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  // --- Highlights Tab ---

  Widget _buildHighlightsTab(AppStrings s) {
    final filteredList = _highlights.where((item) {
      if (_activeHighlightFilter == 'all') return true;
      return (item['category'] ?? '').toString().toLowerCase() == _activeHighlightFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHighlightFilterToggle('all', s.wcAllVideos),
              const SizedBox(width: 8),
              _buildHighlightFilterToggle('highlight', s.wcHighlightsOnly),
              const SizedBox(width: 8),
              _buildHighlightFilterToggle('goal', s.wcGoalsOnly),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingHighlights
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : filteredList.isEmpty
                  ? Center(child: Text(s.wcNoHighlights, style: const TextStyle(color: Colors.white54)))
                  : RefreshIndicator(
                      color: const Color(0xFFD4AF37),
                      backgroundColor: const Color(0xFF1A1A1A),
                      onRefresh: _loadHighlights,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8).copyWith(bottom: 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return _buildHighlightCard(item, s);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHighlightFilterToggle(String category, String label) {
    final isSelected = _activeHighlightFilter == category;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _activeHighlightFilter = category);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFAA8C2C)])
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCard(dynamic item, AppStrings s) {
    final title = item['title'] ?? '';
    final thumbnail = item['thumbnail'] ?? '';
    final durationSec = item['duration'] as int? ?? 0;
    final views = item['views_count'] as int? ?? 0;
    final category = item['category'] ?? 'highlight';

    String categoryText = '';
    Color badgeColor = Colors.blue;
    if (category == 'goal') {
      categoryText = s.wcGoalsOnly.replaceAll(' تەنها', '').replaceAll('Tenê ', '');
      badgeColor = const Color(0xFFD4AF37);
    } else {
      categoryText = s.wcTabHighlights.replaceAll('کان', '').replaceAll('ên', '');
      badgeColor = Colors.blueAccent;
    }

    return GestureDetector(
      onTap: () => _playVideo(item, s),
      child: AnimatedGradientBorder(
        borderWidth: 1.2,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.777,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      thumbnail.isNotEmpty
                          ? Image.network(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white10,
                                child: const Icon(Icons.videocam_rounded, color: Colors.white24, size: 30),
                              ),
                            )
                          : Container(
                              color: Colors.white10,
                              child: const Icon(Icons.videocam_rounded, color: Colors.white24, size: 30),
                            ),
                      Container(color: Colors.black.withValues(alpha: 0.15)),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      if (durationSec > 0)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDuration(durationSec),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoryText,
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_rounded, color: Colors.white38, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            '$views',
                            style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playVideo(dynamic item, AppStrings s) {
    final videoUrl = item['video_url'] ?? '';
    final title = item['title'] ?? 'Video';
    final thumbnail = item['thumbnail'] ?? '';

    if (videoUrl.isEmpty) return;

    final mockChannel = Channel(
      name: title,
      url: videoUrl,
      logo: thumbnail,
      type: 'movie',
    );

    final locale = ref.read(appLocaleProvider);
    final player = OpticPlayer();
    player.open(videoUrl, headers: {'User-Agent': 'SmartIPTV'});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoviePlayerPage(
          player: player,
          channel: mockChannel,
          uiLocale: locale,
          strings: s,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
