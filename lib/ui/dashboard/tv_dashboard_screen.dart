import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../widgets/optic_wordmark.dart';
import '../../providers/login_codes_provider.dart';

class TVDashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenLiveTv;
  final VoidCallback onOpenMovies;
  final VoidCallback onOpenSettings;

  const TVDashboardScreen({
    super.key,
    required this.onOpenLiveTv,
    required this.onOpenMovies,
    required this.onOpenSettings,
    // Add these to satisfy the existing constructor calls in dashboard_screen.dart if needed
    VoidCallback? onOpenSport,
    VoidCallback? onOpenFavorites,
  });

  @override
  ConsumerState<TVDashboardScreen> createState() => _TVDashboardScreenState();
}

class _TVDashboardScreenState extends ConsumerState<TVDashboardScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCodesCount = ref.watch(loginCodesCountProvider).asData?.value ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF161B22),
                  Colors.black,
                ],
              ),
            ),
          ),
          
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuCard(
                        label: 'LIVE TV',
                        icon: Icons.tv_rounded,
                        onTap: widget.onOpenLiveTv,
                        autofocus: true,
                      ),
                      const SizedBox(width: 30),
                      _MenuCard(
                        label: 'MOVIES',
                        icon: Icons.movie_filter_rounded,
                        onTap: widget.onOpenMovies,
                      ),
                      const SizedBox(width: 30),
                      _MenuCard(
                        label: 'SETTINGS',
                        icon: Icons.settings_suggest_rounded,
                        onTap: widget.onOpenSettings,
                      ),
                    ],
                  ),
                ),
              ),
              _buildFooter(activeCodesCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final timeStr = DateFormat('HH:mm').format(_now);
    final dateStr = DateFormat('EEEE, MMMM d').format(_now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 50, 60, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const OpticWordmark(height: 54),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                dateStr.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryGold.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int activeCodesCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 0, 60, 50),
      child: Row(
        children: [
          _StatusCard(
            count: activeCodesCount,
            label: 'ACTIVE CODES',
            icon: Icons.admin_panel_settings_rounded,
          ),
          const Spacer(),
          Text(
            'ULTRA OPTIC V2.1.2',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool autofocus;

  const _MenuCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.enter || 
             event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: Container(
            width: 260,
            height: 380,
            decoration: BoxDecoration(
              color: _focused ? AppTheme.primaryGold : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: _focused ? Colors.white : Colors.white.withOpacity(0.1),
                width: _focused ? 4 : 1,
              ),
              boxShadow: _focused ? [
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.35),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ] : [],
            ),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _focused ? Colors.black.withOpacity(0.1) : AppTheme.primaryGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 80,
                    color: _focused ? Colors.black : AppTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _focused ? Colors.black : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;

  const _StatusCard({
    required this.count,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryGold, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
