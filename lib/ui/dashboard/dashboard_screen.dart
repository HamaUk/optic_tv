import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/ui_settings_provider.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';
import '../admin/admin_screen.dart';
import '../player/player_screen.dart';
import '../settings/settings_screen.dart';

/// Hidden admin portal password.
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
    final s = AppStrings(Localizations.localeOf(context));
    final passwordController = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: Text(s.settingsTitle),
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
              child: Text(s.isEnglish ? 'Cancel' : 'پاشگەزبوونەوە'),
            ),
            FilledButton(
              onPressed: () => _tryAdminPassword(
                dialogContext,
                passwordController.text,
                passwordController,
              ),
              child: Text(s.isEnglish ? 'Enter' : 'بچۆ ژوورەوە'),
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
      final s = AppStrings(Localizations.localeOf(context));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loginErrorInvalid)),
      );
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (mounted) ref.invalidate(appUiSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(Localizations.localeOf(context));
    final channelsAsync = ref.watch(channelsProvider);
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    final tv = settings.tvFriendlyLayout;
    final animMs = settings.reduceMotion ? 100 : 220;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundBlack,
              AppTheme.surfaceGray,
              AppTheme.backgroundBlack.withBlue(24),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(s, tv),
              Expanded(
                child: channelsAsync.when(
                  data: (channels) => _buildChannelView(context, s, channels, settings, animMs),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
                  error: (e, _) => Center(child: Text('${s.channelLoadError}: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings s, bool tv) {
    final pad = tv ? 28.0 : 24.0;
    final iconSize = tv ? 26.0 : 22.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 8),
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
                  s.appBrand,
                  style: TextStyle(
                    fontSize: tv ? 30 : 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  s.appTagline,
                  style: TextStyle(
                    fontSize: tv ? 11 : 10,
                    color: Colors.white.withOpacity(0.38),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              iconSize: iconSize,
              padding: EdgeInsets.all(tv ? 12 : 10),
              icon: Icon(Icons.settings_outlined, color: Colors.white.withOpacity(0.82)),
              tooltip: s.settingsTooltip,
              onPressed: _openSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelView(
    BuildContext context,
    AppStrings s,
    List<Channel> channels,
    AppSettingsData settings,
    int animMs,
  ) {
    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off_rounded, size: settings.tvFriendlyLayout ? 56 : 48, color: Colors.white12),
            const SizedBox(height: 16),
            Text(s.noChannels, style: TextStyle(color: Colors.white.withOpacity(0.35))),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                s.noChannelsHint,
                style: TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final groups = <String, List<Channel>>{};
    for (final channel in channels) {
      groups.putIfAbsent(channel.group, () => []).add(channel);
    }
    final tv = settings.tvFriendlyLayout;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context, s, channels, channels.first, tv, animMs),
          ...groups.entries.map((g) => _buildCategoryRow(context, channels, g.key, g.value, settings, animMs)),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    AppStrings s,
    List<Channel> channels,
    Channel featured,
    bool tv,
    int animMs,
  ) {
    return Container(
      height: tv ? 220 : 240,
      margin: EdgeInsets.symmetric(horizontal: tv ? 28 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGold.withOpacity(0.85),
            AppTheme.surfaceElevated,
            AppTheme.accentTeal.withOpacity(0.35),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.live_tv_rounded,
              size: tv ? 100 : 120,
              color: Colors.black.withOpacity(0.08),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(tv ? 28 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.nowPlaying,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.bold,
                    fontSize: tv ? 12 : 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  featured.name,
                  style: TextStyle(
                    fontSize: tv ? 26 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Focus(
                  child: Builder(
                    builder: (ctx) {
                      final focused = Focus.of(ctx).hasFocus;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: animMs),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: focused
                              ? [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12)]
                              : [],
                        ),
                        child: FilledButton(
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
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: AppTheme.primaryGold,
                            padding: EdgeInsets.symmetric(horizontal: tv ? 28 : 22, vertical: tv ? 14 : 12),
                          ),
                          child: Text(s.watchNow, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    List<Channel> allChannels,
    String title,
    List<Channel> channels,
    AppSettingsData settings,
    int animMs,
  ) {
    final tv = settings.tvFriendlyLayout;
    final rowH = tv ? 186.0 : 148.0;
    final titleSize = tv ? 22.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(tv ? 28 : 24, tv ? 28 : 24, 24, 12),
          child: Text(
            title,
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(
          height: rowH,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: tv ? 20 : 14),
            itemCount: channels.length,
            itemBuilder: (context, index) =>
                _buildChannelCard(context, allChannels, channels[index], settings, animMs),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(
    BuildContext context,
    List<Channel> allChannels,
    Channel channel,
    AppSettingsData settings,
    int animMs,
  ) {
    final tv = settings.tvFriendlyLayout;
    final w = tv ? 128.0 : 108.0;
    final logoSize = tv ? 30.0 : 26.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tv ? 10 : 8),
      child: Focus(
        child: Builder(
          builder: (ctx) {
            final focused = Focus.of(ctx).hasFocus;
            return AnimatedContainer(
              duration: Duration(milliseconds: animMs),
              width: w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: focused ? AppTheme.primaryGold : Colors.white.withOpacity(0.08),
                  width: focused ? 2.2 : 1,
                ),
                color: Colors.white.withOpacity(focused ? 0.08 : 0.04),
                boxShadow: focused
                    ? [BoxShadow(color: AppTheme.primaryGold.withOpacity(0.18), blurRadius: 14)]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.02)],
                              ),
                            ),
                            child: Center(
                              child: channel.logo != null
                                  ? Image.network(
                                      channel.logo!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.tv_rounded, color: Colors.white24, size: logoSize),
                                    )
                                  : Icon(Icons.tv_rounded, color: Colors.white24, size: logoSize),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(8, 8, 8, tv ? 12 : 10),
                          child: Text(
                            channel.name,
                            style: TextStyle(fontSize: tv ? 12 : 11, color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
