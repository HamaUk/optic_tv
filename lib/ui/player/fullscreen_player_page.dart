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
  bool _overlayVisible = false; // Starts hidden as requested
  Timer? _hideTimer;
  
  // Movie HUD & Clock State
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  final List<StreamSubscription> _subscriptions = [];
  
  // Gesture OSD State
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
    _clockTimer?.cancel();
    _osdTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  bool get _isMovie => false; // Logic moved to MoviePlayerPage

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
          onVerticalDragUpdate: _handleVerticalDrag,
          onVerticalDragEnd: (_) => _hideOSD(),
          onHorizontalDragUpdate: _handleHorizontalDrag,
          onHorizontalDragEnd: (_) => _hideOSD(),
          onTap: () {
            setState(() {
              _overlayVisible = !_overlayVisible;
            });
            if (_overlayVisible) {
              _resetHideTimer();
            }
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

              // 2. Ambient Clock
              // Only visible when UI is visible to keep entry clean
              if (_overlayVisible)
                Positioned(
                  top: 30,
                  right: 40,
                  child: _buildAmbientClock(),
                ),

              // 3. Gesture OSD Indicators
              if (_osdLabel != null)
                Center(child: _buildOSDIndicator()),

              // 4. UI Layer (HUD / Guide)
              if (_overlayVisible)
                _buildOverlayContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent() {
    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Stack(
        children: [
          // Left Side Category Selection (Compact rioplayer style)
          _buildCategorySidebar(),
          
          // Row for Channel List (Smaller)
          Positioned(
            left: 100, // Matches compact Sidebar width
            top: 0,
            bottom: 0,
            child: _buildChannelList(),
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

  Widget _buildCategorySidebar() {
    final groups = _groupNames;
    return Container(
      width: 100, // Professional rioplayer width
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
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
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? Colors.red.withOpacity(0.85) : Colors.transparent,
              ),
              child: Text(
                g.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTheme.withRabarIfKurdish(
                  widget.uiLocale,
                  TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _buildChannelList() {
    final channels = _channelsInSelectedGroup;
    return Container(
      width: 240, // More compact as requested
      color: Colors.black.withOpacity(0.6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 0),
        itemCount: channels.length,
        separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
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

  Widget _buildAmbientClock() {
    final timeStr = DateFormat('HH:mm').format(_now);
    final dateStr = DateFormat('yyyy/MM/dd').format(_now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            shadows: [Shadow(color: Colors.black, blurRadius: 15)],
          ),
        ),
        Text(
          dateStr.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: [Shadow(color: Colors.black, blurRadius: 10)],
          ),
        ),
      ],
    );
  }

  // ── Gesture OSD ──

  Widget _buildOSDIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _osdLabel!,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (_volumeValue != null || _brightnessValue != null)
            Container(
              width: 150,
              height: 4,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              clipBehavior: Clip.antiAlias,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_volumeValue ?? _brightnessValue ?? 0.0).clamp(0.0, 1.0),
                child: Container(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.localPosition.dx < screenWidth / 2;
    
    if (isLeftSide) {
      // BRIGHTNESS (simulate or use plugin if available)
      _brightnessValue = ((_brightnessValue ?? 0.5) - details.delta.dy / 300).clamp(0.0, 1.0);
      _osdLabel = "BRIGHTNESS";
    } else {
      // VOLUME
      _volumeValue = ((_volumeValue ?? 0.5) - details.delta.dy / 300).clamp(0.0, 1.0);
      // media_kit setVolume takes a double from 0.0 to 100.0
      widget.player.setVolume((_volumeValue! * 100.0));
      _osdLabel = "VOLUME";
    }
    setState(() {});
    _resetOSDTimer();
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    if (!_isMovie) return;
    
    final offset = details.delta.dx * 10; // 10s per pixel-ish
    final target = _position + Duration(seconds: offset.toInt());
    _osdLabel = offset > 0 ? "+ ${offset.toInt()}s" : "${offset.toInt()}s";
    
    widget.player.seek(target);
    setState(() {});
    _resetOSDTimer();
  }

  void _resetOSDTimer() {
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _osdLabel = null);
    });
  }

  void _hideOSD() {
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _osdLabel = null);
    });
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

  // Movie HUD logic removed (Moved to MoviePlayerPage)

  void _showSubtitleSelector() {
    final tracks = widget.player.state.tracks.subtitle;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SUBTITLES & TRACKS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            if (tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No tracks found", style: TextStyle(color: Colors.white38)),
              ),
            ...tracks.map((t) => ListTile(
                  leading: Icon(Icons.subtitles_rounded, color: t == widget.player.state.track.subtitle ? Colors.red : Colors.white70),
                  title: Text(t.title ?? t.language ?? "Track ${t.id}", style: const TextStyle(color: Colors.white)),
                  trailing: t == widget.player.state.track.subtitle ? const Icon(Icons.check_circle_rounded, color: Colors.red) : null,
                  onTap: () {
                    widget.player.setSubtitleTrack(t);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.subtitles_off_rounded, color: Colors.white38),
              title: const Text("None (Off)", style: TextStyle(color: Colors.white38)),
              onTap: () {
                widget.player.setSubtitleTrack(SubtitleTrack.no());
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PLAYBACK SETTINGS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            const Text("ASPECT RATIO", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _aspectButton("FIT", BoxFit.contain),
                _aspectButton("FILL", BoxFit.cover),
                _aspectButton("STRETCH", BoxFit.fill),
              ],
            ),
            const SizedBox(height: 32),
            const Text("STREAM INFO", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow("Resolution", "${widget.player.state.width} x ${widget.player.state.height}"),
            _infoRow("Hardware", "Auto-Safe (HEVC/AVC)"),
          ],
        ),
      ),
    );
  }

  Widget _aspectButton(String label, BoxFit fit) {
    return InkWell(
      onTap: () {
        // We'll manage aspect ratio via a state variable if needed, but for now we simulate
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Switched to $label mode")));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
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
