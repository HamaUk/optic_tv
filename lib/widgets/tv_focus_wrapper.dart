import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

/// A premium focus wrapper for Android TV that provides a scale-up (8%)
/// and glowing border effect when an item is focused via D-pad.
class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final double borderRadius;
  final Color? accentColor;
  final bool autofocus;

  const TvFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 1.08,
    this.borderRadius = 16.0,
    this.accentColor,
    this.autofocus = false,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTv = MediaQuery.sizeOf(context).width > 900;
    final accent = widget.accentColor ?? AppTheme.primaryGold;
    final showEffects = isTv && _isFocused;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        if (mounted) setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isSelect = event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter;
          
          if (isSelect && widget.onTap != null) {
            widget.onTap!();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: showEffects ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: showEffects ? accent : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: showEffects
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius - 2),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
