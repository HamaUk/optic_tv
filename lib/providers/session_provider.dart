import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/login_codes_service.dart';
import '../services/monitor_service.dart';

class SessionState {
  final bool loggedIn;
  final String? activeCode;
  final String? error;
  SessionState({required this.loggedIn, this.activeCode, this.error});
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    // Initial build can't async access prefs easily, handled by overrides in main.dart
    return SessionState(loggedIn: false);
  }

  /// Called after build to initialize specific session tracking
  void initialize(bool initialLoggedIn, String? code) {
    if (initialLoggedIn && code != null) {
      state = SessionState(loggedIn: true, activeCode: code);
      MonitorService.start(code);
    }
  }

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
      await p.setString('auth_active_code', code);
      
      state = SessionState(loggedIn: true, activeCode: code);
      MonitorService.start(code);
      return true;
    } catch (e) {
      state = SessionState(loggedIn: false, error: 'Connection Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('auth_logged_in', false);
    await p.remove('auth_active_code');
    MonitorService.stop();
    state = SessionState(loggedIn: false);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);
