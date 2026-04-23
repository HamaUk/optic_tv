import 'dart:ui';
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
      body: Stack(
        children: [
          // Dynamic Gradient Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(_glowAnim.value * 0.2 - 0.6, _glowAnim.value * 0.2 - 0.4),
                      radius: 1.8,
                      colors: [
                        const Color(0xFF1A2A4E),
                        const Color(0xFF0A101E),
                        Colors.black,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Ambient Glow Orbs
          Positioned(
            top: -150,
            left: -100,
            child: _GlowOrb(
              color: const Color(0xFF98C2FF).withOpacity(0.15),
              size: 600,
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _GlowOrb(
              color: const Color(0xFF7068F8).withOpacity(0.1),
              size: 500,
            ),
          ),

          SafeArea(
            child: Center(
              child: isTv
                  ? _buildTvLayout(uiLocale, s, session)
                  : _buildMobileLayout(uiLocale, s, session),
            ),
          ),
          
          if (_busy)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Locale uiLocale, AppStrings s, SessionState session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: _glassContainer(
          borderRadius: BorderRadius.circular(32),
          blur: 25,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: OpticWordmark(height: 64)),
                const SizedBox(height: 40),
                Text(
                  s.loginTitle.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTheme.withRabarIfKurdish(
                    uiLocale,
                    const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
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
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Login Code Input
                _buildMatteInput(
                  controller: _codeController,
                  hint: s.loginHint,
                  icon: Icons.key_rounded,
                  obscure: true,
                ),
                
                const SizedBox(height: 24),
                
                // Action Button
                _buildPrimaryButton(
                  onPressed: _busy ? null : () => _submit(s),
                  label: s.loginButton.toUpperCase(),
                ),

                if (session.error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                    ),
                    child: Text(
                      session.error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTvLayout(Locale uiLocale, AppStrings s, SessionState session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OpticWordmark(height: 80),
                const SizedBox(height: 60),
                Text(
                  s.loginTitle.toUpperCase(),
                  style: AppTheme.withRabarIfKurdish(
                    uiLocale,
                    const TextStyle(
                      fontSize: 48,
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
                      color: Colors.white.withOpacity(0.4),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _featurePill(Icons.hd_rounded, 'PREMIUM 4K'),
                    _featurePill(Icons.auto_awesome_rounded, 'GLASS UI'),
                    _featurePill(Icons.bolt_rounded, 'ULTRA FAST'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 5,
            child: Center(
              child: _glassContainer(
                borderRadius: BorderRadius.circular(40),
                blur: 30,
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTvDisplayField(s),
                      const SizedBox(height: 40),
                      _buildKeypad(s, uiLocale),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatteInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
        decoration: InputDecoration(
          hintText: hint.toUpperCase(),
          hintStyle: const TextStyle(color: Colors.black26, letterSpacing: 1, fontSize: 12, fontWeight: FontWeight.w900),
          prefixIcon: Icon(icon, color: AppTheme.primaryGold),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required VoidCallback? onPressed, required String label}) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({required Widget child, required BorderRadius borderRadius, double blur = 15}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvDisplayField(AppStrings s) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _codeController,
      builder: (context, value, _) {
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Center(
            child: value.text.isEmpty
                ? Text(
                    s.loginHint.toUpperCase(),
                    style: TextStyle(color: Colors.black.withOpacity(0.1), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      value.text.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildKeypad(AppStrings s, Locale uiLocale) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        for (var i = 1; i <= 9; i++) _keyButton(i.toString()),
        _keyButton('DEL', icon: Icons.backspace_rounded),
        _keyButton('0'),
        _keyButton('OK', icon: Icons.check_circle_rounded, isPrimary: true),
      ],
    );
  }

  Widget _keyButton(String val, {IconData? icon, bool isPrimary = false}) {
    return GhostenFocusable(
      onTap: () => val == 'OK' ? _submit(AppStrings(ref.read(appLocaleProvider))) : _onKeyPress(val),
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryGold.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppTheme.primaryGold.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: isPrimary ? AppTheme.primaryGold : Colors.white, size: 32)
              : Text(
                  val,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
