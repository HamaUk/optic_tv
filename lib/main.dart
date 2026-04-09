import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'core/theme.dart';
import 'ui/dashboard/dashboard_screen.dart';

void main() {
  // Initialize MediaKit for high-performance playback
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
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
      home: const DashboardScreen(),
    );
  }
}
