import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../providers/channel_library_provider.dart';
import '../../../services/playlist_service.dart';
import '../../../widgets/tv_fluid_focusable.dart';
import 'widgets/tv_sidebar.dart';
import 'widgets/tv_channel_grid.dart';
import 'tv_player_page.dart';
import '../../../widgets/channel_logo_image.dart';

class TvDashboardScreen extends ConsumerStatefulWidget {
  const TvDashboardScreen({super.key});

  @override
  ConsumerState<TvDashboardScreen> createState() => _TvDashboardScreenState();
}

class _TvDashboardScreenState extends ConsumerState<TvDashboardScreen> {
  TvNavDestination _selectedDest = TvNavDestination.live;
  String? _activeCategory;
  final ScrollController _homeScrollController = ScrollController();
  final FocusNode _sidebarFocusNode = FocusNode();
  final FocusNode _gridFocusNode = FocusNode();

  @override
  void dispose() {
    _homeScrollController.dispose();
    _sidebarFocusNode.dispose();
    _gridFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (channels) {
          final categories = channels.map((c) => c.group).toSet().toList()..sort();
          
          return Row(
            children: [
              // 1. Pro Sidebar
              TvSidebar(
                selected: _selectedDest,
                onMoveRight: () => _gridFocusNode.requestFocus(),
                onDestinationSelected: (dest) {
                  setState(() {
                    _selectedDest = dest;
                    _activeCategory = null;
                  });
                },
                customCategories: categories,
                selectedCategory: _activeCategory,
                onCategorySelected: (cat) {
                  setState(() {
                    _activeCategory = cat;
                    _selectedDest = TvNavDestination.live; // Use live as the 'grid' mode base
                  });
                },
              ),

              // 2. Main Content Area
              Expanded(
                child: Stack(
                  children: [
                    // Ambient Background
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black,
                              AppTheme.primaryGold.withOpacity(0.02),
                              Colors.black,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content Switching
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: _buildContent(channels),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(List<Channel> allChannels) {
    // If a specific category is selected, show the Grid
    if (_activeCategory != null) {
      final filtered = allChannels.where((c) => c.group == _activeCategory).toList();
      return TvChannelGrid(channels: filtered, categoryName: _activeCategory!);
    }

    // Otherwise, show standard destinations
    switch (_selectedDest) {
      case TvNavDestination.live:
        return TvChannelGrid(
          channels: allChannels, 
          categoryName: 'All Channels',
          focusNode: _gridFocusNode,
        );
      case TvNavDestination.movies:
        return TvChannelGrid(
          channels: allChannels.where((c) => c.group.toLowerCase().contains('movie')).toList(),
          categoryName: 'Movies',
          isPosterStyle: true,
          focusNode: _gridFocusNode,
        );
      case TvNavDestination.sports:
        return TvChannelGrid(
          channels: allChannels.where((c) => c.group.toLowerCase().contains('sport')).toList(),
          categoryName: 'Sports',
          focusNode: _gridFocusNode,
        );
      default:
        return TvChannelGrid(
          channels: allChannels, 
          categoryName: 'General',
          focusNode: _gridFocusNode,
        );
    }
  }

  Widget _buildHomeView(List<Channel> channels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        Text(
          'OPTIC TV ELITE',
          style: GoogleFonts.outfit(
            color: AppTheme.primaryGold,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 60),
        Expanded(
          child: ListView(
            controller: _homeScrollController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTvRow('CONTINUE WATCHING', channels.take(5).toList()),
              const SizedBox(height: 60),
              _buildTvRow('TRENDING NOW', channels.skip(5).take(10).toList()),
              const SizedBox(height: 60),
              _buildTvRow('BASED ON YOUR INTEREST', channels.reversed.take(10).toList()),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTvRow(String title, List<Channel> rowChannels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rowChannels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 24),
            itemBuilder: (context, index) {
              final ch = rowChannels[index];
              return GhostenFocusable(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TvPlayerPage(
                        channels: rowChannels,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Center(
                          child: Opacity(
                            opacity: 0.6,
                            child: ChannelLogoImage(logo: ch.logo, height: 100, width: 100),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Text(
                              ch.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
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
