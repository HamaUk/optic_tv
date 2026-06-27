import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';
import 'pocketbase_service.dart';

class AuthService {
  static RecordModel? get currentUser => pb.authStore.model as RecordModel?;

  static Future<RecordAuth?> signIn(String email, String password) async {
    try {
      // First try to authenticate as an admin (superuser)
      return await pb.collection('_superusers').authWithPassword(
        email.trim(),
        password.trim(),
      );
    } catch (e) {
      try {
        // Fallback to regular user authentication
        return await pb.collection('users').authWithPassword(
          email.trim(),
          password.trim(),
        );
      } catch (e2) {
        debugPrint('Auth Error: $e2');
        rethrow;
      }
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
