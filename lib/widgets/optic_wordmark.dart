import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// English-only brand mark — never pass through localization.
class OpticWordmark extends StatelessWidget {
  const OpticWordmark({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.92;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF38BDF8),
          AppTheme.primaryGold,
          Color(0xFFA78BFA),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Text(
        'OPTIC',
        textAlign: TextAlign.center,
        style: GoogleFonts.orbitron(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: height * 0.12,
          height: 1.0,
        ),
      ),
    );
  }
}
