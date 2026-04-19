import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'providers/app_locale_provider.dart';
import 'providers/session_provider.dart';
import 'providers/ui_settings_provider.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/tv/tv_login_screen.dart';
import 'ui/tv/tv_dashboard_screen.dart';
import 'ui/tv/tv_mode_selector_screen.dart';
import 'services/platform_service.dart';

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
  final initialCode = prefs.getString('auth_active_code');
  var initialLocaleCode = AppLocaleNotifier.normalizeStoredCode(prefs.getString('app_locale'));
  await prefs.setString('app_locale', initialLocaleCode);

  runApp(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _SeededSessionNotifier(initialSession, initialCode)),
        appLocaleProvider.overrideWith(() => _SeededLocaleNotifier(initialLocaleCode)),
      ],
      child: OpticTvApp(
        initialLoggedIn: initialSession,
        initialCode: initialCode,
      ),
    ),
  );
}

class _SeededSessionNotifier extends SessionNotifier {
  _SeededSessionNotifier(this._initial, this._code);
  final bool _initial;
  final String? _code;

  @override
  SessionState build() => SessionState(loggedIn: _initial, activeCode: _code);
}

class _SeededLocaleNotifier extends AppLocaleNotifier {
  _SeededLocaleNotifier(this._code);

  final String _code;

  @override
  Locale build() => Locale(_code);
}

class OpticTvApp extends ConsumerStatefulWidget {
  final bool initialLoggedIn;
  final String? initialCode;

  const OpticTvApp({
    super.key,
    required this.initialLoggedIn,
    this.initialCode,
  });

  @override
  ConsumerState<OpticTvApp> createState() => _OpticTvAppState();
}

class _OpticTvAppState extends ConsumerState<OpticTvApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).initialize(widget.initialLoggedIn, widget.initialCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final session = ref.watch(sessionProvider);
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    final deviceTypeAsync = ref.watch(deviceTypeProvider);
    final deviceType = deviceTypeAsync.asData?.value ?? DeviceType.phone;

    return MaterialApp(
      title: 'Optic TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkThemeForUi(uiLocale, settings.gradientPreset),
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
import 'ui/tv/elite_tv_dashboard.dart';

// ... (inside OpticTvApp build)
      home: deviceType == DeviceType.tv 
        ? (session.loggedIn ? const EliteTvDashboard() : const TvLoginScreen())
        : (session.loggedIn ? const DashboardScreen() : const LoginScreen()),
    );
  }
}
