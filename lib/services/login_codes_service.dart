import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Validates user-facing login codes from
/// `sync/global/loginCodes` where each child is `{ "code": "...", "active": true }`.
///
/// Also accepts built-in codes (e.g. vip2026) so sign-in works without RTDB; not secret from APK.
class LoginCodesService {
  static const _rtdbPath = 'sync/global/loginCodes';
  static const _cacheKey = 'login_codes_cache_v1';

  /// Lowercase. Works offline and without Firebase.
  static const Set<String> _builtInCodes = {'vip2026'};

  static Future<bool> validate(String raw) async {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return false;

    if (_builtInCodes.contains(normalized)) return true;

    try {
      final snap = await FirebaseDatabase.instance.ref(_rtdbPath).get();
      if (snap.exists && snap.value != null) {
        final ok = _matchSnapshot(snap.value, normalized);
        await _storeCacheFromSnapshot(snap.value);
        return ok;
      }
    } catch (_) {
      // Offline / Firebase error → try cache
    }
    return _matchCached(normalized);
  }

  static String _normalize(String s) =>
      s.trim().toLowerCase();

  static bool _matchSnapshot(dynamic data, String normalized) {
    if (data is! Map) return false;
    for (final v in data.values) {
      if (v is! Map) continue;
      final active = v['active'] != false;
      final code = _normalize('${v['code'] ?? ''}');
      if (active && code.isNotEmpty && code == normalized) return true;
    }
    return false;
  }

  static Future<void> _storeCacheFromSnapshot(dynamic data) async {
    final codes = <String>[];
    if (data is Map) {
      for (final v in data.values) {
        if (v is Map && v['active'] != false) {
          final c = _normalize('${v['code'] ?? ''}');
          if (c.isNotEmpty) codes.add(c);
        }
      }
    }
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_cacheKey, codes);
  }

  static Future<bool> _matchCached(String normalized) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_cacheKey) ?? [];
    return list.contains(normalized);
  }
}
