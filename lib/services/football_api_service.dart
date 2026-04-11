import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// API-Football v3 (api-sports.io) — Free tier: 100 requests/day.
/// Register at https://www.api-football.com/ to get your API key.
///
/// League IDs used:
///   Premier League  = 39
///   La Liga         = 140
///   Iraqi Stars League = 648
class FootballApiService {
  /// ⚠️  Replace with your API-Football key from https://www.api-football.com/
  static const String _apiKey = '6dce7ba23ee16516d6f9fca5466819a0';
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  static const Map<String, int> leagueIds = {
    'Premier League': 39,
    'La Liga': 140,
    'Iraqi Stars League': 648,
  };

  /// Current season (adjust if API returns 404).
  static const int season = 2025;

  late final Dio _dio;

  FootballApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {'x-apisports-key': _apiKey},
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ));
  }

  bool get isConfigured =>
      _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;

  // ─────────────────────────── Fixtures ───────────────────────────

  /// Matches for [date] (YYYY-MM-DD) in [leagueId].
  Future<List<MatchData>> getMatches({
    required int leagueId,
    required String date,
  }) async {
    if (!isConfigured) return [];
    try {
      final res = await _dio.get('/fixtures', queryParameters: {
        'league': leagueId,
        'season': season,
        'date': date,
      });
      return _parseResponse(res.data);
    } catch (_) {
      return [];
    }
  }

  /// Today's matches for a league.
  Future<List<MatchData>> getTodayMatches(int leagueId) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return getMatches(leagueId: leagueId, date: today);
  }

  /// Tomorrow's matches for a league.
  Future<List<MatchData>> getTomorrowMatches(int leagueId) {
    final tomorrow = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().add(const Duration(days: 1)));
    return getMatches(leagueId: leagueId, date: tomorrow);
  }

  /// Live matches for a league.
  Future<List<MatchData>> getLiveMatches(int leagueId) async {
    if (!isConfigured) return [];
    try {
      final res = await _dio.get('/fixtures', queryParameters: {
        'live': 'all',
        'league': leagueId,
      });
      return _parseResponse(res.data);
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────── Helpers ───────────────────────────

  List<MatchData> _parseResponse(dynamic data) {
    if (data is Map && data['response'] is List) {
      return (data['response'] as List)
          .map((e) => MatchData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Model
// ═══════════════════════════════════════════════════════════════════

class MatchData {
  final int fixtureId;
  final String status; // NS, 1H, HT, 2H, FT, …
  final int? elapsed;
  final String date;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final int? homeGoals;
  final int? awayGoals;
  final String? venue;

  MatchData({
    required this.fixtureId,
    required this.status,
    this.elapsed,
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    this.homeGoals,
    this.awayGoals,
    this.venue,
  });

  bool get isLive =>
      const ['1H', '2H', 'HT', 'ET', 'BT', 'P'].contains(status);
  bool get isFinished =>
      const ['FT', 'AET', 'PEN'].contains(status);
  bool get isNotStarted =>
      const ['NS', 'TBD'].contains(status);

  String get statusDisplay => switch (status) {
        'NS'   => 'Not Started',
        'TBD'  => 'TBD',
        '1H'   => '1st Half${elapsed != null ? " $elapsed'" : ""}',
        'HT'   => 'Half Time',
        '2H'   => '2nd Half${elapsed != null ? " $elapsed'" : ""}',
        'ET'   => 'Extra Time',
        'BT'   => 'Break',
        'P'    => 'Penalties',
        'FT'   => 'Full Time',
        'AET'  => 'After ET',
        'PEN'  => 'After Pen',
        'SUSP' => 'Suspended',
        'INT'  => 'Interrupted',
        'PST'  => 'Postponed',
        'CANC' => 'Cancelled',
        'ABD'  => 'Abandoned',
        'AWD'  => 'Awarded',
        'WO'   => 'Walkover',
        _      => status,
      };

  String get kickoffTime {
    try {
      final dt = DateTime.parse(date).toLocal();
      return DateFormat.Hm().format(dt);
    } catch (_) {
      return '--:--';
    }
  }

  factory MatchData.fromJson(Map<String, dynamic> json) {
    final fixture = json['fixture'] as Map<String, dynamic>? ?? {};
    final teams = json['teams'] as Map<String, dynamic>? ?? {};
    final goals = json['goals'] as Map<String, dynamic>? ?? {};
    final st = fixture['status'] as Map<String, dynamic>? ?? {};

    return MatchData(
      fixtureId: fixture['id'] as int? ?? 0,
      status: (st['short'] as String?) ?? 'NS',
      elapsed: st['elapsed'] as int?,
      date: (fixture['date'] as String?) ?? '',
      homeTeam:
          (teams['home'] as Map<String, dynamic>?)?['name'] as String? ??
              'Home',
      awayTeam:
          (teams['away'] as Map<String, dynamic>?)?['name'] as String? ??
              'Away',
      homeLogo:
          (teams['home'] as Map<String, dynamic>?)?['logo'] as String?,
      awayLogo:
          (teams['away'] as Map<String, dynamic>?)?['logo'] as String?,
      homeGoals: goals['home'] as int?,
      awayGoals: goals['away'] as int?,
      venue:
          (fixture['venue'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}
