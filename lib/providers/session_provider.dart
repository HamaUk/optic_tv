import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/login_codes_service.dart';

class SessionState {
  final bool loggedIn;
  final String? error;
  SessionState({required this.loggedIn, this.error});
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => SessionState(loggedIn: false);

  Future<bool> loginWithCode(String code) async {
    state = SessionState(loggedIn: false, error: null);
    try {
      final ok = await LoginCodesService.validate(code);
      if (!ok) {
        state = SessionState(loggedIn: false, error: 'Invalid or expired code.');
        return false;
      }
      final p = await SharedPreferences.getInstance();
      await p.setBool('auth_logged_in', true);
      state = SessionState(loggedIn: true);
      return true;
    } catch (e) {
      state = SessionState(loggedIn: false, error: 'Connection Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('auth_logged_in', false);
    state = SessionState(loggedIn: false);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);
