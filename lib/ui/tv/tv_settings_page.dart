import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../core/theme.dart';
import '../../../widgets/tv_fluid_focusable.dart';

class TvSettingsPage extends ConsumerWidget {
  const TvSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        Text(
          'SETTINGS',
          style: GoogleFonts.outfit(
            color: AppTheme.primaryGold,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 60),
        
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30,
            children: [
              _buildSettingsCard(Icons.person_rounded, 'ACCOUNT', 'Manage your subscription'),
              _buildSettingsCard(Icons.video_settings_rounded, 'PLAYER', 'Buffer and Hardware settings'),
              _buildSettingsCard(Icons.language_rounded, 'LANGUAGE', 'Choose your interface language'),
              _buildSettingsCard(Icons.lock_rounded, 'PARENTAL', 'Manage PIN and locked content'),
              _buildSettingsCard(Icons.info_rounded, 'ABOUT', 'Version 3.1.0 - Elite Build'),
              _buildSettingsCard(Icons.logout_rounded, 'DEACTIVATE', 'Remove this device'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(IconData icon, String title, String subtitle) {
    return GhostenFocusable(
      onTap: () {},
      child: GlassmorphicContainer(
        width: 400,
        height: 250,
        borderRadius: 24,
        blur: 15,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)]),
        borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.02)]),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primaryGold, size: 48),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
