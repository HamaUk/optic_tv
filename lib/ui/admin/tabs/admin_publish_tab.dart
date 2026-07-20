import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminPublishTabExt on _AdminScreenState {
  Widget _buildPublishTab() {
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
            'Publish channel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Streams appear in the app from managedPlaylist.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(height: 24),
          _card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(_channelNameController, 'Channel name', Icons.label_outline_rounded),
                const SizedBox(height: 14),
                _field(_channelUrlController, 'Server 1 URL (Primary)', Icons.link_rounded, maxLines: 3),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field(_channelUrl2NameController, 'Server 2 Name', Icons.label_outline_rounded)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _field(_channelUrl2Controller, 'Server 2 URL', Icons.link_rounded)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field(_channelUrl3NameController, 'Server 3 Name', Icons.label_outline_rounded)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _field(_channelUrl3Controller, 'Server 3 URL', Icons.link_rounded)),
                  ],
                ),
                const SizedBox(height: 14),
                _field(_channelUserAgentController, 'User Agent (Optional)', Icons.language_rounded),
                const SizedBox(height: 14),
                _field(_channelRefererController, 'Referer (Optional)', Icons.link_rounded),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field(_channelDrmSchemeController, 'DRM Type (e.g. widevine)', Icons.security_rounded)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _field(_channelDrmLicenseController, 'DRM License URL', Icons.key_rounded)),
                  ],
                ),
                const SizedBox(height: 14),
                // Content Type Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _channelType == 'movie' ? Icons.movie_filter_rounded : Icons.live_tv_rounded,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Content Type', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            Text(
                              _channelType == 'movie' ? 'VOD / MOVIE' : 'LIVE STREAM',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _channelType == 'movie',
                        onChanged: (isMovie) {
                          setAdminState(() => _channelType = isMovie ? 'movie' : 'live');
                        },
                        activeThumbColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<_PublishShelf>(
                  initialValue: _publishShelf,
                  dropdownColor: AppTheme.surfaceElevated,
                  decoration: InputDecoration(
                    labelText: 'App section',
                    prefixIcon: Icon(Icons.category_rounded, color: Theme.of(context).primaryColor.withValues(alpha: 0.85)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                  ),
                  items: const [
                    DropdownMenuItem(value: _PublishShelf.liveTv, child: Text('Live TV (home / live lists)')),
                    DropdownMenuItem(value: _PublishShelf.movies, child: Text('Movies (Movies tab)')),
                    DropdownMenuItem(value: _PublishShelf.custom, child: Text('Custom group')),
                  ],
                  onChanged: (v) {
                    if (v != null) _setPublishShelf(v);
                  },
                ),
                if (_publishShelf == _PublishShelf.custom) ...[
                  const SizedBox(height: 14),
                  // Intelligent Category Autocomplete
                  StreamBuilder<DatabaseEvent>(
                    stream: _playlistRef.onValue,
                    builder: (context, snapshot) {
                      final List<String> options = [];
                      if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                        final items = _parsePlaylist(snapshot.data!.snapshot.value);
                        final set = <String>{};
                        for (final item in items) {
                          final val = item.value;
                          if (val is Map) {
                            final g = '${val['group'] ?? val['category'] ?? ''}'.trim();
                            if (g.isNotEmpty) set.add(g);
                          }
                        }
                        options.addAll(set.toList()..sort());
                      }

                      return RawAutocomplete<String>(
                        textEditingController: _channelGroupController,
                        focusNode: FocusNode(),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return options;
                          return options.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return _field(controller, 'Group name (e.g., Action, Horror)', Icons.folder_outlined, focusNode: focusNode);
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8,
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 350),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option, style: const TextStyle(color: Colors.white)),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildGroupQuickPick(),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Saved under group: ${_resolvedPublishGroup()}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(_channelLogoController, 'Logo URL (optional)', Icons.image_outlined, maxLines: 2),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: IconButton.filledTonal(
                        tooltip: 'Pick from gallery',
                        onPressed: () => _pickLogoInto(_channelLogoController),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(_channelSubtitleUrlController, 'Subtitle URL (Optional SRT/VTT)', Icons.subtitles_rounded, maxLines: 2),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: IconButton.filledTonal(
                        tooltip: 'Pick local subtitle (.srt/.vtt)',
                        onPressed: _pickSubtitleFile,
                        icon: const Icon(Icons.attach_file_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: const Text('Featured', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  value: _isFeaturedAdmin,
                  onChanged: (v) => setAdminState(() => _isFeaturedAdmin = v),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Content Type:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SegmentedButton<String>(
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppTheme.accentTeal.withValues(alpha: 0.2),
                            selectedForegroundColor: AppTheme.accentTeal,
                          ),
                          segments: const [
                            ButtonSegment(value: 'live', label: Text('Live TV'), icon: Icon(Icons.live_tv_rounded)),
                            ButtonSegment(value: 'movie', label: Text('Movie'), icon: Icon(Icons.movie_rounded)),
                          ],
                          selected: {_channelType},
                          onSelectionChanged: (set) => setAdminState(() => _channelType = set.first),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _addChannel,
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Save to database'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildGroupQuickPick() {
    return StreamBuilder<DatabaseEvent>(
      stream: _groupsRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) return const SizedBox.shrink();
        final value = snapshot.data!.snapshot.value;
        if (value is! Map) return const SizedBox.shrink();
        final names = value.entries
            .map((e) => (e.value is Map) ? '${(e.value as Map)['name'] ?? ''}'.trim() : '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        if (names.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick pick group', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: names
                  .map(
                    (n) => ActionChip(
                      label: Text(n),
                      onPressed: () => setAdminState(() => _channelGroupController.text = n),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }



  Future<void> _pickLogoInto(TextEditingController controller, [VoidCallback? after]) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    try {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final mime = (bytes.length >= 8 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47)
          ? 'image/png'
          : 'image/jpeg';
      controller.text = 'data:$mime;base64,$b64';
      setAdminState(() {});
      after?.call();
      _snack('Logo image attached');
    } catch (e) {
      _snack('Could not read image: $e', error: true);
    }
  }


  Future<void> _pickSubtitleFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    try {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;
      
      final b64 = base64Encode(bytes);
      final ext = file.extension?.toLowerCase() ?? 'srt';
      final mime = ext == 'vtt' ? 'text/vtt' : 'application/x-subrip';
      
      _channelSubtitleUrlController.text = 'data:$mime;base64,$b64';
      setAdminState(() {});
      _snack('Subtitle file attached (${file.name})');
    } catch (e) {
      _snack('Could not read subtitle: $e', error: true);
    }
  }


  Future<void> _addChannel() async {
    final name = _channelNameController.text.trim();
    final url = _channelUrlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      _snack('Channel name and stream URL are required', error: true);
      return;
    }
    final group = _resolvedPublishGroup();
    if (group.isEmpty) {
      _snack('Choose a section or enter a custom group name', error: true);
      return;
    }
    try {
      final logo = _channelLogoController.text.trim();
      final backdrop = _channelBackdropController.text.trim();
      final subUrl = _channelSubtitleUrlController.text.trim();
      final userAgent = _channelUserAgentController.text.trim();
      await _playlistRef.push().set(_channelPayload(
            name: name,
            url: url,
            group: group,
            logo: logo,
            backdrop: backdrop,
            subtitleUrl: subUrl,
            type: _channelType,
            featured: _isFeaturedAdmin,
            userAgent: userAgent,
            url2: _channelUrl2Controller.text.trim(),
            url2Name: _channelUrl2NameController.text.trim(),
            url3: _channelUrl3Controller.text.trim(),
            url3Name: _channelUrl3NameController.text.trim(),
            referer: _channelRefererController.text.trim(),
            drmScheme: _channelDrmSchemeController.text.trim(),
            drmLicense: _channelDrmLicenseController.text.trim(),
          ));
      _channelNameController.clear();
      _channelUrlController.clear();
      _channelUrl2Controller.clear();
      _channelUrl2NameController.clear();
      _channelUrl3Controller.clear();
      _channelUrl3NameController.clear();
      _channelLogoController.clear();
      _channelBackdropController.clear();
      _channelSubtitleUrlController.clear();
      _channelRefererController.clear();
      _channelDrmSchemeController.clear();
      _channelDrmLicenseController.clear();
      _channelUserAgentController.text = 'SmartIPTV';
      setAdminState(() {
        _isFeaturedAdmin = false;
        _channelType = 'live';
        _publishShelf = _PublishShelf.liveTv;
        _channelGroupController.text = 'Live TV';
      });
      _snack('Channel saved to database');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }


  Future<void> _updateChannel(
    String key, {
    required String name,
    required String url,
    required String group,
    required String logo,
    String? backdrop,
    String? type,
    required bool featured,
    String? userAgent,
    String? url2,
    String? url2Name,
    String? url3,
    String? url3Name,
    String? referer,
    String? drmScheme,
    String? drmLicense,
  }) async {
    try {
      final ref = _playlistRef.child(key);
      final g = group.isEmpty ? 'General' : group;
      final updates = <String, dynamic>{
        'name': name,
        'url': url,
        'group': g,
        'type': type ?? 'live',
        'featured': featured,
      };

      if (userAgent != null && userAgent.trim().isNotEmpty) {
        updates['userAgent'] = userAgent.trim();
      } else {
        await ref.child('userAgent').remove();
        await ref.child('user_agent').remove();
      }

      if (backdrop != null && backdrop.trim().isNotEmpty) {
        updates['backdrop'] = backdrop.trim();
      } else {
        await ref.child('backdrop').remove();
      }

      if (url2 != null && url2.trim().isNotEmpty) {
        updates['url2'] = url2.trim();
      } else {
        await ref.child('url2').remove();
      }
      if (url2Name != null && url2Name.trim().isNotEmpty) {
        updates['url2Name'] = url2Name.trim();
      } else {
        await ref.child('url2Name').remove();
      }
      if (url3 != null && url3.trim().isNotEmpty) {
        updates['url3'] = url3.trim();
      } else {
        await ref.child('url3').remove();
      }
      if (url3Name != null && url3Name.trim().isNotEmpty) {
        updates['url3Name'] = url3Name.trim();
      } else {
        await ref.child('url3Name').remove();
      }
      
      if (referer != null && referer.trim().isNotEmpty) {
        updates['referer'] = referer.trim();
      } else {
        await ref.child('referer').remove();
      }
      if (drmScheme != null && drmScheme.trim().isNotEmpty) {
        updates['drmScheme'] = drmScheme.trim();
      } else {
        await ref.child('drmScheme').remove();
      }
      if (drmLicense != null && drmLicense.trim().isNotEmpty) {
        updates['drmLicense'] = drmLicense.trim();
      } else {
        await ref.child('drmLicense').remove();
      }

      await ref.update(updates);
      final logoTrim = logo.trim();
      if (logoTrim.isEmpty) {
        await ref.child('logo').remove();
        await ref.child('icon_url').remove();
      } else {
        await ref.update({'logo': logoTrim});
      }
      _snack('Channel updated');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }


  void _prefillAddFromChannel(Map<dynamic, dynamic> val) {
    _channelNameController.text = '${val['name'] ?? ''} (copy)';
    _channelUrlController.text = '${val['url'] ?? ''}';
    _channelUrl2Controller.text = '${val['url2'] ?? ''}';
    _channelUrl2NameController.text = '${val['url2Name'] ?? ''}';
    _channelUrl3Controller.text = '${val['url3'] ?? ''}';
    _channelUrl3NameController.text = '${val['url3Name'] ?? ''}';
    _channelRefererController.text = '${val['referer'] ?? ''}';
    _channelDrmSchemeController.text = '${val['drmScheme'] ?? ''}';
    _channelDrmLicenseController.text = '${val['drmLicense'] ?? ''}';
    _channelUserAgentController.text = '${val['userAgent'] ?? val['user_agent'] ?? 'SmartIPTV'}';
    final grpRaw = '${val['group'] ?? val['category'] ?? 'General'}';
    _channelLogoController.text = '${val['logo'] ?? val['icon_url'] ?? ''}';
    final gl = grpRaw.toLowerCase();
    final shelf = (gl.contains('movie') || gl.contains('film') || gl.contains('cinema'))
        ? _PublishShelf.movies
        : gl.contains('live')
            ? _PublishShelf.liveTv
            : _PublishShelf.custom;
    setAdminState(() {
      _publishShelf = shelf;
      _channelGroupController.text = grpRaw;
    });
    _tabController.animateTo(4);
    _snack('Form filled ÔÇö adjust name and tap Publish');
  }


  void _setPublishShelf(_PublishShelf v) {
    setAdminState(() {
      _publishShelf = v;
      if (v == _PublishShelf.liveTv) {
        _channelGroupController.text = 'Live TV';
        _channelType = 'live';
      } else if (v == _PublishShelf.movies) {
        _channelGroupController.text = 'Movies';
        _channelType = 'movie';
      } else {
        final t = _channelGroupController.text.trim();
        if (t == 'Live TV' || t == 'Movies') {
          _channelGroupController.clear();
        }
      }
    });
  }


}
