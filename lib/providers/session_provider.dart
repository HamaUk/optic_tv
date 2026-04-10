import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/login_codes_service.dart';

final sessionProvider = StateProvider<bool>((ref) => false);

final sessionActionsProvider = Provider<SessionActions>((ref) => SessionActions(ref));

class SessionActions {
  SessionActions(this._ref);
  final Ref _ref;

  Future<bool> loginWithCode(String code) async {
    final ok = await LoginCodesService.validate(code);
    if (!ok) return false;
    final p = await SharedPreferences.getInstance();
    await p.setBool('auth_logged_in', true);
    _ref.read(sessionProvider.notifier).state = true;
    return true;
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('auth_logged_in', false);
    _ref.read(sessionProvider.notifier).state = false;
  }
}
