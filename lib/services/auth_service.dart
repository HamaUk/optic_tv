import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

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

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Initialize for the 7.x API
      await _googleSignIn.initialize();

      // 2. Authenticate (Identify the user)
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null;

      // 3. Get Authentication (ID Token)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // 4. In 7.x, the access token must be explicitly requested via authorizationClient 
      // if it's not automatically provided or if we need specific scopes.
      // For Firebase Auth, we usually need the accessToken too.
      final authorized = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);
      final String? accessToken = authorized?.accessToken;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  static bool get isAdmin => _auth.currentUser != null;
}
