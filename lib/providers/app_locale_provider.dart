import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing language (`ckb` / `en`). Persisted; **not** passed to [MaterialApp.locale]
/// (that stays [Locale('en')] so Material/Cupertino delegates stay valid).
class AppLocaleNotifier extends Notifier<Locale> {
  static const _prefsKey = 'app_locale';

  static bool isSupportedCode(String code) => code == 'en' || code == 'ckb';

  static String normalizeStoredCode(String? code) {
    if (code != null && isSupportedCode(code)) return code;
    return 'ckb';
  }

  @override
  Locale build() => const Locale('ckb');

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    state = Locale(normalizeStoredCode(p.getString(_prefsKey)));
  }

  Future<void> setLocale(Locale locale) async {
    final c = locale.languageCode;
    if (!isSupportedCode(c)) return;
    state = Locale(c);
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, c);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(AppLocaleNotifier.new);
