import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pocketbase_database_mock.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rxdart/rxdart.dart';
import 'pocketbase_service.dart';

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  final PocketBaseDatabase _db = PocketBaseDatabase.instance;

  Stream<int> getLiveUsersStream() {
    return Stream.periodic(const Duration(seconds: 15), (_) => _fetchCount())
        .asyncMap((event) => event)
        .startWith(0)
        .distinct();
  }
  
  Future<int> _fetchCount() async {
     try {
        final pb = PocketBaseService().pb;
        final staleMs = DateTime.now().millisecondsSinceEpoch - 60000;
        final result = await pb.collection('live_viewers').getList(
           page: 1, 
           perPage: 1, 
           filter: 'last_active >= $staleMs'
        );
        return result.totalItems;
     } catch (_) {
        return 0;
     }
  }

  Future<void> trackAppOpen() async {
    try {
      final ref = _db.ref('sync/global/analytics/views/total');
      final snap = await ref.get();
      int current = 0;
      if (snap.exists && snap.value != null) {
        final data = snap.value as Map<dynamic, dynamic>;
        current = (data['total'] as num?)?.toInt() ?? 0;
      }
      await ref.set({'total': current + 1});
    } catch (e) {
      // Silently fail if DB is unavailable
    }
  }

  Stream<int> getTotalViewsStream() {
    return _db.ref('sync/global/analytics/views/total').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return (data['total'] as num?)?.toInt() ?? 0;
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
