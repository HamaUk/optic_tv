import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// ShotMob Sport API Core Service
/// Handles REST data fetching and real-time WebSocket events.
class ShotMobApiService {
  static const String baseUrl = 'https://api.shotmob.net';
  static const String wsUrl = 'wss://api.shotmob.net';
  
  static const String googleApiKey = 'AIzaSyCi6P0JWAjueCNkmroLWmMNijrfNlhnCKQ';

  late final Dio _dio;
  io.Socket? _socket;
  
  final _updateController = StreamController<ShotMatch>.broadcast();
  Stream<ShotMatch> get matchUpdates => _updateController.stream;

  ShotMobApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'OpticTV-Sport-Core/1.0',
      },
    ));
    _initSocket();
  }

  void _initSocket() {
    try {
      _socket = io.io(wsUrl, io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setReconnectionAttempts(10)
        .build());

      _socket?.onConnect((_) {
        log('ShotMob WebSocket Connected - Subscribing precisely as per LIVE_SCORES.md');
        // Correct subscription format from local SportAPI_Core/LIVE_SCORES.md
        _socket?.emit('subscribe', {
          'data': {
            'topics': ['score', 'events']
          }
        });
      });
      
      _socket?.onConnectError((err) => log('WebSocket Connect Error: $err'));
      _socket?.onDisconnect((_) => log('WebSocket Disconnected'));

      _socket?.on('score_update', (data) {
        log('WebSocket: score_update received: $data');
        if (data is Map<String, dynamic>) {
          _updateController.add(ShotMatch.fromJson(data));
        }
      });

      _socket?.on('match_update', (data) {
        log('WebSocket: match_update received: $data');
        if (data is Map<String, dynamic>) {
          _updateController.add(ShotMatch.fromJson(data));
        }
      });
    } catch (e) {
      log('WebSocket Init Error: $e');
    }
  }

  /// Fetch matches for a specific date (YYYY-MM-DD or 'today')
  Future<List<ShotMatch>> getMatches({String date = 'today'}) async {
    final dateStr = date == 'today' ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : date;

    try {
      final leagueRes = await _dio.get('/league/list');
      final leagues = _leaguesFromListResponse(leagueRes.data);
      if (leagues.isEmpty) return [];

      final List<ShotMatch> allGames = [];

      await Future.wait(leagues.take(15).map((league) async {
        try {
          final lId = league['id'];
          if (lId == null) return;
          final leagueTitle = league['title']?.toString() ?? 'League';
          final gRes = await _dio.get('/league/list/games', queryParameters: {
            'leagueId': lId,
            'date': dateStr,
          });
          allGames.addAll(_matchesFromGamesResponse(gRes.data, fallbackLeagueName: leagueTitle));
        } catch (e) {
          log('ShotMob games fetch error (league ${league['id']}): $e');
        }
      }));

      return allGames;
    } catch (e) {
      log('Error fetching matches dynamically: $e');
    }

    return [];
  }

  /// API returns either a raw list or `{ "leagues": [ ... ] }`.
  List<Map<String, dynamic>> _leaguesFromListResponse(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map && data['leagues'] is List) {
      return (data['leagues'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// API returns `{ "leagues": [ { "title", "games": [ ... ] } ] }` or a flat list of match maps.
  List<ShotMatch> _matchesFromGamesResponse(dynamic data, {required String fallbackLeagueName}) {
    final out = <ShotMatch>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map) {
          out.add(ShotMatch.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      return out;
    }
    if (data is Map && data['leagues'] is List) {
      for (final bucket in data['leagues'] as List) {
        if (bucket is! Map) continue;
        final b = Map<String, dynamic>.from(bucket);
        final title = b['title']?.toString() ?? fallbackLeagueName;
        final games = b['games'];
        if (games is! List) continue;
        for (final g in games) {
          if (g is Map) {
            out.add(ShotMatch.fromShotMobGame(Map<String, dynamic>.from(g), leagueName: title));
          }
        }
      }
    }
    return out;
  }

  void dispose() {
    _socket?.dispose();
    _updateController.close();
  }
}

class ShotMatch {
  final int id;
  final String status;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final int scoreHome;
  final int scoreAway;
  final String? stadium;
  final String? attendance;
  final String? referee;
  final String? predictions; 
  final String matchTime;
  final String? elapsedTime; // Added for live counter
  final String leagueName;

  ShotMatch({
    required this.id,
    required this.status,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    required this.scoreHome,
    required this.scoreAway,
    this.stadium,
    this.attendance,
    this.referee,
    this.predictions,
    required this.matchTime,
    this.elapsedTime,
    required this.leagueName,
  });

  bool get isLive => status.toUpperCase() == 'LIVE' || status.toUpperCase() == 'IN_PLAY';
  bool get isFinished =>
      status.toUpperCase() == 'FINISHED' ||
      status.toUpperCase() == 'FT' ||
      status.toUpperCase() == 'END';

  factory ShotMatch.fromJson(Map<String, dynamic> json) {
    if (json['homeTeam'] is Map || json['awayTeam'] is Map) {
      return ShotMatch.fromShotMobGame(json, leagueName: json['league_name'] as String? ?? 'League');
    }
    return ShotMatch(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? 'NS',
      homeTeam: json['team_home'] ?? json['home_team_name'] ?? 'Home',
      awayTeam: json['team_away'] ?? json['away_team_name'] ?? 'Away',
      homeLogo: json['team_home_logo'],
      awayLogo: json['team_away_logo'],
      scoreHome: json['score_home'] as int? ?? 0,
      scoreAway: json['score_away'] as int? ?? 0,
      stadium: json['stadium'] ?? json['venue'],
      attendance: json['attendance']?.toString(),
      referee: json['referee'] ?? json['Referees'],
      predictions: json['predictions'] ?? json['Predictions'],
      matchTime: json['match_time'] ?? json['start_at'] ?? '',
      elapsedTime: json['elapsed_time'] ?? json['minute']?.toString(), // Map time counter
      leagueName: json['league_name'] ?? 'League',
    );
  }

  /// `/league/list/games` nested game row (`homeTeam` / `awayTeam` objects, `homeTeamScore`, etc.).
  factory ShotMatch.fromShotMobGame(Map<String, dynamic> json, {required String leagueName}) {
    final homeMap = json['homeTeam'] is Map ? Map<String, dynamic>.from(json['homeTeam'] as Map) : <String, dynamic>{};
    final awayMap = json['awayTeam'] is Map ? Map<String, dynamic>.from(json['awayTeam'] as Map) : <String, dynamic>{};

    final raw = (json['status'] as String? ?? 'NS').toLowerCase();
    String status;
    if (raw == 'end') {
      status = 'FT';
    } else if (raw == 'live' || raw == 'in_play' || raw == 'ongoing') {
      status = 'LIVE';
    } else {
      status = (json['status'] as String? ?? 'NS').toUpperCase();
    }

    final dateStr = json['date'] as String?;
    var matchTime = '';
    if (dateStr != null) {
      try {
        matchTime = DateFormat('hh:mm a').format(DateTime.parse(dateStr).toLocal());
      } catch (_) {}
    }

    return ShotMatch(
      id: json['id'] as int? ?? 0,
      status: status,
      homeTeam: homeMap['name'] as String? ?? 'Home',
      awayTeam: awayMap['name'] as String? ?? 'Away',
      homeLogo: homeMap['logo'] as String?,
      awayLogo: awayMap['logo'] as String?,
      scoreHome: json['homeTeamScore'] as int? ?? json['score_home'] as int? ?? 0,
      scoreAway: json['awayTeamScore'] as int? ?? json['score_away'] as int? ?? 0,
      stadium: json['stadium'] ?? json['venue'],
      attendance: json['attendance']?.toString(),
      referee: json['referee']?.toString(),
      predictions: json['predictions']?.toString(),
      matchTime: matchTime,
      elapsedTime: json['minute']?.toString(),
      leagueName: leagueName,
    );
  }
}
