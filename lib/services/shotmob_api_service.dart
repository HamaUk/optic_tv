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
  
  // Security Keys from core files
  static const String googleApiKey = 'AIzaSyCi6P0JWAjueCNkmroLWmMNijrfNlhnCKQ';
  
  static const Map<String, int> leagueIds = {
    'Premier League': 7,
    'La Liga': 8,
    'Iraqi League': 15, // Example ID, adjust based on /league/list
  };

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
        .build());

      _socket?.onConnect((_) => log('ShotMob WebSocket Connected'));
      _socket?.onDisconnect((_) => log('ShotMob WebSocket Disconnected'));

      _socket?.on('score_update', (data) {
        if (data is Map<String, dynamic>) {
          _updateController.add(ShotMatch.fromJson(data));
        }
      });

      _socket?.on('match_update', (data) {
        if (data is Map<String, dynamic>) {
          _updateController.add(ShotMatch.fromJson(data));
        }
      });
    } catch (e) {
      log('WebSocket Init Error: $e');
    }
  }

  void subscribeToMatch(int matchId) {
    _socket?.emit('subscribe', {
      'event': 'subscribe',
      'data': {
        'matchId': matchId.toString(),
        'topics': ['score', 'events']
      }
    });
  }

  Future<List<ShotMatch>> getMatches({int? leagueId}) async {
    try {
      final res = await _dio.get('/league/list/games', queryParameters: {
        if (leagueId != null) 'leagueId': leagueId,
      });
      
      if (res.data is List) {
        return (res.data as List)
            .map((e) => ShotMatch.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      log('Error fetching matches: $e');
    }
    return [];
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
  final String? predictions; // "57% / 23% / 20%"
  final String matchTime;
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
    required this.leagueName,
  });

  bool get isLive => status.toLowerCase() == 'live';
  bool get isFinished => status.toLowerCase() == 'finished';

  String get timeDisplay {
    try {
      final dt = DateTime.parse(matchTime).toLocal();
      return DateFormat.Hm().format(dt);
    } catch (_) {
      return matchTime;
    }
  }

  factory ShotMatch.fromJson(Map<String, dynamic> json) {
    return ShotMatch(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? 'NS',
      homeTeam: json['home_team_name'] ?? json['team_home'] ?? 'Home',
      awayTeam: json['away_team_name'] ?? json['team_away'] ?? 'Away',
      homeLogo: json['team_home_logo'],
      awayLogo: json['team_away_logo'],
      scoreHome: json['score_home'] as int? ?? 0,
      scoreAway: json['score_away'] as int? ?? 0,
      stadium: json['stadium'] ?? json['venue'],
      attendance: json['attendance']?.toString(),
      referee: json['referee'] ?? json['Referees'],
      predictions: json['predictions'] ?? json['Predictions'],
      matchTime: json['match_time'] ?? json['start_at'] ?? '',
      leagueName: json['league_name'] ?? 'League',
    );
  }
}
