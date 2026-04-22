import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../core/theme.dart';

class DynamicBackground extends StatefulWidget {
  final Widget child;
  final AppGradientPreset preset;

  const DynamicBackground({
    super.key,
    required this.child,
    required this.preset,
    String? imageUrl, // Unused
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> with TickerProviderStateMixin {
  late AnimationController _auroraController;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color1 = AppTheme.accentColor(widget.preset);
    final color2 = AppTheme.accentColorDim(widget.preset);
    
    return Stack(
      children: [
        // 1. Static Base Gradient
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.shellGradient(widget.preset),
          ),
        ),

        // 2. Animated Aurora Blobs
        AnimatedBuilder(
          animation: _auroraController,
          builder: (context, child) {
            return Stack(
              children: [
                _buildBlob(
                  color: color1.withOpacity(0.08),
                  size: size.width * 1.3,
                  offset: Offset(
                    size.width * 0.2 * math.cos(_auroraController.value * 2 * math.pi),
                    size.height * 0.1 * math.sin(_auroraController.value * 2 * math.pi),
                  ),
                ),
                _buildBlob(
                  color: color2.withOpacity(0.1),
                  size: size.width * 1.6,
                  offset: Offset(
                    size.width * 0.5 * math.sin(_auroraController.value * 2 * math.pi),
                    size.height * 0.3 * math.cos(_auroraController.value * 2 * math.pi),
                  ),
                ),
              ],
            );
          },
        ),

        // 3. Blur Layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
        ),

        // 4. Content
        widget.child,
      ],
    );
  }

  Widget _buildBlob({required Color color, required double size, required Offset offset}) {
    return Positioned(
      left: offset.dx - (size / 2),
      top: offset.dy - (size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}
