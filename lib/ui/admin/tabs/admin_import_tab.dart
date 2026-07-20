import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminImportTabExt on _AdminScreenState {
  Widget _buildImportTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withValues(alpha: 0.4)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Import playlist',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Add channels from M3U files, URLs, or Xtream Codes.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ÔöÇÔöÇ M3U File ÔöÇÔöÇ
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.file_present_rounded, color: Theme.of(context).primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Text('From file', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick a .m3u or .m3u8 file from your device.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _importBusy ? null : _importFromFile,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Pick M3U file'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ÔöÇÔöÇ M3U URL ÔöÇÔöÇ
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.link_rounded, color: AppTheme.accentTeal, size: 22),
                    const SizedBox(width: 10),
                    Text('From URL', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_importUrlController, 'M3U playlist URL', Icons.link_rounded, maxLines: 2),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _importBusy ? null : _importFromUrl,
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: const Text('Download & parse'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ÔöÇÔöÇ Xtream Codes ÔöÇÔöÇ
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.dns_rounded, color: AppTheme.primaryBlue, size: 22),
                    const SizedBox(width: 10),
                    Text('Xtream Codes', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_xtreamServerController, 'Server URL (e.g. http://iptv.example.com)', Icons.dns_outlined),
                const SizedBox(height: 10),
                _field(_xtreamUserController, 'Username', Icons.person_outline_rounded),
                const SizedBox(height: 10),
                _field(_xtreamPassController, 'Password', Icons.lock_outline_rounded),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _importBusy ? null : _importFromXtream,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Fetch Xtream channels'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ÔöÇÔöÇ Status / Loading ÔöÇÔöÇ
          if (_importBusy)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Theme.of(context).primaryColor),
                    const SizedBox(height: 12),
                    Text(_importStatus, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
            ),

          if (!_importBusy && _importStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _importStatus,
                style: TextStyle(
                  fontSize: 13,
                  color: _importStatus.contains('Error') || _importStatus.contains('failed')
                      ? Colors.redAccent
                      : AppTheme.accentTeal,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // ÔöÇÔöÇ Preview ÔöÇÔöÇ
          if (_importPreview != null && _importPreview!.isNotEmpty) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Preview (${_importPreview!.length} channels)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: ListView.separated(
                      itemCount: _importPreview!.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                      itemBuilder: (context, i) {
                        final ch = _importPreview![i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            radius: 16,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          title: Text(
                            ch['name'] ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            ch['group'] ?? 'General',
                            style: TextStyle(fontSize: 10, color: AppTheme.accentTeal.withValues(alpha: 0.7)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setAdminState(() {
                            _importPreview = null;
                            _importStatus = '';
                          }),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _importBusy ? null : _saveImportedChannels,
                          icon: const Icon(Icons.cloud_upload_rounded),
                          label: const Text('Import All'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentTeal,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildBulkImportOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.movie_filter_rounded, color: AppTheme.accentTeal, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'BULK MOVIE IMPORT',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  _importMoviesStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _importMoviesProgress,
                    minHeight: 12,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accentTeal),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_importMoviesProgress * 100).toInt()}%',
                      style: const TextStyle(color: AppTheme.accentTeal, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$_importMoviesDone / $_importMoviesTotal',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Processing: $_importMoviesCurrentTitle',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Please do not close the app while the import is in progress. Fetching TMDB posters...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Future<void> _importFromFile() async {
    if (_importBusy) return;
    setAdminState(() {
      _importBusy = true;
      _importStatus = 'Picking file...';
    });
    try {
      final pick = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['m3u', 'm3u8', 'txt'],
        withData: false,
      );
      if (pick == null || pick.files.isEmpty || pick.files.single.path == null) {
        setAdminState(() {
          _importBusy = false;
          _importStatus = '';
        });
        return;
      }
      final content = await File(pick.files.single.path!).readAsString();
      final parsed = _parseM3u(content);
      setAdminState(() {
        _importPreview = parsed;
        _importBusy = false;
        _importStatus = 'Found ${parsed.length} channels. Tap "Import All" to save.';
      });
    } catch (e) {
      setAdminState(() {
        _importBusy = false;
        _importStatus = 'Error: $e';
      });
    }
  }


  Future<void> _importFromUrl() async {
    if (_importBusy) return;
    final url = _importUrlController.text.trim();
    if (url.isEmpty) {
      _snack('Enter a playlist URL', error: true);
      return;
    }
    setAdminState(() {
      _importBusy = true;
      _importStatus = 'Downloading playlist...';
    });
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'User-Agent': 'SmartIPTV'},
      ));
      final res = await dio.get<String>(url);
      final parsed = _parseM3u(res.data ?? '');
      setAdminState(() {
        _importPreview = parsed;
        _importBusy = false;
        _importStatus = 'Found ${parsed.length} channels. Tap "Import All" to save.';
      });
    } catch (e) {
      setAdminState(() {
        _importBusy = false;
        _importStatus = 'Download failed: $e';
      });
    }
  }


  Future<void> _importFromXtream() async {
    if (_importBusy) return;
    final server = _xtreamServerController.text.trim();
    final user = _xtreamUserController.text.trim();
    final pass = _xtreamPassController.text.trim();
    if (server.isEmpty || user.isEmpty || pass.isEmpty) {
      _snack('All Xtream fields are required', error: true);
      return;
    }
    setAdminState(() {
      _importBusy = true;
      _importStatus = 'Fetching Xtream channels...';
    });
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'User-Agent': 'SmartIPTV'},
      ));
      final baseUrl = server.endsWith('/') ? server.substring(0, server.length - 1) : server;
      final res = await dio.get('$baseUrl/player_api.php', queryParameters: {
        'username': user,
        'password': pass,
        'action': 'get_live_streams',
      });
      final data = res.data;
      final channels = <Map<String, String>>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            final streamId = item['stream_id'];
            final name = '${item['name'] ?? 'Unknown'}';
            final logo = '${item['stream_icon'] ?? ''}';
            final category = '${item['category_name'] ?? 'General'}';
            if (streamId != null) {
              channels.add({
                'name': name,
                'url': '$baseUrl/live/$user/$pass/$streamId.m3u8',
                'group': category,
                if (logo.isNotEmpty) 'logo': logo,
              });
            }
          }
        }
      }
      setAdminState(() {
        _importPreview = channels;
        _importBusy = false;
        _importStatus = 'Found ${channels.length} channels. Tap "Import All" to save.';
      });
    } catch (e) {
      setAdminState(() {
        _importBusy = false;
        _importStatus = 'Xtream import failed: $e';
      });
    }
  }


  Future<void> _saveImportedChannels() async {
    if (_importPreview == null || _importPreview!.isEmpty) return;
    setAdminState(() {
      _importBusy = true;
      _importStatus = 'Saving ${_importPreview!.length} channels...';
    });
    try {
      for (final ch in _importPreview!) {
        await _playlistRef.push().set({
          'name': ch['name'] ?? 'Unknown',
          'url': ch['url'] ?? '',
          'group': ch['group'] ?? 'General',
          if (ch['logo'] != null) 'logo': ch['logo'],
        });
      }
      final count = _importPreview!.length;
      setAdminState(() {
        _importPreview = null;
        _importBusy = false;
        _importStatus = '$count channels imported successfully!';
      });
      _snack('$count channels imported');
    } catch (e) {
      setAdminState(() {
        _importBusy = false;
        _importStatus = 'Save failed: $e';
      });
    }
  }


  Future<void> _importMoviesBulk() async {
    if (_importMoviesBusy) return;

    final pick = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['m3u', 'm3u8', 'txt'],
    );
    if (pick == null || pick.files.isEmpty || pick.files.single.path == null) return;

    setAdminState(() {
      _importMoviesBusy = true;
      _importMoviesProgress = 0;
      _importMoviesStatus = 'Reading file...';
      _importMoviesDone = 0;
    });

    try {
      final content = await File(pick.files.single.path!).readAsString();
      final parsed = _parseM3u(content);
      if (parsed.isEmpty) {
        _snack('No channels found in file', error: true);
        setAdminState(() => _importMoviesBusy = false);
        return;
      }

      setAdminState(() {
        _importMoviesTotal = parsed.length;
        _importMoviesStatus = 'Preparing to fetch metadata for ${parsed.length} movies...';
      });

      final tmdb = TmdbService();

      for (final ch in parsed) {
        if (!_importMoviesBusy) break; // Allow cancellation if needed (though no UI yet)

        final name = ch['name'] ?? 'Unknown';
        final url = ch['url'] ?? '';
        if (url.isEmpty) continue;

        setAdminState(() {
          _importMoviesCurrentTitle = name;
          _importMoviesStatus = 'Importing: $name';
        });

        // 0. Clean the name for better TMDB matching
        String searchName = name
            .replaceAll(RegExp(r'\.(mp4|mkv|avi|ts|m3u8|mov)$', caseSensitive: false), '')
            .replaceAll(RegExp(r'(1080p|720p|4k|uhd|bluray|h264|h265|web-dl|x264|x265)', caseSensitive: false), '')
            .replaceAll('.', ' ')
            .trim();

        // 1. Fetch TMDB metadata
        final movie = await tmdb.findMovie(searchName);

        // 2. Save to Firebase with fallbacks
        await _playlistRef.push().set({
          'name': name,
          'url': url,
          'group': ch['group'] ?? 'Movies', // Use M3U group or default to Movies
          'type': 'movie',
          // Use TMDB poster if found, otherwise fallback to M3U logo
          'logo': movie?.posterUrl ?? ch['logo'],
          if (movie?.backdropUrl != null) 'backdrop': movie!.backdropUrl,
          if (movie?.overview != null) 'description': movie!.overview,
        });

        setAdminState(() {
          _importMoviesDone++;
          _importMoviesProgress = _importMoviesDone / _importMoviesTotal;
        });

        // Small delay to prevent hitting API rate limits too hard and keep UI responsive
        await Future.delayed(const Duration(milliseconds: 50));
      }

      _snack('Bulk import complete! ${_importMoviesDone} movies added.', error: false);
    } catch (e) {
      _snack('Import error: $e', error: true);
    } finally {
      setAdminState(() {
        _importMoviesBusy = false;
        _importMoviesStatus = '';
        _importMoviesCurrentTitle = '';
      });
    }
  }


  Future<void> _bulkDeleteSelected() async {
    if (_selectedKeys.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Bulk Delete'),
        content: Text('Are you sure you want to delete ${_selectedKeys.length} items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final keys = List<String>.from(_selectedKeys);
      setAdminState(() => _selectedKeys.clear());
      try {
        for (final k in keys) {
          await _playlistRef.child(k).remove();
        }
        _snack('Bulk delete successful');
      } catch (e) {
        _snack('Error during bulk delete: $e', error: true);
      }
    }
  }


}
