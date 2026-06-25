import 'dart:convert';
import 'package:http/http.dart' as http;

class WorldCupService {
  static const String baseUrl = 'https://worldcup26.ir/get';

  static Map<String, dynamic>? _teamsCache;
  static List<dynamic>? _gamesCache;
  static List<dynamic>? _groupsCache;
  static Map<String, List<dynamic>> _liveSoccerCache = {};
  static List<dynamic>? _newsCache;
  static List<dynamic>? _topScorersCache;
  static List<dynamic>? _teamsListCache;

  static Future<List<dynamic>> fetchTeamsList() async {
    if (_teamsListCache != null) {
      _fetchTeamsListBackground();
      return _teamsListCache!;
    }
    return await _fetchTeamsListBackground();
  }

  static Future<List<dynamic>> _fetchTeamsListBackground() async {
    try {
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/teams'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sports = data['sports'] as List<dynamic>? ?? [];
        if (sports.isNotEmpty) {
           final leagues = sports[0]['leagues'] as List<dynamic>? ?? [];
           if (leagues.isNotEmpty) {
             final teams = leagues[0]['teams'] as List<dynamic>? ?? [];
             _teamsListCache = teams;
             return teams;
           }
        }
      }
    } catch (e) {
      print('Error fetching Teams List: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchMatchProbabilities(String eventId) async {
    try {
      final response = await http.get(Uri.parse('https://sports.core.api.espn.com/v2/sports/soccer/leagues/fifa.world/events/$eventId/competitions/$eventId/probabilities'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
           return items[0]['playbyplay'] ?? items[0]; // probabilities structure varies, we'll return the first item
        }
      }
    } catch (e) {
      print('Error fetching probabilities: $e');
    }
    return null;
  }
  static Future<List<dynamic>> fetchTeamRoster(String teamId) async {
    try {
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/teams/$teamId/roster'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final athletes = data['athletes'] as List<dynamic>? ?? [];
        if (athletes.isNotEmpty) {
           return athletes[0]['items'] as List<dynamic>? ?? [];
        }
      }
    } catch (e) {
      print('Error fetching Team Roster: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchTeamsMap() async {
    if (_teamsCache != null) return _teamsCache!;
    try {
      final response = await http.get(Uri.parse('$baseUrl/teams'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final teams = data['teams'] as List<dynamic>? ?? [];
        _teamsCache = { for (var t in teams) t['id'].toString() : t };
        return _teamsCache!;
      }
    } catch (e) {
      print('Error fetching WC teams: $e');
    }
    return {};
  }

  static Future<List<dynamic>> fetchGames() async {
    if (_gamesCache != null) {
      _fetchGamesBackground();
      return _gamesCache!;
    }
    return await _fetchGamesBackground();
  }

  static Future<List<dynamic>> _fetchGamesBackground() async {
    try {
      final gamesFuture = http.get(Uri.parse('$baseUrl/games'));
      final teamsMapFuture = fetchTeamsMap();
      
      final responses = await Future.wait([gamesFuture, teamsMapFuture]);
      final gamesResponse = responses[0] as http.Response;
      final teamsMap = responses[1] as Map<String, dynamic>;

      if (gamesResponse.statusCode == 200) {
        final data = json.decode(gamesResponse.body);
        final games = data['games'] as List<dynamic>? ?? [];
        
        for (var game in games) {
          final homeTeamId = game['home_team_id']?.toString();
          final awayTeamId = game['away_team_id']?.toString();
          
          if (homeTeamId != null && teamsMap.containsKey(homeTeamId)) {
             game['home_team_flag'] = teamsMap[homeTeamId]['flag'];
          }
          if (awayTeamId != null && teamsMap.containsKey(awayTeamId)) {
             game['away_team_flag'] = teamsMap[awayTeamId]['flag'];
          }
        }
        _gamesCache = games;
        return games;
      }
    } catch (e) {
      print('Error fetching WC games: $e');
    }
    return [];
  }

  static Future<List<dynamic>> fetchGroups() async {
    if (_groupsCache != null) {
      _fetchGroupsBackground();
      return _groupsCache!;
    }
    return await _fetchGroupsBackground();
  }

  static Future<List<dynamic>> _fetchGroupsBackground() async {
    try {
      final groupsFuture = http.get(Uri.parse('$baseUrl/groups'));
      final teamsMapFuture = fetchTeamsMap();
      
      final responses = await Future.wait([groupsFuture, teamsMapFuture]);
      final groupsResponse = responses[0] as http.Response;
      final teamsMap = responses[1] as Map<String, dynamic>;

      if (groupsResponse.statusCode == 200) {
        final data = json.decode(groupsResponse.body);
        final groups = data['groups'] as List<dynamic>? ?? [];
        
        for (var group in groups) {
          final teams = group['teams'] as List<dynamic>? ?? [];
          for (var team in teams) {
            final teamId = team['team_id']?.toString();
            if (teamId != null && teamsMap.containsKey(teamId)) {
              team['team_name_en'] = teamsMap[teamId]['name_en'];
              team['team_flag'] = teamsMap[teamId]['flag'];
            }
          }
        }
        _groupsCache = groups;
        return groups;
      }
    } catch (e) {
      print('Error fetching WC groups: $e');
    }
    return [];
  }

  static Future<List<dynamic>> fetchLiveSoccerForDate(DateTime date) async {
    final dateStr = "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
    if (_liveSoccerCache.containsKey(dateStr)) {
      _fetchLiveSoccerBackground(dateStr);
      return _liveSoccerCache[dateStr]!;
    }
    return await _fetchLiveSoccerBackground(dateStr);
  }

  static Future<List<dynamic>> _fetchLiveSoccerBackground(String dateStr) async {
    try {
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard?dates=$dateStr'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['events'] as List<dynamic>? ?? [];
        _liveSoccerCache[dateStr] = events;
        return events;
      }
    } catch (e) {
      print('Error fetching ESPN live soccer for date: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchMatchSummary(String eventId) async {
    try {
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/summary?event=$eventId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching ESPN match summary: $e');
    }
    return null;
  }

  static Future<List<dynamic>> fetchNews() async {
    if (_newsCache != null) {
      _fetchNewsBackground();
      return _newsCache!;
    }
    return await _fetchNewsBackground();
  }

  static Future<List<dynamic>> _fetchNewsBackground() async {
    try {
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/news'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List<dynamic>? ?? [];
        _newsCache = articles;
        return articles;
      }
    } catch (e) {
      print('Error fetching ESPN news: $e');
    }
    return [];
  }

  static Future<List<dynamic>> fetchTopScorers() async {
    if (_topScorersCache != null) {
      _fetchTopScorersBackground();
      return _topScorersCache!;
    }
    return await _fetchTopScorersBackground();
  }

  static Future<List<dynamic>> _fetchTopScorersBackground() async {
    try {
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/statistics'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = data['stats'] as List<dynamic>? ?? [];
        if (stats.isNotEmpty) {
          final goalsLeaders = stats.firstWhere((s) => s['name'] == 'goalsLeaders', orElse: () => null);
          if (goalsLeaders != null) {
            final leaders = goalsLeaders['leaders'] as List<dynamic>? ?? [];
            _topScorersCache = leaders;
            return leaders;
          }
        }
      }
    } catch (e) {
      print('Error fetching ESPN top scorers: $e');
    }
    return [];
  }

  static List<dynamic>? _eventVideosCache;

  static Future<List<dynamic>> fetchEventVideos({int page = 1, int limit = 100}) async {
    try {
      final response = await http.get(Uri.parse('https://admin.dramaramadan.net/api/matches/event_videos.php?page=$page&limit=$limit'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] as List<dynamic>? ?? [];
        _eventVideosCache = list;
        return list;
      }
    } catch (e) {
      print('Error fetching event videos: $e');
    }
    return _eventVideosCache ?? [];
  }
}


