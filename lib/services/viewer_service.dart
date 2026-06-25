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
  final Map<String, List<DatabaseReference>> _presenceRefs = {};
  
  // Heartbeat timer to keep presence alive and clean stale entries
  final Map<String, Timer> _heartbeatTimers = {};
  static const _heartbeatInterval = Duration(seconds: 15);
  static const _staleTimeout = Duration(seconds: 60);

  /// Join a channel to be counted as a viewer
  Future<void> joinChannel(String channelUrl, {String? channelName}) async {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return;
    
    try {
      // 1. Live presence with timestamp for stale detection
      final ref = _db.ref('live_viewers/$sanitizedKey').push();
      if (!_presenceRefs.containsKey(channelUrl)) {
        _presenceRefs[channelUrl] = [];
      }
      _presenceRefs[channelUrl]!.add(ref);
      
      // Set with timestamp for heartbeat tracking
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await ref.set({
        'active': true,
        'lastSeen': timestamp,
      });
      await ref.onDisconnect().remove();
      
      // Start heartbeat to keep this entry alive
      _startHeartbeat(channelUrl, ref, timestamp);

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
      
      // Clean stale entries periodically
      _cleanStaleEntries(sanitizedKey);
      
    } catch (e) {
      debugPrint('Error joining channel: $e');
    }
  }

  /// Leave a channel
  Future<void> leaveChannel(String channelUrl) async {
    // Stop heartbeat timer
    _heartbeatTimers[channelUrl]?.cancel();
    _heartbeatTimers.remove(channelUrl);
    
    final refs = _presenceRefs.remove(channelUrl);
    if (refs != null) {
      for (final ref in refs) {
        try {
          await ref.remove();
          await ref.onDisconnect().cancel();
        } catch (e) {
          debugPrint('Error leaving channel reference: $e');
        }
      }
    }
  }
  
  /// Start heartbeat timer to keep presence alive
  void _startHeartbeat(String channelUrl, DatabaseReference ref, int initialTimestamp) {
    _heartbeatTimers[channelUrl]?.cancel();
    _heartbeatTimers[channelUrl] = Timer.periodic(_heartbeatInterval, (timer) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      ref.update({'lastSeen': timestamp});
    });
  }
  
  /// Clean stale entries that haven't been updated recently
  Future<void> _cleanStaleEntries(String sanitizedKey) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final staleThreshold = now - _staleTimeout.inMilliseconds;
      
      final snapshot = await _db.ref('live_viewers/$sanitizedKey').get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          if (entry.value is Map) {
            final viewerData = entry.value as Map;
            final lastSeen = viewerData['lastSeen'];
            if (lastSeen != null && lastSeen is int && lastSeen < staleThreshold) {
              // Remove stale entry
              await _db.ref('live_viewers/$sanitizedKey/${entry.key}').remove();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning stale entries: $e');
    }
  }

  /// Get real-time stream of viewer count (only counts active, non-stale entries)
  Stream<int> getViewersStream(String channelUrl) {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return Stream.value(0);
    
    return _db.ref('live_viewers/$sanitizedKey').onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      
      // Only count entries that have been updated recently (active viewers)
      final now = DateTime.now().millisecondsSinceEpoch;
      final staleThreshold = now - _staleTimeout.inMilliseconds;
      int activeCount = 0;
      
      for (final entry in data.values) {
        if (entry is Map) {
          final lastSeen = entry['lastSeen'];
          if (lastSeen != null && lastSeen is int && lastSeen >= staleThreshold) {
            activeCount++;
          }
        }
      }
      
      return activeCount;
    });
  }

  /// Firebase keys cannot contain . # $ [ ]
  String _sanitizeKey(String url) {
    return url.replaceAll(RegExp(r'[\.\#\$\[\]]'), '_').replaceAll(RegExp(r'[/:]'), '_');
  }
}
