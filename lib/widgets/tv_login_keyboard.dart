import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

/// Latin access-code entry tuned for D-pad / remote: predictable focus order,
/// no system IME. Wrapped in [Directionality.ltr] by the parent so QWERTY stays
/// left-to-right even when the app uses RTL for Kurdish.
class TvLoginKeyboard extends StatelessWidget {
  const TvLoginKeyboard({
    super.key,
    required this.onCharacter,
    required this.onBackspace,
    required this.onClear,
    required this.onDone,
    this.maxLength = 64,
  });

  final ValueChanged<String> onCharacter;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onDone;
  final int maxLength;

  static const _digitRow = '1234567890';
  static const _row1 = 'qwertyuiop';
  static const _row2 = 'asdfghjkl';
  static const _row3 = 'zxcvbnm';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2228).withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _letterRow(context, theme, _digitRow.chars, firstKeyAutofocus: true),
                const SizedBox(height: 10),
                _letterRow(context, theme, _row1.chars),
                const SizedBox(height: 10),
                _letterRow(context, theme, _row2.chars),
                const SizedBox(height: 10),
                _letterRow(context, theme, _row3.chars, trailing: [
                  _wideKey(
                    context,
                    theme,
                    icon: Icons.backspace_outlined,
                    onPressed: onBackspace,
                  ),
                ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _symKey(context, theme, '-'),
                    _symKey(context, theme, '_'),
                    _symKey(context, theme, '.'),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _wideKey(
                        context,
                        theme,
                        label: 'CLEAR',
                        onPressed: onClear,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _wideKey(
                        context,
                        theme,
                        label: 'DONE',
                        onPressed: onDone,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _letterRow(
    BuildContext context,
    ThemeData theme,
    List<String> chars, {
    bool firstKeyAutofocus = false,
    List<Widget> trailing = const [],
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < chars.length; i++)
          _keyCell(
            context,
            theme,
            chars[i],
            autofocus: firstKeyAutofocus && i == 0,
          ),
        ...trailing,
      ],
    );
  }

  Widget _symKey(BuildContext context, ThemeData theme, String ch) {
    return Expanded(child: _keyCell(context, theme, ch));
  }

  Widget _keyCell(
    BuildContext context,
    ThemeData theme,
    String ch, {
    bool autofocus = false,
  }) {
    return SizedBox(
      width: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: _KeyButton(
          autofocus: autofocus,
          onPressed: () => onCharacter(ch),
          maxLength: maxLength,
          child: Text(
            ch,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _wideKey(
    BuildContext context,
    ThemeData theme, {
    String? label,
    IconData? icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    assert(label != null || icon != null);
    return SizedBox(
      width: label == null ? 90 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _KeyButton(
          onPressed: onPressed,
          maxLength: maxLength,
          color: isPrimary ? AppTheme.primaryGold : null,
          child: icon != null
              ? Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 28)
              : Text(
                  label!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isPrimary ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

extension on String {
  List<String> get chars => split('');
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    this.autofocus = false,
    required this.onPressed,
    required this.maxLength,
    required this.child,
    this.color,
  });

  final bool autofocus;
  final VoidCallback onPressed;
  final int maxLength;
  final Widget child;
  final Color? color;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_syncFocusDecoration);
  }

  void _syncFocusDecoration() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_syncFocusDecoration);
    _focusNode.dispose();
    super.dispose();
  }

  bool get _focused => _focusNode.hasFocus;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final activates = k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter;
    if (!activates) return KeyEventResult.ignored;
    widget.onPressed();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Colors.white.withOpacity(0.08);
    final focusColor = widget.color ?? AppTheme.primaryGold;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_focused ? 1.08 : 1.0),
        decoration: BoxDecoration(
          color: _focused ? focusColor : baseColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? Colors.white : Colors.white.withOpacity(0.05),
            width: _focused ? 2 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: focusColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            canRequestFocus: false,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 62,
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

