import 'dart:ui';
import 'package:flutter/material.dart';

/// A professional, glassmorphic button designed for the video player.
/// Features a Gaussian blur background, subtle border, and interactive feedback.
class PlayerControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final String? tooltip;
  final bool isToggle;
  final bool toggled;

  const PlayerControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.color,
    this.tooltip,
    this.isToggle = false,
    this.toggled = false,
  });

  @override
  State<PlayerControlButton> createState() => _PlayerControlButtonState();
}

class _PlayerControlButtonState extends State<PlayerControlButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) => _controller.forward();
  void _handleTapUp(_) => _controller.reverse();
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Colors.white;
    final displayColor = widget.isToggle && widget.toggled ? Colors.amber : themeColor;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size * 0.3),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(widget.size * 0.3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (widget.isToggle && widget.toggled)
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: displayColor,
                  size: widget.size * 0.55,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
