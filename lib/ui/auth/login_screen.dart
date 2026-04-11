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

    // Standard Scaffold resizing works best for TV focus.
    // We use a Column inside a SingleChildScrollView to ensure focus moves correctly.
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F14), Color(0xFF151B24), Color(0xFF0B0F14)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
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
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2430),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: TextField(
                                focusNode: _codeFocus,
                                controller: _codeController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  hintText: s.loginHint,
                                  hintStyle: _loginTextStyle(context, opacity: 0.38),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                style: _loginTextStyle(context, opacity: 1),
                                cursorColor: AppTheme.primaryGold,
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
          ),
        ),
      ),
    );
  }
}
