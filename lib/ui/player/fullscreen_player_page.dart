import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:glassmorphism/glassmorphism.dart';

import '../../services/playlist_service.dart';
import '../../services/platform_service.dart';
import '../../widgets/tv/tv_focusable.dart';
import '../../widgets/channel_logo_image.dart';
import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_locale_provider.dart';

/// Professional Universal Player Page with isolated Platform HUDs.
/// - TV: Premium Koya HUD + D-pad Zapping + Quick Zap Sidebar.
/// - Phone: Restored "Nano Banana" Elite Mobile HUD + Glassmorphism + Gestures.
class FullscreenPlayerPage extends ConsumerStatefulWidget {
  final Player player;
  final VideoController controller;
  final List<Channel> channels;
  final int initialIndex;
  final Locale uiLocale;
  final dynamic strings; // Using dynamic for compatibility with original calls

  const FullscreenPlayerPage({
    super.key, 
    required this.player,
    required this.controller,
    required this.channels,
    required this.initialIndex,
    required this.uiLocale,
    this.strings,
  });

  @override
  ConsumerState<FullscreenPlayerPage> createState() => _FullscreenPlayerPageState();
}

class _FullscreenPlayerPageState extends ConsumerState<FullscreenPlayerPage> {
  // COMMON STATE
  late int _currentIndex;
  late Channel _currentChannel;
  bool _overlayVisible = false;
  Timer? _hideTimer;
  final List<StreamSubscription> _subscriptions = [];

  // TV SPECIFIC STATE
  bool _zapListVisible = false;

  // MOBILE SPECIFIC STATE (Nano Banana)
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  String? _osdLabel;
  Timer? _osdTimer;
  double? _brightnessValue;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentChannel = widget.channels[_currentIndex];
    _selectedGroup = _currentChannel.group;
    
