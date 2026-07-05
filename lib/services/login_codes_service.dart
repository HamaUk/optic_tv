import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import 'dart:async';

/// Validates user-facing login codes from PocketBase
/// `loginCodes` collection
class LoginCodesService {
  static const _cacheKey = 'login_codes_cache_v1';

  static Future<bool> validate(String raw) async {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return false;

    try {
      final records = await pb.collection('loginCodes').getFullList(
        filter: 'code = "$normalized"',
      );
      
      if (records.isNotEmpty) {
        final ok = _matchRecords(records, normalized);
        if (ok) {
          await _storeCache(normalized);
        }
        return ok;
      }
      return false;
    } catch (e) {
      // Offline / API error -> try cache
      final cachedOk = await _matchCached(normalized);
      if (cachedOk) return true;
      throw Exception('DB Error: $e');
    }
  }

  static Stream<bool> watchValidation(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return Stream.value(false);

    final controller = StreamController<bool>.broadcast();

    // Initial check
    validate(raw).then(controller.add).catchError((_) => controller.add(false));

    // Subscribe to PocketBase realtime updates for loginCodes
    pb.collection('loginCodes').subscribe('*', (e) {
      validate(raw).then(controller.add).catchError((_) {});
    });

    return controller.stream;
  }

  static void triggerRefresh() {
    // No-op for old ViewerService, or we could trigger validation
  }

  static String _normalize(String s) =>
      s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static bool _isExpired(String? expiresAt) {
    if (expiresAt == null || expiresAt.isEmpty) return false;
    try {
      final dt = DateTime.parse(expiresAt);
      return DateTime.now().toUtc().isAfter(dt);
    } catch (_) {
      return false;
    }
  }

  static bool _matchRecords(List<RecordModel> records, String normalized) {
    for (final v in records) {
      final active = v.getBoolValue('active');
      final code = _normalize(v.getStringValue('code'));
      if (!active || code.isEmpty || code != normalized) continue;
      
      final expiresAt = v.getStringValue('expiresAt');
      if (_isExpired(expiresAt)) continue;
      
      return true;
    }
    return false;
  }

  static Future<void> _storeCache(String code) async {
    final p = await SharedPreferences.getInstance();
    var list = p.getStringList(_cacheKey) ?? [];
    if (!list.contains(code)) {
      list.add(code);
      await p.setStringList(_cacheKey, list);
    }
  }

  static Future<bool> _matchCached(String normalized) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_cacheKey) ?? [];
    return list.contains(normalized);
  }
}
