import 'dart:async';
import 'dart:math' as math;
import '../../services/viewer_service.dart';
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
import '../../providers/ui_settings_provider.dart';
import '../../services/settings_service.dart';

/// Professional Universal Player Page with isolated Platform HUDs.
/// - TV: Premium Koya HUD + D-pad Zapping + Quick Zap Sidebar.
/// - Phone: Restored "Nano Banana" Elite Mobile HUD + Glassmorphism + Gestures.
class FullscreenPlayerPage extends ConsumerStatefulWidget {
  final Player player;
  final VideoController controller;
  final List<Channel> channels;
  final int initialIndex;
  final int activeServerIndex;
  final Locale uiLocale;
  final dynamic strings; // Using dynamic for compatibility with original calls
  final void Function(int serverIndex)? onServerChanged;

  const FullscreenPlayerPage({
    super.key, 
    required this.player,
    required this.controller,
    required this.channels,
    required this.initialIndex,
    required this.activeServerIndex,
    required this.uiLocale,
    this.strings,
    this.onServerChanged,
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
  late int _currentServerIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentServerIndex = widget.activeServerIndex;
    _currentChannel = widget.channels[_currentIndex];
    
    _subscriptions.add(widget.player.stream.position.listen((p) {
      if (mounted) setState(() {}); // Refresh for progress if needed
    }));

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Force landscape for all devices in fullscreen mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _resetHideTimer();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(viewerServiceProvider).joinChannel(_currentChannel.url, channelName: _currentChannel.name);
      }
    });
  }

  @override
  void dispose() {
    ref.read(viewerServiceProvider).leaveChannel(_currentChannel.url);
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
    
    final oldUrl = _currentChannel.url;

    setState(() {
      _currentIndex = index;
      _currentChannel = widget.channels[_currentIndex];
      _currentServerIndex = 0;
      widget.onServerChanged?.call(0);
      _overlayVisible = true;
      _zapListVisible = false;
    });

    final newUrl = _currentChannel.url;
    if (oldUrl != newUrl) {
      ref.read(viewerServiceProvider).leaveChannel(oldUrl);
      ref.read(viewerServiceProvider).joinChannel(newUrl, channelName: _currentChannel.name);
    }

    widget.player.open(Media(
      _currentChannel.url,
      httpHeaders: {'User-Agent': _currentChannel.userAgent ?? 'SmartIPTV'},
    ));
    _resetHideTimer();
  }

  void _switchServer(int serverIndex, String url) {
    if (_currentServerIndex == serverIndex) return;
    setState(() {
      _currentServerIndex = serverIndex;
      _overlayVisible = true;
    });
    widget.onServerChanged?.call(serverIndex);
    widget.player.open(Media(
      url,
      httpHeaders: {'User-Agent': _currentChannel.userAgent ?? 'SmartIPTV'},
    ));
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
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? AppSettingsData();
    final accent = AppTheme.accentColor(settings.gradientPreset);
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
                  child: isTv ? _buildTvHud(accent) : _buildNanoOverlay(accent),
                ),

              // QUICK ZAP OVERLAY (TV Only)
              if (isTv && _zapListVisible) _buildQuickZap(accent),

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

  Widget _buildNanoOverlay(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.transparent, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _currentChannel.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.lock_outline_rounded, color: Colors.white), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white), 
                    onPressed: () {
                      final tracks = widget.player.state.tracks.video;
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF141A22),
                          title: const Text('Select Quality', style: TextStyle(color: Colors.white)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: tracks.isEmpty 
                                ? [const Text('No multiple qualities available for this stream.', style: TextStyle(color: Colors.white70))]
                                : tracks.map((track) {
                                    final isAuto = track.id == 'auto' || track.id == 'no';
                                    final title = isAuto ? 'Auto' : '${track.h ?? track.id}p';
                                    final isCurrent = widget.player.state.track.video == track;
                                    return ListTile(
                                      title: Text(title, style: TextStyle(color: isCurrent ? Colors.redAccent : Colors.white70, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                                      trailing: isCurrent ? const Icon(Icons.check, color: Colors.redAccent) : null,
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.player.setVideoTrack(track);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quality changed to $title')));
                                      },
                                    );
                            }).toList(),
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),
            
            // Horizontal Server List
            _buildHorizontalServerSelection(accent),
            
            // Center Play/Pause Control
            const Spacer(),
            Center(
              child: StreamBuilder<bool>(
                stream: widget.player.stream.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? true;
                  return GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        widget.player.pause();
                      } else {
                        widget.player.play();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            
            // Bottom Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Row(
                children: [
                  StreamBuilder<Duration>(
                    stream: widget.player.stream.position,
                    builder: (context, snap) {
                      final pos = snap.data ?? Duration.zero;
                      return Text(_formatDuration(pos), style: const TextStyle(color: Colors.white));
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StreamBuilder<Duration>(
                      stream: widget.player.stream.position,
                      builder: (context, posSnap) {
                        return StreamBuilder<Duration>(
                          stream: widget.player.stream.duration,
                          builder: (context, durSnap) {
                            final pos = posSnap.data ?? Duration.zero;
                            final dur = durSnap.data ?? Duration.zero;
                            double progress = 0;
                            if (dur.inMilliseconds > 0) {
                              progress = pos.inMilliseconds / dur.inMilliseconds;
                            }
                            return SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: accent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: accent,
                              ),
                              child: Slider(
                                value: progress.clamp(0.0, 1.0),
                                onChanged: (val) {
                                  if (dur.inMilliseconds > 0) {
                                    widget.player.seek(Duration(milliseconds: (val * dur.inMilliseconds).round()));
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  StreamBuilder<Duration>(
                    stream: widget.player.stream.duration,
                    builder: (context, snap) {
                      final dur = snap.data ?? Duration.zero;
                      return Text(_formatDuration(dur), style: const TextStyle(color: Colors.white));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalServerSelection(Color accent) {
    List<Map<String, dynamic>> servers = [
      {'index': 0, 'name': 'Server 1', 'url': _currentChannel.url},
    ];

    if (_currentChannel.url2 != null && _currentChannel.url2!.trim().isNotEmpty) {
      final n = (_currentChannel.url2Name != null && _currentChannel.url2Name!.trim().isNotEmpty) ? _currentChannel.url2Name! : 'Server 2';
      servers.add({'index': 1, 'name': n, 'url': _currentChannel.url2!});
    }
    if (_currentChannel.url3 != null && _currentChannel.url3!.trim().isNotEmpty) {
      final n = (_currentChannel.url3Name != null && _currentChannel.url3Name!.trim().isNotEmpty) ? _currentChannel.url3Name! : 'Server 3';
      servers.add({'index': 2, 'name': n, 'url': _currentChannel.url3!});
    }

    if (servers.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: servers.length,
        itemBuilder: (context, i) {
          final s = servers[i];
          final active = _currentServerIndex == s['index'];
          return GestureDetector(
            onTap: () => _switchServer(s['index'], s['url']),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? accent : Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? accent : Colors.white24),
              ),
              child: Text(
                s['name'].toUpperCase(),
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
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

  Widget _buildTvHud(Color accent) {
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
                  Text(_currentChannel.group.toUpperCase(), style: TextStyle(color: accent, letterSpacing: 2, fontSize: 12)),
                  Text(_currentChannel.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.unfold_more, color: accent, size: 20),
              SizedBox(width: 10),
              Text('ZAP: UP/DOWN', style: TextStyle(color: Colors.white54, fontSize: 14)),
              SizedBox(width: 40),
              Icon(Icons.list, color: accent, size: 20),
              SizedBox(width: 10),
              Text('CHANNELS: OK', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickZap(Color accent) {
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
            Padding(
              padding: EdgeInsets.fromLTRB(30, 50, 30, 20),
              child: Text('QUICK ZAP', style: TextStyle(color: accent, letterSpacing: 4, fontWeight: FontWeight.bold)),
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
                          color: isFocused ? accent.withOpacity(0.1) : Colors.transparent,
                          border: isCurrent ? Border(left: BorderSide(color: accent, width: 4)) : null,
                        ),
                        child: Row(
                          children: [
                            Text('${index + 1}', style: const TextStyle(color: Colors.white24, fontSize: 12)),
                            const SizedBox(width: 15),
                            Expanded(child: Text(ch.name, style: TextStyle(color: isFocused ? Colors.white : Colors.white70))),
                            if (isCurrent) Icon(Icons.play_arrow, color: accent, size: 16),
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
