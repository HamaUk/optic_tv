import 'package:flutter/material.dart';
import '../services/optic_player.dart';

/// Displays the native ExoPlayer video frames via Flutter's Texture widget.
///
/// The native ExoPlayer renders into a SurfaceTexture registered with Flutter's
/// TextureRegistry. This widget displays that texture via `Texture(textureId)`.
/// 
/// Because it's texture-based (not PlatformView), the same video frames
/// are displayed correctly on ANY page — inline player, fullscreen, PiP.
class NativePlayerView extends StatelessWidget {
  final OpticPlayer player;
  
  const NativePlayerView({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: player.textureIdNotifier,
      builder: (context, id, _) {
        if (id < 0) {
          return const ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
            ),
          );
        }
        return Texture(textureId: id);
      },
    );
  }
}
