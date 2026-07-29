import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminMoviesTabExt on _AdminScreenState {
  Widget _buildMoviesTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withValues(alpha: 0.35)],
        ),
      ),
      child: StreamBuilder<DatabaseEvent>(
        stream: _groupsRef.onValue,
        builder: (context, groupsSnapshot) {
          final groupsRaw = groupsSnapshot.data?.snapshot.value;
          final groupOrders = <String, int>{};
          if (groupsRaw is Map) {
            for (final entry in groupsRaw.entries) {
              final val = entry.value;
              if (val is Map) {
                final name = '${val['name'] ?? entry.key}';
                final order = val['order'] as int? ?? 999999;
                groupOrders[name.toLowerCase()] = order;
              }
            }
          }

          return StreamBuilder<DatabaseEvent>(
            stream: _playlistRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
              }
              final raw = snapshot.data?.snapshot.value;
              var items = _parsePlaylist(raw);
              _sortChannelEntries(items);

          final groups = <String>{};
          for (final e in items) {
            final v = e.value;
            if (v is Map) {
              final grp = '${v['group'] ?? v['category'] ?? ''}'.toLowerCase();
              final isMovie = grp.contains('movie') || grp.contains('film') || grp.contains('cinema') || grp == 'vod' || v['type'] == 'movie';
              if (isMovie) {
                groups.add('${v['group'] ?? v['category'] ?? 'Movies'}');
              }
            }
          }
          final sortedGroups = groups.toList()..sort((a, b) {
            final oa = groupOrders[a.toLowerCase()] ?? 999999;
            final ob = groupOrders[b.toLowerCase()] ?? 999999;
            if (oa != ob) return oa.compareTo(ob);
            return a.toLowerCase().compareTo(b.toLowerCase());
          });

          items = items.where((e) {
            final v = e.value;
            if (v is! Map) return false;
            final grp = '${v['group'] ?? v['category'] ?? ''}'.toLowerCase();
            final isMovie = grp.contains('movie') || grp.contains('film') || grp.contains('cinema') || grp == 'vod' || v['type'] == 'movie';
            if (!isMovie) return false;

            final name = '${v['name'] ?? ''}'.toLowerCase();
            final url = '${v['url'] ?? ''}'.toLowerCase();
            final actualGrp = '${v['group'] ?? v['category'] ?? 'Movies'}';
            
            if (_movieGroupFilter != null && actualGrp != _movieGroupFilter) return false;
            if (_movieSearchQuery.isEmpty) return true;
            return name.contains(_movieSearchQuery) ||
                url.contains(_movieSearchQuery) ||
                actualGrp.toLowerCase().contains(_movieSearchQuery);
          }).toList();

          final header = Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showAddMovieDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Movie'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _importMoviesBusy ? null : _importMoviesBulk,
                        icon: const Icon(Icons.file_upload_rounded),
                        label: const Text('Bulk Import'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.accentTeal,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _movieSearchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search name, URL, group...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                          prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
                          suffixIcon: _movieSearchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _movieSearchController.clear();
                                    setAdminState(() => _movieSearchQuery = '');
                                  },
                                ),
                          filled: true,
                          fillColor: AppTheme.surfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ),

                    if (_selectedKeys.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _deleteBatch,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                        label: Text('Delete (${_selectedKeys.length})'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('All movies'),
                                selected: _movieGroupFilter == null,
                                onSelected: (_) => setAdminState(() {
                                  _movieGroupFilter = null;
                                  _selectedKeys.clear();
                                }),
                                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                              ),
                            ),
                            for (final g in sortedGroups)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(g),
                                  selected: _movieGroupFilter == g,
                                  onSelected: (val) => setAdminState(() {
                                    _movieGroupFilter = val ? g : null;
                                    _selectedKeys.clear();
                                  }),
                                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ActionChip(
                                label: const Text('Manage Groups'),
                                avatar: const Icon(Icons.sort_rounded, size: 16),
                                onPressed: () => _tabController.animateTo(5), // 5 is ACCESS tab
                                backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.1),
                                side: BorderSide(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          final allFiltered = items.map((e) => '${e.key}').toSet();
                          setAdminState(() {
                            if (_selectedKeys.containsAll(allFiltered)) {
                              _selectedKeys.removeAll(allFiltered);
                            } else {
                              _selectedKeys.addAll(allFiltered);
                            }
                          });
                        },
                        icon: Icon(
                          _selectedKeys.containsAll(items.map((e) => '${e.key}'))
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                        label: Text('Select All', style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor)),
                      ),
                    ],
                  ],
                ),
                if (_movieGroupFilter != null && _movieSearchQuery.isEmpty && items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.drag_indicator_rounded, color: AppTheme.accentTeal, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Manual sorting active',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Drag these movies to move them. The new order will sync to all users.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );

          if (items.isEmpty) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text(
                          'No movies match',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (_movieGroupFilter != null && _movieSearchQuery.isEmpty) {
            return Column(
              children: [
                header,
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) => _moveChannel(items, oldIndex, newIndex),
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(20),
                        color: AppTheme.surfaceElevated,
                        shadowColor: AppTheme.accentTeal.withValues(alpha: 0.25),
                        child: child,
                      );
                    },
                    itemBuilder: (context, i) {
                      return Padding(
                        key: ValueKey(items[i].key),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _adminChannelListTile(items[i], position: i + 1),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              header,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _adminChannelListTile(items[i], position: i + 1),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  ),
);
  }

  void _showAddMovieDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final logoCtrl = TextEditingController();
    final groupCtrl = TextEditingController(text: 'Movies');

    showDialog<void>(
      context: context,
      builder: (ctx) => _adminEnglishLtr(
        AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: const Text('Add New Movie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Movie Title',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Stream URL',
                    hintText: '.m3u8, .ts, .mp4...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: logoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Logo / Poster URL (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: groupCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Group / Category',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final url = urlCtrl.text.trim();
                final logo = logoCtrl.text.trim();
                final group = groupCtrl.text.trim();

                if (name.isEmpty || url.isEmpty) {
                  _snack('Title and URL are required', error: true);
                  return;
                }

                try {
                  final payload = _channelPayload(
                    name: name,
                    url: url,
                    group: group.isEmpty ? 'Movies' : group,
                    logo: logo,
                    type: 'movie',
                  );
                  await _playlistRef.push().set(payload);
                  if (mounted) Navigator.pop(ctx);
                  _snack('Movie added successfully');
                } catch (e) {
                  _snack('Failed to add movie: $e', error: true);
                }
              },
              child: const Text('Add Movie'),
            ),
          ],
        ),
      ),
    );
  }
}
