import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';

/// A premium background that extracts colors from an image to create
/// a smooth, blurred gradient background.
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

class _DynamicBackgroundState extends State<DynamicBackground> {
  Color? _color1;
  Color? _color2;
  String? _lastUrl;

  @override
  void initState() {
    super.initState();
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
    } catch (_) {
      // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Gradient
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (_color1 ?? Colors.black).withOpacity(0.35),
                (_color2 ?? Colors.black).withOpacity(0.45),
                Colors.black,
              ],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Foreground Content
        widget.child,
      ],
    );
  }
}
