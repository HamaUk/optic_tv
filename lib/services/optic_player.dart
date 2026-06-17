import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native ExoPlayer engine connected via MethodChannel.
///
/// Replaces the Flutter `video_player` plugin with a direct Kotlin bridge
/// to Media3 ExoPlayer — identical architecture to Ghosten Player.
///
/// Performance advantages over video_player plugin:
/// - forceEnableMediaCodecAsynchronousQueueing() → async hardware decode
/// - SurfaceView rendering → zero-copy frame pipeline
/// - Custom HttpDataSource → cross-protocol redirects, custom User-Agent
/// - HLS + RTSP + RTMP → all IPTV protocols natively supported
/// - SeekParameters tuned for live TV fast seeking
///
/// Public API is identical to the previous OpticPlayer so all UI files
/// (player_screen, fullscreen_player_page, movie_player_page) need zero changes.
class OpticPlayer {
  static const _channel = MethodChannel('com.kobani4k/native_player');

  // ─── ValueNotifiers (for ValueListenableBuilder in UI) ────────────────
  final ValueNotifier<bool> playing = ValueNotifier(false);
  final ValueNotifier<bool> buffering = ValueNotifier(true);

  // ─── Stream controllers (for StreamBuilder compatibility) ─────────────
  final _positionCtrl = StreamController<Duration>.broadcast();
  final _durationCtrl = StreamController<Duration>.broadcast();
  final _playingCtrl = StreamController<bool>.broadcast();
  final _bufferingCtrl = StreamController<bool>.broadcast();
  final _errorCtrl = StreamController<String?>.broadcast();
  final _volumeCtrl = StreamController<double>.broadcast();
  final _videoSizeCtrl = StreamController<Map<String, int>>.broadcast();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = true;
  double _volume = 1.0;
  double _speed = 1.0;
  bool _disposed = false;

  /// Convenience getters for synchronous access (matches old API)
  Duration get currentPosition => _position;
  Duration get totalDuration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;

  /// Stream-based access (mirrors the old media_kit Player.stream API so
  /// callers don't need to be rewritten).
  late final _OpticPlayerStreams stream = _OpticPlayerStreams(
    position: _positionCtrl.stream,
    duration: _durationCtrl.stream,
    playing: _playingCtrl.stream,
    buffering: _bufferingCtrl.stream,
    error: _errorCtrl.stream,
    volume: _volumeCtrl.stream,
  );

  /// No VideoPlayerController anymore — the native view is embedded via AndroidView.
  /// This getter returns null since we use PlatformView now.
  dynamic get controller => null;

  OpticPlayer() {
    // Listen for events FROM native Kotlin → Dart
    _channel.setMethodCallHandler(_handleNativeEvent);
  }

  // ─── Commands (Dart → Kotlin) ─────────────────────────────────────────

  /// Open a media URL. The native ExoPlayer prepares and auto-plays.
  Future<void> open(String url, {Map<String, String>? headers}) async {
    if (_disposed) return;
    buffering.value = true;
    _isBuffering = true;
    _bufferingCtrl.add(true);
    
    await _channel.invokeMethod('open', {
      'url': url,
      'headers': headers ?? {'User-Agent': 'SmartIPTV'},
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

  Future<void> stop() async {
    if (_disposed) return;
    await _channel.invokeMethod('stop');
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _channel.invokeMethod('dispose');
    _positionCtrl.close();
    _durationCtrl.close();
    _playingCtrl.close();
    _bufferingCtrl.close();
    _errorCtrl.close();
    _volumeCtrl.close();
    _videoSizeCtrl.close();
    playing.dispose();
    buffering.dispose();
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
        // Map with 'width' and 'height'
        break;

      case 'onBufferPositionChanged':
        // Buffer position — currently not used by UI
        break;

      case 'onCompleted':
        _isPlaying = false;
        playing.value = false;
        _playingCtrl.add(false);
        break;
    }
  }
}

/// Stream bundle — mirrors the old `Player.stream` API from media_kit
/// so existing StreamBuilder / listener code in the UI doesn't need changes.
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
