import 'package:flutter/material.dart';
import '../services/optic_player.dart';

/// Displays the native ExoPlayer video frames via Flutter's Texture widget.
///
/// Uses Flutter's Texture to ensure seamless inline-to-fullscreen transitions
/// and flawless rotation without the black screen glitches associated with AndroidView.
class NativePlayerView extends StatelessWidget {
  final OpticPlayer player;
  final BoxFit fit;
  
  const NativePlayerView({
    super.key, 
    required this.player,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: player.textureIdNotifier,
      builder: (context, id, _) {
        if (id < 0) return const SizedBox.shrink();
        
        return ValueListenableBuilder<Size>(
          valueListenable: player.videoSize,
          builder: (context, size, _) {
            Widget texture = Texture(textureId: id);

            if (size.width > 0 && size.height > 0) {
              texture = SizedBox.expand(
                child: FittedBox(
                  fit: fit,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: texture,
                  ),
                ),
              );
            }

            return texture;
          },
        );
      },
    );
  }
}