    _subscriptions.add(widget.player.stream.position.listen((p) {
      if (mounted) setState(() {}); // Refresh for progress if needed
    }));

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _resetHideTimer();
  }

  @override
  void dispose() {
    for (var s in _subscriptions) {
      s.cancel();
    }
    _hideTimer?.cancel();
    _clockTimer?.cancel();
    _osdTimer?.cancel();
    super.dispose();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_zapListVisible) return;
    if (_overlayVisible) {
      _hideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _overlayVisible = false);
      });
    }
  }

  void _zapTo(int index) {
    if (index < 0 || index >= widget.channels.length) return;
    
    setState(() {
      _currentIndex = index;
      _currentChannel = widget.channels[_currentIndex];
      _selectedGroup = _currentChannel.group;
      _overlayVisible = true;
      _zapListVisible = false;
    });

    widget.player.open(Media(_currentChannel.url));
    _resetHideTimer();
  }

  // TV D-PAD HANDLER
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      _zapTo(_currentIndex - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _zapTo(_currentIndex + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      setState(() {
        _zapListVisible = !_zapListVisible;
        _overlayVisible = true;
      });
      if (!_zapListVisible) _resetHideTimer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      if (_zapListVisible) {
        setState(() => _zapListVisible = false);
        _resetHideTimer();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = ref.watch(deviceTypeProvider).value ?? DeviceType.phone;
    final isTv = deviceType == DeviceType.tv;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: isTv,
        onKeyEvent: isTv ? _handleKeyEvent : null,
        child: GestureDetector(
          onTap: () {
            setState(() => _overlayVisible = !_overlayVisible);
            if (_overlayVisible) _resetHideTimer();
          },
          onVerticalDragUpdate: !isTv ? _handleVerticalDrag : null,
          child: Stack(
            children: [
              // THE VIDEO LAYER
              Center(
                child: Video(
                  controller: widget.controller,
                  fill: Colors.black,
                  controls: NoVideoControls, 
                ),
              ),
              
              // THE HUD LAYER
              if (_overlayVisible && !_zapListVisible)
                AnimatedOpacity(
                  opacity: _overlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: isTv ? _buildTvHud() : _buildNanoOverlay(),
                ),

              // QUICK ZAP OVERLAY (TV Only)
              if (isTv && _zapListVisible) _buildQuickZap(),

              // GESTURE OSD (Mobile Only)
              if (!isTv && _osdLabel != null) Center(child: _buildOSDIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // RESTORED NANO BANANA MOBILE HUD
  // ==========================================

  Widget _buildNanoOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black54, Colors.transparent, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: 40, right: 40, child: _buildAmbientClock()),
          Positioned(top: 40, left: 160, child: _buildCurrentInfo()),

          _buildProZapArea(),

          Positioned(
            right: 40,
            bottom: 40,
            child: _buildHUDAction(
              const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 24), 
              'EXIT', 
              () => Navigator.pop(context)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_currentChannel.group.toUpperCase(), style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 3)),
        Text(_currentChannel.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildProZapArea() {
    final groups = widget.channels.map((e) => e.group).toSet().toList()..sort();
    final channelsInGroup = widget.channels.where((c) => c.group == _selectedGroup).toList();

    return Row(
      children: [
        // Categories
        GlassmorphicContainer(
          width: 120,
          height: double.infinity,
          borderRadius: 0,
          blur: 25,
          alignment: Alignment.center,
          border: 0,
          linearGradient: LinearGradient(colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.6)]),
          borderGradient: const LinearGradient(colors: [Colors.white10, Colors.white10]),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 60),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final g = groups[i];
              final selected = g == _selectedGroup;
              return GestureDetector(
                onTap: () => setState(() => _selectedGroup = g),
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  color: selected ? AppTheme.primaryGold.withOpacity(0.15) : Colors.transparent,
                  child: Text(
                    g.toUpperCase(),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white38,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Channels
        GlassmorphicContainer(
          width: 320,
          height: double.infinity,
          borderRadius: 0,
          blur: 15,
          alignment: Alignment.center,
          border: 0,
          linearGradient: LinearGradient(colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.2)]),
          borderGradient: const LinearGradient(colors: [Colors.white10, Colors.white10]),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
            itemCount: channelsInGroup.length,
            itemBuilder: (context, i) {
              final ch = channelsInGroup[i];
              final active = ch.url == _currentChannel.url;
              return GestureDetector(
                onTap: () => _zapTo(widget.channels.indexOf(ch)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? AppTheme.primaryGold.withOpacity(0.3) : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      ChannelLogoImage(logo: ch.logo, height: 32, width: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          ch.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      if (active) const Icon(Icons.graphic_eq_rounded, color: AppTheme.primaryGold, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHUDAction(Widget icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: 130,
        height: 52,
        borderRadius: 16,
        blur: 10,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.4)]),
        borderGradient: const LinearGradient(colors: [Colors.white10, Colors.white10]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientClock() {
    final timeStr = DateFormat('HH:mm').format(_now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1)),
        Text(DateFormat('yyyy/MM/dd').format(_now), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ],
    );
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    _brightnessValue = ((_brightnessValue ?? 0.5) - details.delta.dy / 300).clamp(0.0, 1.0);
    _osdLabel = "BRIGHTNESS";
    setState(() {});
    _resetOSDTimer();
  }

  void _resetOSDTimer() {
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 1), () => setState(() => _osdLabel = null));
  }

  Widget _buildOSDIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Text(_osdLabel!, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
    );
  }

  // ==========================================
  // PREMIUM KOYA TV HUD
  // ==========================================

  Widget _buildTvHud() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _currentChannel.logo != null 
                    ? ChannelLogoImage(logo: _currentChannel.logo, width: 60, height: 60)
                    : const Icon(Icons.tv, color: Colors.white24),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentChannel.group.toUpperCase(), style: const TextStyle(color: AppTheme.primaryGold, letterSpacing: 2, fontSize: 12)),
                  Text(_currentChannel.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Row(
            children: [
              Icon(Icons.unfold_more, color: AppTheme.primaryGold, size: 20),
              SizedBox(width: 10),
              Text('ZAP: UP/DOWN', style: TextStyle(color: Colors.white54, fontSize: 14)),
              SizedBox(width: 40),
              Icon(Icons.list, color: AppTheme.primaryGold, size: 20),
              SizedBox(width: 10),
              Text('CHANNELS: OK', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickZap() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 400,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: const Border(right: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(30, 50, 30, 20),
              child: Text('QUICK ZAP', style: TextStyle(color: AppTheme.primaryGold, letterSpacing: 4, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: widget.channels.length,
                itemBuilder: (context, index) {
                  final ch = widget.channels[index];
                  final isCurrent = index == _currentIndex;
                  return TVFocusable(
                    autofocus: isCurrent,
                    onSelect: () => _zapTo(index),
                    showFocusBorder: true,
                    builder: (context, isFocused, child) {
                      return Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isFocused ? AppTheme.primaryGold.withOpacity(0.1) : Colors.transparent,
                          border: isCurrent ? const Border(left: BorderSide(color: AppTheme.primaryGold, width: 4)) : null,
                        ),
                        child: Row(
                          children: [
                            Text('${index + 1}', style: const TextStyle(color: Colors.white24, fontSize: 12)),
                            const SizedBox(width: 15),
                            Expanded(child: Text(ch.name, style: TextStyle(color: isFocused ? Colors.white : Colors.white70))),
                            if (isCurrent) const Icon(Icons.play_arrow, color: AppTheme.primaryGold, size: 16),
                          ],
                        ),
                      );
                    },
                    child: const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
