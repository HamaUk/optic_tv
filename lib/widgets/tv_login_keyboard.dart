import 'package:flutter/material.dart';

/// Latin access-code entry tuned for D-pad / remote: predictable focus order,
/// no system IME. Wrapped in [Directionality.ltr] by the parent so QWERTY stays
/// left-to-right even when the app uses RTL for Kurdish.
class TvLoginKeyboard extends StatelessWidget {
  const TvLoginKeyboard({
    super.key,
    required this.onCharacter,
    required this.onBackspace,
    required this.onClear,
    this.maxLength = 64,
  });

  final ValueChanged<String> onCharacter;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
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
              _letterRow(context, theme, _digitRow.chars),
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
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _wideKey(
                      context,
                      theme,
                      label: 'Clear',
                      onPressed: onClear,
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

  Widget _letterRow(BuildContext context, ThemeData theme, List<String> chars) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final c in chars) _keyCell(context, theme, c)],
    );
  }

  Widget _symKey(BuildContext context, ThemeData theme, String ch) {
    return Expanded(child: _keyCell(context, theme, ch));
  }

  Widget _keyCell(BuildContext context, ThemeData theme, String ch) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: _KeyButton(
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
  }) {
    assert(label != null || icon != null);
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: _KeyButton(
          onPressed: onPressed,
          maxLength: maxLength,
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 22)
              : Text(
                  label!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
    required this.onPressed,
    required this.maxLength,
    required this.child,
  });

  final VoidCallback onPressed;
  final int maxLength;
  final Widget child;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: _focused ? Colors.white.withValues(alpha: 0.55) : Colors.white24,
      width: _focused ? 2 : 1,
    );

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: Material(
        color: _focused ? const Color(0xFF4A505A) : const Color(0xFF3D434D),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          canRequestFocus: false,
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
