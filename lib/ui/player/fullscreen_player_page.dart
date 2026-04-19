import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../services/playlist_service.dart';
import '../../services/settings_service.dart';
import '../../providers/ui_settings_provider.dart';
import '../../widgets/channel_logo_image.dart';

class FullscreenPlayerPage extends ConsumerStatefulWidget {
  final Player player;
  final VideoController controller;
  final List<Channel> channels;
  final int initialIndex;
  final Locale uiLocale;
  final AppStrings strings;

  const FullscreenPlayerPage({
    super.key,
    required this.player,
    required this.controller,
    required this.channels,
    required this.initialIndex,
    required this.uiLocale,
    required this.strings,
  });

  @override
  ConsumerState<FullscreenPlayerPage> createState() => _FullscreenPlayerPageState();
}

class _FullscreenPlayerPageState extends ConsumerState<FullscreenPlayerPage> {
  late int _index;
  late String _selectedGroup;
  bool _overlayVisible = false;
  Timer? _hideTimer;
  BoxFit _fit = BoxFit.contain;
  
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  final List<StreamSubscription> _subscriptions = [];
  
  double? _volumeValue;
  double? _brightnessValue;
  String? _osdLabel;
  Timer? _osdTimer;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _selectedGroup = widget.channels[_index].group;
    
    _position = widget.player.state.position;
    _duration = widget.player.state.duration;

    _subscriptions.add(widget.player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subscriptions.add(widget.player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    }));

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_overlayVisible) {
      _hideTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _overlayVisible = false);
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _clockTimer?.cancel();
    _osdTimer?.cancel();
    for (final s in _subscriptions) s.cancel();
    super.dispose();
  }

  void _onChannelSelected(int fullIdx) {
    setState(() => _index = fullIdx);
    widget.player.open(Media(widget.channels[_index].url));
    _resetHideTimer();
  }

  void _cycleAspectRatio() {
    setState(() {
      if (_fit == BoxFit.contain) {
        _fit = BoxFit.cover;
      } else if (_fit == BoxFit.cover) {
        _fit = BoxFit.fill;
      } else {
        _fit = BoxFit.contain;
      }
    });
    _resetHideTimer();
  }

  List<Channel> get _channelsInSelectedGroup {
    return widget.channels.where((c) {
       final isMovie = c.type == 'movie' || c.group.toLowerCase().contains('movie');
       return !isMovie && (_selectedGroup == 'ALL' || c.group == _selectedGroup);
    }).toList();
  }

  List<String> get _groupNames {
    final set = <String>{'ALL'};
    for (final c in widget.channels) {
      final isMovie = c.type == 'movie' || c.group.toLowerCase().contains('movie');
      if (!isMovie) set.add(c.group);
    }
    final list = set.toList()..sort();
    return list;
  }

  Channel get _current => widget.channels[_index];

  Future<bool> _exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _exitFullscreen,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragUpdate: _handleVerticalDrag,
          onVerticalDragEnd: (_) => _hideOSD(),
          onTap: () {
            setState(() => _overlayVisible = !_overlayVisible);
            if (_overlayVisible) _resetHideTimer();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Layer
              Video(
                controller: widget.controller,
                controls: NoVideoControls,
                fit: _fit,
              ),

              // 2. Nano Banana Overlay
              if (_overlayVisible) _buildNanoOverlay(),

              // 3. Gesture OSD
              if (_osdLabel != null) Center(child: _buildOSDIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNanoOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.6)],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // 1. Precise Header Info (Clock & Channel)
          Positioned(top: 40, right: 60, child: _buildAmbientClock()),
          Positioned(top: 40, left: 160, child: _buildCurrentInfo()),

          // 2. Pro Quick-Zap Area (Left Side)
          _buildProZapArea(),

          // 3. Minimalist Control Stack (Bottom Right)
          Positioned(
            right: 40,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 _buildHUDAction(
                   Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 24), 
                   'ASPECT', 
                   _cycleAspectRatio
                 ),
                 const SizedBox(height: 12),
                 _buildHUDAction(
                   Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 24), 
                   'EXIT', 
                   () async {
                     await _exitFullscreen();
                     if (mounted) Navigator.pop(context);
                   }
                 ),
              ],
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
        Text(_current.group.toUpperCase(), style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 3)),
        Text(_current.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildProZapArea() {
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
          borderGradient: LinearGradient(colors: [Colors.white10, Colors.white10]),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 60),
            itemCount: _groupNames.length,
            itemBuilder: (context, i) {
              final g = _groupNames[i];
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
                      fontSize: 11,
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
          borderGradient: LinearGradient(colors: [Colors.white10, Colors.white10]),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
            itemCount: _channelsInSelectedGroup.length,
            itemBuilder: (context, i) {
              final ch = _channelsInSelectedGroup[i];
              final active = ch.url == _current.url;
              return GestureDetector(
                onTap: () => _onChannelSelected(widget.channels.indexOf(ch)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? AppTheme.primaryGold.withOpacity(0.3) : Colors.transparent),
                    boxShadow: active ? [BoxShadow(color: AppTheme.primaryGold.withOpacity(0.05), blurRadius: 10)] : [],
                  ),
                  child: Row(
                    children: [
                      ChannelLogoImage(logo: ch.logo, height: 32, width: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          ch.name,
                          style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: active ? FontWeight.w900 : FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      if (active) Icon(Icons.graphic_eq_rounded, color: AppTheme.primaryGold, size: 16),
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
        borderGradient: LinearGradient(colors: [Colors.white10, Colors.white10]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
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

  void _hideOSD() {
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(milliseconds: 500), () => setState(() => _osdLabel = null));
  }

  Widget _buildOSDIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Text(_osdLabel!, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
    );
  }
}
