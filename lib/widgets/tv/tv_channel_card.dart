import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/playlist_service.dart';
import '../channel_logo_image.dart';
import 'tv_focusable.dart';

/// Professional TV Channel Card ported from KoyaPlayer.
/// Dense layout optimized for 6-column leanback grids.
class TVChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final bool autofocus;

  const TVChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      autofocus: autofocus,
      onSelect: onTap,
      borderRadius: BorderRadius.circular(12),
      builder: (context, isFocused, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isFocused ? Colors.transparent : Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Area
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: ChannelLogoImage(
                      logo: channel.logo,
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
              ),
              // Info Area
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        channel.group.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
