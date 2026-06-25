import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../core/theme.dart';

/// Professional TV Focus Engine ported from KoyaPlayer.
/// Provides 1.05x zoom and Amber Gold highlighting for remote navigation.
class TVFocusable extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, bool isFocused, Widget child)? builder;
  final VoidCallback? onSelect;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;
  final double focusScale;
  final bool showFocusBorder;
  final BorderRadius? borderRadius;

  const TVFocusable({
    super.key,
    required this.child,
    this.builder,
    this.onSelect,
    this.onFocus,
    this.onBlur,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
    this.focusScale = 1.05,
    this.showFocusBorder = true,
    this.borderRadius,
  });

  @override
  State<TVFocusable> createState() => _TVFocusableState();
}

class _TVFocusableState extends State<TVFocusable> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  bool _lastInputWasHardware = false; // true only when D-pad/keyboard was used

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.focusScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    if (!mounted) return;
    setState(() => _isFocused = hasFocus);
    if (hasFocus) {
      _animationController.forward();
      widget.onFocus?.call();
    } else {
      _animationController.reverse();
      widget.onBlur?.call();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // Mark that hardware input is in use (shows TV focus border)
    if (mounted) setState(() => _lastInputWasHardware = true);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (widget.onSelect != null) {
        widget.onSelect!.call();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  /// Returns true only when running on an Android/Google TV device
  /// OR when the user has used hardware D-pad/keyboard input.
  bool get _isTvInput {
    if (!kIsWeb && Platform.isAndroid) {
      // Show border only when hardware key was used (D-pad remote)
      return _lastInputWasHardware;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      canRequestFocus: false, // DpadFocusable handles actual focus
      child: DpadFocusable(
        autofocus: widget.autofocus,
        onFocusChange: _handleFocusChange,
        onSelect: widget.onSelect,
        effects: const [], // effects handled by internal animated builder
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            final focusedChild = widget.builder != null 
                ? widget.builder!(context, _isFocused, widget.child) 
                : widget.child;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: focusedChild,
                ),
                if (widget.showFocusBorder && _isFocused && _isTvInput)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFD4AF37), // Real gold, not theme red
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.35),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
