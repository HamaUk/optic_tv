import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/playlist_service.dart';
import '../../../widgets/tv/tv_focusable.dart';
import '../../../core/theme.dart';
import '../../../../providers/app_locale_provider.dart';
import '../../../../providers/ui_settings_provider.dart';

/// Navigation Destinations for the Main Sidebar
enum TvNavDestination { live, movies, search, settings, sports }

/// Ported Koya-style Sidebar with dual-layer (Icons & Categories) as per reference image.
/// This version is strictly isolated for TV use only.
class TVSidebar extends ConsumerStatefulWidget {
  final TvNavDestination selectedDestination;
  final ValueChanged<TvNavDestination> onDestinationSelected;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final Widget child;

  const TVSidebar({
    super.key,
    required this.selectedDestination,
    required this.onDestinationSelected,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.child,
  });

  @override
  ConsumerState<TVSidebar> createState() => _TVSidebarState();
}

class _TVSidebarState extends ConsumerState<TVSidebar> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();
    final accent = AppTheme.accentColor(settings.gradientPreset);
    final channelsAsync = ref.watch(channelsProvider);
    
    const navWidth = 64.0;
    const categoryWidth = 240.0;

    return FocusScope(
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Row(
          children: [
            // LAYER 1: NARROW ICON NAV (Far Left)
            Container(
              width: navWidth,
              color: Colors.black,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/optic_logo.png', width: 32, height: 32),
                  ),
                  const SizedBox(height: 40),
                  _buildNavIcon(0, Icons.live_tv, TvNavDestination.live),
                  _buildNavIcon(1, Icons.movie_filter, TvNavDestination.movies),
                  _buildNavIcon(2, Icons.search, TvNavDestination.search),
                  _buildNavIcon(3, Icons.settings, TvNavDestination.settings),
                ],
              ),
            ),

            // LAYER 2: WIDE CATEGORY LIST (Mid Left)
            Container(
              width: categoryWidth,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                border: const Border(right: BorderSide(color: Colors.white10, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    child: Text(
                      widget.selectedDestination.name.toUpperCase(),
                      style: TextStyle(color: accent, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: channelsAsync.when(
                      data: (channels) => _buildCategoryList(channels),
                      loading: () => Center(child: CircularProgressIndicator(color: accent)),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),

            // LAYER 3: THE CONTENT GRID
            Expanded(
              child: Container(
                color: Colors.black,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, TvNavDestination dest) {
    final isSelected = widget.selectedDestination == dest;
    return TVFocusable(
      onSelect: () => widget.onDestinationSelected(dest),
      showFocusBorder: false,
      builder: (context, isFocused, child) {
        return Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            border: isFocused ? Border(left: BorderSide(color: accent, width: 4)) : null,
            color: isFocused ? Colors.white10 : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: isFocused || isSelected ? accent : Colors.white24,
            size: 28,
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryList(List<Channel> channels) {
    final counts = <String, int>{};
    for (var c in channels) {
      if (widget.selectedDestination == TvNavDestination.movies && c.type != 'movie') continue;
      if (widget.selectedDestination == TvNavDestination.live && c.type != 'live') continue;
      counts[c.group] = (counts[c.group] ?? 0) + 1;
    }

    final sortedCategories = counts.keys.toList()..sort();
    final allCount = counts.values.fold(0, (sum, count) => sum + count);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        _buildCategoryItem('All Channels', allCount, isAll: true),
        const Divider(color: Colors.white10, height: 20),
        for (var cat in sortedCategories)
          _buildCategoryItem(cat, counts[cat]!),
      ],
    );
  }

  Widget _buildCategoryItem(String name, int count, {bool isAll = false}) {
    final isSelected = (isAll && widget.selectedCategory == null) || (widget.selectedCategory == name);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TVFocusable(
        onSelect: () => widget.onCategorySelected(isAll ? null : name),
        showFocusBorder: false,
        builder: (context, isFocused, child) {
          final active = isFocused || isSelected;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isFocused ? accent.withOpacity(0.1) : (isSelected ? Colors.white10 : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: isFocused ? Border.all(color: accent, width: 2) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white54,
                      fontWeight: active ? FontWeight.w900 : FontWeight.normal,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected && !isFocused)
                  Icon(Icons.arrow_forward_ios, color: accent, size: 10),
                const SizedBox(width: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: active ? accent : Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}
