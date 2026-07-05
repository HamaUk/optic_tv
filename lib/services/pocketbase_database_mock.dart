import 'dart:async';
import 'dart:math';
import 'package:pocketbase/pocketbase.dart';
import 'package:rxdart/rxdart.dart';
import 'pocketbase_service.dart';
import 'notification_service.dart';

class PocketBaseDatabase {
  static final instance = PocketBaseDatabase();
  DatabaseReference ref(String path) => DatabaseReference(path);

  Future<void> notify(String targetPath) async {
    final controller = DatabaseReference._streamCache[targetPath];
    if (controller != null && !controller.isClosed) {
      final snap = await ref(targetPath).get();
      controller.add(DatabaseEvent(snap));
    }
  }
}

class DataSnapshot {
  final String? key;
  final dynamic value;
  DataSnapshot(this.key, this.value);
  bool get exists => value != null;
}

class DatabaseEvent {
  final DataSnapshot snapshot;
  DatabaseEvent(this.snapshot);
}

class DatabaseReference {
  final String path;
  DatabaseReference(this.path);

  DatabaseReference child(String pathStr) {
    if (pathStr.startsWith('/')) pathStr = pathStr.substring(1);
    return DatabaseReference('$path/$pathStr');
  }

  DatabaseReference push() {
    // Generate exactly 15 lowercase alphanumeric chars for PocketBase ID
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    final id = String.fromCharCodes(Iterable.generate(
      15, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return DatabaseReference('$path/$id');
  }

  String get key => path.split('/').last;

  String get _collectionName {
    if (path.contains('managedPlaylist')) return 'managedPlaylist';
    if (path.contains('channelGroups')) return 'channelGroups';
    if (path.contains('loginCodes')) return 'loginCodes';
    if (path.contains('announcement')) return 'announcements';
    if (path.contains('notifications/broadcast')) return 'broadcasts';
    if (path.contains('notifications/history')) return 'broadcasts';
    if (path.contains('updateManager')) return 'updateManager';
    if (path.contains('activeSessions')) return 'activeSessions';
    if (path.contains('liveViewers') || path.contains('live_viewers')) return 'liveViewers';
    if (path.contains('analytics/views/total')) return 'analytics_views_total';
    if (path.contains('analytics/views/daily')) return 'analytics_views_daily';
    if (path.contains('analytics/channel_views')) return 'analytics_channel_views';
    return 'unknown';
  }

  String? get _recordId {
    if (path.contains('updateManager')) return 'globalupdate123';
    if (path.endsWith('notifications/broadcast')) return 'globalbroadcast';
    if (path.contains('announcement')) return 'globalannounce1';
    
    final parts = path.split('/');
    if (parts.length > 3) return parts.last;
    return null;
  }

  Future<DataSnapshot> get() async {
    final col = _collectionName;
    final id = _recordId;

    try {
      if (id != null) {
        final record = await pb.collection(col).getOne(id);
        return DataSnapshot(id, record.toJson());
      } else {
        final records = await pb.collection(col).getFullList();
        final map = <String, dynamic>{};
        for (var r in records) {
          map[r.id] = r.toJson();
        }
        return DataSnapshot(key, map.isEmpty ? null : map);
      }
    } catch (_) {
      return DataSnapshot(key, null);
    }
  }

  // Use a static map to cache BehaviorSubjects by path so they aren't recreated on every build
  // BehaviorSubject remembers the latest value and emits it immediately to new listeners!
  static final Map<String, BehaviorSubject<DatabaseEvent>> _streamCache = {};

  Stream<DatabaseEvent> get onValue {
    if (_streamCache.containsKey(path)) {
      return _streamCache[path]!.stream;
    }

    final col = _collectionName;
    final id = _recordId;
    
    // Create a BehaviorSubject
    final controller = BehaviorSubject<DatabaseEvent>();

    void fetchAndEmit() async {
      final snap = await get();
      if (!controller.isClosed) {
        controller.add(DatabaseEvent(snap));
      }
    }

    // Always fetch immediately
    fetchAndEmit();

    controller.onCancel = () {
      if (!controller.hasListener) {
        controller.close();
        _streamCache.remove(path);
      }
    };

    _streamCache[path] = controller;
    return controller.stream;
  }

  Future<void> set(dynamic value) async {
    final col = _collectionName;
    final id = _recordId;
    if (id != null) {
      if (value == null) {
        try { await pb.collection(col).delete(id); } catch (_) {}
      } else {
        try {
          await pb.collection(col).update(id, body: value);
        } catch (_) {
          try {
            await pb.collection(col).create(body: {'id': id, ...?value as Map?});
          } catch (_) {
            await pb.collection(col).create(body: value);
          }
        }
      }
    } else {
      if (value is Map) {
        await Future.wait(value.keys.map((k) async {
          try {
            await pb.collection(col).create(body: {'id': k, ...?value[k] as Map?});
          } catch (_) {}
        }));
      }
    }
    await PocketBaseDatabase.instance.notify(path);
    NotificationService().sendSilentRefreshPulse(col);
  }

  Future<void> update(Map<String, dynamic> value) async {
    final col = _collectionName;
    final id = _recordId;
    if (id != null) {
      try {
        await pb.collection(col).update(id, body: value);
      } catch (_) {
        try { await pb.collection(col).create(body: {'id': id, ...value}); } catch (_) {}
      }
    } else {
      // Firebase-style multi-path updates use keys like "recordId/field".
      // Group these by record ID so we send one pb.update() per record.
      final grouped = <String, Map<String, dynamic>>{};
      final direct = <String, dynamic>{};

      for (final entry in value.entries) {
        if (entry.key.contains('/')) {
          final slashIdx = entry.key.indexOf('/');
          final recId = entry.key.substring(0, slashIdx);
          final field = entry.key.substring(slashIdx + 1);
          grouped.putIfAbsent(recId, () => <String, dynamic>{});
          grouped[recId]![field] = entry.value;
        } else {
          direct[entry.key] = entry.value;
        }
      }

      // Handle grouped multi-path updates (e.g. reorder)
      await Future.wait(grouped.entries.map((entry) async {
        try {
          await pb.collection(col).update(entry.key, body: entry.value);
        } catch (_) {
          try { await pb.collection(col).create(body: {'id': entry.key, ...entry.value}); } catch (_) {}
        }
      }));

      // Handle direct key-value updates (original behavior)
      await Future.wait(direct.entries.map((entry) async {
        if (entry.value == null) {
          try { await pb.collection(col).delete(entry.key); } catch (_) {}
        } else {
          try {
            await pb.collection(col).update(entry.key, body: entry.value);
          } catch (_) {
            try { await pb.collection(col).create(body: {'id': entry.key, ...?entry.value as Map?}); } catch (_) {}
          }
        }
      }));
    }
    await PocketBaseDatabase.instance.notify(path);
    NotificationService().sendSilentRefreshPulse(col);
  }

  Future<void> remove() async {
    final col = _collectionName;
    final id = _recordId;
    if (id != null) {
      try { await pb.collection(col).delete(id); } catch (_) {}
    }
    await PocketBaseDatabase.instance.notify(path);
    NotificationService().sendSilentRefreshPulse(col);
  }
}
