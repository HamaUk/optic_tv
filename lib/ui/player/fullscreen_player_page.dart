import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/native_player_view.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:glassmorphism/glassmorphism.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import '../../services/optic_player.dart';

import '../../services/playlist_service.dart';
import '../../services/platform_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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
  final OpticPlayer player;
  final List<Channel> channels;
  final int initialIndex;
  final int activeServerIndex;
  final Locale uiLocale;
  final dynamic strings;
  final void Function(int serverIndex)? onServerChanged;
  final void Function(Channel oldChannel, Channel newChannel)? onChannelChanged;

  const FullscreenPlayerPage({
    super.key, 
    required this.player,
    required this.channels,
    required this.initialIndex,
    required this.activeServerIndex,
    required this.uiLocale,
    this.strings,
    this.onServerChanged,
    this.onChannelChanged,
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
  bool _streamFailed = false;
  int _retryCount = 0;

  // TV SPECIFIC STATE
  bool _zapListVisible = false;

  // MOBILE SPECIFIC STATE (Nano Banana)
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  String? _osdLabel;
  Timer? _osdTimer;
  double? _brightnessValue;
  late int _currentServerIndex;
  late final ScrollController _scrollController;
  bool _isPlaying = true;
  BoxFit _currentFit = BoxFit.fill;
  int _currentMaxHeight = 0; // 0 = Auto

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentServerIndex = widget.activeServerIndex;
    _currentChannel = widget.channels[_currentIndex];
    _scrollController = ScrollController();
    
    _subscriptions.add(widget.player.stream.position.listen((p) {
      if (mounted) setState(() {}); // Refresh for progress if needed
    }));

    _subscriptions.add(widget.player.stream.error.listen((err) {
      if (err != null) _handlePlayerError(err);
    }));

    // _clockTimer removed to prevent 1-second setState lag

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });

    _resetHideTimer();
    
    // Enable wakelock to prevent screen sleep
    WakelockPlus.enable();



    // Load video fit settings & scroll bottom carousel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToActiveChannel();
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _scrollController.dispose();
    if (widget.onChannelChanged == null) {
      try {
        widget.player.stop();
      } catch (e) {
        debugPrint('Error stopping player on dispose: $e');
      }
    }
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
    if (_streamFailed) return;
    if (_overlayVisible) {
      _hideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _overlayVisible = false);
      });
    }
  }

  void _scrollToActiveChannel() {
    if (!_scrollController.hasClients) return;
    const cardWidth = 116.0; // 100 card width + 16 horizontal margins
    final targetOffset = _currentIndex * cardWidth - (MediaQuery.of(context).size.width / 2) + (cardWidth / 2);
    final clampedOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handlePlayerError(dynamic err) {
    if (!mounted) return;

    List<String> validUrls = [_currentChannel.url];
    if (_currentChannel.url2 != null && _currentChannel.url2!.trim().isNotEmpty) validUrls.add(_currentChannel.url2!);
    if (_currentChannel.url3 != null && _currentChannel.url3!.trim().isNotEmpty) validUrls.add(_currentChannel.url3!);

    if (_currentServerIndex + 1 < validUrls.length) {
      _currentServerIndex++;
      _retryCount = 0;
      debugPrint('Stream error: $err. Failing over to Server ${_currentServerIndex + 1}');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _zapTo(_currentIndex, preserveServer: true);
      });
      return;
    }

    if (_retryCount < 2) {
      _retryCount++;
      debugPrint('Stream error, retrying ($_retryCount / 2): $err');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _zapTo(_currentIndex, preserveServer: true);
      });
    } else {
      setState(() {
        _streamFailed = true;
        _overlayVisible = true;
      });
    }
  }

  void _zapTo(int index, {bool preserveServer = false}) async {
    if (index < 0 || index >= widget.channels.length) return;
    
    setState(() {
      _streamFailed = false;
    });

    final oldChannel = _currentChannel;

    setState(() {
      _currentIndex = index;
      _currentChannel = widget.channels[_currentIndex];
      if (!preserveServer) {
        _currentServerIndex = 0;
      }
      widget.onServerChanged?.call(_currentServerIndex);
      _overlayVisible = true;
      _zapListVisible = false;
    });

    final newChannel = _currentChannel;

    if (oldChannel.url != newChannel.url) {
      if (widget.onChannelChanged != null) {
        widget.onChannelChanged!(oldChannel, newChannel);
      }
    }

    final validUrls = [_currentChannel.url, if (_currentChannel.url2 != null) _currentChannel.url2!, if (_currentChannel.url3 != null) _currentChannel.url3!];
    await widget.player.open(
      validUrls[widget.activeServerIndex],
      headers: {
        'User-Agent': _currentChannel.userAgent ?? 'SmartIPTV',
        'X-Optic-Security-Token': 'k4k-secure-stream-99X',
        if (_currentChannel.referer != null && _currentChannel.referer!.isNotEmpty) ...{
          'Referer': _currentChannel.referer!,
          'Origin': Uri.parse(_currentChannel.referer!).origin,
        },
      },
      drmScheme: _currentChannel.drmScheme,
      drmLicense: _currentChannel.drmLicense,
    );
    await widget.player.play();
    _resetHideTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToActiveChannel();
    });
  }

  void _showAspectDialog() {
    final options = [
      {'label': 'Default (Auto Fit)', 'fit': BoxFit.contain},
      {'label': 'Stretch to Screen', 'fit': BoxFit.fill},
      {'label': 'Zoom (Crop Edges)', 'fit': BoxFit.cover},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141A22),
        title: const Text('Select Screen Size', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final fit = opt['fit'] as BoxFit;
            final label = opt['label'] as String;
            final isCurrent = _currentFit == fit;
            return ListTile(
              title: Text(label, style: TextStyle(color: isCurrent ? Colors.redAccent : Colors.white70, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
              trailing: isCurrent ? const Icon(Icons.check, color: Colors.redAccent) : null,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentFit = fit);
                _osdLabel = "SIZE: ${label.toUpperCase()}";
                _resetOSDTimer();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showQualityDialog() async {
    final tracks = await widget.player.getTracks();
    
    final options = <Map<String, dynamic>>[
      {'label': 'Auto', 'height': 0},
    ];

    if (tracks.isNotEmpty) {
      tracks.sort((a, b) => (b['height'] as int).compareTo(a['height'] as int));
      final seen = <String>{};
      for (final t in tracks) {
        final h = t['height'] as int;
        final w = t['width'] as int;
        final b = t['bitrate'] as int;
        final c = t['codecs'] as String? ?? '';
        final key = '${w}x$h-$b';
        if (!seen.contains(key)) {
          seen.add(key);
          final mbps = (b / 1000000).toStringAsFixed(2);
          final codecStr = c.isNotEmpty ? ', $c' : '';
          options.add({'label': '$w × $h, $mbps Mbps$codecStr', 'height': h});
        }
      }
    } else {
      options.addAll([
        {'label': '4K (2160p)', 'height': 2160},
        {'label': 'Full HD (1080p)', 'height': 1080},
        {'label': 'HD (720p)', 'height': 720},
        {'label': 'SD (480p)', 'height': 480},
        {'label': 'Low (360p)', 'height': 360},
      ]);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141A22),
        title: const Text('Broadcast Quality', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map((opt) {
            final h = opt['height'] as int;
            final label = opt['label'] as String;
            final isCurrent = _currentMaxHeight == h;
            return ListTile(
              title: Text(label, style: TextStyle(color: isCurrent ? Colors.redAccent : Colors.white70, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
              trailing: isCurrent ? const Icon(Icons.radio_button_checked, color: Colors.redAccent) : const Icon(Icons.radio_button_unchecked, color: Colors.white24),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentMaxHeight = h);
                widget.player.setMaxResolution(h);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quality set to $label')));
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _switchServer(int serverIndex, String url) {
    if (_currentServerIndex == serverIndex) return;
    setState(() {
      _currentServerIndex = serverIndex;
      _overlayVisible = true;
    });
    widget.onServerChanged?.call(serverIndex);
    widget.player.open(
      url,
      headers: {
        'User-Agent': _currentChannel.userAgent ?? 'SmartIPTV',
        'X-Optic-Security-Token': 'k4k-secure-stream-99X',
        if (_currentChannel.referer != null && _currentChannel.referer!.isNotEmpty) ...{
          'Referer': _currentChannel.referer!,
          'Origin': Uri.parse(_currentChannel.referer!).origin,
        },
      },
      drmScheme: _currentChannel.drmScheme,
      drmLicense: _currentChannel.drmLicense,
    );
    _resetHideTimer();
  }

  // TV D-PAD HANDLER
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      if (_zapListVisible) return KeyEventResult.ignored;
      _zapTo(_currentIndex - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_zapListVisible) return KeyEventResult.ignored;
      _zapTo(_currentIndex + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      if (!_overlayVisible || _zapListVisible) {
        setState(() {
          _overlayVisible = true;
          _zapListVisible = false;
        });
        _resetHideTimer();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      if (!_overlayVisible && !_zapListVisible) {
        setState(() => _overlayVisible = true);
        _resetHideTimer();
        return KeyEventResult.handled;
      }
      if (!_zapListVisible) {
        setState(() => _zapListVisible = true);
      } else {
        setState(() => _zapListVisible = false);
        _resetHideTimer();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.backspace) {
      if (_zapListVisible) {
        setState(() => _zapListVisible = false);
        _resetHideTimer();
        return KeyEventResult.handled;
      }
      if (_overlayVisible) {
        setState(() => _overlayVisible = false);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? AppSettingsData();
    final accent = AppTheme.accentColor(settings.gradientPreset);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: false,
        child: GestureDetector(
          onTap: () {
            setState(() => _overlayVisible = !_overlayVisible);
            if (_overlayVisible) _resetHideTimer();
          },
          onVerticalDragUpdate: _handleVerticalDrag,
          child: Stack(
            children: [
              // THE VIDEO LAYER
              const Center(
                child: SizedBox.expand(),
              ),
              Center(
                child: NativePlayerView(player: widget.player, fit: _currentFit),
              ),
              
              if (_streamFailed)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 64),
                        const SizedBox(height: 16),
                        const Text('Stream Connection Lost', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Please check your internet or try another server.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            _retryCount = 0;
                            _zapTo(_currentIndex, preserveServer: true);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              
              // THE HUD LAYER
              IgnorePointer(
                ignoring: !_overlayVisible || _zapListVisible,
                child: AnimatedOpacity(
                  opacity: (_overlayVisible && !_zapListVisible) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildNanoOverlay(accent),
                ),
              ),

              // GESTURE OSD (Mobile Only)
              if (_osdLabel != null) Center(child: _buildOSDIndicator()),
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
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar (Back + Logo + Name + Viewers + FHD Quality Tag)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button & logo/name
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        if (_currentChannel.logo != null && _currentChannel.logo!.isNotEmpty) ...[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white10,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ChannelLogoImage(
                                logo: _currentChannel.logo,
                                channelName: _currentChannel.name,
                                width: 36,
                                height: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            _currentChannel.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8)                  // FHD Quality Tag,
                ],
              ),
            ),
            _buildHorizontalServerSelection(accent),

            // 2. Spacer
            const Spacer(),

            // 3. Center Controls Row (Prev, Mute, Settings, Play/Pause, Aspect, PiP, Next)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous Channel
                IconButton(
                  icon: const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    final prevIdx = (_currentIndex - 1 + widget.channels.length) % widget.channels.length;
                    _zapTo(prevIdx);
                  },
                ),
                const SizedBox(width: 20),
                // Volume/Mute Toggle
                StreamBuilder<double>(
                  stream: widget.player.stream.volume,
                  builder: (context, snapshot) {
                    final volume = snapshot.data ?? 100.0;
                    final isMuted = volume == 0.0;
                    return IconButton(
                      icon: Icon(
                        isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        widget.player.setVolume(isMuted ? 100.0 : 0.0);
                        _resetHideTimer();
                      },
                    );
                  },
                ),
                const SizedBox(width: 20),
                // Settings/Quality
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    _showQualityDialog();
                    _resetHideTimer();
                  },
                ),
                const SizedBox(width: 20),
                // Play/Pause
                StreamBuilder<bool>(
                  stream: widget.player.stream.playing,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? true;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            widget.player.pause();
                          } else {
                            widget.player.play();
                          }
                          _resetHideTimer();
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                // Aspect Ratio (Fit Toggle)
                IconButton(
                  icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    _showAspectDialog();
                    _resetHideTimer();
                  },
                ),
                const SizedBox(width: 20),
                // Picture-in-Picture Mode
                IconButton(
                  icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    SimplePip().enterPipMode();
                    _resetHideTimer();
                  },
                ),
                const SizedBox(width: 20),
                // Next Channel
                IconButton(
                  icon: const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    final nextIdx = (_currentIndex + 1) % widget.channels.length;
                    _zapTo(nextIdx);
                  },
                ),
              ],
            ),

            // 4. Spacer
            const Spacer(),

            // 5. Bottom Channel Carousel
            Container(
              height: 110,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                border: const Border(
                  top: BorderSide(color: Colors.white12, width: 0.5),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.channels.length,
                itemBuilder: (context, idx) => _buildChannelCarouselItem(idx, accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCarouselItem(int index, Color accent) {
    final channel = widget.channels[index];
    final isSelected = index == _currentIndex;

    return GestureDetector(
      onTap: () {
        _zapTo(index);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 90,
              height: 65,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? accent : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: ChannelLogoImage(
                    logo: channel.logo,
                    channelName: channel.name,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              channel.name.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalServerSelection(Color accent, {double padding = 76}) {
    final sLoc = AppStrings(ref.watch(appLocaleProvider));
    List<Map<String, dynamic>> servers = [
      {'index': 0, 'name': sLoc.serverName(1), 'url': _currentChannel.url},
    ];

    if (_currentChannel.url2 != null && _currentChannel.url2!.trim().isNotEmpty) {
      final n = (_currentChannel.url2Name != null && _currentChannel.url2Name!.trim().isNotEmpty) ? _currentChannel.url2Name! : sLoc.serverName(2);
      servers.add({'index': 1, 'name': n, 'url': _currentChannel.url2!});
    }
    if (_currentChannel.url3 != null && _currentChannel.url3!.trim().isNotEmpty) {
      final n = (_currentChannel.url3Name != null && _currentChannel.url3Name!.trim().isNotEmpty) ? _currentChannel.url3Name! : sLoc.serverName(3);
      servers.add({'index': 2, 'name': n, 'url': _currentChannel.url3!});
    }

    if (servers.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 36,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: servers.length,
        itemBuilder: (context, i) {
          final s = servers[i];
          final active = _currentServerIndex == s['index'];
          return InkWell(
            onTap: () => _switchServer(s['index'], s['url']),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? accent : Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? accent : Colors.white24),
              ),
              child: Text(
                s['name'].toUpperCase(),
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
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
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Text(_osdLabel!, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
    );
  }


}
