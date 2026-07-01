import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class MonitorService {
  static String? _deviceId;
  static String? _currentCode;
  static String? _currentChannel;
  static DatabaseReference? _currentRef;

  static Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('monitor_device_id');
    if (id == null) {
      id = 'DEV_${Random().nextInt(999999).toString().padLeft(6, '0')}';
      await prefs.setString('monitor_device_id', id);
    }
    _deviceId = id;
    return id;
  }

  static Future<void> start(String code) async {
    _currentCode = code;
    _getDeviceId().then((id) {
       _setupSession(id);
    });
  }

  static void updateActivity(String? channelName) {
    _currentChannel = channelName;
    _updateSession();
  }

  static Future<void> _setupSession(String id) async {
    if (_currentCode == null) return;
    try {
      _currentRef = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://kobani-4k-default-rtdb.europe-west1.firebasedatabase.app')
          .ref('sync/global/activeSessions/$_deviceId');
          
      // Tell Firebase to delete this session when the user disconnects
      await _currentRef!.onDisconnect().remove();
      
      await _updateSession();
    } catch (e) {
      debugPrint('MonitorService setup error: $e');
    }
  }

  static Future<void> _updateSession() async {
    if (_currentRef == null || _deviceId == null || _currentCode == null) return;
    try {
      await _currentRef!.set({
        'deviceId': _deviceId,
        'code': _currentCode,
        'channel': _currentChannel ?? 'Dashboard',
        'platform': 'App',
        'joinedAt': ServerValue.timestamp,
      });
    } catch (e) {
       // Silent fail
    }
  }

  static void stop() {
    _currentCode = null;
    if (_currentRef != null) {
      _currentRef!.remove().catchError((_) {});
      _currentRef!.onDisconnect().cancel().catchError((_) {});
      _currentRef = null;
    }
  }
}
