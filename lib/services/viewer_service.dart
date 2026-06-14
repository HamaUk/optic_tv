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
  Future<void> joinChannel(String channelUrl) async {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return;
    
    try {
      final ref = _db.ref('live_viewers/$sanitizedKey').push();
      _presenceRefs[channelUrl] = ref;
      
      await ref.set(true);
      
      // Auto-remove when the app closes or disconnects
      await ref.onDisconnect().remove();
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
