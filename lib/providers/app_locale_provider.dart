import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App UI locale — English only (`MaterialApp` / strings).
class AppLocaleNotifier extends Notifier<Locale> {
  static const _prefsKey = 'app_locale';

  @override
  Locale build() => const Locale('en');

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    await _normalizePrefs(p);
    state = const Locale('en');
  }

  static Future<void> _normalizePrefs(SharedPreferences p) async {
    final code = p.getString(_prefsKey);
    if (code == null || code != 'en') {
      await p.setString(_prefsKey, 'en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = const Locale('en');
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, 'en');
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(AppLocaleNotifier.new);
