import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  // The singleton PocketBase instance pointing to your VPS
  late final PocketBase pb;

  void initialize(String url) {
    pb = PocketBase(url);
  }
}

// Global accessor
final pb = PocketBaseService().pb;
