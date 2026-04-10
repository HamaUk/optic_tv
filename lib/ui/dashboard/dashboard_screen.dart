import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/playlist_service.dart';
import '../admin/admin_screen.dart';
import '../player/player_screen.dart';
import '../settings/settings_screen.dart';

/// Hidden admin portal: matches [AdminScreen] gate.
const String _kAdminPortalPassword = 'hamakoye99';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _adminLogoTaps = 0;
  Timer? _adminTapResetTimer;

  @override
  void dispose() {
    _adminTapResetTimer?.cancel();
    super.dispose();
  }

  void _onLogoTapForAdminPortal() {
    _adminTapResetTimer?.cancel();
    _adminTapResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _adminLogoTaps = 0);
    });

    setState(() => _adminLogoTaps++);

    if (_adminLogoTaps >= 7) {
      _adminTapResetTimer?.cancel();
      setState(() => _adminLogoTaps = 0);
      _showAdminPasswordDialog();
    }
  }

  void _showAdminPasswordDialog() {
    final passwordController = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D26),
          title: const Text('Admin portal'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _tryAdminPassword(
              dialogContext,
              passwordController.text,
              passwordController,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Future.microtask(passwordController.dispose);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _tryAdminPassword(
                dialogContext,
                passwordController.text,
                passwordController,
              ),
              child: const Text('Enter'),
            ),
          ],
        );
      },
    );
  }

  void _tryAdminPassword(
    BuildContext dialogContext,
    String password,
    TextEditingController passwordController,
  ) {
    if (password == _kAdminPortalPassword) {
      Navigator.pop(dialogContext);
      Future.microtask(passwordController.dispose);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the dynamic channel stream from Realtime Database
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundBlack,
              Color(0xFF161A25),
              AppTheme.backgroundBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: channelsAsync.when(
                  data: (channels) => _buildChannelView(channels),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
                  error: (e, _) => Center(child: Text('Error loading channels: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelView(List<Channel> channels) {
    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv_off, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            const Text('No Channels Found', style: TextStyle(color: Colors.white30)),
            const SizedBox(height: 8),
            const Text(
              'Channels sync from your library when available.',
              style: TextStyle(color: Colors.white24, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final groups = <String, List<Channel>>{};
    for (var channel in channels) {
      groups.putIfAbsent(channel.group, () => []).add(channel);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(channels.first),
          ...groups.entries.map((group) => _buildCategoryRow(channels, group.key, group.value)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _onLogoTapForAdminPortal,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPTIC TV',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'PREMIUM ENTERTAINMENT',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white30,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white10),
            ),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70),
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Channel featured) {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.connected_tv,
              size: 200,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Now Playing',
                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  featured.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final i = channels.indexOf(featured);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          channels: channels,
                          initialIndex: i >= 0 ? i : 0,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('WATCH NOW'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(List<Channel> allChannels, String title, List<Channel> channels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: channels.length,
            itemBuilder: (context, index) => _buildChannelCard(allChannels, channels[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(List<Channel> allChannels, Channel channel) {
    return GestureDetector(
      onTap: () {
        final i = allChannels.indexOf(channel);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              channels: allChannels,
              initialIndex: i >= 0 ? i : 0,
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white10, Colors.white.withOpacity(0.05)],
                    ),
                  ),
                  child: Center(
                    child: channel.logo != null
                        ? Image.network(channel.logo!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white24, size: 40))
                        : const Icon(Icons.tv, color: Colors.white24, size: 40),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  channel.name,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
