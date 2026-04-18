import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme.dart';
import '../../../providers/session_provider.dart';
import '../../../widgets/optic_wordmark.dart';
import '../../../widgets/tv_fluid_focusable.dart';

class TvLoginScreen extends ConsumerStatefulWidget {
  const TvLoginScreen({super.key});

  @override
  ConsumerState<TvLoginScreen> createState() => _TvLoginScreenState();
}

class _TvLoginScreenState extends ConsumerState<TvLoginScreen> {
  String _enteredCode = "";
  bool _isLoading = false;
  String? _error;

  void _onDigitPressed(String digit) {
    if (_enteredCode.length < 6) {
      setState(() {
        _enteredCode += digit;
        _error = null;
      });
    }
  }

  void _onBackspace() {
    if (_enteredCode.isNotEmpty) {
      setState(() {
        _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
        _error = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredCode = "";
      _error = null;
    });
  }

  Future<void> _handleLogin() async {
    if (_enteredCode.length < 6) {
      setState(() => _error = "Please enter a 6-digit code");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref.read(sessionProvider.notifier).loginWithCode(_enteredCode);
      if (!success && mounted) {
        setState(() {
          _isLoading = false;
          _error = "Invalid or Expired Code";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Connection Error";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Cinematic Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/optic_logo.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.9),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.5,
                child: Lottie.network(
                  'https://assets3.lottiefiles.com/packages/lf20_M9pWvS.json', // Pro Cinematic Ambient
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // 3. Dual-Panel Layout (Display + Keypad)
          Row(
            children: [
              // LEFT: Branding & Code Display
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const OpticWordmark(height: 80),
                    const SizedBox(height: 60),
                    Text(
                      'ACTIVATE SERVICE',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGold,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildCodeDisplay(),
                    if (_error != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _error!.toUpperCase(),
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ],
                ),
              ),

              // RIGHT: Pro Keypad
              Expanded(
                flex: 3,
                child: Center(
                  child: GlassmorphicContainer(
                    width: 400,
                    height: 550,
                    borderRadius: 32,
                    blur: 25,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGold.withOpacity(0.3),
                        AppTheme.primaryGold.withOpacity(0.05),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.2,
                              children: [
                                for (var i = 1; i <= 9; i++) _buildKey('$i'),
                                _buildSpecialKey(Icons.backspace_rounded, _onBackspace),
                                _buildKey('0'),
                                _buildSpecialKey(Icons.delete_forever_rounded, _onClear),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final hasDigit = index < _enteredCode.length;
        return Container(
          width: 64,
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasDigit ? AppTheme.primaryGold : Colors.white.withOpacity(0.1),
              width: hasDigit ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            hasDigit ? _enteredCode[index] : "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKey(String label) {
    return GhostenFocusable(
      onTap: () => _onDigitPressed(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(IconData icon, VoidCallback onTap) {
    return GhostenFocusable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GhostenFocusable(
      onTap: _handleLogin,
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _enteredCode.length == 6 ? AppTheme.primaryGold : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.black)
          : Text(
              'ACTIVATE DEVICE',
              style: TextStyle(
                color: _enteredCode.length == 6 ? Colors.black : Colors.white24,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
      ),
    );
  }
}
