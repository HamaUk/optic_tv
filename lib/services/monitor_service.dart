import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class MonitorService {
  static const _rtdbPath = 'sync/global/activeSessions';
  static Timer? _timer;
  static String? _deviceId;
  static String? _currentCode;
  static String? _currentChannel;

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
       _setupHeartbeat(id);
    });
  }

  static void updateActivity(String? channelName) {
    _currentChannel = channelName;
    _ping(); // Immediate ping on activity change
  }

  static void _setupHeartbeat(String id) {
    _timer?.cancel();
    _ping();
    // Heartbeat every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _ping());
    
    // Clean up when app disconnects
    FirebaseDatabase.instance.ref('$_rtdbPath/$id').onDisconnect().remove();
  }

  static Future<void> _ping() async {
    if (_deviceId == null || _currentCode == null) return;
    try {
      await FirebaseDatabase.instance.ref('$_rtdbPath/$_deviceId').set({
        'code': _currentCode,
        'channel': _currentChannel ?? 'Dashboard',
        'lastSeen': ServerValue.timestamp,
        'platform': 'App',
      });
    } catch (e) {
       // Silent fail for pings
    }
  }

  static void stop() {
    _timer?.cancel();
    _currentCode = null;
    if (_deviceId != null) {
      FirebaseDatabase.instance.ref('$_rtdbPath/$_deviceId').remove();
    }
  }
}
