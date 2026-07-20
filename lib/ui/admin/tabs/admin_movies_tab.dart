import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminMoviesTabExt on _AdminScreenState {
  Widget _buildMoviesTab() {
    return StreamBuilder<DatabaseEvent>(
      stream: _playlistRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
        }
        final raw = snapshot.data?.snapshot.value;
        var items = _parsePlaylist(raw);

        // Filter for Movies
        items = items.where((e) {
          final v = e.value;
          if (v is! Map) return false;
          final grp = '${v['group'] ?? v['category'] ?? ''}'.toLowerCase();
          final isMovie = grp.contains('movie') || grp.contains('film') || grp.contains('cinema') || grp == 'vod';
          if (!isMovie) return false;

          final name = '${v['name'] ?? ''}'.toLowerCase();
          if (_channelSearchQuery.isEmpty) return true;
          return name.contains(_channelSearchQuery);
        }).toList();

        _sortChannelEntries(items);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _showAddMovieDialog,
                      icon: const Icon(Icons.movie_rounded),
                      label: const Text('Add New'),
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
                      icon: const Icon(Icons.auto_awesome_rounded),
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
            ),
            if (_selectedKeys.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FilledButton.icon(
                  onPressed: _bulkDeleteSelected,
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: Text('Delete Selected (${_selectedKeys.length})'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Opacity(
                  opacity: 0.3,
                  child: Column(
                    children: [
                      const Icon(Icons.movie_filter_rounded, size: 64),
                      const SizedBox(height: 16),
                      const Text('No movies added yet'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _adminChannelListTile(items[i]),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }



  void _showAddMovieDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final logoCtrl = TextEditingController();

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

                if (name.isEmpty || url.isEmpty) {
                  _snack('Title and URL are required', error: true);
                  return;
                }

                try {
                  final payload = _channelPayload(
                    name: name,
                    url: url,
                    group: 'Movies',
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
