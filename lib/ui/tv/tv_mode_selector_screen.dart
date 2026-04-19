import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme.dart';
import '../../../widgets/tv_fluid_focusable.dart';
import 'tv_dashboard_screen.dart';
import 'widgets/tv_sidebar.dart';

class TvModeSelectorScreen extends StatelessWidget {
  const TvModeSelectorScreen({super.key});

  void _navigateToMode(BuildContext context, TvNavDestination mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TvDashboardScreen(initialMode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Cinematic Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Lottie.network(
                'https://assets3.lottiefiles.com/packages/lf20_M9pWvS.json',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SELECT EXPERIENCE',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryGold,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 80),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeCard(
                      context,
                      'LIVE TV',
                      Icons.live_tv_rounded,
                      TvNavDestination.live,
                      const Color(0xff0966d6),
                    ),
                    const SizedBox(width: 40),
                    _buildModeCard(
                      context,
                      'MOVIES',
                      Icons.movie_filter_rounded,
                      TvNavDestination.movies,
                      const Color(0xffe91e63),
                    ),
                    const SizedBox(width: 40),
                    _buildModeCard(
                      context,
                      'SPORTS',
                      Icons.sports_soccer_rounded,
                      TvNavDestination.sports,
                      const Color(0xff4caf50),
                    ),
                    const SizedBox(width: 40),
                    _buildModeCard(
                      context,
                      'SETTINGS',
                      Icons.settings_rounded,
                      TvNavDestination.settings,
                      const Color(0xff9e9e9e),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, String title, IconData icon, TvNavDestination mode, Color accent) {
    return GhostenFocusable(
      onTap: () => _navigateToMode(context, mode),
      child: GlassmorphicContainer(
        width: 250,
        height: 350,
        borderRadius: 32,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.5),
            accent.withOpacity(0.1),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white),
            const SizedBox(height: 32),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
