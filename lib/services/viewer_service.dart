import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final viewerServiceProvider = Provider((ref) => ViewerService());

final channelViewersProvider = StreamProvider.family<int, String>((ref, channelUrl) {
  return ref.watch(viewerServiceProvider).getViewersStream(channelUrl);
});

class ViewerService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  // Track our presence refs so we can remove them manually if needed
  final Map<String, DatabaseReference> _presenceRefs = {};

  /// Join a channel to be counted as a viewer
  Future<void> joinChannel(String channelUrl, {String? channelName}) async {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return;
    
    try {
      // 1. Live presence
      final ref = _db.ref('live_viewers/$sanitizedKey').push();
      _presenceRefs[channelUrl] = ref;
      await ref.set(true);
      await ref.onDisconnect().remove();

      // 2. Historical Analytics (Increment counts)
      final now = DateTime.now().toUtc();
      final todayKey = "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}";
      
      final analyticsRef = _db.ref('sync/global/analytics');
      
      // Global App Views
      analyticsRef.child('views/total').set(ServerValue.increment(1));
      analyticsRef.child('views/daily/$todayKey').set(ServerValue.increment(1));
      
      // Channel Specific Views
      analyticsRef.child('channel_views/$sanitizedKey/total').set(ServerValue.increment(1));
      analyticsRef.child('channel_views/$sanitizedKey/daily/$todayKey').set(ServerValue.increment(1));
      if (channelName != null) {
        analyticsRef.child('channel_views/$sanitizedKey/name').set(channelName);
      }
      
    } catch (e) {
      debugPrint('Error joining channel: $e');
    }
  }

  /// Leave a channel
  Future<void> leaveChannel(String channelUrl) async {
    final ref = _presenceRefs.remove(channelUrl);
    if (ref != null) {
      try {
        await ref.remove();
        await ref.onDisconnect().cancel();
      } catch (e) {
        debugPrint('Error leaving channel: $e');
      }
    }
  }

  /// Get real-time stream of viewer count
  Stream<int> getViewersStream(String channelUrl) {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return Stream.value(0);
    
    return _db.ref('live_viewers/$sanitizedKey').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.length;
    });
  }

  /// Firebase keys cannot contain . # $ [ ]
  String _sanitizeKey(String url) {
    return url.replaceAll(RegExp(r'[\.\#\$\[\]]'), '_').replaceAll(RegExp(r'[/:]'), '_');
  }
}
