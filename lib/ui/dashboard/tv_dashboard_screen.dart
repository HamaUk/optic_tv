import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';
import '../../widgets/optic_wordmark.dart';

class TVDashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenLiveTv;
  final VoidCallback onOpenMovies;
  final VoidCallback onOpenSport;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenSettings;

  const TVDashboardScreen({
    super.key,
    required this.onOpenLiveTv,
    required this.onOpenMovies,
    required this.onOpenSport,
    required this.onOpenFavorites,
    required this.onOpenSettings,
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
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(s),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuTile(
                        label: 'LIVE TV',
                        icon: Icons.tv_rounded,
                        color: const Color(0xFF3B82F6), // Smarters Blue
                        onTap: widget.onOpenLiveTv,
                        isLarge: true,
                        autofocus: true,
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuTile(
                            label: 'MOVIES',
                            icon: Icons.movie_filter_rounded,
                            color: const Color(0xFF10B981), // Smarters Green
                            onTap: widget.onOpenMovies,
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuTile(
                            label: 'SPORT',
                            icon: Icons.sports_soccer_rounded,
                            color: const Color(0xFFF59E0B), // Smarters Orange
                            onTap: widget.onOpenSport,
                          ),
                          const SizedBox(height: 20),
                          _MenuTile(
                            label: 'FAVORITES',
                            icon: Icons.star_rounded,
                            color: const Color(0xFFEAB308), // Smarters Yellow/Gold
                            onTap: widget.onOpenFavorites,
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      _MenuTile(
                        label: 'SETTINGS',
                        icon: Icons.settings_suggest_rounded,
                        color: const Color(0xFF64748B), // Smarters Grey
                        onTap: widget.onOpenSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings s) {
    final timeStr = DateFormat('HH:mm').format(_now);
    final dateStr = DateFormat('EEE, MMM d').format(_now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OpticWordmark(height: 48),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Expires: Perpetual',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLarge;
  final bool autofocus;
  final bool isEnabled;

  const _MenuTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLarge = false,
    this.autofocus = false,
    this.isEnabled = true,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final double width = widget.isLarge ? 220 : 180;
    final double height = widget.isLarge ? 320 : 150;

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.enter || 
             event.logicalKey == LogicalKeyboardKey.select || 
             event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          if (widget.isEnabled) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _focused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: widget.isEnabled 
                  ? ( _focused ? widget.color : widget.color.withOpacity(0.2))
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _focused ? Colors.white : widget.color.withOpacity(0.3),
                width: _focused ? 3 : 1,
              ),
              boxShadow: _focused 
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Opacity(
              opacity: widget.isEnabled ? 1.0 : 0.4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: widget.isLarge ? 64 : 48,
                    color: _focused ? Colors.black : widget.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: _focused ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
