import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// English-only brand mark — never pass through localization.
class OpticWordmark extends StatefulWidget {
  const OpticWordmark({
    super.key, 
    this.height = 40,
    this.twoLine = false,
  });

  final double height;
  final bool twoLine;

  @override
  State<OpticWordmark> createState() => _OpticWordmarkState();
}

class _OpticWordmarkState extends State<OpticWordmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Made the base size larger to fulfill "make the logo bigger"
    final double imageSize = widget.height * 1.5;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        // Subtle breathing scale effect (1.0 to 1.05)
        final double scale = 1.0 + (math.sin(t * math.pi * 2) + 1) / 40.0;
        
        return Transform.scale(
          scale: scale,
          child: Image.asset(
            'assets/images/logonewww.png',
            height: imageSize,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
