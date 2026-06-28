import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_locale_provider.dart';
import '../auth/login_screen.dart';
import '../../widgets/animated_gradient_border.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late VideoPlayerController _controller;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/splash.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video
          if (_controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          
          // Dark Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.3)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // Content Pages
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _FadeInSlide(
      key: const ValueKey(1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', width: 140, height: 140),
          const SizedBox(height: 32),
          const Text(
            'Welcome to KOBANI 4K',
            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'The Ultimate Streaming Experience',
            style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 0.5),
          ),
          const SizedBox(height: 64),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A922),
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
            ),
            onPressed: _nextPage,
            child: const Text('GET STARTED', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _FadeInSlide(
      key: const ValueKey(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choose Your Language',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          _buildLangBtn('Kurdish (Sorani)', 'ckb'),
          const SizedBox(height: 20),
          _buildLangBtn('Kurdish (Kurmanji)', 'kmr'),
          const SizedBox(height: 20),
          _buildLangBtn('English', 'en'),
        ],
      ),
    );
  }

  Widget _buildLangBtn(String title, String code) {
    return SizedBox(
      width: 280,
      height: 64,
      child: AnimatedGradientBorder(
        borderRadius: BorderRadius.circular(16),
        borderWidth: 2,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
            _nextPage();
          },
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return _FadeInSlide(
      key: const ValueKey(3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choose Your Device',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'How are you using this app?',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 64),
          _buildDeviceBtn('📱 Phone / Tablet', () async {
            final p = await SharedPreferences.getInstance();
            await p.setString('device_mode', 'phone');
            _finishOnboarding();
          }),
          const SizedBox(height: 24),
          _buildDeviceBtn('📺 TV Interface', () async {
            final p = await SharedPreferences.getInstance();
            await p.setString('device_mode', 'tv');
            _finishOnboarding();
          }),
        ],
      ),
    );
  }

  Widget _buildDeviceBtn(String title, VoidCallback onTap) {
    return SizedBox(
      width: 320,
      height: 80,
      child: AnimatedGradientBorder(
        borderRadius: BorderRadius.circular(20),
        borderWidth: 2,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          onPressed: onTap,
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

class _FadeInSlide extends StatefulWidget {
  final Widget child;
  const _FadeInSlide({required super.key, required this.child});

  @override
  State<_FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<_FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    
    // Slight delay to allow PageView transition
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: widget.child,
      ),
    );
  }
}
