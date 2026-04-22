import 'package:flutter/material.dart';
import '../core/theme.dart';

class DynamicBackground extends StatelessWidget {
  final Widget child;
  final AppGradientPreset preset;

  const DynamicBackground({
    super.key,
    required this.child,
    required this.preset,
    String? imageUrl, // Unused
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.shellGradient(preset),
      ),
      child: child,
    );
  }
}
