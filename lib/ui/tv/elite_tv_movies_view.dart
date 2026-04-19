import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../core/theme.dart';
import '../../services/playlist_service.dart';
import '../../widgets/tv/tv_channel_card.dart';
import '../player/fullscreen_player_page.dart';

/// Professional TV Movies Gallery ported from KoyaPlayer.
/// Isolated for TV use only.
class EliteTvMoviesView extends ConsumerWidget {
  const EliteTvMoviesView({super.key});

  void _playMovie(BuildContext context, WidgetRef ref, Channel movie, List<Channel> list) {
    final player = ref.read(playerProvider);
    player.open(Media(movie.url));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenPlayerPage(
          player: player,
          controller: ref.read(videoControllerProvider),
          channels: list,
          initialIndex: list.indexOf(movie),
          uiLocale: ref.read(appLocaleProvider),
          strings: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);
    return channelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      error: (e, __) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white24))),
      data: (channels) {
        final movies = channels.where((c) => c.type == 'movie' || c.group.toLowerCase().contains('movie')).toList();
        if (movies.isEmpty) {
          return const Center(child: Text('No Movies Found', style: TextStyle(color: Colors.white24, letterSpacing: 2)));
        }

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(40, 60, 40, 30),
                child: Text('CINEMA HALL', style: TextStyle(color: AppTheme.primaryGold, letterSpacing: 6, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movie = movies[index];
                    return TVChannelCard(
                      channel: movie,
                      onTap: () => _playMovie(context, ref, movie, movies),
                    );
                  },
                  childCount: movies.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
