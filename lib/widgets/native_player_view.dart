import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embeds the native ExoPlayer PlayerView via AndroidView.
/// 
/// This widget renders zero-copy SurfaceView frames from the Kotlin ExoPlayer
/// engine — no TextureView intermediate copies. The native view is identified
/// by the same viewType registered in MainActivity:
///   "com.kobani4k/native_player_view"
class NativePlayerView extends StatelessWidget {
  const NativePlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Native player only available on Android',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return AndroidView(
      viewType: 'com.kobani4k/native_player_view',
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (_) {
        // View is ready — ExoPlayer is already attached by the factory
      },
    );
  }
}
