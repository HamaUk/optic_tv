import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'providers/app_locale_provider.dart';
import 'providers/session_provider.dart';
import 'ui/auth/login_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed (Expected if not configured): $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final initialSession = prefs.getBool('auth_logged_in') ?? false;
  var initialLocaleCode = AppLocaleNotifier.normalizeStoredCode(prefs.getString('app_locale'));
  await prefs.setString('app_locale', initialLocaleCode);

  runApp(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _SeededSessionNotifier(initialSession)),
        appLocaleProvider.overrideWith(() => _SeededLocaleNotifier(initialLocaleCode)),
      ],
      child: const OpticTvApp(),
    ),
  );
}

class _SeededSessionNotifier extends SessionNotifier {
  _SeededSessionNotifier(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;
}

class _SeededLocaleNotifier extends AppLocaleNotifier {
  _SeededLocaleNotifier(this._code);

  final String _code;

  @override
  Locale build() => Locale(_code);
}

class OpticTvApp extends ConsumerStatefulWidget {
  const OpticTvApp({super.key});

  @override
  ConsumerState<OpticTvApp> createState() => _OpticTvAppState();
}

class _OpticTvAppState extends ConsumerState<OpticTvApp> {
  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final loggedIn = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'Optic TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkThemeForUi(uiLocale),
      // Keep Material/Cupertino on English — `ckb` is not a full Material locale.
      locale: const Locale('en'),
      builder: (context, child) {
        return Directionality(
          textDirection: uiLocale.languageCode == 'ckb' ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: loggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
