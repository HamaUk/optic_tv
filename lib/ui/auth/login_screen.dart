import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:custom_tv_text_field/custom_tv_text_field.dart';

import '../../core/theme.dart';
import '../../widgets/kobani_wordmark.dart';
import '../../widgets/tv_fluid_focusable.dart';
import '../../widgets/animated_gradient_border.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/platform_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  bool _busy = false;

  // Video
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  // Animations
  late AnimationController _bgGlowCtrl;
  late AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    _bgGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset('assets/video/splash.mp4');
      await controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('Video init timed out — using gradient fallback');
          controller.dispose();
          throw Exception('Video timeout');
        },
      );
      controller.setLooping(true);
      controller.setVolume(0);
      controller.play();
      if (mounted) {
        setState(() {
          _videoController = controller;
          _videoReady = true;
        });
      }
    } catch (e) {
      debugPrint('Video Player Error: $e — using gradient fallback');
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _videoController?.dispose();
    _bgGlowCtrl.dispose();
    _particleCtrl.dispose();
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
    await ref.read(sessionProvider.notifier).loginWithCode(code);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final session = ref.watch(sessionProvider);
    final deviceTypeAsync = ref.watch(deviceTypeProvider);
    final s = AppStrings(uiLocale);
    
    final isTv = deviceTypeAsync.asData?.value == DeviceType.tv;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Layer 1: Video or Animated Gradient Background ───
          if (_videoReady && _videoController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            _buildAnimatedGradientBg(),

          // ─── Layer 2: Dark Overlay ───
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ─── Layer 3: Floating Particles ───
          _buildParticles(),

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

  // ═══════════════════════════════════════════════════════════════
  //  ANIMATED GRADIENT BACKGROUND (fallback when video fails)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAnimatedGradientBg() {
    return AnimatedBuilder(
      animation: _bgGlowCtrl,
      builder: (context, _) {
        final t = _bgGlowCtrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(t * math.pi * 2) * 0.5,
                math.cos(t * math.pi * 2) * 0.3 - 0.2,
              ),
              radius: 1.8,
              colors: [
                Color.lerp(
                    const Color(0xFF1A0A2E), const Color(0xFF0D1B3E), t)!,
                Color.lerp(
                    const Color(0xFF0A0A12), const Color(0xFF12091F), t)!,
                Colors.black,
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  FLOATING PARTICLES
  // ═══════════════════════════════════════════════════════════════
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(_particleCtrl.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMobileLayout(Locale uiLocale, AppStrings s, SessionState session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: KobaniWordmark(height: 48, twoLine: true)),
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
            
            // Login Card
            _glassContainer(
              borderRadius: BorderRadius.circular(32),
              blur: 25,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _buildMatteInput(
                      controller: _codeController,
                      hint: s.loginHint,
                      icon: Icons.key_rounded,
                      obscure: true,
                    ),
                    const SizedBox(height: 24),
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
          ],
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
                const KobaniWordmark(height: 60, twoLine: true),
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
                      color: Colors.white.withOpacity(0.6),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _featurePill(Icons.hd_rounded, s.isSorani ? '4K و HDR' : '4K HDR'),
                    _featurePill(Icons.auto_awesome_rounded, s.isSorani ? 'ڕووکاری شووشەیی' : 'GLASS UI'),
                    _featurePill(Icons.bolt_rounded, s.isSorani ? 'خێرایەکی زۆر' : 'ULTRA FAST'),
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
                      CustomTVTextField(
                        controller: _codeController,
                        isFocused: true,
                        hint: s.loginHint.toUpperCase(),
                        textFieldType: TextFieldType.number,
                        textStyle: const TextStyle(color: AppTheme.primaryGold, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 8),
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
                        backgroundColor: Colors.white.withOpacity(0.03),
                        borderColor: Colors.white.withOpacity(0.15),
                        focusedBorderColor: AppTheme.primaryGold.withOpacity(0.5),
                        borderRadius: 24,
                        verticalContentPadding: 24,
                        horizontalContentPadding: 32,
                        textAlign: TextAlign.center,
                        onFieldSubmitted: (_) => _submit(s),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      TvFluidFocusable(
                        onPressed: _busy ? () {} : () => _submit(s),
                        builder: (context, isFocused) {
                          return AnimatedGradientBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderWidth: isFocused ? 4 : 2,
                            child: Container(
                              width: double.infinity,
                              height: 72,
                              decoration: BoxDecoration(
                                color: isFocused ? const Color(0xFF1a1a1a) : const Color(0xFF121212),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Center(
                                child: Text(
                                  s.loginButton.toUpperCase(),
                                  style: AppTheme.withRabarIfKurdish(
                                    uiLocale,
                                    TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: 2,
                                      color: isFocused ? AppTheme.primaryGold : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      if (session.error != null) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                          ),
                          child: Text(
                            session.error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
        decoration: InputDecoration(
          hintText: hint.toUpperCase(),
          hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 1, fontSize: 12, fontWeight: FontWeight.w900),
          prefixIcon: Icon(icon, color: AppTheme.primaryGold),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.white24, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required VoidCallback? onPressed, required String label}) {
    return AnimatedGradientBorder(
      borderRadius: BorderRadius.circular(24),
      borderWidth: 2,
      child: SizedBox(
        width: double.infinity,
        height: 72,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF121212),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
      ),
    );
  }

  Widget _glassContainer({required Widget child, required BorderRadius borderRadius, double blur = 25}) {
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.primaryGold, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 35; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final radius = 1.0 + rng.nextDouble() * 2.5;
      final phase = rng.nextDouble() * math.pi * 2;

      final x = baseX + math.sin(t * math.pi * 2 * speed + phase) * 30;
      final y = baseY - (t * speed * 80) % size.height;
      final wrappedY = y < 0 ? y + size.height : y;

      final alpha = (0.15 + math.sin(t * math.pi * 2 + phase) * 0.1)
          .clamp(0.0, 1.0);
      paint.color = const Color(0xFFE5A922).withOpacity(alpha);

      canvas.drawCircle(Offset(x, wrappedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
