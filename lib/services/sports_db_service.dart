import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:developer';

/// Service to fetch high-quality team logos from TheSportsDB.
class SportsDbService {
  static const String baseUrl = 'https://www.thesportsdb.com/api/v1/json/123';
  static const String testKey = '123'; // Free test key from TheSportsDB

  final Dio _dio = Dio();
  
  // Local cache to avoid repeated lookups for the same team name
  static final Map<String, String> _logoCache = {};

  /// Fetches a high-quality team badge URL by team name.
  /// Returns null if not found or on error.
  Future<String?> getTeamLogo(String teamName) async {
    // 1. Check cache first
    if (_logoCache.containsKey(teamName)) {
      return _logoCache[teamName];
    }

    try {
      // 2. Search for the team
      // Using standard search endpoint
      final response = await _dio.get('$baseUrl/searchteams.php', queryParameters: {
        't': teamName,
      });

      if (response.data != null && response.data['teams'] != null) {
        final List teams = response.data['teams'];
        if (teams.isNotEmpty) {
          // Get the primary badge
          final String? badgeUrl = teams.first['strTeamBadge'];
          
          if (badgeUrl != null && badgeUrl.isNotEmpty) {
            // Use documented TheSportsDB image size modifier.
            final optimizedUrl = '$badgeUrl/small';
            _logoCache[teamName] = optimizedUrl;
            return optimizedUrl;
          }
        }
      }
    } catch (e) {
      log('SportsDB Error for $teamName: $e');
    }

    return null;
  }

  /// Batch pre-fetch logos for a list of matches (optional optimization)
  Future<void> prefetchAll(List<String> teamNames) async {
    // To stay under 30 req/min, we should be careful here
    // For now, we'll let lazy-loading handle it
  }
}
