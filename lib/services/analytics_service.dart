import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<int> getLiveUsersStream() {
    return _db.ref('sync/global/activeSessions').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      // Filter out stale sessions (older than 3 minutes)
      final now = DateTime.now().millisecondsSinceEpoch;
      int active = 0;
      data.forEach((key, value) {
        if (value is Map && value.containsKey('lastSeen')) {
          final lastSeen = value['lastSeen'] as int;
          if (now - lastSeen < 3 * 60 * 1000) {
            active++;
          }
        }
      });
      return active;
    });
  }

  Stream<int> getLiveChannelViewersStream(String channelName) {
    return _db.ref('sync/global/activeSessions').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;
      int active = 0;
      data.forEach((key, value) {
        if (value is Map && value.containsKey('lastSeen')) {
          final lastSeen = value['lastSeen'] as int;
          final channel = value['channel']?.toString();
          if (now - lastSeen < 3 * 60 * 1000 && channel == channelName) {
            active++;
          }
        }
      });
      return active;
    });
  }

  Stream<int> getTotalViewsStream() {
    return _db.ref('sync/global/analytics/views/total').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      return (event.snapshot.value as num).toInt();
    });
  }

  Stream<Map<String, int>> getDailyViewsStream() {
    return _db.ref('sync/global/analytics/views/daily').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.map((key, value) => MapEntry(key.toString(), (value as num).toInt()));
    });
  }

  Stream<List<Map<String, dynamic>>> getTopChannelsStream({int limit = 10}) {
    return _db.ref('sync/global/analytics/channel_views').onValue.map((event) {
      if (event.snapshot.value == null) return [];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final channels = <Map<String, dynamic>>[];
      
      data.forEach((key, value) {
        if (value is Map) {
          final total = (value['total'] as num?)?.toInt() ?? 0;
          final name = value['name']?.toString() ?? 'Unknown Channel';
          channels.add({
            'key': key.toString(),
            'name': name,
            'total': total,
          });
        }
      });

      channels.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      return channels.take(limit).toList();
    });
  }
}
