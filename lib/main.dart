import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'ui/dashboard/dashboard_screen.dart';

void main() async {
  // Initialize standard Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MediaKit for high-performance playback
  MediaKit.ensureInitialized();
  
  // Initialize Firebase (Safe initialization)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed (Expected if not configured): $e');
  }
  
  runApp(
    const ProviderScope(
      child: OpticTvApp(),
    ),
  );
}

class OpticTvApp extends StatelessWidget {
  const OpticTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optic TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      
      // Setting defaults to LTR while still allowing Kurdish text
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),    // English
        Locale('ckb', ''),   // Kurdish Sorani
      ],
      locale: const Locale('en', ''), // Changed to English/LTR by default
      
      home: const DashboardScreen(),
    );
  }
}
