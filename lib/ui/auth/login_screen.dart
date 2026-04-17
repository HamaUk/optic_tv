import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/optic_wordmark.dart';
import '../../widgets/tv_fluid_focusable.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  bool _busy = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onKeyPress(String val) {
    if (_busy) return;
    if (val == 'DEL') {
      if (_codeController.text.isNotEmpty) {
        _codeController.text =
            _codeController.text.substring(0, _codeController.text.length - 1);
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
    await ref.read(sessionProvider.notifier).loginWithCode(code);
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
      body: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.6, -0.4),
                radius: 1.5,
                colors: [
                  const Color(0xFF0D1B35).withValues(alpha: 0.95),
                  const Color(0xFF050A12),
                  Colors.black,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Ambient glow orb top-left
                Positioned(
                  top: -120 + 30 * _glowAnim.value,
                  left: -100,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF98C2FF).withValues(
                              alpha: 0.08 + 0.04 * _glowAnim.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Ambient glow orb bottom-right
                Positioned(
                  bottom: -80,
                  right: -80,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF7068F8).withValues(
                              alpha: 0.06 + 0.03 * _glowAnim.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                child!,
              ],
            ),
          );
        },
        child: SafeArea(
          child: Center(
            child: isTv
                ? _buildTvLayout(uiLocale, s, session)
                : _buildMobileLayout(uiLocale, s, session),
          ),
        ),
      ),
    );
  }

  // ── MOBILE LAYOUT ──────────────────────────────────────────────────────────
  Widget _buildMobileLayout(Locale uiLocale, AppStrings s, SessionState session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Center(child: const OpticWordmark(height: 56)),
            const SizedBox(height: 48),

            // Title
            Text(
              s.loginTitle,
              textAlign: TextAlign.center,
              style: AppTheme.withRabarIfKurdish(
                uiLocale,
                const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              s.loginSubtitle,
              textAlign: TextAlign.center,
              style: AppTheme.withRabarIfKurdish(
                uiLocale,
                TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Input field — glassmorphic
            _buildMobileInputField(s),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              height: 58,
              child: FilledButton(
                onPressed: _busy ? null : () => _submit(s),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF98C2FF),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      const Color(0xFF98C2FF).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4B4B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF4B4B).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  session.error!,
                  style: const TextStyle(
                    color: Color(0xFFFF4B4B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileInputField(AppStrings s) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 16,
            ),
            border: InputBorder.none,
            icon: const Icon(
              Icons.vpn_key_rounded,
              color: Color(0xFF98C2FF),
              size: 22,
            ),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 17),
          cursorColor: const Color(0xFF98C2FF),
          onSubmitted: (_) => _submit(s),
        ),
      ),
    );
  }

  // ── TV LAYOUT (Ghosten-inspired, beautiful) ────────────────────────────────
  Widget _buildTvLayout(Locale uiLocale, AppStrings s, SessionState session) {
    return Row(
      children: [
        // Left pane — info + branding
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OpticWordmark(height: 64),
                const SizedBox(height: 48),

                Text(
                  s.loginTitle,
                  style: AppTheme.withRabarIfKurdish(
                    uiLocale,
                    const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.loginSubtitle,
                  style: AppTheme.withRabarIfKurdish(
                    uiLocale,
                    TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.45),
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Feature pills
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _featurePill(Icons.hd_rounded, '4K HD Streams'),
                    _featurePill(Icons.security_rounded, 'Secure Access'),
                    _featurePill(Icons.devices_rounded, 'All Devices'),
                  ],
                ),

                if (session.error != null) ...[
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFF4B4B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF4B4B).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFFF4B4B), size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            session.error!,
                            style: const TextStyle(
                              color: Color(0xFFFF4B4B),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Divider
        Container(
          width: 1,
          height: 300,
          color: Colors.white.withValues(alpha: 0.08),
        ),

        // Right pane — keypad
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDisplayField(s),
                    const SizedBox(height: 32),
                    _buildKeypad(s, uiLocale),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF98C2FF), size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayField(AppStrings s) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF98C2FF).withValues(alpha: 0.06),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _codeController,
          builder: (context, value, _) {
            final text = value.text;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (text.isEmpty)
                  Text(
                    s.loginHint,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w300,
                    ),
                  )
                else
                  // Show dots for entered chars
                  ...List.generate(
                    text.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF98C2FF),
                        shape: BoxShape.circle,
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

  Widget _buildKeypad(AppStrings s, Locale uiLocale) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (var i = 1; i <= 9; i++) _keyButton(i.toString()),
        _keyButton('DEL',
            icon: Icons.backspace_outlined,
            color: Colors.white.withValues(alpha: 0.5)),
        _keyButton('0'),
        _keyButton('OK',
            icon: Icons.check_rounded,
            color: const Color(0xFF98C2FF),
            filled: true),
      ],
    );
  }

  Widget _keyButton(
    String val, {
    IconData? icon,
    Color? color,
    bool filled = false,
  }) {
    final locale = ref.read(appLocaleProvider);
    final s = AppStrings(locale);
    final isOk = val == 'OK';
    final isDel = val == 'DEL';
    final focusNode = FocusNode();

    return GhostenFocusable(
      onTap: () {
        if (isOk) {
          _submit(s);
        } else {
          _onKeyPress(val);
        }
      },
      backgroundColor: filled
          ? const Color(0xFF98C2FF).withValues(alpha: 0.15)
          : Colors.white.withValues(alpha: 0.05),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: filled
              ? Border.all(
                  color: const Color(0xFF98C2FF).withValues(alpha: 0.4))
              : null,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: color ?? Colors.white, size: 26)
              : Text(
                  val,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
