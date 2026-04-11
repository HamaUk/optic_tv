import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/optic_wordmark.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  bool _busy = false;

  /// Use the platform UI font for the code field so Latin digits stay crisp on Android.
  TextStyle _loginTextStyle(BuildContext context, {required double opacity}) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return TextStyle(
      color: Colors.white.withValues(alpha: opacity),
      fontSize: 18,
      height: 1.25,
      fontFamily: isAndroid ? 'Roboto' : null,
    );
  }

  @override
  void dispose() {
    _codeFocus.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppStrings s) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loginErrorEmpty)),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = await ref.read(sessionProvider.notifier).loginWithCode(code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loginErrorInvalid)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);

    // On Android TV the system virtual keyboard causes the Scaffold to
    // resize, which crushes the layout into a grey box.  Setting
    // resizeToAvoidBottomInset=false prevents that; we manually add bottom
    // padding equal to the keyboard height so the user can still scroll to
    // the input field.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F14), Color(0xFF151B24), Color(0xFF0B0F14)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: 28,
                  right: 28,
                  top: 24,
                  // Extra bottom space so the input stays above the keyboard.
                  bottom: 24 + keyboardInset,
                ),
                child: ConstrainedBox(
                  // Ensure the content fills the screen when the keyboard is hidden.
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48, // 24 top + 24 bottom
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: OpticWordmark(height: 52),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        s.loginTitle,
                        textAlign: TextAlign.center,
                        style: AppTheme.withRabarIfKurdish(
                          uiLocale,
                          const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTheme.withRabarIfKurdish(
                          uiLocale,
                          TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 56,
                                child: Material(
                                  color: const Color(0xFF1C2430),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.only(
                                            start: 12,
                                            end: 4,
                                          ),
                                          // CupertinoTextField skips Material InputDecorator (no M3 gray fill layer).
                                          child: CupertinoTextField(
                                            focusNode: _codeFocus,
                                            controller: _codeController,
                                            keyboardType: TextInputType.visiblePassword,
                                            textInputAction: TextInputAction.done,
                                            enableSuggestions: false,
                                            autocorrect: false,
                                            maxLines: 1,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            style: _loginTextStyle(context, opacity: 1),
                                            placeholder: s.loginHint,
                                            placeholderStyle: _loginTextStyle(context, opacity: 0.38),
                                            cursorColor: AppTheme.primaryGold,
                                            selectionControls: materialTextSelectionControls,
                                            decoration: const BoxDecoration(
                                              color: Colors.transparent,
                                            ),
                                            onSubmitted: (_) => _submit(s),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _busy ? null : () => _submit(s),
                                        icon: _busy
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppTheme.primaryGold,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: AppTheme.primaryGold,
                                                size: 28,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 56,
                                child: FilledButton(
                                  onPressed: _busy ? null : () => _submit(s),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor:
                                        AppTheme.primaryGold.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _busy
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.black,
                                          ),
                                        )
                                      : Text(
                                          s.loginButton,
                                          style: AppTheme.withRabarIfKurdish(
                                            uiLocale,
                                            const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
