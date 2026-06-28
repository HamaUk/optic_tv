import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_locale_provider.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
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
    // Inject a global error handler to show exactly what crashed on screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "CRASH: ${details.exceptionAsString()}",
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    };

    final lang = ref.watch(appLocaleProvider).languageCode;
    String t(String en, String ckb) => (lang == 'ckb' || lang == 'kmr') ? ckb : en;

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          _buildStep1(t),
          _buildStep2(t),
          _buildStep3(t),
        ],
      ),
    );
  }

  Widget _buildStep1(String Function(String, String) t) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.live_tv, size: 100, color: Color(0xFFE5A922)),
        const SizedBox(height: 32),
        Text(
          t('Welcome to KOBANI 4K', 'KOBANI 4K بەخێربێیت بۆ'),
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          t('The Ultimate Streaming Experience', 'باشترین ئەزموونی سەیرکردن'),
          style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 0.5),
        ),
        const SizedBox(height: 64),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5A922),
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: _nextPage,
          child: Text(t('GET STARTED', 'دەستپێکردن'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildStep2(String Function(String, String) t) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t('Choose Your Language', 'زمانەکەت هەڵبژێرە'),
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 64),
        _buildLangBtn('Kurdish (Sorani)', 'ckb'),
        const SizedBox(height: 20),
        _buildLangBtn('Kurdish (Kurmanji)', 'kmr'),
        const SizedBox(height: 20),
        _buildLangBtn('English', 'en'),
      ],
    );
  }

  Widget _buildLangBtn(String title, String code) {
    return SizedBox(
      width: 280,
      height: 64,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5A922), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          ref.read(appLocaleProvider.notifier).setLocale(Locale(code));
          _nextPage();
        },
        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20)),
      ),
    );
  }

  Widget _buildStep3(String Function(String, String) t) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t('Choose Your Device', 'ئامێرەکەت هەڵبژێرە'),
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          t('How are you using this app?', 'چۆن ئەم بەرنامەیە بەکاردەهێنیت؟'),
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 64),
        _buildDeviceBtn('📱 ${t("Phone / Tablet", "مۆبایل / تابلێت")}', () async {
          final p = await SharedPreferences.getInstance();
          await p.setString('device_mode', 'phone');
          _finishOnboarding();
        }),
        const SizedBox(height: 24),
        _buildDeviceBtn('📺 ${t("TV Interface", "ڕووکاری تەلەفزیۆن")}', () async {
          final p = await SharedPreferences.getInstance();
          await p.setString('device_mode', 'tv');
          _finishOnboarding();
        }),
      ],
    );
  }

  Widget _buildDeviceBtn(String title, VoidCallback onTap) {
    return SizedBox(
      width: 320,
      height: 80,
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
    
    _ctrl.forward();
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
