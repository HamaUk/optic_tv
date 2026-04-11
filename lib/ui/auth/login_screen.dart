import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/optic_wordmark.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/session_provider.dart';
import '../../platform/android_tv.dart';
import '../../widgets/tv_login_keyboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  bool _busy = false;
  bool _isTV = false;

  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    final tv = await queryAndroidTelevisionDevice();
    if (mounted) setState(() => _isTV = tv);
  }

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
                    // Code Display Zone (Prevents TV system password overlay)
                    _isTV
                        ? _buildTvCodeDisplay(s)
                        : Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C2430),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                focusNode: _codeFocus,
                                controller: _codeController,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: s.loginHint,
                                  hintStyle: _loginTextStyle(context, opacity: 0.35),
                                  border: InputBorder.none,
                                  icon: const Icon(Icons.vpn_key_rounded,
                                      color: AppTheme.primaryGold, size: 22),
                                ),
                                style: _loginTextStyle(context, opacity: 1),
                                cursorColor: AppTheme.primaryGold,
                                onSubmitted: (_) => _submit(s),
                              ),
                            ),
                          ),
                    if (_isTV) ...[
                      const SizedBox(height: 16),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: TvLoginKeyboard(
                          onCharacter: (ch) {
                            _codeController.text += ch;
                          },
                          onBackspace: () {
                            if (_codeController.text.isNotEmpty) {
                              _codeController.text = _codeController.text
                                  .substring(0, _codeController.text.length - 1);
                            }
                          },
                          onClear: () => _codeController.clear(),
                        ),
                      ),
                    ],
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

  Widget _buildTvCodeDisplay(AppStrings s) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2430),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGold.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.vpn_key_rounded, color: AppTheme.primaryGold, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _codeController.text.isEmpty
                    ? s.loginHint
                    : '●' * _codeController.text.length,
                style: _loginTextStyle(context,
                    opacity: _codeController.text.isEmpty ? 0.35 : 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
