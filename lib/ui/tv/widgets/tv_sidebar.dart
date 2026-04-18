import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/tv_fluid_focusable.dart';

enum TvNavDestination { home, live, movies, sports, favorites, search, settings }

class TvSidebar extends StatefulWidget {
  final TvNavDestination selected;
  final ValueChanged<TvNavDestination> onDestinationSelected;
  final List<String> customCategories;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const TvSidebar({
    super.key,
    required this.selected,
    required this.onDestinationSelected,
    required this.customCategories,
    required this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  State<TvSidebar> createState() => _TvSidebarState();
}

class _TvSidebarState extends State<TvSidebar> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final FocusScopeNode _sideBarFocusScope = FocusScopeNode();

  @override
  void dispose() {
    _sideBarFocusScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _sideBarFocusScope,
      onFocusChange: (focused) {
        setState(() => _isExpanded = focused);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuart,
        width: _isExpanded ? 240 : 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildNavItem(TvNavDestination.home, Icons.home_rounded, 'Home'),
            _buildNavItem(TvNavDestination.live, Icons.live_tv_rounded, 'Live TV'),
            _buildNavItem(TvNavDestination.movies, Icons.movie_filter_rounded, 'Movies'),
            _buildNavItem(TvNavDestination.sports, Icons.sports_soccer_rounded, 'Sports'),
            _buildNavItem(TvNavDestination.favorites, Icons.star_rounded, 'Favorites'),
            _buildNavItem(TvNavDestination.search, Icons.search_rounded, 'Search'),
            const Spacer(),
            
            // Dynamic Categories Section
            if (_isExpanded && widget.customCategories.isNotEmpty) ...[
              const Divider(color: Colors.white10, indent: 20, endIndent: 20),
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: widget.customCategories.length,
                  itemBuilder: (context, index) {
                    final cat = widget.customCategories[index];
                    return _buildCategoryItem(cat);
                  },
                ),
              ),
            ],
            
            _buildNavItem(TvNavDestination.settings, Icons.settings_rounded, 'Settings'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(TvNavDestination dest, IconData icon, String label) {
    final isSelected = widget.selected == dest;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: GhostenFocusable(
        onTap: () => widget.onDestinationSelected(dest),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGold.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Icon(icon, color: isSelected ? AppTheme.primaryGold : Colors.white54, size: 28),
              if (_isExpanded) ...[
                const SizedBox(width: 20),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category) {
    final isSelected = widget.selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: GhostenFocusable(
        onTap: () => widget.onCategorySelected(category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(
              color: isSelected ? AppTheme.primaryGold : Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
