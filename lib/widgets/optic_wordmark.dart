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
    final double fontSize = widget.height * 0.92;
    final double letterSpacing = widget.height * 0.08;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-2.0 + t * 4.0, -1.0),
            end: Alignment(0.0 + t * 4.0, 1.0),
            colors: const [
              Color(0xFF38BDF8),
              AppTheme.primaryGold,
              Color(0xFFA78BFA),
              Color(0xFF38BDF8),
            ],
            stops: const [0.0, 0.35, 0.7, 1.0],
          ).createShader(bounds),
          child: widget.twoLine
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
                    const SizedBox(height: 6),
                    Text(
                      '4K',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        fontSize: fontSize * 0.8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: letterSpacing * 1.8,
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
                    letterSpacing: widget.height * 0.12,
                    height: 1.0,
                  ),
                ),
        );
      },
    );
  }
}
