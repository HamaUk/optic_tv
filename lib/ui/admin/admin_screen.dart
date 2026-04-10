import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';

enum _PublishShelf { liveTv, movies, custom }

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  static const _playlistPath = 'sync/global/managedPlaylist';
  static const _groupsPath = 'sync/global/channelGroups';
  static const _loginCodesPath = 'sync/global/loginCodes';

  final _channelNameController = TextEditingController();
  final _channelUrlController = TextEditingController();
  final _channelGroupController = TextEditingController();
  final _channelLogoController = TextEditingController();
  final _newGroupController = TextEditingController();
  final _newLoginCodeController = TextEditingController();
  final _channelSearchController = TextEditingController();

  late TabController _tabController;
  String _channelSearchQuery = '';
  String? _groupFilter;
  _PublishShelf _publishShelf = _PublishShelf.liveTv;

  DatabaseReference get _playlistRef => FirebaseDatabase.instance.ref(_playlistPath);
  DatabaseReference get _groupsRef => FirebaseDatabase.instance.ref(_groupsPath);
  DatabaseReference get _loginCodesRef => FirebaseDatabase.instance.ref(_loginCodesPath);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _channelGroupController.text = 'Live TV';
    _channelSearchController.addListener(() {
      setState(() => _channelSearchQuery = _channelSearchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _channelNameController.dispose();
    _channelUrlController.dispose();
    _channelGroupController.dispose();
    _channelLogoController.dispose();
    _newGroupController.dispose();
    _newLoginCodeController.dispose();
    _channelSearchController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFF7F1D1D) : AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool> _confirmDelete(String title, String body) async {
    final r = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
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
        ) ??
        false;
    return r;
  }

  Map<String, dynamic> _channelPayload({
    required String name,
    required String url,
    required String group,
    required String logo,
  }) {
    final map = <String, dynamic>{
      'name': name,
      'url': url,
      'group': group.isEmpty ? 'General' : group,
    };
    if (logo.isNotEmpty) map['logo'] = logo;
    return map;
  }

  List<MapEntry<dynamic, dynamic>> _parsePlaylist(dynamic raw) {
    if (raw == null) return [];
    if (raw is Map) return raw.entries.toList();
    if (raw is List) {
      final items = <MapEntry<dynamic, dynamic>>[];
      for (var i = 0; i < raw.length; i++) {
        final v = raw[i];
        if (v is Map) items.add(MapEntry('$i', v));
      }
      return items;
    }
    return [];
  }

  void _sortChannelEntries(List<MapEntry<dynamic, dynamic>> items) {
    items.sort((a, b) {
      final an = (a.value is Map) ? '${(a.value as Map)['name']}' : '';
      final bn = (b.value is Map) ? '${(b.value as Map)['name']}' : '';
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });
  }

  String _resolvedPublishGroup() {
    switch (_publishShelf) {
      case _PublishShelf.liveTv:
        return 'Live TV';
      case _PublishShelf.movies:
        return 'Movies';
      case _PublishShelf.custom:
        return _channelGroupController.text.trim();
    }
  }

  void _setPublishShelf(_PublishShelf v) {
    setState(() {
      _publishShelf = v;
      if (v == _PublishShelf.liveTv) {
        _channelGroupController.text = 'Live TV';
      } else if (v == _PublishShelf.movies) {
        _channelGroupController.text = 'Movies';
      } else {
        final t = _channelGroupController.text.trim();
        if (t == 'Live TV' || t == 'Movies') {
          _channelGroupController.clear();
        }
      }
    });
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
      setState(() {});
      after?.call();
      _snack('Logo image attached');
    } catch (e) {
      _snack('Could not read image: $e', error: true);
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
      await _playlistRef.push().set(_channelPayload(name: name, url: url, group: group, logo: logo));
      _channelNameController.clear();
      _channelUrlController.clear();
      _channelLogoController.clear();
      setState(() {
        _publishShelf = _PublishShelf.liveTv;
        _channelGroupController.text = 'Live TV';
      });
      _snack('Channel saved to database');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  void _prefillAddFromChannel(Map<dynamic, dynamic> val) {
    _channelNameController.text = '${val['name'] ?? ''} (copy)';
    _channelUrlController.text = '${val['url'] ?? ''}';
    final grpRaw = '${val['group'] ?? val['category'] ?? 'General'}';
    _channelLogoController.text = '${val['logo'] ?? val['icon_url'] ?? ''}';
    final gl = grpRaw.toLowerCase();
    final shelf = (gl.contains('movie') || gl.contains('film') || gl.contains('cinema'))
        ? _PublishShelf.movies
        : gl.contains('live')
            ? _PublishShelf.liveTv
            : _PublishShelf.custom;
    setState(() {
      _publishShelf = shelf;
      _channelGroupController.text = grpRaw;
    });
    _tabController.animateTo(2);
    _snack('Form filled — adjust name and tap Publish');
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    _snack('Stream URL copied');
  }

  Future<void> _addGroup() async {
    final name = _newGroupController.text.trim();
    if (name.isEmpty) {
      _snack('Enter a group name', error: true);
      return;
    }
    try {
      await _groupsRef.push().set({'name': name});
      _newGroupController.clear();
      _snack('Group added');
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
  }) async {
    try {
      final ref = _playlistRef.child(key);
      final g = group.isEmpty ? 'General' : group;
      await ref.update({'name': name, 'url': url, 'group': g});
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

  Future<void> _deleteChannel(String key, String name) async {
    final ok = await _confirmDelete('Remove channel?', '“$name” will be removed from the playlist.');
    if (!ok) return;
    try {
      await _playlistRef.child(key).remove();
      _snack('Channel removed');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Future<void> _deleteGroup(String key, String label) async {
    final ok = await _confirmDelete('Remove group?', '“$label” will be removed from saved groups.');
    if (!ok) return;
    try {
      await _groupsRef.child(key).remove();
      _snack('Group removed');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Future<void> _addLoginCode() async {
    final code = _newLoginCodeController.text.trim();
    if (code.isEmpty) {
      _snack('Enter a login code', error: true);
      return;
    }
    try {
      await _loginCodesRef.push().set({'code': code, 'active': true});
      _newLoginCodeController.clear();
      _snack('Login code created');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Future<void> _toggleLoginCode(String key, bool currentlyActive) async {
    try {
      await _loginCodesRef.child(key).update({'active': !currentlyActive});
      _snack(currentlyActive ? 'Code disabled' : 'Code enabled');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Future<void> _deleteLoginCode(String key, String code) async {
    final ok = await _confirmDelete('Remove login code?', 'Users won’t be able to sign in with “$code”.');
    if (!ok) return;
    try {
      await _loginCodesRef.child(key).remove();
      _snack('Login code removed');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  void _showEditChannelDialog(String key, Map<dynamic, dynamic> raw) {
    final nameCtrl = TextEditingController(text: '${raw['name'] ?? ''}');
    final urlCtrl = TextEditingController(text: '${raw['url'] ?? ''}');
    final groupCtrl = TextEditingController(text: '${raw['group'] ?? raw['category'] ?? 'General'}');
    final logoCtrl = TextEditingController(text: '${raw['logo'] ?? raw['icon_url'] ?? ''}');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
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
                      _sheetField(urlCtrl, 'Stream URL', Icons.link_rounded, maxLines: 3),
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                for (final c in [nameCtrl, urlCtrl, groupCtrl, logoCtrl]) {
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
                                if (name.isEmpty || url.isEmpty) {
                                  for (final c in [nameCtrl, urlCtrl, groupCtrl, logoCtrl]) {
                                    Future.microtask(c.dispose);
                                  }
                                  _snack('Name and URL are required', error: true);
                                  return;
                                }
                                for (final c in [nameCtrl, urlCtrl, groupCtrl, logoCtrl]) {
                                  Future.microtask(c.dispose);
                                }
                                _updateChannel(
                                  key,
                                  name: name,
                                  url: url,
                                  group: groupCtrl.text.trim(),
                                  logo: logoCtrl.text.trim(),
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
        );
      },
    );
  }

  Widget _sheetField(TextEditingController c, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGold.withValues(alpha: 0.85)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundBlack,
            AppTheme.surfaceGray,
            AppTheme.primaryGold.withValues(alpha: 0.06),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryGold, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control center',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        'Firebase Realtime Database',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAdminHeader(context),
            Material(
              color: AppTheme.backgroundBlack,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryGold,
                indicatorWeight: 3,
                labelColor: AppTheme.primaryGold,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(icon: Icon(Icons.space_dashboard_rounded, size: 20), text: 'Overview'),
                  Tab(icon: Icon(Icons.live_tv_rounded, size: 20), text: 'Channels'),
                  Tab(icon: Icon(Icons.add_circle_outline_rounded, size: 20), text: 'Publish'),
                  Tab(icon: Icon(Icons.key_rounded, size: 20), text: 'Access'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildChannelsTab(),
                  _buildPublishTab(),
                  _buildAccessTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withValues(alpha: 0.45)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: StreamBuilder<DatabaseEvent>(
          stream: _playlistRef.onValue,
          builder: (context, snapPl) {
            if (snapPl.connectionState == ConnectionState.waiting && !snapPl.hasData) {
              return const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
              );
            }
            final pl = snapPl.data?.snapshot.value;
            final channels = _parsePlaylist(pl);
            _sortChannelEntries(channels);

            return StreamBuilder<DatabaseEvent>(
                stream: _groupsRef.onValue,
                builder: (context, snapG) {
                  int gCount = 0;
                  final gv = snapG.data?.snapshot.value;
                  if (gv is Map) gCount = gv.length;

                  return StreamBuilder<DatabaseEvent>(
                    stream: _loginCodesRef.onValue,
                    builder: (context, snapC) {
                      int cCount = 0;
                      int activeCodes = 0;
                      final cv = snapC.data?.snapshot.value;
                      if (cv is Map) {
                        cCount = cv.length;
                        for (final v in cv.values) {
                          if (v is Map && v['active'] != false) activeCodes++;
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
                                color: AppTheme.primaryGold,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick paths', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 10),
                                _monoPath(_playlistPath),
                                _monoPath(_groupsPath),
                                _monoPath(_loginCodesPath),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Shortcuts', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _tabController.animateTo(2),
                                  icon: const Icon(Icons.publish_rounded),
                                  label: const Text('Add new channel'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(1),
                                  icon: const Icon(Icons.manage_search_rounded),
                                  label: const Text('Browse & search channels'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(3),
                                  icon: const Icon(Icons.key_rounded),
                                  label: const Text('Groups & login codes'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surfaceElevated,
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ],
      ),
    );
  }

  Widget _monoPath(String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SelectableText(
        path,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: AppTheme.accentTeal.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.surfaceElevated,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

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
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
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
              children: [
                TextField(
                  controller: _channelSearchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search name, URL, group…',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryGold.withValues(alpha: 0.8)),
                    suffixIcon: _channelSearchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _channelSearchController.clear();
                              setState(() => _channelSearchQuery = '');
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
                      borderSide: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All groups'),
                          selected: _groupFilter == null,
                          onSelected: (_) => setState(() => _groupFilter = null),
                          selectedColor: AppTheme.primaryGold.withValues(alpha: 0.35),
                        ),
                      ),
                      ...sortedGroups.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: _groupFilter == g,
                            onSelected: (_) => setState(() => _groupFilter = g),
                            selectedColor: AppTheme.primaryGold.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (items.isEmpty) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: header),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: header),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = items[index];
                      final val = entry.value as Map;
                      final logo = val['logo'] ?? val['icon_url'];
                      final name = '${val['name'] ?? 'Untitled'}';
                      final grp = '${val['group'] ?? val['category'] ?? 'General'}';
                      final url = '${val['url'] ?? ''}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showEditChannelDialog('${entry.key}', val),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: logo != null && '$logo'.isNotEmpty
                                        ? ChannelLogoImage(
                                            logo: '$logo',
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            fallback: _channelPlaceholder(),
                                          )
                                        : _channelPlaceholder(),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentTeal.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            grp,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.accentTeal.withValues(alpha: 0.95),
                                            ),
                                          ),
                                        ),
                                        if (url.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            url,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withValues(alpha: 0.35),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Copy URL',
                                        icon: Icon(Icons.copy_rounded, color: AppTheme.primaryGold.withValues(alpha: 0.85)),
                                        onPressed: url.isEmpty ? null : () => _copyUrl(url),
                                      ),
                                      IconButton(
                                        tooltip: 'Duplicate to form',
                                        icon: const Icon(Icons.control_point_duplicate_rounded),
                                        onPressed: () => _prefillAddFromChannel(val),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                        onPressed: () => _deleteChannel('${entry.key}', name),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _channelPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.white.withValues(alpha: 0.06),
      child: Icon(Icons.tv_rounded, color: Colors.white.withValues(alpha: 0.25)),
    );
  }

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(_channelNameController, 'Channel name', Icons.label_outline_rounded),
                const SizedBox(height: 14),
                _field(_channelUrlController, 'Stream URL (M3U8 / HLS / MP4)', Icons.link_rounded, maxLines: 3),
                const SizedBox(height: 14),
                DropdownButtonFormField<_PublishShelf>(
                  value: _publishShelf,
                  dropdownColor: AppTheme.surfaceElevated,
                  decoration: InputDecoration(
                    labelText: 'App section',
                    prefixIcon: Icon(Icons.category_rounded, color: AppTheme.primaryGold.withValues(alpha: 0.85)),
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
                  _field(_channelGroupController, 'Group name', Icons.folder_outlined),
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

  Widget _field(TextEditingController c, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGold.withValues(alpha: 0.85)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
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
                      onPressed: () => setState(() => _channelGroupController.text = n),
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

  Widget _buildAccessTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withValues(alpha: 0.35)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Groups',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _field(_newGroupController, 'New group name', Icons.create_new_folder_outlined)),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _addGroup,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<DatabaseEvent>(
                  stream: _groupsRef.onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                      return Text('No saved groups', style: TextStyle(color: Colors.white.withValues(alpha: 0.35)));
                    }
                    final value = snapshot.data!.snapshot.value;
                    if (value is! Map || value.isEmpty) {
                      return Text('No saved groups', style: TextStyle(color: Colors.white.withValues(alpha: 0.35)));
                    }
                    final entries = value.entries.toList()
                      ..sort((a, b) {
                        final an = (a.value is Map) ? '${(a.value as Map)['name']}' : '';
                        final bn = (b.value is Map) ? '${(b.value as Map)['name']}' : '';
                        return an.compareTo(bn);
                      });
                    return Column(
                      children: entries.map((e) {
                        final m = e.value;
                        final label = (m is Map) ? '${m['name'] ?? e.key}' : '${e.key}';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.2),
                            child: Icon(Icons.folder_rounded, color: AppTheme.accentTeal.withValues(alpha: 0.9)),
                          ),
                          title: Text(label),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deleteGroup('${e.key}', label),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Login codes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Users type these at sign-in (case-insensitive).',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _field(_newLoginCodeController, 'New access code', Icons.password_rounded)),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _addLoginCode,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<DatabaseEvent>(
                  stream: _loginCodesRef.onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                      return Text(
                        'No codes — users cannot sign in.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                      );
                    }
                    final value = snapshot.data!.snapshot.value;
                    if (value is! Map || value.isEmpty) {
                      return Text(
                        'No codes — users cannot sign in.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                      );
                    }
                    final entries = value.entries.toList()
                      ..sort((a, b) {
                        final ac = (a.value is Map) ? '${(a.value as Map)['code']}' : '';
                        final bc = (b.value is Map) ? '${(b.value as Map)['code']}' : '';
                        return ac.compareTo(bc);
                      });
                    return Column(
                      children: entries.map((e) {
                        final m = e.value;
                        final code = (m is Map) ? '${m['code'] ?? e.key}' : '${e.key}';
                        final active = (m is Map) && m['active'] != false;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.key_rounded, color: AppTheme.primaryGold.withValues(alpha: 0.8), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(code, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  Switch.adaptive(
                                    value: active,
                                    activeTrackColor: AppTheme.primaryGold.withValues(alpha: 0.45),
                                    onChanged: (_) => _toggleLoginCode('${e.key}', active),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    onPressed: () => _deleteLoginCode('${e.key}', code),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
