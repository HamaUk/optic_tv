import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return cred;
    } catch (e) {
      debugPrint('Auth Error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static bool get isAdmin => _auth.currentUser != null;
}
