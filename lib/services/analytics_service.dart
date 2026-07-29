import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pocketbase_service.dart';

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  String? _userId;
  late String _sessionId;
  bool _appOpenTracked = false;

  AnalyticsService() {
    _sessionId = _generateId();
    _initUserId();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + '_' + Random().nextInt(100000).toString();
  }

  Future<void> _initUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('analytics_user_id');
      if (_userId == null) {
        _userId = _generateId();
        await prefs.setString('analytics_user_id', _userId!);
      }
    } catch (e) {
      debugPrint('Analytics init error: $e');
      _userId = _generateId();
    }
  }

  Future<void> trackAppOpen() async {
    if (_appOpenTracked) return; // Only track once per session
    _appOpenTracked = true;
    await _postEvent('app_open');
  }

  Future<void> trackChannelStart(String channelId, String channelName) async {
    await _postEvent('channel_start', channelId: channelId, channelName: channelName);
  }

  Future<void> trackChannelStop(String channelId, String channelName) async {
    await _postEvent('channel_stop', channelId: channelId, channelName: channelName);
  }

  Future<void> _postEvent(String eventType, {String? channelId, String? channelName}) async {
    try {
      if (_userId == null) await _initUserId();
      
      final pb = PocketBaseService().pb;
      await pb.collection('analytics_events').create(body: {
        'user_id': _userId,
        'session_id': _sessionId,
        'event_type': eventType,
        'channel_id': channelId ?? '',
        'channel_name': channelName ?? '',
      });
    } catch (e) {
      debugPrint('Failed to post analytics event: $e');
    }
  }

  Stream<AnalyticsDashboardData> getDashboardDataStream() {
    return Stream.periodic(const Duration(seconds: 10))
        .startWith(0)
        .asyncMap((_) => _fetchDashboardData());
  }

  Future<AnalyticsDashboardData> _fetchDashboardData() async {
    try {
      final pb = PocketBaseService().pb;
      
      // Get start of today (UTC)
      final now = DateTime.now().toUtc();
      final startOfDay = DateTime.utc(now.year, now.month, now.day).toIso8601String().replaceFirst('T', ' ');
      
      // Fetch all-time stats from the super-fast view
      final allTimeStatsRes = await pb.collection('analytics_all_time_stats').getFullList();
      int allTimeUniqueUsers = 0;
      int allTimeTotalSessions = 0;
      int allTimeChannelStarts = 0;
      
      if (allTimeStatsRes.isNotEmpty) {
        final stats = allTimeStatsRes.first;
        allTimeUniqueUsers = stats.getIntValue('unique_users');
        allTimeTotalSessions = stats.getIntValue('total_sessions');
        allTimeChannelStarts = stats.getIntValue('channel_views');
      }

      // Fetch ONLY today's records to save bandwidth and memory
      final records = await pb.collection('analytics_events').getFullList(
        filter: 'created >= "$startOfDay"'
      );
      
      
      final uniqueUsers = <String>{};
      final uniqueSessions = <String>{};
      int channelStarts = 0;
      
      // 4-Hour buckets: 0, 1, 2, 3, 4, 5 (for 00-04, 04-08, ...)
      final fourHourBuckets = <int, Set<String>>{0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}};
      final channelCounts = <String, int>{};
      final channelNames = <String, String>{};

      for (var r in records) {
        final userId = r.getStringValue('user_id');
        final sessionId = r.getStringValue('session_id');
        final type = r.getStringValue('event_type');
        final chId = r.getStringValue('channel_id');
        final chName = r.getStringValue('channel_name');
        
        // Parse time to get 4-hour bucket
        final createdStr = r.getStringValue('created');
        if (createdStr.isEmpty) continue;
        
        final dtUtc = DateTime.tryParse(createdStr)?.toUtc();
        if (dtUtc == null) continue;
        
        // We no longer calculate allTime stats manually because they are fetched from the view.

        // All records fetched are guaranteed to be from today because of the PocketBase filter!

        final dt = dtUtc.toLocal();
        if (userId.isNotEmpty) {
          final bucket = dt.hour ~/ 4;
          if (bucket >= 0 && bucket <= 5) {
            fourHourBuckets[bucket]!.add(userId);
          }
        }
        
        if (userId.isNotEmpty) uniqueUsers.add(userId);
        if (sessionId.isNotEmpty) uniqueSessions.add(sessionId);
        
        if (type == 'channel_start') {
          channelStarts++;
          if (chName.isNotEmpty) {
             channelCounts[chName] = (channelCounts[chName] ?? 0) + 1;
          }
        }
      }
      
      final bucketCounts = <String, int>{
        '00-04': fourHourBuckets[0]!.length,
        '04-08': fourHourBuckets[1]!.length,
        '08-12': fourHourBuckets[2]!.length,
        '12-16': fourHourBuckets[3]!.length,
        '16-20': fourHourBuckets[4]!.length,
        '20-24': fourHourBuckets[5]!.length,
      };
      
      final topChannels = channelCounts.entries.map((e) => {
        'name': e.key,
        'total': e.value,
      }).toList();
      
      topChannels.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

      return AnalyticsDashboardData(
        uniqueUsers: uniqueUsers.length,
        totalSessions: uniqueSessions.length,
        channelViews: channelStarts,
        allTimeUniqueUsers: allTimeUniqueUsers,
        allTimeTotalSessions: allTimeTotalSessions,
        allTimeChannelViews: allTimeChannelStarts,
        usersBy4Hour: bucketCounts,
        topChannels: topChannels.take(5).toList(),
      );
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      return AnalyticsDashboardData.empty();
    }
  }
}

class AnalyticsDashboardData {
  final int uniqueUsers;
  final int totalSessions;
  final int channelViews;
  final int allTimeUniqueUsers;
  final int allTimeTotalSessions;
  final int allTimeChannelViews;
  final Map<String, int> usersBy4Hour;
  final List<Map<String, dynamic>> topChannels;

  AnalyticsDashboardData({
    required this.uniqueUsers,
    required this.totalSessions,
    required this.channelViews,
    required this.allTimeUniqueUsers,
    required this.allTimeTotalSessions,
    required this.allTimeChannelViews,
    required this.usersBy4Hour,
    required this.topChannels,
  });

  factory AnalyticsDashboardData.empty() => AnalyticsDashboardData(
    uniqueUsers: 0,
    totalSessions: 0,
    channelViews: 0,
    allTimeUniqueUsers: 0,
    allTimeTotalSessions: 0,
    allTimeChannelViews: 0,
    usersBy4Hour: {'00-04': 0, '04-08': 0, '08-12': 0, '12-16': 0, '16-20': 0, '20-24': 0},
    topChannels: [],
  );
}
