import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'pocketbase_service.dart';

final viewerServiceProvider = Provider((ref) => ViewerService());

final channelViewersProvider = StreamProvider.family<int, String>((ref, channelUrl) {
  return ref.watch(viewerServiceProvider).getViewersStream(channelUrl);
});

class ViewerService {
  static String? _deviceId;
  String? _currentChannelKey;
  String? _recordId;
  Timer? _heartbeatTimer;

  static const _heartbeatInterval = Duration(seconds: 20);

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

      final body = {
        'channelKey': sanitizedKey,
        'deviceId': deviceId,
        'lastSeen': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        final existing = await pb.collection('liveViewers').getFirstListItem('deviceId="$deviceId"');
        _recordId = existing.id;
        await pb.collection('liveViewers').update(_recordId!, body: body);
      } catch (_) {
        final record = await pb.collection('liveViewers').create(body: body);
        _recordId = record.id;
      }

      _startHeartbeat();
    } catch (e) {
      debugPrint('ViewerService.joinChannel error: $e');
    }
  }

  Future<void> leaveChannel(String channelUrl) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_recordId != null) {
      try {
        await pb.collection('liveViewers').delete(_recordId!);
      } catch (e) {
        debugPrint('ViewerService.leaveChannel error: $e');
      }
      _recordId = null;
    }
    _currentChannelKey = null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (_recordId != null) {
        try {
          await pb.collection('liveViewers').update(_recordId!, body: {
            'lastSeen': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {}
      }
    });
  }

  Stream<int> getViewersStream(String channelUrl) {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return Stream.value(0);

    final controller = StreamController<int>.broadcast();

    void fetchCount() {
      // Fetch viewers updated in the last 60 seconds
      final staleTime = DateTime.now().toUtc().subtract(const Duration(seconds: 60)).toIso8601String();
      pb.collection('liveViewers').getList(
        page: 1, 
        perPage: 1, 
        filter: 'channelKey="$sanitizedKey" && lastSeen >= "$staleTime"'
      ).then((res) {
        if (!controller.isClosed) controller.add(res.totalItems);
      }).catchError((_) {});
    }

    fetchCount();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) => fetchCount());

    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    if (_recordId != null) {
      await pb.collection('liveViewers').delete(_recordId!).catchError((_) {});
    }
  }

  String _sanitizeKey(String url) {
    return url
        .replaceAll(RegExp(r'[\.#\$\[\]]'), '_')
        .replaceAll(RegExp(r'[/:]'), '_');
  }
}
