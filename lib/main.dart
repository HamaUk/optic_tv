import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/pocketbase_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpad/dpad.dart';
import 'core/theme.dart';
import 'core/security/http_overrides.dart';
import 'providers/app_locale_provider.dart';
import 'providers/session_provider.dart';
import 'providers/ui_settings_provider.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'services/platform_service.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

void main() async {
  HttpOverrides.global = GlobalSecurityHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();

  
  // RASP Security Check: Block Rooted / Jailbroken Devices
  if (!identical(0, 0.0) && Platform.isAndroid || Platform.isIOS) {
    try {
      final bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      if (jailbroken) {
        debugPrint('Security violation: Device is rooted/jailbroken.');
        SystemNavigator.pop();
        return;
      }
    } catch (e) {
      debugPrint('Jailbreak detection failed: $e');
    }
  }

  final prefs = await SharedPreferences.getInstance();

  try {
    PocketBaseService().initialize('http://64.225.76.43', prefs);
    // We will handle notifications via PocketBase later if needed, or simply not initialize FCM.
  } catch (e) {
    debugPrint('PocketBase initialization failed: $e');
  }

  final initialSession = prefs.getBool('auth_logged_in') ?? false;
  final initialCode = prefs.getString('auth_active_code');
  final isFirstLaunch = prefs.getBool('first_launch') ?? true;
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
        isFirstLaunch: isFirstLaunch,
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
  final bool isFirstLaunch;

  const OpticTvApp({
    super.key,
    required this.initialLoggedIn,
    required this.isFirstLaunch,
    this.initialCode,
  });

  @override
  ConsumerState<OpticTvApp> createState() => _OpticTvAppState();
}

class _OpticTvAppState extends ConsumerState<OpticTvApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).initialize(widget.initialLoggedIn, widget.initialCode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-run security check every time the app comes back to the foreground
      ref.refresh(securityCheckProvider);
    }
  }

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final session = ref.watch(sessionProvider);
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    final deviceTypeAsync = ref.watch(deviceTypeProvider);
    final deviceType = deviceTypeAsync.asData?.value ?? DeviceType.phone;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'KOBANI 4K',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkThemeForUi(uiLocale, settings.gradientPreset),
      locale: const Locale('en'),
      builder: (context, child) {
        final dpadBuilder = Dpad.wrap(
          debugOverlay: false,
          onBack: () {
            final ctx = _navigatorKey.currentContext;
            if (ctx != null && Navigator.canPop(ctx)) {
              Navigator.pop(ctx);
              return true;
            }
            return false;
          },
        );
        final dpadChild = dpadBuilder(context, child);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: dpadChild,
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Consumer(
        builder: (context, ref, child) {
          final securityCheckAsync = ref.watch(securityCheckProvider);
          
          return securityCheckAsync.when(
            data: (maliciousApps) {
              if (maliciousApps.isNotEmpty) {
                return _buildSecurityWarning(maliciousApps);
              }
              
              if (widget.isFirstLaunch) return const OnboardingScreen();
              return session.loggedIn ? const DashboardScreen() : const LoginScreen();
            },
            loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator())),
            error: (_, __) {
              if (widget.isFirstLaunch) return const OnboardingScreen();
              return session.loggedIn ? const DashboardScreen() : const LoginScreen();
            },
          );
        },
      ),
    );
  }

  Widget _buildSecurityWarning(List<String> apps) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security_rounded, color: Colors.redAccent, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Security Warning',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'We have detected an active VPN/Proxy or a network analysis application installed on your device. To protect our servers and your privacy, please disconnect your VPN and remove any sniffing tools to continue using KOBANI 4K:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...apps.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(a, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              )),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () {
                  // Usually user would go uninstall, but we can't easily launch uninstall intent without more native code.
                  // Just tell them to restart the app.
                  ref.refresh(securityCheckProvider);
                },
                child: const Text('I have resolved the issue, Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
