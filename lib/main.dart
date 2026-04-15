import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'providers/app_locale_provider.dart';
import 'providers/session_provider.dart';
import 'services/notification_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  try {
    if (identical(0, 0.0)) { // Simple check for web
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCvNllsitniHSvzTIKiH74EqgCrHqB5xJI",
          appId: "1:476890397528:web:9107ccb708b51d368e7343",
          messagingSenderId: "476890397528",
          projectId: "optic-tv",
          databaseURL: "https://optic-tv-default-rtdb.firebaseio.com",
          storageBucket: "optic-tv.firebasestorage.app",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
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
  SessionState build() => SessionState(loggedIn: _initial);
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
    final session = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'Optic TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkThemeForUi(uiLocale),
      locale: const Locale('en'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: session.loggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
