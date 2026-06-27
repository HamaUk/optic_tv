import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'pocketbase_service.dart';

class MonitorService {
  static Timer? _timer;
  static String? _deviceId;
  static String? _currentCode;
  static String? _currentChannel;
  static String? _recordId;

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
    _ping();
  }

  static void _setupHeartbeat(String id) {
    _timer?.cancel();
    _ping();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _ping());
  }

  static Future<void> _ping() async {
    if (_deviceId == null || _currentCode == null) return;
    try {
      final body = {
        'deviceId': _deviceId,
        'code': _currentCode,
        'channel': _currentChannel ?? 'Dashboard',
        'platform': 'App',
        'lastSeen': DateTime.now().toUtc().toIso8601String(),
      };

      if (_recordId == null) {
        try {
            final existing = await pb.collection('activeSessions').getFirstListItem('deviceId="$_deviceId"');
            _recordId = existing.id;
            await pb.collection('activeSessions').update(_recordId!, body: body);
        } catch (_) {
            final record = await pb.collection('activeSessions').create(body: body);
            _recordId = record.id;
        }
      } else {
        await pb.collection('activeSessions').update(_recordId!, body: body);
      }
    } catch (e) {
       // Silent fail
    }
  }

  static void stop() {
    _timer?.cancel();
    _currentCode = null;
    if (_recordId != null) {
      pb.collection('activeSessions').delete(_recordId!).catchError((_) {});
      _recordId = null;
    }
  }
}
