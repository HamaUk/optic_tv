import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../core/theme.dart';
import '../../services/playlist_service.dart';
import '../../widgets/tv/tv_channel_card.dart';
import '../player/fullscreen_player_page.dart';
import 'widgets/tv_sidebar.dart';
import 'elite_tv_movies_view.dart';
import 'elite_tv_settings_view.dart';

/// The high-performance TV Dashboard using the Grid structure from your reference image.
/// Isolated for TV use only—never called by the Phone app.
class EliteTvDashboard extends ConsumerStatefulWidget {
  const EliteTvDashboard({super.key});

  @override
  ConsumerState<EliteTvDashboard> createState() => _EliteTvDashboardState();
}

class _EliteTvDashboardState extends ConsumerState<EliteTvDashboard> {
  TvNavDestination _selectedDest = TvNavDestination.live;
  String? _selectedCategory;

  void _playChannel(Channel channel, List<Channel> contextChannels) {
    final player = ref.read(playerProvider);
    player.open(Media(channel.url));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenPlayerPage(
          player: player,
          controller: ref.read(videoControllerProvider), // Using existing provider
          channels: contextChannels,
          initialIndex: contextChannels.indexOf(channel),
          uiLocale: ref.read(appLocaleProvider),
          strings: null, // Will be handled by the player's internal strings
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: TVSidebar(
        selectedDestination: _selectedDest,
        onDestinationSelected: (dest) => setState(() {
          _selectedDest = dest;
          _selectedCategory = null; 
        }),
        selectedCategory: _selectedCategory,
        onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
        child: channelsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
          data: (channels) {
            switch (_selectedDest) {
              case TvNavDestination.movies:
                return const EliteTvMoviesView();
              case TvNavDestination.settings:
                return const EliteTvSettingsView();
              case TvNavDestination.search:
                return const Center(child: Text('Search Coming Soon', style: TextStyle(color: Colors.white54)));
              case TvNavDestination.live:
              default:
                return _buildChannelGrid(channels);
            }
          },
        ),
      ),
    );
  }

  Widget _buildChannelGrid(List<Channel> channels) {
    final filtered = channels.where((c) {
      if (_selectedDest == TvNavDestination.live && c.type != 'live') return false;
      if (_selectedCategory != null && c.group != _selectedCategory) return false;
      return true;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory ?? 'ALL CHANNELS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${filtered.length} channels',
                  style: const TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final channel = filtered[index];
                return TVChannelCard(
                  key: ValueKey('${_selectedCategory}_${channel.url}'),
                  autofocus: index == 0,
                  channel: channel,
                  onTap: () => _playChannel(channel, filtered),
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
      ],
    );
  }
}
