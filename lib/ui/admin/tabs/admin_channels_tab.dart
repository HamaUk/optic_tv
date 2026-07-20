import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminChannelsTabExt on _AdminScreenState {
  Widget _buildChannelsTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withValues(alpha: 0.35)],
        ),
      ),
      child: StreamBuilder<DatabaseEvent>(
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
              groups.add('${v['group'] ?? v['category'] ?? 'General'}');
            }
          }
          final sortedGroups = groups.toList()..sort();

          items = items.where((e) {
            final v = e.value;
            if (v is! Map) return false;
            final name = '${v['name'] ?? ''}'.toLowerCase();
            final url = '${v['url'] ?? ''}'.toLowerCase();
            final grp = '${v['group'] ?? v['category'] ?? 'General'}';
            if (_groupFilter != null && grp != _groupFilter) return false;
            if (_channelSearchQuery.isEmpty) return true;
            return name.contains(_channelSearchQuery) ||
                url.contains(_channelSearchQuery) ||
                grp.toLowerCase().contains(_channelSearchQuery);
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
                        onPressed: () => _tabController.animateTo(4), // Publish tab
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Channel'),
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
                        onPressed: () => _tabController.animateTo(5), // Import tab
                        icon: const Icon(Icons.file_upload_rounded),
                        label: const Text('Bulk Upload M3U'),
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
                        controller: _channelSearchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search name, URL, groupÔÇª',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                          prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
                          suffixIcon: _channelSearchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _channelSearchController.clear();
                                    setAdminState(() => _channelSearchQuery = '');
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
                                label: const Text('All groups'),
                                selected: _groupFilter == null,
                                onSelected: (_) => setAdminState(() {
                                  _groupFilter = null;
                                  _selectedKeys.clear();
                                }),
                                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                              ),
                            ),
                            ...sortedGroups.map(
                              (g) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(g),
                                  selected: _groupFilter == g,
                                  onSelected: (_) => setAdminState(() {
                                    _groupFilter = g;
                                    _selectedKeys.clear();
                                  }),
                                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                ),
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
                if (_groupFilter != null && _channelSearchQuery.isEmpty)
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
                                  'Drag these channels to move them. The new order will sync to all users.',
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
                          'No channels match',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // If a group filter is selected, use ReorderableListView for that group.
          if (_groupFilter != null && _channelSearchQuery.isEmpty) {
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
      ),
    );
  }



  Future<void> _deleteChannel(String key, String name) async {
    final ok = await _confirmDelete('Remove channel?', '"$name" will be removed from the playlist.');
    if (!ok) return;
    try {
      await _playlistRef.child(key).remove();
      _snack('Channel removed');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }


  Future<void> _deleteBatch() async {
    if (_selectedKeys.isEmpty) return;
    final count = _selectedKeys.length;
    final ok = await _confirmDelete(
      'Remove $count items?',
      'Are you sure you want to delete $count selected channels? This cannot be undone.',
    );
    if (!ok) return;

    try {
      final updates = <String, dynamic>{};
      for (final key in _selectedKeys) {
        updates[key] = null;
      }
      await _playlistRef.update(updates);
      setAdminState(() => _selectedKeys.clear());
      _snack('$count channels removed');
    } catch (e) {
      _snack('Batch delete failed: $e', error: true);
    }
  }


  void _showEditChannelDialog(String key, Map<dynamic, dynamic> raw) {
    final nameCtrl = TextEditingController(text: '${raw['name'] ?? ''}');
    final urlCtrl = TextEditingController(text: Channel.decrypt('${raw['url'] ?? ''}'));
    final url2Ctrl = TextEditingController(text: Channel.decrypt('${raw['url2'] ?? ''}'));
    final url2NameCtrl = TextEditingController(text: '${raw['url2Name'] ?? ''}');
    final url3Ctrl = TextEditingController(text: Channel.decrypt('${raw['url3'] ?? ''}'));
    final url3NameCtrl = TextEditingController(text: '${raw['url3Name'] ?? ''}');
    final groupCtrl = TextEditingController(text: '${raw['group'] ?? raw['category'] ?? 'General'}');
    final logoCtrl = TextEditingController(text: '${raw['logo'] ?? raw['icon_url'] ?? ''}');
    final backdropCtrl = TextEditingController(text: '${raw['backdrop'] ?? ''}');
    final userAgentCtrl = TextEditingController(text: '${raw['userAgent'] ?? raw['user_agent'] ?? ''}');
    final refererCtrl = TextEditingController(text: '${raw['referer'] ?? ''}');
    final drmSchemeCtrl = TextEditingController(text: '${raw['drmScheme'] ?? ''}');
    final drmLicenseCtrl = TextEditingController(text: '${raw['drmLicense'] ?? ''}');
    String contentType = raw['type'] ?? 'live';
    bool isFeatured = raw['featured'] == true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _adminEnglishLtr(
          StatefulBuilder(
            builder: (ctx, setModalState) {
              return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Edit channel', style: Theme.of(ctx).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      _sheetField(nameCtrl, 'Name', Icons.live_tv_rounded),
                      const SizedBox(height: 12),
                      _sheetField(urlCtrl, 'Server 1 URL (Primary)', Icons.link_rounded, maxLines: 3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _sheetField(url2NameCtrl, 'Server 2 Name', Icons.label_outline_rounded)),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: _sheetField(url2Ctrl, 'Server 2 URL', Icons.link_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _sheetField(url3NameCtrl, 'Server 3 Name', Icons.label_outline_rounded)),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: _sheetField(url3Ctrl, 'Server 3 URL', Icons.link_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _sheetField(userAgentCtrl, 'User Agent (Optional)', Icons.language_rounded),
                      const SizedBox(height: 12),
                      _sheetField(refererCtrl, 'Referer (Optional)', Icons.link_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _sheetField(drmSchemeCtrl, 'DRM Type (e.g. widevine)', Icons.security_rounded)),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: _sheetField(drmLicenseCtrl, 'DRM License URL', Icons.key_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _sheetField(groupCtrl, 'Group', Icons.folder_outlined),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _sheetField(logoCtrl, 'Logo URL or image', Icons.image_outlined, maxLines: 2),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Pick from gallery',
                            onPressed: () => _pickLogoInto(logoCtrl, () => setModalState(() {})),
                            icon: const Icon(Icons.photo_library_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _sheetField(backdropCtrl, 'Hero Backdrop URL', Icons.wallpaper_rounded, maxLines: 2),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Pick from gallery',
                            onPressed: () => _pickLogoInto(backdropCtrl, () => setModalState(() {})),
                            icon: const Icon(Icons.image_search_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Featured in Carousel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Spotlight this in the home hero card', style: TextStyle(fontSize: 12)),
                        value: isFeatured,
                        activeThumbColor: Theme.of(context).primaryColor,
                        onChanged: (v) => setModalState(() => isFeatured = v),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('Type:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SegmentedButton<String>(
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: Colors.black26,
                                  selectedBackgroundColor: AppTheme.accentTeal.withValues(alpha: 0.2),
                                  selectedForegroundColor: AppTheme.accentTeal,
                                ),
                                segments: const [
                                  ButtonSegment(value: 'live', label: Text('Live TV'), icon: Icon(Icons.live_tv_rounded, size: 16)),
                                  ButtonSegment(value: 'movie', label: Text('Movie'), icon: Icon(Icons.movie_rounded, size: 16)),
                                ],
                                selected: {contentType},
                                onSelectionChanged: (set) => setModalState(() => contentType = set.first),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                final toDispose = [nameCtrl, urlCtrl, url2Ctrl, url2NameCtrl, url3Ctrl, url3NameCtrl, groupCtrl, logoCtrl, backdropCtrl, userAgentCtrl, refererCtrl, drmSchemeCtrl, drmLicenseCtrl];
                                for (final c in toDispose) {
                                  Future.microtask(c.dispose);
                                }
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                final name = nameCtrl.text.trim();
                                final url = urlCtrl.text.trim();
                                final toDispose = [nameCtrl, urlCtrl, url2Ctrl, url2NameCtrl, url3Ctrl, url3NameCtrl, groupCtrl, logoCtrl, backdropCtrl, userAgentCtrl, refererCtrl, drmSchemeCtrl, drmLicenseCtrl];
                                if (name.isEmpty || url.isEmpty) {
                                  for (final c in toDispose) {
                                    Future.microtask(c.dispose);
                                  }
                                  _snack('Name and URL are required', error: true);
                                  return;
                                }
                                  for (final c in toDispose) {
                                    Future.microtask(c.dispose);
                                  }
                                    _updateChannel(
                                      key,
                                      name: name,
                                      url: url,
                                      group: groupCtrl.text.trim(),
                                      logo: logoCtrl.text.trim(),
                                      backdrop: backdropCtrl.text.trim(),
                                      type: contentType,
                                      featured: isFeatured,
                                      userAgent: userAgentCtrl.text.trim(),
                                      url2: url2Ctrl.text.trim(),
                                      url2Name: url2NameCtrl.text.trim(),
                                      url3: url3Ctrl.text.trim(),
                                      url3Name: url3NameCtrl.text.trim(),
                                      referer: refererCtrl.text.trim(),
                                      drmScheme: drmSchemeCtrl.text.trim(),
                                      drmLicense: drmLicenseCtrl.text.trim(),
                                    );
                              },
                              child: const Text('Save changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        );
      },
    );
  }


  Future<bool> _confirmDelete(String title, String body) async {
    final r = await showDialog<bool>(
          context: context,
          builder: (ctx) => _adminEnglishLtr(
            AlertDialog(
              backgroundColor: AppTheme.surfaceElevated,
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    return r;
  }


  Future<void> _reorderFeatured(List<MapEntry<dynamic, dynamic>> featured, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = featured.removeAt(oldIndex);
    featured.insert(newIndex, item);

    final updates = <String, dynamic>{};
    for (var i = 0; i < featured.length; i++) {
      updates['${featured[i].key}/featured_order'] = i;
    }
    try {
      await _playlistRef.update(updates);
      _snack('Featured order updated');
    } catch (e) {
      _snack('Failed to update order: $e', error: true);
    }
  }


}
