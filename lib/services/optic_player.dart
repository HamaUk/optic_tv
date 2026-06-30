import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
/// Native ExoPlayer engine connected via MethodChannel.
///
/// Uses Texture-based rendering: the native ExoPlayer renders frames into a
/// SurfaceTexture registered with Flutter's TextureRegistry. Flutter displays
/// them via `Texture(textureId: textureId)` — works on any page, any widget,
/// inline or fullscreen, without re-parenting issues.
///
/// All Ghosten-level optimizations are active:
/// - forceEnableMediaCodecAsynchronousQueueing() → async hardware decode
/// - Custom HttpDataSource → cross-protocol redirects, custom User-Agent
/// - HLS + RTSP + RTMP → all IPTV protocols natively supported
/// - SeekParameters tuned for live TV fast seeking
class OpticPlayer with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.kobani4k/native_player');

  // ─── Texture ID for rendering ─────────────────────────────────────────
  /// The Flutter texture ID. Use `Texture(textureId: player.textureId)` to display.
  int textureId = -1;
  final ValueNotifier<int> textureIdNotifier = ValueNotifier(-1);

  // ─── ValueNotifiers (for ValueListenableBuilder in UI) ────────────────
  final ValueNotifier<bool> playing = ValueNotifier(false);
  final ValueNotifier<bool> buffering = ValueNotifier(true);
  final ValueNotifier<Size> videoSize = ValueNotifier(Size.zero);

  // ─── Stream controllers (for StreamBuilder compatibility) ─────────────
  final _positionCtrl = StreamController<Duration>.broadcast();
  final _durationCtrl = StreamController<Duration>.broadcast();
  final _playingCtrl = StreamController<bool>.broadcast();
  final _bufferingCtrl = StreamController<bool>.broadcast();
  final _errorCtrl = StreamController<String?>.broadcast();
  final _volumeCtrl = StreamController<double>.broadcast();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = true;
  double _volume = 1.0;
  double _speed = 1.0;
  bool _disposed = false;
  bool _initialized = false;
  bool _wasPlayingBeforePause = false;

  /// Convenience getters for synchronous access
  Duration get currentPosition => _position;
  Duration get totalDuration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isInitialized => _initialized;

  /// Stream-based access (mirrors the old Player.stream API)
  late final _OpticPlayerStreams stream = _OpticPlayerStreams(
    position: _positionCtrl.stream,
    duration: _durationCtrl.stream,
    playing: _playingCtrl.stream,
    buffering: _bufferingCtrl.stream,
    error: _errorCtrl.stream,
    volume: _volumeCtrl.stream,
  );

  /// No VideoPlayerController — rendering is via Texture(textureId).
  dynamic get controller => null;

  OpticPlayer() {
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler(_handleNativeEvent);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPlayingBeforePause = _isPlaying;
      if (_isPlaying) {
        stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause && _lastUrl != null) {
        // Reinitialize texture and player to ensure clean state after resume
        _initialized = false;
        textureId = -1;
        textureIdNotifier.value = -1;
        _init().then((_) {
          if (_initialized && _lastUrl != null) {
            open(_lastUrl!, headers: _lastHeaders).then((_) {
              if (_wasPlayingBeforePause) {
                play();
              }
              _wasPlayingBeforePause = false;
            });
          }
        });
      }
    }
  }

  Future<void> _init() async {
    try {
      final id = await _channel.invokeMethod<int>('init');
      if (id != null && id >= 0) {
        textureId = id;
        textureIdNotifier.value = id;
        _initialized = true;
      }
    } catch (e) {
      debugPrint('OpticPlayer init error: $e');
    }
  }

  // ─── Commands (Dart → Kotlin) ─────────────────────────────────────────

  String? _lastUrl;
  Map<String, String>? _lastHeaders;
  String? _lastDrmScheme;
  String? _lastDrmLicense;

  Future<void> open(
    String url, {
    Map<String, String>? headers,
    String? drmScheme,
    String? drmLicense,
  }) async {
    if (_disposed) return;
    _lastUrl = url;
    _lastHeaders = headers;
    _lastDrmScheme = drmScheme;
    _lastDrmLicense = drmLicense;
    // Ensure init is complete before opening
    if (!_initialized) {
      await _init();
    }
    buffering.value = true;
    _isBuffering = true;
    _bufferingCtrl.add(true);
    
    await _channel.invokeMethod('open', {
      'url': url,
      'headers': headers ?? {'User-Agent': 'SmartIPTV'},
      'drmScheme': drmScheme,
      'drmLicense': drmLicense,
    });
  }

  Future<void> play() async {
    if (_disposed) return;
    await _channel.invokeMethod('play');
  }

  Future<void> pause() async {
    if (_disposed) return;
    await _channel.invokeMethod('pause');
  }

  Future<void> stop() async {
    if (_disposed) return;
    await _channel.invokeMethod('stop');
  }

  Future<void> playOrPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    if (_disposed) return;
    final ms = position.inMilliseconds.clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 999999999);
    await _channel.invokeMethod('seekTo', {'position': ms});
  }

  Future<List<Map<String, dynamic>>> getTracks() async {
    if (_disposed) return [];
    try {
      final List<dynamic>? tracks = await _channel.invokeMethod('getTracks');
      if (tracks == null) return [];
      return tracks.map((t) => Map<String, dynamic>.from(t as Map)).toList();
    } catch (e) {
      debugPrint('Error getting tracks: $e');
      return [];
    }
  }

  Future<void> setVolume(double percent) async {
    if (_disposed) return;
    final vol = (percent / 100.0).clamp(0.0, 1.0);
    _volume = vol;
    _volumeCtrl.add(percent);
    await _channel.invokeMethod('setVolume', {'volume': vol});
  }

  Future<void> setRate(double speed) async {
    if (_disposed) return;
    _speed = speed;
    await _channel.invokeMethod('setSpeed', {'speed': speed});
  }

  Future<void> setMaxResolution(int maxHeight) async {
    if (_disposed) return;
    await _channel.invokeMethod('setMaxResolution', {'maxHeight': maxHeight});
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    if (_disposed) return;
    // The native player in MainActivity is shared and should persist,
    // but we MUST stop playback before setting _disposed = true
    await stop();
    _disposed = true;
    _positionCtrl.close();
    _durationCtrl.close();
    _playingCtrl.close();
    _bufferingCtrl.close();
    _errorCtrl.close();
    _volumeCtrl.close();
    playing.dispose();
    buffering.dispose();
    textureIdNotifier.dispose();
  }

  // ─── Native Event Handler (Kotlin → Dart) ─────────────────────────────

  Future<dynamic> _handleNativeEvent(MethodCall call) async {
    if (_disposed) return;

    switch (call.method) {
      case 'onPositionChanged':
        final ms = (call.arguments as num).toInt();
        _position = Duration(milliseconds: ms);
        _positionCtrl.add(_position);
        break;

      case 'onDurationChanged':
        final ms = (call.arguments as num).toInt();
        _duration = Duration(milliseconds: ms);
        _durationCtrl.add(_duration);
        break;

      case 'onPlayingChanged':
        _isPlaying = call.arguments as bool;
        playing.value = _isPlaying;
        _playingCtrl.add(_isPlaying);
        break;

      case 'onBufferingChanged':
        _isBuffering = call.arguments as bool;
        buffering.value = _isBuffering;
        _bufferingCtrl.add(_isBuffering);
        break;

      case 'onError':
        final msg = call.arguments as String?;
        _errorCtrl.add(msg);
        break;

      case 'onVideoSizeChanged':
        final map = call.arguments as Map;
        final w = (map['width'] as num).toDouble();
        final h = (map['height'] as num).toDouble();
        if (w > 0 && h > 0) {
          videoSize.value = Size(w, h);
        }
        break;

      case 'onTextureChanged':
        final newTextureId = call.arguments as int?;
        if (newTextureId != null && newTextureId >= 0) {
          textureId = newTextureId;
          textureIdNotifier.value = newTextureId;
        }
        break;

      case 'onBufferPositionChanged':
        break;

      case 'onCompleted':
        _isPlaying = false;
        playing.value = false;
        _playingCtrl.add(false);
        break;
    }
  }
}

/// Stream bundle — mirrors the old `Player.stream` API
class _OpticPlayerStreams {
  final Stream<Duration> position;
  final Stream<Duration> duration;
  final Stream<bool> playing;
  final Stream<bool> buffering;
  final Stream<String?> error;
  final Stream<double> volume;

  _OpticPlayerStreams({
    required this.position,
    required this.duration,
    required this.playing,
    required this.buffering,
    required this.error,
    required this.volume,
  });
}
