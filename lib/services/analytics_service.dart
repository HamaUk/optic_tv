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

  Future<int> getTotalViews() async {
    final snap = await _db.ref('sync/global/analytics/views/total').get();
    if (snap.value == null) return 0;
    return (snap.value as num).toInt();
  }

  Future<Map<String, int>> getDailyViews() async {
    final snap = await _db.ref('sync/global/analytics/views/daily').get();
    if (snap.value == null) return {};
    final data = snap.value as Map<dynamic, dynamic>;
    return data.map((key, value) => MapEntry(key.toString(), (value as num).toInt()));
  }

  Future<List<Map<String, dynamic>>> getTopChannels({int limit = 10}) async {
    final snap = await _db.ref('sync/global/analytics/channel_views').get();
    if (snap.value == null) return [];
    
    final data = snap.value as Map<dynamic, dynamic>;
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
  }
}
