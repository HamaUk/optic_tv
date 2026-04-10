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
  final initialLocaleCode = prefs.getString('app_locale') ?? 'ckb';

  runApp(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith((ref) => initialSession),
        appLocaleProvider.overrideWith(() => _SeededLocaleNotifier(initialLocaleCode)),
      ],
      child: const OpticTvApp(),
    ),
  );
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
    final locale = ref.watch(appLocaleProvider);
    final loggedIn = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'Optic TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ckb'),
        Locale('en'),
      ],
      home: loggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
