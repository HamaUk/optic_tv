import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

final viewerServiceProvider = Provider((ref) => ViewerService());

final channelViewersProvider = StreamProvider.family<int, String>((ref, channelUrl) {
  return ref.watch(viewerServiceProvider).getViewersStream(channelUrl);
});

class ViewerService {
  static String? _deviceId;
  String? _currentChannelKey;
  DatabaseReference? _currentRef;

  static Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('viewer_device_id');
    if (id == null) {
      id = 'DEV_${Random().nextInt(9999999).toString().padLeft(7, '0')}';
      await prefs.setString('viewer_device_id', id);
    }
    _deviceId = id;
    return id;
  }

  Future<void> joinChannel(String channelUrl, {String? channelName}) async {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return;

    await leaveChannel(channelUrl);

    try {
      final deviceId = await _getDeviceId();
      _currentChannelKey = sanitizedKey;

      _currentRef = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://kobani-4k-default-rtdb.europe-west1.firebasedatabase.app').ref('sync/global/liveViewers/$sanitizedKey/$deviceId');
      
      // Tell Firebase to automatically delete this record when the user disconnects
      await _currentRef!.onDisconnect().remove();
      
      // Write the initial record
      await _currentRef!.set({
        'joinedAt': ServerValue.timestamp,
      });

    } catch (e) {
      debugPrint('ViewerService.joinChannel error: $e');
    }
  }

  Future<void> leaveChannel(String channelUrl) async {
    if (_currentRef != null) {
      try {
        await _currentRef!.remove();
        await _currentRef!.onDisconnect().cancel();
      } catch (e) {
        debugPrint('ViewerService.leaveChannel error: $e');
      }
      _currentRef = null;
    }
    _currentChannelKey = null;
  }

  Stream<int> getViewersStream(String channelUrl) {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return Stream.value(0);

    final ref = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://kobani-4k-default-rtdb.europe-west1.firebasedatabase.app').ref('sync/global/liveViewers/$sanitizedKey');
    
    return ref.onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.length;
    });
  }

  Future<void> dispose() async {
    if (_currentRef != null) {
      await _currentRef!.remove().catchError((_) {});
      await _currentRef!.onDisconnect().cancel().catchError((_) {});
    }
  }

  String _sanitizeKey(String url) {
    return url
        .replaceAll(RegExp(r'[\.#\$\[\]]'), '_')
        .replaceAll(RegExp(r'[/:]'), '_');
  }
}
