import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleNotifier extends Notifier<Locale> {
  static const _prefsKey = 'app_locale';

  @override
  Locale build() => const Locale('ckb');

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_prefsKey) ?? 'ckb';
    final next = Locale(code);
    if (next.languageCode != state.languageCode) {
      state = next;
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, locale.languageCode);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(AppLocaleNotifier.new);
