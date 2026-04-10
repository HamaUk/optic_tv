import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/login_codes_service.dart';

class SessionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<bool> loginWithCode(String code) async {
    final ok = await LoginCodesService.validate(code);
    if (!ok) return false;
    final p = await SharedPreferences.getInstance();
    await p.setBool('auth_logged_in', true);
    state = true;
    return true;
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('auth_logged_in', false);
    state = false;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, bool>(SessionNotifier.new);
