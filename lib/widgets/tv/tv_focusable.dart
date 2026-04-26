import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      widget.onSelect?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: widget.enabled,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
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
                if (widget.showFocusBorder && _isFocused)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).primaryColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
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
