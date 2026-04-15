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

  /// Fetched first so Premier, La Liga, Iraq leagues, European cups, etc. appear reliably.
  static const List<int> _priorityLeagueIds = [
    274, 331, 14, 13, 28, 19, 15, 21, 22, 18, 40, 20, 32, 23, 17, 41,
    1, 3, 2, 4, 6, 5, 10, 9, 986, 999, 1058, 1078, 981,
    393, 567, 712, 713,
 ];

  /// Cap avoids hundreds of parallel requests; ordered list still surfaces major leagues first.
  static const int _maxLeaguesPerDay = 80;
  static const int _leagueFetchBatchSize = 10;

  /// Per-match socket subscribe (see SportAPI_Core/LIVE_SCORES.md); avoids flooding the server.
  static const int _maxMatchSocketSubscriptions = 160;

  late final Dio _dio;
  io.Socket? _socket;

  /// Match IDs we last asked the socket for (live first, then scheduled). Re-sent on reconnect.
  final List<int> _matchSubscriptionIds = [];
  
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
        log('ShotMob WebSocket connected; global + per-match subscribe');
        _subscribeGlobalTopics();
        _flushPerMatchSubscriptions();
      });
      
      _socket?.onConnectError((err) => log('WebSocket Connect Error: $err'));
      _socket?.onDisconnect((_) => log('WebSocket Disconnected'));

      _socket?.on('score_update', (data) {
        log('WebSocket: score_update received: $data');
        _emitParsedWsPayload(data);
      });

      _socket?.on('match_update', (data) {
        log('WebSocket: match_update received: $data');
        _emitParsedWsPayload(data);
      });
    } catch (e) {
      log('WebSocket Init Error: $e');
    }
  }

  void _emitParsedWsPayload(dynamic data) {
    if (data is! Map) return;
    var map = Map<String, dynamic>.from(data as Map);
    if (map['data'] is Map) {
      final inner = Map<String, dynamic>.from(map['data'] as Map);
      map = {...map, ...inner};
    }
    try {
      if (map['homeTeam'] is Map || map['awayTeam'] is Map) {
        _updateController.add(ShotMatch.fromJson(map));
        return;
      }
      final id = _parseInt(map['id'] ?? map['matchId']);
      if (id != null) {
        _updateController.add(ShotMatch.fromRealtimePatch(map, matchId: id));
      }
    } catch (e) {
      log('WebSocket payload parse error: $e');
    }
  }

  /// Broad topics subscription (existing behaviour).
  void _subscribeGlobalTopics() {
    _socket?.emit('subscribe', {
      'data': {
        'topics': ['score', 'events'],
      },
    });
  }

  /// After each REST refresh, (re)register interest in live + upcoming matches for this day.
  void syncMatchSubscriptions(List<ShotMatch> matches) {
    final ids = _selectMatchIdsForSocket(matches);
    _matchSubscriptionIds
      ..clear()
      ..addAll(ids);
    _flushPerMatchSubscriptions();
  }

  List<int> _selectMatchIdsForSocket(List<ShotMatch> matches) {
    final out = <int>[];
    final seen = <int>{};
    void take(Iterable<ShotMatch> rows) {
      for (final m in rows) {
        if (out.length >= _maxMatchSocketSubscriptions) return;
        if (m.id == 0 || seen.contains(m.id)) continue;
        seen.add(m.id);
        out.add(m.id);
      }
    }

    take(matches.where((m) => m.isLive));
    take(matches.where((m) => m.isScheduled));
    return out;
  }

  void _flushPerMatchSubscriptions() {
    final s = _socket;
    if (s == null || s.connected != true) return;

    for (final id in _matchSubscriptionIds) {
      s.emit('subscribe', {
        'data': {
          'matchId': id,
          'topics': ['score', 'events'],
        },
      });
    }
    if (_matchSubscriptionIds.isNotEmpty) {
      log('ShotMob WS: per-match subscribe count=${_matchSubscriptionIds.length}');
    }
  }

  /// Fetch matches for a specific date (YYYY-MM-DD or 'today')
  Future<List<ShotMatch>> getMatches({String date = 'today'}) async {
    final dateStr = date == 'today' ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : date;

    try {
      final leagueRes = await _dio.get('/league/list');
      final leagues = _leaguesFromListResponse(leagueRes.data);
      if (leagues.isEmpty) {
        syncMatchSubscriptions([]);
        return [];
      }

      final ordered = _leaguesOrderedForFetch(leagues).take(_maxLeaguesPerDay).toList();
      final List<ShotMatch> allGames = [];

      for (var i = 0; i < ordered.length; i += _leagueFetchBatchSize) {
        final batch = ordered.skip(i).take(_leagueFetchBatchSize);
        await Future.wait(batch.map((league) async {
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
      }

      syncMatchSubscriptions(allGames);
      return allGames;
    } catch (e) {
      log('Error fetching matches dynamically: $e');
    }

    syncMatchSubscriptions([]);
    return [];
  }

  List<Map<String, dynamic>> _leaguesOrderedForFetch(List<Map<String, dynamic>> all) {
    final byId = <int, Map<String, dynamic>>{};
    for (final L in all) {
      final id = _parseInt(L['id']);
      if (id != null) byId[id] = L;
    }
    final out = <Map<String, dynamic>>[];
    final added = <int>{};
    for (final id in _priorityLeagueIds) {
      final L = byId[id];
      if (L != null) {
        out.add(L);
        added.add(id);
      }
    }
    for (final L in all) {
      final id = _parseInt(L['id']);
      if (id == null || added.contains(id)) continue;
      out.add(L);
      added.add(id);
    }
    return out;
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
    _matchSubscriptionIds.clear();
    _socket?.dispose();
    _updateController.close();
  }
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v);
  return null;
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
  /// Kick-off in local time for scheduled vs live display (optional).
  final DateTime? kickoffLocal;

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
    this.kickoffLocal,
  });

  bool get isLive =>
      status.toUpperCase() == 'LIVE' ||
      status.toUpperCase() == 'IN_PLAY' ||
      status.toUpperCase() == 'HT';
  bool get isFinished =>
      status.toUpperCase() == 'FINISHED' ||
      status.toUpperCase() == 'FT' ||
      status.toUpperCase() == 'END' ||
      status.toUpperCase() == 'AET' ||
      status.toUpperCase() == 'PEN' ||
      status.toUpperCase() == 'PENALTIES';

  bool get isScheduled => !isLive && !isFinished;

  ShotMatch copyWith({
    String? status,
    int? scoreHome,
    int? scoreAway,
    String? elapsedTime,
    String? matchTime,
    DateTime? kickoffLocal,
  }) {
    return ShotMatch(
      id: id,
      status: status ?? this.status,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeLogo: homeLogo,
      awayLogo: awayLogo,
      scoreHome: scoreHome ?? this.scoreHome,
      scoreAway: scoreAway ?? this.scoreAway,
      stadium: stadium,
      attendance: attendance,
      referee: referee,
      predictions: predictions,
      matchTime: matchTime ?? this.matchTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      leagueName: leagueName,
      kickoffLocal: kickoffLocal ?? this.kickoffLocal,
    );
  }

  /// Merge a partial realtime row into an existing match (scores, minute, status).
  ShotMatch applyPatch(ShotMatch patch) {
    if (patch.id != id) return this;
    return ShotMatch(
      id: id,
      status: patch.status != 'NS' && patch.status.isNotEmpty ? patch.status : status,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeLogo: homeLogo,
      awayLogo: awayLogo,
      scoreHome: patch.scoreHome,
      scoreAway: patch.scoreAway,
      stadium: stadium,
      attendance: attendance,
      referee: referee,
      predictions: predictions,
      matchTime: matchTime,
      elapsedTime: patch.elapsedTime ?? elapsedTime,
      leagueName: leagueName,
      kickoffLocal: kickoffLocal,
    );
  }

  factory ShotMatch.fromJson(Map<String, dynamic> json) {
    if (json['homeTeam'] is Map || json['awayTeam'] is Map) {
      return ShotMatch.fromShotMobGame(json, leagueName: json['league_name'] as String? ?? 'League');
    }
    return ShotMatch(
      id: _parseInt(json['id']) ?? 0,
      status: json['status'] as String? ?? 'NS',
      homeTeam: json['team_home'] ?? json['home_team_name'] ?? 'Home',
      awayTeam: json['team_away'] ?? json['away_team_name'] ?? 'Away',
      homeLogo: json['team_home_logo'],
      awayLogo: json['team_away_logo'],
      scoreHome: _parseInt(json['score_home']) ?? 0,
      scoreAway: _parseInt(json['score_away']) ?? 0,
      stadium: json['stadium'] ?? json['venue'],
      attendance: json['attendance']?.toString(),
      referee: json['referee'] ?? json['Referees'],
      predictions: json['predictions'] ?? json['Predictions'],
      matchTime: json['match_time'] ?? json['start_at'] ?? '',
      elapsedTime: json['elapsed_time'] ?? json['minute']?.toString(), // Map time counter
      leagueName: json['league_name'] ?? 'League',
      kickoffLocal: null,
    );
  }

  /// Minimal match row from websocket score payloads (merge with list item in UI).
  factory ShotMatch.fromRealtimePatch(Map<String, dynamic> json, {required int matchId}) {
    final raw = (json['status'] as String? ?? 'NS').toLowerCase().trim();
    String status;
    const finishedRaw = {
      'end', 'finished', 'ft', 'complete', 'completed', 'full_time',
      'fulltime', 'aet', 'pen', 'after_pen', 'afterpen', 'wo', 'awd',
    };
    const liveRaw = {'live', 'in_play', 'inplay', 'ongoing', '1h', '2h', 'ht'};
    if (finishedRaw.contains(raw)) {
      status = 'FT';
    } else if (liveRaw.contains(raw)) {
      status = 'LIVE';
    } else {
      status = (json['status'] as String? ?? 'NS').toUpperCase();
    }
    return ShotMatch(
      id: matchId,
      status: status,
      homeTeam: 'Home',
      awayTeam: 'Away',
      scoreHome: _parseInt(json['homeTeamScore'] ?? json['score_home']) ?? 0,
      scoreAway: _parseInt(json['awayTeamScore'] ?? json['score_away']) ?? 0,
      matchTime: '',
      elapsedTime: json['minute']?.toString() ?? json['elapsed_time']?.toString(),
      leagueName: 'League',
    );
  }

  /// `/league/list/games` nested game row (`homeTeam` / `awayTeam` objects, `homeTeamScore`, etc.).
  factory ShotMatch.fromShotMobGame(Map<String, dynamic> json, {required String leagueName}) {
    final homeMap = json['homeTeam'] is Map ? Map<String, dynamic>.from(json['homeTeam'] as Map) : <String, dynamic>{};
    final awayMap = json['awayTeam'] is Map ? Map<String, dynamic>.from(json['awayTeam'] as Map) : <String, dynamic>{};

    final raw = (json['status'] as String? ?? 'NS').toLowerCase().trim();
    String status;
    const finishedRaw = {
      'end', 'finished', 'ft', 'complete', 'completed', 'full_time',
      'fulltime', 'aet', 'pen', 'after_pen', 'afterpen', 'wo', 'awd',
    };
    const liveRaw = {'live', 'in_play', 'inplay', 'ongoing', '1h', '2h', 'ht'};
    if (finishedRaw.contains(raw)) {
      status = 'FT';
    } else if (liveRaw.contains(raw)) {
      status = 'LIVE';
    } else if (raw == 'ns' || raw == 'not_started' || raw == 'notstarted' || raw == 'scheduled' || raw == 'postponed') {
      status = 'NS';
    } else {
      status = (json['status'] as String? ?? 'NS').toUpperCase();
    }

    final dateStr = json['date'] as String?;
    var matchTime = '';
    DateTime? kickoffLocal;
    if (dateStr != null) {
      try {
        kickoffLocal = DateTime.parse(dateStr).toLocal();
        matchTime = DateFormat('hh:mm a').format(kickoffLocal);
      } catch (_) {}
    }

    return ShotMatch(
      id: _parseInt(json['id']) ?? 0,
      status: status,
      homeTeam: homeMap['name'] as String? ?? 'Home',
      awayTeam: awayMap['name'] as String? ?? 'Away',
      homeLogo: homeMap['logo'] as String?,
      awayLogo: awayMap['logo'] as String?,
      scoreHome: _parseInt(json['homeTeamScore'] ?? json['score_home']) ?? 0,
      scoreAway: _parseInt(json['awayTeamScore'] ?? json['score_away']) ?? 0,
      stadium: json['stadium'] ?? json['venue'],
      attendance: json['attendance']?.toString(),
      referee: json['referee']?.toString(),
      predictions: json['predictions']?.toString(),
      matchTime: matchTime,
      elapsedTime: json['minute']?.toString(),
      leagueName: leagueName,
      kickoffLocal: kickoffLocal,
    );
  }
}
