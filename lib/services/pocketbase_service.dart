import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  // The singleton PocketBase instance pointing to your VPS
  PocketBase? _pb;

  bool get isInitialized => _pb != null;

  PocketBase get pb {
    if (_pb == null) {
      throw StateError('PocketBaseService must be initialized before accessing pb. Call initialize() first.');
    }
    return _pb!;
  }

  void initialize(String url, SharedPreferences prefs) {
    final store = AsyncAuthStore(
      save: (String data) async => prefs.setString('pb_auth', data),
      initial: prefs.getString('pb_auth'),
      clear: () async => prefs.remove('pb_auth'),
    );
    _pb = PocketBase(url, authStore: store);
  }
}

// Global accessor - safe getter that checks initialization
PocketBase get pb => PocketBaseService().pb;
