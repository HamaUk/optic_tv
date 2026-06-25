import 'dart:convert';
import 'package:http/http.dart' as http;

class WorldCupService {
  static const String baseUrl = 'https://worldcup26.ir/get';

  /// Fetches teams to map IDs to Names and Flags
  static Future<Map<String, dynamic>> fetchTeamsMap() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teams'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final teams = data['teams'] as List<dynamic>? ?? [];
        return { for (var t in teams) t['id'].toString() : t };
      }
    } catch (e) {
      print('Error fetching WC teams: $e');
    }
    return {};
  }

  /// Fetches all matches and injects team flags
  static Future<List<dynamic>> fetchGames() async {
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
        return games;
      }
    } catch (e) {
      print('Error fetching WC games: $e');
    }
    return [];
  }

  /// Fetches group standings and injects team names and flags
  static Future<List<dynamic>> fetchGroups() async {
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
        return groups;
      }
    } catch (e) {
      print('Error fetching WC groups: $e');
    }
    return [];
  }

  /// Fetches Live Soccer games from ESPN API (FIFA World Cup Only) for a specific date
  static Future<List<dynamic>> fetchLiveSoccerForDate(DateTime date) async {
    try {
      final dateStr = "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard?dates=$dateStr'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['events'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      print('Error fetching ESPN live soccer for date: $e');
    }
    return [];
  }

  /// Fetches Match Summary (Commentary, Lineups, Venue) from ESPN API
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

  /// Fetches FIFA World Cup News from ESPN API
  static Future<List<dynamic>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/news'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['articles'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      print('Error fetching ESPN news: $e');
    }
    return [];
  }

  /// Fetches Top Scorers from ESPN API
  static Future<List<dynamic>> fetchTopScorers() async {
    try {
      final response = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/statistics'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = data['stats'] as List<dynamic>? ?? [];
        if (stats.isNotEmpty) {
          final goalsLeaders = stats.firstWhere((s) => s['name'] == 'goalsLeaders', orElse: () => null);
          if (goalsLeaders != null) {
            return goalsLeaders['leaders'] as List<dynamic>? ?? [];
          }
        }
      }
    } catch (e) {
      print('Error fetching ESPN top scorers: $e');
    }
    return [];
  }
}
