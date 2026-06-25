import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<int> getLiveUsersCount() async {
    try {
      final snap = await _db.ref('live_viewers').get();
      if (!snap.exists || snap.value == null) return 0;

      int totalActive = 0;
      final data = snap.value as Map<dynamic, dynamic>;
      data.forEach((channelKey, channelData) {
        if (channelData is Map) {
          totalActive += channelData.length;
        }
      });
      return totalActive;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getTotalViews() async {
    try {
      final snap = await _db.ref('sync/global/analytics/views/total').get();
      if (!snap.exists || snap.value == null) return 0;
      return (snap.value as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> getDailyViews() async {
    try {
      final snap = await _db.ref('sync/global/analytics/views/daily').get();
      if (!snap.exists || snap.value == null) return {};
      final data = snap.value as Map<dynamic, dynamic>;
      return data.map((key, value) => MapEntry(key.toString(), (value as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getTopChannels({int limit = 10}) async {
    try {
      final snap = await _db.ref('sync/global/analytics/channel_views').get();
      if (!snap.exists || snap.value == null) return [];

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
    } catch (_) {
      return [];
    }
  }
}
