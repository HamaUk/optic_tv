import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// English-only brand mark — never pass through localization.
class KobaniWordmark extends StatelessWidget {
  const KobaniWordmark({
    super.key, 
    this.height = 40,
    this.twoLine = false,
  });

  final double height;
  final bool twoLine;

  @override
  Widget build(BuildContext context) {
    // Made the base font size smaller as requested
    final double fontSize = height * 0.75;
    final double letterSpacing = height * 0.06;

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
      child: twoLine
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'KOBANI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: letterSpacing * 1.2,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '4K',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: letterSpacing * 0.1,
                    height: 0.95,
                  ),
                ),
              ],
            )
          : Text(
              'KOBANI 4K',
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

