import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_locale_provider.dart';
import '../../widgets/animated_gradient_border.dart';
import '../../widgets/kobani_wordmark.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Video
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  // Animations
  late AnimationController _bgGlowCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Background glow animation
    _bgGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Floating particles
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Page content fade-in
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();

    // Video — safe initialization with timeout
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
    _videoController?.dispose();
    _pageController.dispose();
    _bgGlowCtrl.dispose();
    _particleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _fadeCtrl.reset();
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  void _nextPage() => _goToPage(_currentPage + 1);

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    String t(String en, String ckb) =>
        (lang == 'ckb' || lang == 'kmr') ? ckb : en;

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

          // ─── Layer 4: Content ───
          SafeArea(
            child: Column(
              children: [
                // Page Indicators
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _buildPageIndicators(),
                ),

                // Page Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildStep1(t),
                      _buildStep2(t),
                      _buildStep3(t),
                    ],
                  ),
                ),
              ],
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

  // ═══════════════════════════════════════════════════════════════
  //  PAGE INDICATORS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: isActive
                ? const Color(0xFFE5A922)
                : Colors.white.withValues(alpha: 0.25),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFE5A922).withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STEP 1: WELCOME
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep1(String Function(String, String) t) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with glow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5A922).withValues(alpha: 0.3),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.live_tv,
                      size: 100,
                      color: Color(0xFFE5A922),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Animated Wordmark
              const KobaniWordmark(height: 50, twoLine: true),
              const SizedBox(height: 20),

              // Subtitle
              Text(
                t('The Ultimate Streaming Experience',
                    'باشترین ئەزموونی سەیرکردن'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 17,
                  letterSpacing: 0.8,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Feature chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _chip(t('🎬 4K HDR', '🎬 4K و HDR')),
                  _chip(t('⚡ Ultra Fast', '⚡ خێرایەکی زۆر')),
                  _chip(t('🌐 Multi-Language', '🌐 فرەزمان')),
                ],
              ),
              const SizedBox(height: 48),

              // GET STARTED button with animated gradient border
              AnimatedGradientBorder(
                borderRadius: BorderRadius.circular(30),
                borderWidth: 2.5,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF121212),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                    ),
                    onPressed: _nextPage,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t('GET STARTED', 'دەستپێکردن'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Color(0xFFE5A922), size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STEP 2: LANGUAGE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep2(String Function(String, String) t) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5A922).withValues(alpha: 0.1),
                  border: Border.all(
                      color: const Color(0xFFE5A922).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.translate_rounded,
                    size: 48, color: Color(0xFFE5A922)),
              ),
              const SizedBox(height: 32),

              Text(
                t('Choose Your Language', 'زمانەکەت هەڵبژێرە'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t('You can change this later in settings',
                    'دواتر لە ڕێکخستنەکان دەتوانیت بیگۆڕیت'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              _buildLangBtn('کوردی (سۆرانی)', 'ckb', 0),
              const SizedBox(height: 16),
              _buildLangBtn('Kurdî (Kurmancî)', 'kmr', 1),
              const SizedBox(height: 16),
              _buildLangBtn('English', 'en', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangBtn(String title, String code, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 150),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: 300,
        height: 64,
        child: AnimatedGradientBorder(
          borderRadius: BorderRadius.circular(18),
          borderWidth: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF121212),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
              ),
            ),
            onPressed: () {
              ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
              _nextPage();
            },
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STEP 3: DEVICE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep3(String Function(String, String) t) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5A922).withValues(alpha: 0.1),
                  border: Border.all(
                      color: const Color(0xFFE5A922).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.devices_rounded,
                    size: 48, color: Color(0xFFE5A922)),
              ),
              const SizedBox(height: 32),

              Text(
                t('Choose Your Device', 'ئامێرەکەت هەڵبژێرە'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t('Optimize the interface for your screen',
                    'ڕووکارەکە بۆ شاشەکەت باشتر بکە'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              _buildDeviceBtn(
                icon: Icons.smartphone_rounded,
                title: t('Phone / Tablet', 'مۆبایل / تابلێت'),
                subtitle: t('Touch-optimized interface',
                    'ڕووکاری تایبەت بە دەست پێوەدان'),
                index: 0,
                onTap: () async {
                  final p = await SharedPreferences.getInstance();
                  await p.setString('device_mode', 'phone');
                  _finishOnboarding();
                },
              ),
              const SizedBox(height: 20),
              _buildDeviceBtn(
                icon: Icons.tv_rounded,
                title: t('TV Interface', 'ڕووکاری تەلەفزیۆن'),
                subtitle: t('Remote-friendly layout',
                    'ڕووکاری تایبەت بە ڕیمۆت کۆنترۆڵ'),
                index: 1,
                onTap: () async {
                  final p = await SharedPreferences.getInstance();
                  await p.setString('device_mode', 'tv');
                  _finishOnboarding();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceBtn({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 700 + index * 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: AnimatedGradientBorder(
        borderRadius: BorderRadius.circular(22),
        borderWidth: 2.5,
        child: Material(
          color: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFE5A922).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon,
                        color: const Color(0xFFE5A922), size: 30),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.3), size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════
  Widget _chip(String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FLOATING PARTICLE PAINTER
// ═══════════════════════════════════════════════════════════════
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
      paint.color = Color(0xFFE5A922).withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, wrappedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
