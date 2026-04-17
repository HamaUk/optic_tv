import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../services/playlist_service.dart';

class FullscreenPlayerPage extends StatefulWidget {
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
  State<FullscreenPlayerPage> createState() => _FullscreenPlayerPageState();
}

class _FullscreenPlayerPageState extends State<FullscreenPlayerPage> {
  late int _index;
  late String _selectedGroup;
  bool _overlayVisible = true;
  Timer? _hideTimer;
  
  // Movie HUD State
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  final List<StreamSubscription> _subscriptions = [];

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

    // Set orientations
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
      _hideTimer = Timer(const Duration(seconds: 12), () {
        if (mounted) setState(() => _overlayVisible = false);
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  bool get _isMovie {
    final g = widget.channels[_index].group.toLowerCase();
    return g.contains('movie') || g.contains('film') || g.contains('cinema');
  }

  void _onChannelSelected(int fullIdx) {
    setState(() {
      _index = fullIdx;
      _selectedGroup = widget.channels[_index].group;
    });
    widget.player.open(Media(widget.channels[_index].url));
    _resetHideTimer();
  }

  Channel get _current => widget.channels[_index];

  List<String> get _groupNames {
    final set = <String>{};
    for (final c in widget.channels) {
      set.add(c.group);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Channel> get _channelsInSelectedGroup {
    return widget.channels.where((c) => c.group == _selectedGroup).toList();
  }

  Future<bool> _exitFullscreen() async {
    // Restore orientations before popping
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _exitFullscreen,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() => _overlayVisible = !_overlayVisible);
            _resetHideTimer();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Layer
              Video(
                controller: widget.controller,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),

              // 2. Precision Guide Overlay
              AnimatedOpacity(
                opacity: _overlayVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_overlayVisible,
                  child: _buildOverlayContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent() {
    if (_isMovie) {
      return _buildMovieHUD();
    }

    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Stack(
        children: [
          // 1. Categories (Far Left)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 180,
            child: _buildCategoryPane(),
          ),

          // 2. Channels (Center-Left)
          Positioned(
            left: 180,
            top: 0,
            bottom: 0,
            right: MediaQuery.sizeOf(context).width * 0.25,
            child: _buildChannelPane(),
          ),

          // 3. Exit Button (Bottom Right)
          Positioned(
            right: 32,
            bottom: 32,
            child: Material(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () async {
                  await _exitFullscreen();
                  if (mounted) Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPane() {
    final groups = _groupNames;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 60),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final g = groups[i];
          final selected = g == _selectedGroup;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedGroup = g;
              _resetHideTimer();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                color: selected ? Colors.red.withOpacity(0.85) : Colors.transparent,
              ),
              child: Text(
                g.toUpperCase(),
                style: AppTheme.withRabarIfKurdish(
                  widget.uiLocale,
                  TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelPane() {
    final channels = _channelsInSelectedGroup;
    return Container(
      color: Colors.transparent,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 0),
        itemCount: channels.length,
        itemBuilder: (context, i) {
          final ch = channels[i];
          final active = ch.url == _current.url;
          final fullIdx = widget.channels.indexOf(ch);
          return Material(
            key: ValueKey('fs_page_${ch.url}_$fullIdx'),
            color: active ? Colors.red.withOpacity(0.25) : Colors.transparent,
            child: InkWell(
              onTap: () => _onChannelSelected(fullIdx),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  border: active ? const Border(left: BorderSide(color: Colors.red, width: 6)) : null,
                ),
                child: Row(
                  children: [
                    Text(
                      '${fullIdx + 1}',
                      style: TextStyle(
                        color: active ? Colors.redAccent.shade100 : Colors.white38,
                        fontSize: 16,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        ch.name.toUpperCase(),
                        style: AppTheme.withRabarIfKurdish(
                          widget.uiLocale,
                          TextStyle(
                            color: active ? Colors.redAccent : Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    if (active) _buildEqualizerIcon(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEqualizerIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _eqBar(12),
        const SizedBox(width: 2),
        _eqBar(18),
        const SizedBox(width: 2),
        _eqBar(14),
        const SizedBox(width: 2),
        _eqBar(22),
      ],
    );
  }

  Widget _eqBar(double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Movie HUD ──

  Widget _buildMovieHUD() {
    return Stack(
      children: [
        // 1. Top Bar: Title & Badge
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _current.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildBadge('4K ULTRA HD', Colors.red),
                          const SizedBox(width: 12),
                          _buildBadge('ATMOS', Colors.white30),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildHUDAction(Icons.settings_outlined, () {}),
              ],
            ),
          ),
        ),

        // 2. Play/Pause Big Icon (Center)
        Center(
          child: AnimatedOpacity(
            opacity: _overlayVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _buildHUDAction(
              widget.player.state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              () => widget.player.playOrPause(),
              isLarge: true,
            ),
          ),
        ),

        // 3. Bottom HUD
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(50, 20, 50, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seek Bar
                _buildSeekBar(),
                const SizedBox(height: 16),
                // Control Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildHUDAction(Icons.replay_10_rounded, () => widget.player.seek(_position - const Duration(seconds: 10))),
                        const SizedBox(width: 20),
                        _buildHUDAction(Icons.forward_10_rounded, () => widget.player.seek(_position + const Duration(seconds: 10))),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHUDAction(Icons.closed_caption_rounded, () {}),
                        const SizedBox(width: 24),
                        _buildSpeedButton(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeekBar() {
    final pos = _position.inSeconds.toDouble();
    final dur = _duration.inSeconds.toDouble().clamp(1.0, double.infinity);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.red,
          ),
          child: Slider(
            value: pos.clamp(0.0, dur),
            max: dur,
            onChanged: (v) {
              widget.player.seek(Duration(seconds: v.toInt()));
              _resetHideTimer();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white30, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHUDAction(IconData icon, VoidCallback onTap, {bool isLarge = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: isLarge ? 56 : 28),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSpeedButton() {
    return InkWell(
      onTap: () {
        setState(() {
          if (_playbackSpeed >= 3.0) {
            _playbackSpeed = 1.0;
          } else {
            _playbackSpeed += 0.5;
          }
        });
        widget.player.setRate(_playbackSpeed);
        _resetHideTimer();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${_playbackSpeed.toStringAsFixed(1)}x',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hh = d.inHours;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hh > 0) return '$hh:$mm:$ss';
    return '$mm:$ss';
  }
}
