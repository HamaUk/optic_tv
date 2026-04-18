import 'package:flutter/material.dart';
import '../../../../services/playlist_service.dart';
import '../../../../widgets/tv_fluid_focusable.dart';
import '../../../../widgets/channel_logo_image.dart';
import '../tv_player_page.dart';

class TvChannelGrid extends StatelessWidget {
  final List<Channel> channels;
  final String categoryName;
  final bool isPosterStyle;
  final FocusNode? focusNode;

  const TvChannelGrid({
    super.key,
    required this.channels,
    required this.categoryName,
    this.isPosterStyle = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            categoryName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isPosterStyle ? 6 : 5,
              childAspectRatio: isPosterStyle ? 0.65 : 1.1,
              crossAxisSpacing: 24,
              mainAxisSpacing: 32,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final ch = channels[index];
              return Focus(
                focusNode: index == 0 ? focusNode : null, // The "Bridge" for the first item
                child: GhostenFocusable(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TvPlayerPage(
                          channels: channels,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Logo/Poster Container
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ChannelLogoImage(
                              logo: isPosterStyle ? ch.backdrop ?? ch.logo : ch.logo,
                              height: double.infinity,
                              width: double.infinity,
                              fit: isPosterStyle ? BoxFit.cover : BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      
                      // 2. Clear Label Underneath
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ch.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
