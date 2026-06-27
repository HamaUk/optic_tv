import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';
import 'pocketbase_service.dart';

class AuthService {
  static RecordModel? get currentUser => pb.authStore.model as RecordModel?;

  static Future<RecordAuth?> signIn(String email, String password) async {
    try {
      final cred = await pb.collection('users').authWithPassword(
        email.trim(),
        password.trim(),
      );
      return cred;
    } catch (e) {
      debugPrint('Auth Error: $e');
      rethrow;
    }
  }

  static Future<RecordAuth?> signInWithGoogle() async {
    try {
      // Note: PocketBase OAuth2 requires web fallback or deep linking
      // This is a placeholder for Google OAuth if needed.
      final authData = await pb.collection('users').authWithOAuth2('google', (url) async {
        // Implement OAuth URL launcher here
      });
      return authData;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    pb.authStore.clear();
  }

  static bool get isAdmin => pb.authStore.isValid && pb.authStore.model != null;
}
