import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pocketbase_database_mock.dart';

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  final PocketBaseDatabase _db = PocketBaseDatabase.instance;

  Stream<int> getLiveUsersStream() {
    return _db.ref('liveViewers').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      // In PocketBase, each record in liveViewers is a distinct active session
      return data.length;
    });
  }

  Stream<int> getTotalViewsStream() {
    return _db.ref('sync/global/analytics/views/total').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      if (data.isNotEmpty && data.values.first is Map) {
        final firstRecord = data.values.first as Map;
        return (firstRecord['total'] as num?)?.toInt() ?? 0;
      }
      return 0;
    });
  }

  Stream<Map<String, int>> getDailyViewsStream() {
    return _db.ref('sync/global/analytics/views/daily').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      
      final result = <String, int>{};
      data.forEach((key, value) {
        if (value is Map) {
           final dateStr = value['date']?.toString() ?? value['id']?.toString() ?? key.toString();
           final count = (value['count'] as num?)?.toInt() ?? 0;
           result[dateStr] = count;
        }
      });
      return result;
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
