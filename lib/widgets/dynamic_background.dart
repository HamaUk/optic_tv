import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/palette_service.dart';

/// A background that animates between the current image's extracted palette
/// and the static app gradient preset.
/// 
/// When an [imageUrl] is provided the widget extracts its dominant colour
/// and smoothly blends it into the background gradient so the whole shell
/// "breathes" the mood of the focused channel/movie.
class DynamicBackground extends StatefulWidget {
  final Widget child;
  final AppGradientPreset preset;
  final String? imageUrl;

  const DynamicBackground({
    super.key,
    required this.child,
    required this.preset,
    this.imageUrl,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;

  ImagePalette? _palette;
  String? _lastUrl;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic);
    _loadPalette();
  }

  @override
  void didUpdateWidget(DynamicBackground old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) {
      _loadPalette();
    }
  }

  Future<void> _loadPalette() async {
    if (widget.imageUrl == null || widget.imageUrl == _lastUrl) return;
    _lastUrl = widget.imageUrl;

    final palette = await PaletteService.instance.generate(widget.imageUrl);
    if (!mounted) return;
    setState(() => _palette = palette);
    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staticGradient = AppTheme.shellGradient(widget.preset);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        // If we have a palette, overlay a subtle radial ambient glow at the top
        // that uses the extracted vivid colour.
        final palette = _palette;
        final glowColor = palette?.accent ?? AppTheme.accentColor(widget.preset);

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: staticGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Ambient palette glow ───────────────────────────────────────
              if (palette != null)
                Positioned(
                  top: -80,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _anim.value * 0.20, // subtle — never overpowering
                    child: Container(
                      height: 420,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.2,
                          colors: [
                            glowColor.withOpacity(0.9),
                            glowColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // ── Bottom darkening vignette ──────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.backgroundBlack.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Actual page content ────────────────────────────────────────
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
