import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that streams the count of active, non-expired login codes.
final loginCodesCountProvider = StreamProvider<int>((ref) {
  final dbRef = FirebaseDatabase.instance.ref('sync/global/loginCodes');

  return dbRef.onValue.map((event) {
    final data = event.snapshot.value;
    if (data == null) return 0;

    int activeCount = 0;
    final now = DateTime.now().toUtc();

    void checkItem(dynamic v) {
      if (v is Map) {
        final active = v['active'] != false;
        if (!active) return;

        final expiresAt = v['expiresAt'];
        if (expiresAt != null) {
          try {
            final dt = DateTime.parse('$expiresAt');
            if (now.isAfter(dt)) return;
          } catch (_) {
            // Treat malformed dates as permanent if they were meant to be active
          }
        }
        activeCount++;
      }
    }

    if (data is List) {
      for (var item in data) {
        if (item != null) checkItem(item);
      }
    } else if (data is Map) {
      for (var item in data.values) {
        checkItem(item);
      }
    }

    return activeCount;
  });
});
