import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminOverviewTabExt on _AdminScreenState {
  Widget _buildOverviewTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withValues(alpha: 0.45)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          StreamBuilder<DatabaseEvent>(
            stream: _playlistRef.onValue,
            builder: (context, snapPl) {
              if (snapPl.connectionState == ConnectionState.waiting && !snapPl.hasData) {
                return SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
                );
              }
              if (!snapPl.hasData) {
                return SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
                );
              }
              final pl = snapPl.data?.snapshot.value;
              final channels = _parsePlaylist(pl);
              _sortChannelEntries(channels);

              return StreamBuilder<DatabaseEvent>(
                stream: _groupsRef.onValue,
                builder: (context, snapG) {
                  int gCount = 0;
                  if (snapG.hasData) {
                    final gv = snapG.data?.snapshot.value;
                    if (gv is Map) gCount = gv.length;
                  }

                  return StreamBuilder<DatabaseEvent>(
                    stream: _loginCodesRef.onValue,
                    builder: (context, snapC) {
                      int cCount = 0;
                      int activeCodes = 0;
                      if (snapC.hasData) {
                        final cv = snapC.data?.snapshot.value;
                        if (cv is Map) {
                          cCount = cv.length;
                          for (final v in cv.values) {
                            if (v is Map && v['active'] != false) activeCodes++;
                          }
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _statTile(
                                icon: Icons.live_tv_rounded,
                                label: 'Channels',
                                value: '${channels.length}',
                                color: Theme.of(context).primaryColor,
                              ),
                              _statTile(
                                icon: Icons.folder_special_rounded,
                                label: 'Groups',
                                value: '$gCount',
                                color: AppTheme.accentTeal,
                              ),
                              _statTile(
                                icon: Icons.vpn_key_rounded,
                                label: 'Access codes',
                                value: '$activeCodes / $cCount',
                                color: AppTheme.primaryBlue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _card(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick paths', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 10),
                                 _monoPath(_AdminScreenState._playlistPath),
                                _monoPath(_AdminScreenState._groupsPath),
                                _monoPath(_AdminScreenState._loginCodesPath),
                                _monoPath(_AdminScreenState._announcementPath),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _card(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Shortcuts', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _tabController.animateTo(4),
                                  icon: const Icon(Icons.publish_rounded),
                                  label: const Text('Add new content'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(2),
                                  icon: const Icon(Icons.manage_search_rounded),
                                  label: const Text('Browse & search channels'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(5),
                                  icon: const Icon(Icons.file_download_rounded),
                                  label: const Text('Import M3U / Xtream'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(6),
                                  icon: const Icon(Icons.health_and_safety_rounded),
                                  label: const Text('Check channel health'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(7),
                                  icon: const Icon(Icons.key_rounded),
                                  label: const Text('Groups & login codes'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Backup & restore', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Text(
                                  'Export saves every channel (including Movies tab items) and saved groups '
                                  'to a JSON file. Use Import to restore them if Firebase data is lost. '
                                  'Login codes are not included.',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: _backupBusy ? null : _exportLibraryBackup,
                                        icon: _backupBusy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                              )
                                            : const Icon(Icons.save_alt_rounded),
                                        label: const Text('Export library'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _backupBusy ? null : _importLibraryBackup,
                                        icon: const Icon(Icons.upload_file_rounded),
                                        label: const Text('Import library'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildFeaturedManager(channels),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildFeaturedManager(List<MapEntry<dynamic, dynamic>> allChannels) {
    final featured = allChannels.where((e) {
      final val = e.value as Map;
      return val['featured'] == true;
    }).toList();

    // Sort by existing order if available
    featured.sort((a, b) {
      final ordA = (a.value as Map)['featured_order'] ?? 999;
      final ordB = (b.value as Map)['featured_order'] ?? 999;
      return (ordA as int).compareTo(ordB as int);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_motion_rounded, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 12),
            Text(
              '3D Dashboard Cards (Featured)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Drag and drop to change the order on the home screen carousel.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 16),
        if (featured.isEmpty)
          _card(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No featured items yet. Edit a channel and turn on "Featured".',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: featured.length,
              onReorder: (oldIndex, newIndex) => _reorderFeatured(featured, oldIndex, newIndex),
              itemBuilder: (context, i) {
                final e = featured[i];
                final val = e.value as Map;
                return ListTile(
                  key: ValueKey('feat_${e.key}'),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ChannelLogoImage(
                      logo: val['logo'] ?? val['icon_url'],
                      channelName: val['name'] != null ? '${val['name']}' : null,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text('${val['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${val['group'] ?? 'General'}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('#${i + 1}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 12),
                      const Icon(Icons.drag_handle_rounded, color: Colors.white24),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }



  Future<void> _exportLibraryBackup() async {
    if (_backupBusy) return;
    setAdminState(() => _backupBusy = true);
    try {
      final plSnap = await _playlistRef.get();
      final grSnap = await _groupsRef.get();
      final payload = <String, dynamic>{
        'opticTvBackupVersion': _AdminScreenState._backupFileVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'managedPlaylist': plSnap.value,
        'channelGroups': grSnap.value ?? {},
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final dir = await getTemporaryDirectory();
      final day = DateTime.now().toUtc().toIso8601String().split('T').first;
      final file = File('${dir.path}/optic_tv_library_$day.json');
      await file.writeAsString(jsonStr);
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: 'optic_tv_library_$day.json')],
        subject: 'KOBANI 4K library backup',
        text: 'Channels, groups & movies (all playlist data). Keep this file safe.',
      );
      if (mounted) _snack('Share sheet opened ÔÇö save to Downloads, Drive, or Files.');
    } catch (e) {
      if (mounted) _snack('Export failed: $e', error: true);
    } finally {
      if (mounted) setAdminState(() => _backupBusy = false);
    }
  }


  Future<void> _importLibraryBackup() async {
    if (_backupBusy) return;
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => _adminEnglishLtr(
            AlertDialog(
              backgroundColor: AppTheme.surfaceElevated,
              title: const Text('Import library backup?'),
              content: const Text(
                'This replaces ALL channels in managedPlaylist and ALL saved channel groups '
                'with the contents of the backup file.\n\n'
                'Login codes are NOT changed.\n\n'
                'Continue?',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Import'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;

    setAdminState(() => _backupBusy = true);
    try {
      final pick = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: false,
      );
      if (pick == null || pick.files.isEmpty) {
        if (mounted) setAdminState(() => _backupBusy = false);
        return;
      }
      final path = pick.files.single.path;
      if (path == null) {
        if (mounted) {
          setAdminState(() => _backupBusy = false);
          _snack('Could not read file path', error: true);
        }
        return;
      }
      final text = await File(path).readAsString();
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        if (mounted) _snack('Invalid backup: root must be a JSON object', error: true);
        return;
      }
      final root = Map<String, dynamic>.from(decoded);
      final ver = root['opticTvBackupVersion'];
      if (ver != null && ver is! int) {
        if (mounted) _snack('Invalid backup: bad version field', error: true);
        return;
      }
      if (ver != null && ver != _AdminScreenState._backupFileVersion) {
        if (mounted) _snack('Backup version $ver ÔÇö importing anyway (may need manual check).');
      }
      if (!root.containsKey('managedPlaylist')) {
        if (mounted) _snack('Invalid backup: missing managedPlaylist', error: true);
        return;
      }
      final playlist = root['managedPlaylist'];
      if (playlist != null && playlist is! Map && playlist is! List) {
        if (mounted) _snack('Invalid backup: managedPlaylist must be object or array', error: true);
        return;
      }
      var groupsRaw = root['channelGroups'];
      if (groupsRaw != null && groupsRaw is! Map) {
        if (mounted) _snack('Invalid backup: channelGroups must be an object', error: true);
        return;
      }
      groupsRaw ??= <String, dynamic>{};

      await _playlistRef.set(playlist);
      await _groupsRef.set(Map<Object?, Object?>.from(groupsRaw as Map));

      if (mounted) _snack('Import complete ÔÇö playlist & groups restored.');
    } catch (e) {
      if (mounted) _snack('Import failed: $e', error: true);
    } finally {
      if (mounted) setAdminState(() => _backupBusy = false);
    }
  }


}
