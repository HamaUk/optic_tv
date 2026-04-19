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
import 'tv_settings_page.dart';

class TvDashboardScreen extends ConsumerStatefulWidget {
  final TvNavDestination initialMode;
  const TvDashboardScreen({super.key, required this.initialMode});

  @override
  ConsumerState<TvDashboardScreen> createState() => _TvDashboardScreenState();
}

class _TvDashboardScreenState extends ConsumerState<TvDashboardScreen> {
  late TvNavDestination _selectedMode;
  String? _activeCategory;
  final FocusNode _sidebarFocusNode = FocusNode();
  final FocusNode _gridFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  @override
  void dispose() {
    _sidebarFocusNode.dispose();
    _gridFocusNode.dispose();
    super.dispose();
  }

  // Pure filtering based on Mode + Category
  List<Channel> _getFilteredChannels(List<Channel> all) {
    List<Channel> modeFiltered = [];
    
    switch (_selectedMode) {
      case TvNavDestination.settings:
        return [];
      case TvNavDestination.movies:
        modeFiltered = all.where((c) => c.type == 'movie').toList();
        break;
      case TvNavDestination.sports:
        modeFiltered = all.where((c) => c.group.toLowerCase().contains('sport')).toList();
        break;
      case TvNavDestination.live:
      default:
        modeFiltered = all.where((c) => c.type == 'live').toList();
        break;
    }

    if (_activeCategory != null) {
      return modeFiltered.where((c) => c.group == _activeCategory).toList();
    }
    
    return modeFiltered;
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
          final filteredChannels = _getFilteredChannels(channels);
          // Categories should only be from the currently filtered MODE
          final modeAllChannels = channels.where((c) {
            if (_selectedMode == TvNavDestination.movies) return c.type == 'movie';
            if (_selectedMode == TvNavDestination.sports) return c.group.toLowerCase().contains('sport');
            return c.type == 'live';
          }).toList();
          
          final categories = modeAllChannels.map((c) => c.group).toSet().toList()..sort();
          
          return Row(
            children: [
              // 1. Morphing Sidebar
              TvSidebar(
                mode: _selectedMode,
                onMoveRight: () => _gridFocusNode.requestFocus(),
                customCategories: categories,
                selectedCategory: _activeCategory,
                onBackToSelector: () => Navigator.pop(context),
                onCategorySelected: (cat) {
                  setState(() {
                    _activeCategory = cat;
                  });
                },
              ),

              // 2. Main Content Area (Stable Grid)
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
                      child: TvChannelGrid(
                        key: ValueKey('grid_$_selectedMode$_activeCategory'), // Stable key for focus persistence
                        channels: filteredChannels, 
                        categoryName: _activeCategory ?? 'All Channels',
                        isPosterStyle: _selectedMode == TvNavDestination.movies || _selectedMode == TvNavDestination.sports,
                        focusNode: _gridFocusNode,
                      ),
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
}
