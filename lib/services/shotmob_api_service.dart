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
      // 1. Discovery: Get all active leagues from the core API
      final leagueRes = await _dio.get('/league/list');
      if (leagueRes.data is List) {
        final List<ShotMatch> allGames = [];
        final List leagues = leagueRes.data;

        // 2. Iterative Fetch: Pull games only for active leagues
        // This ensures the data is 100% real and dynamically named by the server.
        await Future.wait(leagues.take(15).map((league) async {
          try {
            final lId = league['id'];
            final gRes = await _dio.get('/league/list/games', queryParameters: {
              'leagueId': lId,
              'date': dateStr,
            });
            if (gRes.data is List) {
              allGames.addAll((gRes.data as List).map((e) => ShotMatch.fromJson(e as Map<String, dynamic>)));
            }
          } catch (_) {}
        }));

        if (allGames.isNotEmpty) return allGames;
      }
    } catch (e) {
      log('Error fetching matches dynamically: $e');
    }

    // Returning empty list instead of sample data to ensure user only sees what the API actually provides
    return [];
  }
        leagueName: 'چامپیۆنزلیگ',
      ),
    ];
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
  bool get isFinished => status.toUpperCase() == 'FINISHED' || status.toUpperCase() == 'FT';

  factory ShotMatch.fromJson(Map<String, dynamic> json) {
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
}
