import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pocketbase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  Future<int> getLiveUsersCount() async {
    try {
      final ref = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://kobani-4k-default-rtdb.europe-west1.firebasedatabase.app').ref('sync/global/liveViewers');
      final snapshot = await ref.get();
      if (!snapshot.exists || snapshot.value == null) return 0;
      
      int total = 0;
      final data = snapshot.value as Map<dynamic, dynamic>;
      for (final channelViewers in data.values) {
        if (channelViewers is Map) {
          total += channelViewers.length;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getTotalViews() async {
    try {
      final record = await pb.collection('analytics_views_total').getFirstListItem('');
      return record.getIntValue('total');
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> getDailyViews() async {
    try {
      final records = await pb.collection('analytics_views_daily').getFullList();
      final map = <String, int>{};
      for (final r in records) {
        map[r.getStringValue('date')] = r.getIntValue('views');
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getTopChannels({int limit = 10}) async {
    try {
      final records = await pb.collection('analytics_channel_views').getFullList(
        sort: '-total',
      );
      
      return records.take(limit).map((r) => {
        'key': r.id,
        'name': r.getStringValue('name'),
        'total': r.getIntValue('total'),
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
