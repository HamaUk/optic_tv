// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// OpticPlayer
///
/// A thin wrapper around the Flutter `video_player` plugin (ExoPlayer on
/// Android) that replaces our former media_kit/mpv dependency.
///
/// Why ExoPlayer vs mpv?
///   • ExoPlayer is the native Android codec pipeline — zero start latency.
///   • Built-in adaptive HLS/RTSP/RTMP demuxing tuned for live streams.
///   • Hardware decoding goes through MediaCodec directly, no bridging.
///   • ~30 MB smaller APK (no bundled libmpv .so files).
/// ─────────────────────────────────────────────────────────────────────────
class OpticPlayer {
  VideoPlayerController? _controller;

  // ── Public state streams / notifiers ──────────────────────────────────
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> playing = ValueNotifier(false);
  final ValueNotifier<bool> buffering = ValueNotifier(false);
  final ValueNotifier<double> volume = ValueNotifier(1.0);
  final ValueNotifier<String?> error = ValueNotifier(null);

  // Convenience streams (mirrors media_kit API so callers need no rework)
  late final _OpticPlayerStream stream = _OpticPlayerStream(this);

  VideoPlayerController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  // ── Internal ───────────────────────────────────────────────────────────
  Timer? _positionTicker;
  VoidCallback? _listener;

  // ── Open ───────────────────────────────────────────────────────────────

  /// Open a new URL, optionally with HTTP headers.
  /// This disposes any existing controller before creating a new one.
  Future<void> open(String url, {Map<String, String> headers = const {}}) async {
    error.value = null;
    buffering.value = true;
    playing.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;

    // Tear down old controller
    await _disposeController();

    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: headers,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    _controller = ctrl;

    try {
      await ctrl.initialize();
      if (_controller != ctrl) return; // was replaced while initializing
      duration.value = ctrl.value.duration;
      buffering.value = false;
      _attachListener(ctrl);
      _startPositionTicker();
      await ctrl.play();
      playing.value = true;
    } catch (e) {
      if (_controller == ctrl) {
        error.value = e.toString();
        buffering.value = false;
      }
    }
  }

  // ── Playback controls ──────────────────────────────────────────────────

  Future<void> play() async {
    await _controller?.play();
    playing.value = true;
  }

  Future<void> pause() async {
    await _controller?.pause();
    playing.value = false;
  }

  Future<void> playOrPause() async {
    if (playing.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    await _controller?.pause();
    await _controller?.seekTo(Duration.zero);
    playing.value = false;
  }

  Future<void> seek(Duration position) async {
    await _controller?.seekTo(position);
    this.position.value = position;
  }

  Future<void> setVolume(double vol) async {
    // video_player uses 0.0–1.0; we keep API compat with old 0–100 range
    final clamped = vol > 1.0 ? vol / 100.0 : vol.clamp(0.0, 1.0);
    await _controller?.setVolume(clamped);
    volume.value = clamped;
  }

  Future<void> setRate(double rate) async {
    await _controller?.setPlaybackSpeed(rate);
  }

  // ── State accessors ────────────────────────────────────────────────────

  bool get isPlaying => _controller?.value.isPlaying ?? false;
  Duration get currentPosition => _controller?.value.position ?? Duration.zero;
  Duration get totalDuration => _controller?.value.duration ?? Duration.zero;
  Size get size => _controller?.value.size ?? Size.zero;
  int get width => size.width.toInt();
  int get height => size.height.toInt();

  // ── Internal helpers ───────────────────────────────────────────────────

  void _attachListener(VideoPlayerController ctrl) {
    _listener?.call(); // remove old listener ref (no-op here, but safe)
    void listener() {
      if (!ctrl.value.isInitialized) return;
      playing.value = ctrl.value.isPlaying;
      buffering.value = ctrl.value.isBuffering;
      if (ctrl.value.hasError) {
        error.value = ctrl.value.errorDescription;
      }
    }
    _listener = listener;
    ctrl.addListener(listener);
  }

  void _startPositionTicker() {
    _positionTicker?.cancel();
    _positionTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final ctrl = _controller;
      if (ctrl == null || !ctrl.value.isInitialized) return;
      position.value = ctrl.value.position;
      duration.value = ctrl.value.duration;
      buffering.value = ctrl.value.isBuffering;
      playing.value = ctrl.value.isPlaying;
    });
  }

  Future<void> _disposeController() async {
    _positionTicker?.cancel();
    _positionTicker = null;
    final old = _controller;
    _controller = null;
    if (old != null) {
      try {
        await old.dispose();
      } catch (_) {}
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _disposeController();
    position.dispose();
    duration.dispose();
    playing.dispose();
    buffering.dispose();
    volume.dispose();
    error.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Provides `.stream.position`, `.stream.playing`, etc. so existing listeners
/// don't need to be rewritten (mirrors media_kit's Player.stream API).
// ─────────────────────────────────────────────────────────────────────────────
class _OpticPlayerStream {
  _OpticPlayerStream(OpticPlayer player) : _player = player;
  final OpticPlayer _player;

  Stream<Duration> get position => _valueNotifierToStream(_player.position);
  Stream<Duration> get duration => _valueNotifierToStream(_player.duration);
  Stream<bool> get playing => _valueNotifierToStream(_player.playing);
  Stream<bool> get buffering => _valueNotifierToStream(_player.buffering);
  Stream<double> get volume => _valueNotifierToStream(_player.volume);
  Stream<String?> get error => _valueNotifierToStream(_player.error);

  Stream<T> _valueNotifierToStream<T>(ValueNotifier<T> notifier) {
    late StreamController<T> controller;
    void listener() => controller.add(notifier.value);
    controller = StreamController<T>.broadcast(
      onListen: () => notifier.addListener(listener),
      onCancel: () => notifier.removeListener(listener),
    );
    return controller.stream;
  }
}
