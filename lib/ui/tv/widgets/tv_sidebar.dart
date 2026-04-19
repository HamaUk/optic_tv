import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/tv_fluid_focusable.dart';

enum TvNavDestination { live, movies, sports, search, settings }

class TvSidebar extends StatefulWidget {
  final TvNavDestination mode;
  final ValueChanged<TvNavDestination>? onDestinationSelected;
  final List<String> customCategories;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback? onMoveRight;
  final VoidCallback? onBackToSelector;

  const TvSidebar({
    super.key,
    required this.mode,
    required this.customCategories,
    required this.onCategorySelected,
    this.onDestinationSelected,
    this.selectedCategory,
    this.onMoveRight,
    this.onBackToSelector,
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

  String _getModeTitle() {
    switch (widget.mode) {
      case TvNavDestination.live: return "LIVE CHANNELS";
      case TvNavDestination.movies: return "MOVIES & VOD";
      case TvNavDestination.sports: return "SPORTS CENTER";
      case TvNavDestination.settings: return "SETTINGS";
      default: return "MENU";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _sideBarFocusScope,
      onFocusChange: (focused) {
        setState(() => _isExpanded = focused);
      },
      onKey: (node, event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
          widget.onMoveRight?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuart,
        width: _isExpanded ? 280 : 80,
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(color: AppTheme.primaryGold.withOpacity(0.05), blurRadius: 40, spreadRadius: 0)
          ],
          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            
            // Back to Selector Icon
            _buildBackAction(),
            
            const SizedBox(height: 20),
            
            if (_isExpanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  _getModeTitle(),
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryGold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Divider(color: Colors.white10, indent: 24, endIndent: 24),
            ],

            // Category List - Purely Categories as requested
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: widget.customCategories.length,
                itemBuilder: (context, index) {
                  final cat = widget.customCategories[index];
                  return _buildCategoryItem(cat);
                },
              ),
            ),
            
            const SizedBox(height: 20),
            // Minimal Search icon at bottom
            _buildActionItem(Icons.search_rounded, 'Search'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBackAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GhostenFocusable(
        onTap: () {
          if (widget.onBackToSelector != null) {
            widget.onBackToSelector!();
          } else {
             Navigator.pop(context);
          }
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(width: 22),
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 24),
              if (_isExpanded) ...[
                const SizedBox(width: 20),
                Text(
                  'EXIT MODE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12,
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: GhostenFocusable(
        onTap: () => widget.onCategorySelected(category),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGold.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppTheme.primaryGold.withOpacity(0.3) : Colors.transparent),
          ),
          child: Row(
            children: [
              const SizedBox(width: 22),
              Icon(
                widget.mode == TvNavDestination.movies ? Icons.movie_rounded : Icons.live_tv_rounded, 
                color: isSelected ? AppTheme.primaryGold : Colors.white24, 
                size: 20
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white30,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GhostenFocusable(
        onTap: () {},
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Row(
            children: [
              const SizedBox(width: 22),
              Icon(icon, color: Colors.white30, size: 24),
              if (_isExpanded) ...[
                const SizedBox(width: 20),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
