import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

final viewerServiceProvider = Provider((ref) => ViewerService());

final channelViewersProvider = StreamProvider.family<int, String>((ref, channelName) {
  return ref.watch(viewerServiceProvider).getViewersStream(channelName);
});

class ViewerService {
  static String? _deviceId;
  String? _currentChannelName;
  final _channelControllers = <String, StreamController<int>>{};

  static Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    String? id;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor;
      }
    } catch (_) {}

    if (id == null || id.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      id = prefs.getString('viewer_device_id');
      if (id == null) {
        id = 'DEV_${Random().nextInt(9999999).toString().padLeft(7, '0')}';
        await prefs.setString('viewer_device_id', id);
      }
    }
    
    _deviceId = id;
    return id;
  }

  Future<void> joinChannel(String channelName) async {
    if (channelName.isEmpty) return;
    
    // Sanitize the channel name slightly just in case it contains invalid characters for Firebase keys.
    // Firebase keys cannot contain: . # $ [ ]
    final safeName = channelName.replaceAll(RegExp(r'[\.#\$\[\]]'), '_');

    await leaveChannel(_currentChannelName ?? '');

    try {
      final deviceId = await _getDeviceId();
      _currentChannelName = safeName;

      final db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://kobani-4k-default-rtdb.europe-west1.firebasedatabase.app');
      final ref = db.ref('channel_viewers/$safeName/$deviceId');
      
      // Tell Firebase to delete this node automatically if the client disconnects!
      await ref.onDisconnect().remove();
      // Set the node to true, indicating we are watching
      await ref.set(true);

    } catch (e) {
      debugPrint('ViewerService.joinChannel error: $e');
    }
  }

  Future<void> leaveChannel(String channelName) async {
    if (_currentChannelName == null) return;
    try {
      final deviceId = await _getDeviceId();
      final db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://kobani-4k-default-rtdb.europe-west1.firebasedatabase.app');
      final ref = db.ref('channel_viewers/$_currentChannelName/$deviceId');
      
      await ref.remove();
      await ref.onDisconnect().cancel();
    } catch (e) {
      debugPrint('ViewerService.leaveChannel error: $e');
    }
    _currentChannelName = null;
  }

  Stream<int> getViewersStream(String channelName) {
    final safeName = channelName.replaceAll(RegExp(r'[\.#\$\[\]]'), '_');
    if (safeName.isEmpty) return Stream.value(0);

    if (_channelControllers.containsKey(safeName)) {
      return _channelControllers[safeName]!.stream;
    }

    final controller = StreamController<int>.broadcast();
    _channelControllers[safeName] = controller;

    final db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://kobani-4k-default-rtdb.europe-west1.firebasedatabase.app');
    final ref = db.ref('channel_viewers/$safeName');

    final sub = ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final val = event.snapshot.value;
          int count = 0;
          if (val is Map) {
            count = val.length;
          } else if (val is List) {
            count = val.where((e) => e != null).length;
          }
          if (!controller.isClosed) {
            controller.add(count);
          }
        } catch (e) {
          debugPrint('LiveViewers parsing error: $e');
          if (!controller.isClosed) controller.add(0);
        }
      } else {
        if (!controller.isClosed) controller.add(0);
      }
    }, onError: (error) {
       debugPrint('LiveViewers stream error: $error');
       if (!controller.isClosed) controller.add(0);
    });

    controller.onCancel = () {
      sub.cancel();
      _channelControllers.remove(safeName);
      controller.close();
    };

    return controller.stream;
  }

  Future<void> dispose() async {
    if (_currentChannelName != null) {
      await leaveChannel(_currentChannelName!);
    }
  }
}
