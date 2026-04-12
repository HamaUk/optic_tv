import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme.dart';
import '../../providers/channel_library_provider.dart';
import '../../services/playlist_service.dart';
import '../player/player_screen.dart';

class TVChannelManagerScreen extends ConsumerStatefulWidget {
  final List<Channel> allChannels;
  final bool isMovies;
  const TVChannelManagerScreen({
    super.key, 
    required this.allChannels,
    this.isMovies = false,
  });

  @override
  ConsumerState<TVChannelManagerScreen> createState() => _TVChannelManagerScreenState();
}

class _TVChannelManagerScreenState extends ConsumerState<TVChannelManagerScreen> {
  late List<String> _categories;
  String? _selectedCategory;
  List<Channel> _filteredChannels = [];
  Channel? _previewChannel;

  // Media Kit elements
  late final Player _player;
  late final VideoController _controller;
  bool _playerInitialized = false;

  final FocusNode _categoryScrollNode = FocusNode();
  final FocusNode _channelScrollNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _categories = widget.allChannels.map((e) => e.group).toSet().toList()..sort();
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
      _updateFilteredChannels();
    }
  }

  @override
  void dispose() {
    _categoryScrollNode.dispose();
    _channelScrollNode.dispose();
    super.dispose();
  }

  void _updateFilteredChannels() {
    setState(() {
      _filteredChannels = widget.allChannels.where((c) => c.group == _selectedCategory).toList();
      if (_filteredChannels.isNotEmpty) {
        _previewChannel = _filteredChannels.first;
      }
    });
  }

  void _onCategoryFocused(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredChannels = widget.allChannels.where((c) => c.group == _selectedCategory).toList();
    });
  }

  void _onChannelFocused(Channel channel) {
    if (_previewChannel == channel) return;
    setState(() {
      _previewChannel = channel;
    });
  }

  void _openFullscreen() {
    if (_previewChannel == null) return;
    
    // Find absolute index in widget.allChannels
    final index = widget.allChannels.indexOf(_previewChannel!);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          channels: widget.allChannels,
          initialIndex: index >= 0 ? index : 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Column 1: Categories
          Container(
            width: 300,
            color: const Color(0xFF0A0E14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 20),
                  child: Text(
                    widget.isMovies ? 'GENRES' : 'CATEGORIES',
                    style: const TextStyle(
                      color: AppTheme.primaryGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat;
                      return _TVListTile(
                        label: cat,
                        isSelected: isSelected,
                        onFocused: () => _onCategoryFocused(cat),
                        onTap: () {}, // Handled by focus
                        icon: Icons.folder_rounded,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Column 2: Channels
          // Column 2: Channels (Expanded)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF101419),
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 40, 30, 20),
                    child: Text(
                      widget.isMovies ? 'MOVIES' : 'CHANNELS',
                      style: const TextStyle(
                        color: AppTheme.primaryGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 40),
                      itemCount: _filteredChannels.length,
                      itemBuilder: (context, i) {
                        final ch = _filteredChannels[i];
                        final isPreview = _previewChannel == ch;
                        return _TVListTile(
                          label: ch.name,
                          isSelected: isPreview,
                          onFocused: () => _onChannelFocused(ch),
                          onTap: _openFullscreen,
                          icon: Icons.play_arrow_rounded,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TVListTile extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onFocused;
  final VoidCallback onTap;
  final IconData icon;

  const _TVListTile({
    required this.label,
    required this.isSelected,
    required this.onFocused,
    required this.onTap,
    required this.icon,
  });

  @override
  State<_TVListTile> createState() => _TVListTileState();
}

class _TVListTileState extends State<_TVListTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) widget.onFocused();
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.enter || 
             event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _isFocused ? AppTheme.primaryGold : (widget.isSelected ? AppTheme.primaryGold.withOpacity(0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: _isFocused ? Colors.black : (widget.isSelected ? AppTheme.primaryGold : Colors.white54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: _isFocused ? Colors.black : (widget.isSelected ? Colors.white : Colors.white70),
                  fontSize: 16,
                  fontWeight: widget.isSelected || _isFocused ? FontWeight.w900 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white24, size: 20),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
