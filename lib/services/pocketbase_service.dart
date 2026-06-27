import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  // The singleton PocketBase instance pointing to your VPS
  late final PocketBase pb;

  void initialize(String url, SharedPreferences prefs) {
    final store = AsyncAuthStore(
      save: (String data) async => prefs.setString('pb_auth', data),
      initial: prefs.getString('pb_auth'),
      clear: () async => prefs.remove('pb_auth'),
    );
    pb = PocketBase(url, authStore: store);
  }
}

// Global accessor
final pb = PocketBaseService().pb;
