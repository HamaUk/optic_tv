import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import 'dart:math' as math;

class DynamicBackground extends StatefulWidget {
  final String? imageUrl;
  final Widget child;

  const DynamicBackground({
    super.key,
    required this.imageUrl,
    required this.child,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> with TickerProviderStateMixin {
  Color? _color1;
  Color? _color2;
  String? _lastUrl;
  late AnimationController _auroraController;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    if (widget.imageUrl != null) {
      _extractColors(widget.imageUrl!);
    }
  }

  @override
  void didUpdateWidget(DynamicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != null && widget.imageUrl != _lastUrl) {
      _extractColors(widget.imageUrl!);
    }
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  Future<void> _extractColors(String url) async {
    _lastUrl = url;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(url),
        maximumColorCount: 10,
      );

      if (mounted) {
        setState(() {
          _color1 = palette.vibrantColor?.color ?? palette.dominantColor?.color ?? Colors.blueGrey;
          _color2 = palette.darkMutedColor?.color ?? palette.darkVibrantColor?.color ?? Colors.black;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // 1. Static Base Gradient
        AnimatedContainer(
          duration: const Duration(milliseconds: 1200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (_color1 ?? Colors.black).withOpacity(0.2),
                (_color2 ?? Colors.black).withOpacity(0.3),
                Colors.black,
              ],
            ),
          ),
        ),

        // 2. Animated Aurora Blobs
        AnimatedBuilder(
          animation: _auroraController,
          builder: (context, child) {
            return Stack(
              children: [
                _buildBlob(
                  color: (_color1 ?? Colors.blue).withOpacity(0.15),
                  size: size.width * 1.2,
                  offset: Offset(
                    size.width * 0.2 * math.cos(_auroraController.value * 2 * math.pi),
                    size.height * 0.1 * math.sin(_auroraController.value * 2 * math.pi),
                  ),
                ),
                _buildBlob(
                  color: (_color2 ?? Colors.purple).withOpacity(0.12),
                  size: size.width * 1.5,
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
            filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
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
