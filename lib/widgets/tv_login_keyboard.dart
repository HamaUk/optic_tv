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
      child: Material(
        color: const Color(0xFF2A2F38),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _letterRow(context, theme, _digitRow.chars, firstKeyAutofocus: true),
              const SizedBox(height: 6),
              _letterRow(context, theme, _row1.chars),
              const SizedBox(height: 6),
              _letterRow(context, theme, _row2.chars),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in _row3.chars) _keyCell(context, theme, c),
                  _wideKey(
                    context,
                    theme,
                    icon: Icons.backspace_outlined,
                    label: 'Backspace',
                    onPressed: onBackspace,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _symKey(context, theme, '-'),
                  _symKey(context, theme, '_'),
                  _symKey(context, theme, '.'),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _wideKey(
                      context,
                      theme,
                      label: 'Clear',
                      onPressed: onClear,
                    ),
                  ),
                  const SizedBox(width: 6),
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
    );
  }

  Widget _letterRow(
    BuildContext context,
    ThemeData theme,
    List<String> chars, {
    bool firstKeyAutofocus = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < chars.length; i++)
          _keyCell(
            context,
            theme,
            chars[i],
            autofocus: firstKeyAutofocus && i == 0,
          ),
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: _KeyButton(
          autofocus: autofocus,
          onPressed: () => onCharacter(ch),
          maxLength: maxLength,
          child: Text(
            ch,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: _KeyButton(
        onPressed: onPressed,
        maxLength: maxLength,
        color: isPrimary ? AppTheme.primaryGold : null,
        child: icon != null
            ? Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 22)
            : Text(
                label!,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isPrimary ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
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

  /// Android TV / STB remotes often send [LogicalKeyboardKey.select] (DPAD center)
  /// instead of routing [ActivateIntent] the same way phones do.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final activates = k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.gameButtonSelect ||
        k == LogicalKeyboardKey.gameButtonA;
    if (!activates) return KeyEventResult.ignored;
    widget.onPressed();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: _focused ? Colors.white.withOpacity(0.55) : Colors.white24,
      width: _focused ? 2 : 1,
    );

    final baseColor = widget.color ?? const Color(0xFF3D434D);
    final focusColor = widget.color?.withOpacity(0.8) ?? const Color(0xFF4A505A);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: Material(
        color: _focused ? focusColor : baseColor,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          canRequestFocus: false,
          mouseCursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: border, borderRadius: BorderRadius.circular(6)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
