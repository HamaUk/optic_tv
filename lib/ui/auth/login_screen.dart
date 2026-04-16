import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/optic_wordmark.dart';
import '../../widgets/tv_focus_wrapper.dart';
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
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String val) {
    if (_busy) return;
    if (val == 'DEL') {
      if (_codeController.text.isNotEmpty) {
        _codeController.text = _codeController.text.substring(0, _codeController.text.length - 1);
      }
    } else {
      if (_codeController.text.length < 12) {
        _codeController.text += val;
      }
    }
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
    final result = await ref.read(sessionProvider.notifier).loginWithCode(code);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final session = ref.watch(sessionProvider);
    final s = AppStrings(uiLocale);
    final isTv = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E1217), // Deep Charcoal
              Color(0xFF001219), // Dark Teal Tint
              Color(0xFF000000), // Black
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: isTv ? _buildTvLayout(uiLocale, s, session) : _buildMobileLayout(uiLocale, s, session),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Locale uiLocale, AppStrings s, SessionState session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: [
            const OpticWordmark(height: 52),
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
                  color: Colors.white.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildStandardInputField(s),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : () => _submit(s),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppTheme.primaryGold.withOpacity(0.4),
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
            if (session.error != null) ...[
              const SizedBox(height: 32),
              Text(
                'LOG: ${session.error}',
                style: const TextStyle(
                  color: Color(0xFFFF4B4B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTvLayout(Locale uiLocale, AppStrings s, SessionState session) {
    return Row(
      children: [
        // Left: Info
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OpticWordmark(height: 64),
                const SizedBox(height: 40),
                Text(
                  s.loginTitle,
                  style: AppTheme.withRabarIfKurdish(
                    uiLocale,
                    const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.loginSubtitle,
                  style: AppTheme.withRabarIfKurdish(
                    uiLocale,
                    TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.5,
                    ),
                  ),
                ),
                if (session.error != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    'LOG: ${session.error}',
                    style: const TextStyle(
                      color: Color(0xFFFF4B4B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Right: Keypad
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDisplayField(s),
                  const SizedBox(height: 32),
                  _buildKeypad(s),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardInputField(AppStrings s) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2430),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _codeController,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          obscureText: true,
          decoration: InputDecoration(
            hintText: s.loginHint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 16),
            border: InputBorder.none,
            icon: const Icon(Icons.vpn_key_rounded, color: AppTheme.primaryGold, size: 22),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: AppTheme.primaryGold,
          onSubmitted: (_) => _submit(s),
        ),
      ),
    );
  }

  Widget _buildDisplayField(AppStrings s) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF141A22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Center(
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _codeController,
          builder: (context, value, _) {
            final text = value.text;
            return Text(
              text.isEmpty ? s.loginHint : '*' * text.length,
              style: TextStyle(
                color: text.isEmpty ? Colors.white24 : Colors.white,
                fontSize: 28,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKeypad(AppStrings s) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        for (var i = 1; i <= 9; i++) _keyButton(i.toString()),
        _keyButton('DEL', icon: Icons.backspace_rounded, color: Colors.white24),
        _keyButton('0'),
        _keyButton('OK', icon: Icons.check_circle_rounded, color: AppTheme.primaryGold),
      ],
    );
  }

  Widget _keyButton(String val, {IconData? icon, Color? color}) {
    final s = AppStrings(ref.read(appLocaleProvider));
    return TvFocusWrapper(
      onTap: () {
        if (val == 'OK') {
          _submit(s);
        } else {
          _onKeyPress(val);
        }
      },
      borderRadius: 16,
      accentColor: color ?? Colors.white.withOpacity(0.8),
      child: Container(
        decoration: BoxDecoration(
          color: color?.withOpacity(0.12) ?? Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: color ?? Colors.white70, size: 28)
              : Text(
                  val,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}
