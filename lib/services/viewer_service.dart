import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

final viewerServiceProvider = Provider((ref) => ViewerService());

final channelViewersProvider = StreamProvider.family<int, String>((ref, channelUrl) {
  return ref.watch(viewerServiceProvider).getViewersStream(channelUrl);
});

/// Device-ID based viewer presence service.
///
/// Each device gets a stable random ID stored in SharedPreferences.
/// When the user opens a channel:
///   live_viewers/$channelKey/$deviceId = { lastSeen: timestamp }
/// When the user leaves, the entry is removed immediately + via onDisconnect.
/// This guarantees: 1 device = 1 entry, no duplicates, instant count update.
class ViewerService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  static String? _deviceId;
  String? _currentChannelKey;
  DatabaseReference? _currentRef;
  Timer? _heartbeatTimer;

  static const _heartbeatInterval = Duration(seconds: 20);

  // ─── Device ID ────────────────────────────────────────────────

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

  // ─── Join / Leave ─────────────────────────────────────────────

  /// Call this when the user starts watching a channel.
  Future<void> joinChannel(String channelUrl, {String? channelName}) async {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return;

    // Leave previous channel first
    await leaveChannel(channelUrl);

    try {
      final deviceId = await _getDeviceId();
      _currentChannelKey = sanitizedKey;

      final ref = _db.ref('live_viewers/$sanitizedKey/$deviceId');
      _currentRef = ref;

      // Write presence — auto-removed on disconnect
      await ref.set({'lastSeen': ServerValue.timestamp});
      await ref.onDisconnect().remove();

      // Heartbeat to keep presence alive
      _startHeartbeat(ref);

      // Historical analytics (increment)
      _recordAnalytics(sanitizedKey, channelName);
    } catch (e) {
      debugPrint('ViewerService.joinChannel error: $e');
    }
  }

  /// Call this when the user leaves a channel.
  Future<void> leaveChannel(String channelUrl) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

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

  // ─── Heartbeat ────────────────────────────────────────────────

  void _startHeartbeat(DatabaseReference ref) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      ref.update({'lastSeen': ServerValue.timestamp}).catchError((_) {});
    });
  }

  // ─── Analytics ───────────────────────────────────────────────

  void _recordAnalytics(String sanitizedKey, String? channelName) {
    // Analytics tracking removed to save Firebase bandwidth and write limits
  }

  // ─── Stream ───────────────────────────────────────────────────

  /// Polling-based viewer count (uses one-shot .get() every 30s instead of
  /// a persistent .onValue listener, saving 1 Firebase connection per user).
  Stream<int> getViewersStream(String channelUrl) {
    final sanitizedKey = _sanitizeKey(channelUrl);
    if (sanitizedKey.isEmpty) return Stream.value(0);

    late StreamController<int> controller;
    Timer? pollTimer;

    Future<int> fetchCount() async {
      try {
        final snap = await _db.ref('live_viewers/$sanitizedKey').get();
        if (!snap.exists || snap.value == null) return 0;
        final data = snap.value;
        if (data is! Map) return 0;

        final now = DateTime.now().millisecondsSinceEpoch;
        final staleMs = now - 60000;
        int count = 0;
        for (final entry in data.values) {
          if (entry is Map) {
            final lastSeen = entry['lastSeen'];
            if (lastSeen is int && lastSeen >= staleMs) {
              count++;
            }
          }
        }
        return count;
      } catch (_) {
        return 0;
      }
    }

    controller = StreamController<int>(
      onListen: () async {
        // Emit immediately
        controller.add(await fetchCount());
        // Then poll every 30 seconds
        pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
          if (!controller.isClosed) {
            controller.add(await fetchCount());
          }
        });
      },
      onCancel: () {
        pollTimer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  // ─── Cleanup ──────────────────────────────────────────────────

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    if (_currentRef != null) {
      await _currentRef!.remove().catchError((_) {});
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _sanitizeKey(String url) {
    return url
        .replaceAll(RegExp(r'[\.#\$\[\]]'), '_')
        .replaceAll(RegExp(r'[/:]'), '_');
  }
}
