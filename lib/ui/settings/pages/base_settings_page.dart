import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/ui_settings_provider.dart';
import '../../../widgets/animated_gradient_border.dart';

class BaseSettingsPage extends ConsumerWidget {
  final String title;
  final Widget child;

  const BaseSettingsPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiSettings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.settingsBackdropGradient(uiSettings.gradientPreset),
        ),
        child: SafeArea(
          bottom: false,
          child: child,
        ),
      ),
    );
  }
}

Widget glassCard({required Widget child}) {
  return AnimatedGradientBorder(
    borderWidth: 2,
    borderRadius: BorderRadius.circular(24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    ),
  );
}
