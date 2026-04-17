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

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _selectedGroup = widget.channels[_index].group;
    
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
    super.dispose();
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
}
