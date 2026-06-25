import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<int> getLiveUsersStream() {
    return _db.ref('live_viewers').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      
      int totalActive = 0;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      
      // Iterate through all channel nodes
      data.forEach((channelKey, channelData) {
        if (channelData is Map) {
          // Count the number of active device IDs in this channel
          totalActive += channelData.length;
        }
      });
      
      return totalActive;
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
