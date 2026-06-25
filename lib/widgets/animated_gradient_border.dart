import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 3.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The rotating animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: Container(
                    // Multiply size to ensure it covers the corners when rotating
                    margin: const EdgeInsets.all(-40),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFF1B1B1B),
                          Color(0xFF382A18),
                          Color(0xFF543814),
                          Color(0xFF714711),
                          Color(0xFF8D560E),
                          Color(0xFFC67307),
                          Color(0xFFFF9000),
                          Color(0xFFC67307),
                          Color(0xFF8D560E),
                          Color(0xFF714711),
                          Color(0xFF543814),
                          Color(0xFF382A18),
                          Color(0xFF1B1B1B),
                        ],
                        stops: [0.0, 0.1, 0.2, 0.3, 0.4, 0.45, 0.5, 0.55, 0.6, 0.7, 0.8, 0.9, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Inner child with padding to act as the "border width" mask
          Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF121212), // Inner background color
                borderRadius: widget.borderRadius.subtract(BorderRadius.circular(widget.borderWidth)),
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
