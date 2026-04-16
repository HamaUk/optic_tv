import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../widgets/channel_logo_image.dart';

enum _PublishShelf { liveTv, movies, custom }
enum _LoginDuration { day, week, month, year, never }

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  static const _playlistPath = 'sync/global/managedPlaylist';
  static const _groupsPath = 'sync/global/channelGroups';
  static const _loginCodesPath = 'sync/global/loginCodes';
  static const _announcementPath = 'sync/global/announcement';
  static const _notifBroadcastPath = 'sync/global/notifications/broadcast';
  static const _notifHistoryPath = 'sync/global/notifications/history';
  static const _backupFileVersion = 1;

  final _channelNameController = TextEditingController();
  final _channelUrlController = TextEditingController();
  final _channelGroupController = TextEditingController();
  final _channelLogoController = TextEditingController();
  final _newGroupController = TextEditingController();
  final _newLoginCodeController = TextEditingController();
  final _channelSearchController = TextEditingController();
  final _announcementController = TextEditingController();
  final _notifTitleController = TextEditingController();
  final _notifBodyController = TextEditingController();
  final _notifImageController = TextEditingController();

  // Admin Auth Shield State
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAuthenticating = false;
  bool _isAuthenticated = false;
  String? _authError;

  // Import tab controllers
  final _importUrlController = TextEditingController();
  final _xtreamServerController = TextEditingController();
  final _xtreamUserController = TextEditingController();
  final _xtreamPassController = TextEditingController();

  late TabController _tabController;
  String _channelSearchQuery = '';
  String? _groupFilter;
  _PublishShelf _publishShelf = _PublishShelf.liveTv;
  bool _backupBusy = false;
  final Set<String> _selectedKeys = {};

  // Import state
  bool _importBusy = false;
  List<Map<String, String>>? _importPreview;
  String _importStatus = '';

  // Health checker state
  bool _healthCheckRunning = false;
  double _healthProgress = 0;
  final Map<String, _ChannelHealthStatus> _healthResults = {};
  bool _showBrokenOnly = false;
  _LoginDuration _selectedLoginDuration = _LoginDuration.month;

  DatabaseReference get _playlistRef => FirebaseDatabase.instance.ref(_playlistPath);
  DatabaseReference get _groupsRef => FirebaseDatabase.instance.ref(_groupsPath);
  DatabaseReference get _loginCodesRef => FirebaseDatabase.instance.ref(_loginCodesPath);
  DatabaseReference get _announcementRef => FirebaseDatabase.instance.ref(_announcementPath);
  DatabaseReference get _notifBroadcastRef => FirebaseDatabase.instance.ref(_notifBroadcastPath);
  DatabaseReference get _notifHistoryRef => FirebaseDatabase.instance.ref(_notifHistoryPath);

  void initState() {
    super.initState();
    _isAuthenticated = FirebaseAuth.instance.currentUser != null;
    _tabController = TabController(length: 8, vsync: this);
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
    _importUrlController.dispose();
    _xtreamServerController.dispose();
    _xtreamUserController.dispose();
    _xtreamPassController.dispose();
    _announcementController.dispose();
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    _notifImageController.dispose();
    super.dispose();
  }

  /// Admin portal is always English copy, LTR layout, and default Latin typography (no Rabar).
  Widget _adminEnglishLtr(Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: AppTheme.darkTheme,
        child: Stack(
          children: [
            child,
            if (!_isAuthenticated) _buildLoginShield(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginShield() {
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_rounded, color: AppTheme.primaryGold, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'ADMIN SECURITY SHIELD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please authorize to modify infrastructure',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Admin Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_authError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _authError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isAuthenticating ? null : _performAuth,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isAuthenticating
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                        : const Text('Access Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to App', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performAuth() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _authError = 'Enter both email and password');
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      setState(() {
        _isAuthenticating = false;
        _isAuthenticated = true;
      });
      _snack('Authenticated as Owner');
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authError = 'Shield Check Failed: $e';
      });
    }
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

  Future<void> _exportLibraryBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final plSnap = await _playlistRef.get();
      final grSnap = await _groupsRef.get();
      final payload = <String, dynamic>{
        'opticTvBackupVersion': _backupFileVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'managedPlaylist': plSnap.value,
        'channelGroups': grSnap.value ?? {},
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final dir = await getTemporaryDirectory();
      final day = DateTime.now().toUtc().toIso8601String().split('T').first;
      final file = File('${dir.path}/optic_tv_library_$day.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: 'optic_tv_library_$day.json')],
        subject: 'Optic TV library backup',
        text: 'Channels, groups & movies (all playlist data). Keep this file safe.',
      );
      if (mounted) _snack('Share sheet opened — save to Downloads, Drive, or Files.');
    } catch (e) {
      if (mounted) _snack('Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
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

    setState(() => _backupBusy = true);
    try {
      final pick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: false,
      );
      if (pick == null || pick.files.isEmpty) {
        if (mounted) setState(() => _backupBusy = false);
        return;
      }
      final path = pick.files.single.path;
      if (path == null) {
        if (mounted) {
          setState(() => _backupBusy = false);
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
      if (ver != null && ver != _backupFileVersion) {
        if (mounted) _snack('Backup version $ver — importing anyway (may need manual check).');
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

      if (mounted) _snack('Import complete — playlist & groups restored.');
    } catch (e) {
      if (mounted) _snack('Import failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
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

  Map<String, dynamic> _channelPayload({
    required String name,
    required String url,
    required String group,
    required String logo,
    int? order,
  }) {
    final map = <String, dynamic>{
      'name': name,
      'url': url,
      'group': group.isEmpty ? 'General' : group,
    };
    if (logo.isNotEmpty) map['logo'] = logo;
    if (order != null) map['order'] = order;
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
      final av = a.value;
      final bv = b.value;
      if (av is Map && bv is Map) {
        final ao = av['order'] as int? ?? 999999;
        final bo = bv['order'] as int? ?? 999999;
        if (ao != bo) return ao.compareTo(bo);
      }
      final an = (av is Map) ? '${av['name']}' : '';
      final bn = (bv is Map) ? '${bv['name']}' : '';
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
      setState(() => _selectedKeys.clear());
      _snack('$count channels removed');
    } catch (e) {
      _snack('Batch delete failed: $e', error: true);
    }
  }

  Future<void> _deleteGroup(String key, String label) async {
    final ok = await _confirmDelete('Remove group?', '"$label" will be removed from saved groups.');
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
      String? expiresAt;
      final now = DateTime.now().toUtc();
      switch (_selectedLoginDuration) {
        case _LoginDuration.day:
          expiresAt = now.add(const Duration(days: 1)).toIso8601String();
          break;
        case _LoginDuration.week:
          expiresAt = now.add(const Duration(days: 7)).toIso8601String();
          break;
        case _LoginDuration.month:
          expiresAt = now.add(const Duration(days: 30)).toIso8601String();
          break;
        case _LoginDuration.year:
          expiresAt = now.add(const Duration(days: 365)).toIso8601String();
          break;
        case _LoginDuration.never:
          expiresAt = null;
          break;
      }

      await _loginCodesRef.push().set({
        'code': code,
        'active': true,
        'expiresAt': expiresAt,
        'createdAt': now.toIso8601String(),
      });
      _newLoginCodeController.clear();
      _snack('Login code created');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  bool _isCodeExpired(dynamic expiresAt) {
    if (expiresAt == null) return false;
    try {
      final dt = DateTime.parse('$expiresAt');
      return DateTime.now().toUtc().isAfter(dt);
    } catch (_) {
      return false;
    }
  }

  Widget _durationChip(String label, _LoginDuration duration) {
    final selected = _selectedLoginDuration == duration;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (val) {
          if (val) setState(() => _selectedLoginDuration = duration);
        },
        selectedColor: AppTheme.primaryGold.withOpacity(0.35),
      ),
    );
  }

  String _formatExpiry(dynamic expiresAt) {
    if (expiresAt == null) return 'Never expires';
    try {
      final dt = DateTime.parse('$expiresAt').toLocal();
      final now = DateTime.now();
      final diff = dt.difference(now);
      if (diff.isNegative) return 'EXPIRED';

      final y = dt.year;
      final m = dt.month;
      final d = dt.day;
      return 'Expires: $y-$m-$d';
    } catch (_) {
      return 'Invalid date';
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
    final ok = await _confirmDelete('Remove login code?', "Users won't be able to sign in with \"$code\".");
    if (!ok) return;
    try {
      await _loginCodesRef.child(key).remove();
      _snack('Login code removed');
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  // ─────────────────────── Channel Reordering ───────────────────────

  Future<void> _moveChannel(
    List<MapEntry<dynamic, dynamic>> groupItems,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = groupItems.removeAt(oldIndex);
    groupItems.insert(newIndex, item);

    // Update order field for all items in this group.
    final updates = <String, dynamic>{};
    for (var i = 0; i < groupItems.length; i++) {
      updates['${groupItems[i].key}/order'] = i;
    }
    try {
      await _playlistRef.update(updates);
    } catch (e) {
      _snack('Reorder failed: $e', error: true);
    }
  }

  // ─────────────────────── M3U / Xtream Import ───────────────────────

  List<Map<String, String>> _parseM3u(String content) {
    final lines = content.split('\n');
    final channels = <Map<String, String>>[];
    String? name, group, logo;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.startsWith('#EXTINF:')) {
        final nameMatch = RegExp(r'tvg-name="([^"]*)"').firstMatch(line);
        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);

        name = nameMatch?.group(1);
        logo = logoMatch?.group(1);
        group = groupMatch?.group(1);

        // Fallback: channel name after the last comma.
        if (name == null || name.isEmpty) {
          final commaIndex = line.lastIndexOf(',');
          if (commaIndex >= 0) {
            name = line.substring(commaIndex + 1).trim();
          }
        }
      } else if (line.isNotEmpty && !line.startsWith('#') && name != null) {
        channels.add({
          'name': name,
          'url': line,
          'group': group ?? 'General',
          if (logo != null && logo.isNotEmpty) 'logo': logo,
        });
        name = null;
        group = null;
        logo = null;
      }
    }
    return channels;
  }

  Future<void> _importFromFile() async {
    if (_importBusy) return;
    setState(() {
      _importBusy = true;
      _importStatus = 'Picking file...';
    });
    try {
      final pick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['m3u', 'm3u8', 'txt'],
        withData: false,
      );
      if (pick == null || pick.files.isEmpty || pick.files.single.path == null) {
        setState(() {
          _importBusy = false;
          _importStatus = '';
        });
        return;
      }
      final content = await File(pick.files.single.path!).readAsString();
      final parsed = _parseM3u(content);
      setState(() {
        _importPreview = parsed;
        _importBusy = false;
        _importStatus = 'Found ${parsed.length} channels. Tap "Import All" to save.';
      });
    } catch (e) {
      setState(() {
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
    setState(() {
      _importBusy = true;
      _importStatus = 'Downloading playlist...';
    });
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final res = await dio.get<String>(url);
      final parsed = _parseM3u(res.data ?? '');
      setState(() {
        _importPreview = parsed;
        _importBusy = false;
        _importStatus = 'Found ${parsed.length} channels. Tap "Import All" to save.';
      });
    } catch (e) {
      setState(() {
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
    setState(() {
      _importBusy = true;
      _importStatus = 'Fetching Xtream channels...';
    });
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
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
      setState(() {
        _importPreview = channels;
        _importBusy = false;
        _importStatus = 'Found ${channels.length} channels. Tap "Import All" to save.';
      });
    } catch (e) {
      setState(() {
        _importBusy = false;
        _importStatus = 'Xtream import failed: $e';
      });
    }
  }

  Future<void> _saveImportedChannels() async {
    if (_importPreview == null || _importPreview!.isEmpty) return;
    setState(() {
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
      setState(() {
        _importPreview = null;
        _importBusy = false;
        _importStatus = '$count channels imported successfully!';
      });
      _snack('$count channels imported');
    } catch (e) {
      setState(() {
        _importBusy = false;
        _importStatus = 'Save failed: $e';
      });
    }
  }

  // ─────────────────────── Health Check ───────────────────────

  Future<void> _runHealthCheck() async {
    if (_healthCheckRunning) return;
    setState(() {
      _healthCheckRunning = true;
      _healthProgress = 0;
      _healthResults.clear();
    });

    try {
      final snap = await _playlistRef.get();
      final items = _parsePlaylist(snap.value);
      if (items.isEmpty) {
        setState(() {
          _healthCheckRunning = false;
          _healthProgress = 1;
        });
        _snack('No channels to check');
        return;
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        followRedirects: true,
        maxRedirects: 5,
      ));

      for (var i = 0; i < items.length; i++) {
        final entry = items[i];
        final val = entry.value;
        if (val is! Map) continue;
        final key = '${entry.key}';
        final url = '${val['url'] ?? ''}';
        final name = '${val['name'] ?? 'Untitled'}';

        if (url.isEmpty) {
          _healthResults[key] = _ChannelHealthStatus(
            name: name,
            url: url,
            status: _HealthStatus.broken,
            message: 'Empty URL',
          );
        } else {
          try {
            final res = await dio.head(url);
            if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 400) {
              _healthResults[key] = _ChannelHealthStatus(
                name: name,
                url: url,
                status: _HealthStatus.ok,
                message: 'HTTP ${res.statusCode}',
              );
            } else {
              _healthResults[key] = _ChannelHealthStatus(
                name: name,
                url: url,
                status: _HealthStatus.broken,
                message: 'HTTP ${res.statusCode}',
              );
            }
          } on DioException catch (e) {
            if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout) {
              _healthResults[key] = _ChannelHealthStatus(
                name: name,
                url: url,
                status: _HealthStatus.warning,
                message: 'Timeout',
              );
            } else {
              _healthResults[key] = _ChannelHealthStatus(
                name: name,
                url: url,
                status: _HealthStatus.broken,
                message: e.message ?? 'Connection failed',
              );
            }
          } catch (e) {
            _healthResults[key] = _ChannelHealthStatus(
              name: name,
              url: url,
              status: _HealthStatus.broken,
              message: '$e',
            );
          }
        }

        if (mounted) {
          setState(() {
            _healthProgress = (i + 1) / items.length;
          });
        }
      }
    } catch (e) {
      if (mounted) _snack('Health check error: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _healthCheckRunning = false);
      }
    }
  }

  // ─────────────────────── Edit Channel Dialog ───────────────────────

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
          ),
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
        prefixIcon: Icon(icon, color: AppTheme.primaryGold.withOpacity(0.85)),
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
            AppTheme.primaryGold.withOpacity(0.06),
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
                    color: AppTheme.primaryGold.withOpacity(0.15),
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
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
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
    return _adminEnglishLtr(
      Scaffold(
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
                    Tab(icon: Icon(Icons.movie_rounded, size: 20), text: 'Movies'),
                    Tab(icon: Icon(Icons.add_circle_outline_rounded, size: 20), text: 'Publish'),
                    Tab(icon: Icon(Icons.file_download_rounded, size: 20), text: 'Import'),
                    Tab(icon: Icon(Icons.health_and_safety_rounded, size: 20), text: 'Health'),
                    Tab(icon: Icon(Icons.key_rounded, size: 20), text: 'Access'),
                    Tab(icon: Icon(Icons.campaign_rounded, size: 20), text: 'Broadcast'),
                  ],
              ),
            ),
            Expanded(
              child: Material(
                color: AppTheme.backgroundBlack,
                child: TabBarView(
                  controller: _tabController,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_overview'),
                      child: _KeepAliveTab(child: _buildOverviewTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_channels'),
                      child: _KeepAliveTab(child: _buildChannelsTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_movies'),
                      child: _KeepAliveTab(child: _buildMoviesTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_publish'),
                      child: _KeepAliveTab(child: _buildPublishTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_import'),
                      child: _KeepAliveTab(child: _buildImportTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_health'),
                      child: _KeepAliveTab(child: _buildHealthTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_access'),
                      child: _KeepAliveTab(child: _buildAccessTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_announcement'),
                      child: _KeepAliveTab(child: _buildAnnouncementTab()),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Tab: Overview
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOverviewTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withOpacity(0.45)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          StreamBuilder<DatabaseEvent>(
            stream: _playlistRef.onValue,
            builder: (context, snapPl) {
              if (snapPl.connectionState == ConnectionState.waiting && !snapPl.hasData) {
                return const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
                );
              }
              if (!snapPl.hasData) {
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
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick paths', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 10),
                                 _monoPath(_playlistPath),
                                _monoPath(_groupsPath),
                                _monoPath(_loginCodesPath),
                                _monoPath(_announcementPath),
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
                                  icon: const Icon(Icons.file_download_rounded),
                                  label: const Text('Import M3U / Xtream'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(4),
                                  icon: const Icon(Icons.health_and_safety_rounded),
                                  label: const Text('Check channel health'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(5),
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
                                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
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
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45))),
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
          color: AppTheme.accentTeal.withOpacity(0.9),
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
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Tab: Channels (with drag reorder per group)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChannelsTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withOpacity(0.35)],
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _channelSearchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search name, URL, group…',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryGold.withOpacity(0.8)),
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
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.primaryGold.withOpacity(0.5)),
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
                                onSelected: (_) => setState(() {
                                  _groupFilter = null;
                                  _selectedKeys.clear();
                                }),
                                selectedColor: AppTheme.primaryGold.withOpacity(0.35),
                              ),
                            ),
                            ...sortedGroups.map(
                              (g) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(g),
                                  selected: _groupFilter == g,
                                  onSelected: (_) => setState(() {
                                    _groupFilter = g;
                                    _selectedKeys.clear();
                                  }),
                                  selectedColor: AppTheme.primaryGold.withOpacity(0.35),
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
                          setState(() {
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
                          color: AppTheme.primaryGold,
                        ),
                        label: const Text('Select All', style: TextStyle(fontSize: 12, color: AppTheme.primaryGold)),
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
                        color: AppTheme.accentTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentTeal.withOpacity(0.2)),
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
                                    color: Colors.white.withOpacity(0.5),
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
                        Icon(Icons.search_off_rounded, size: 56, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 12),
                        Text(
                          'No channels match',
                          style: TextStyle(color: Colors.white.withOpacity(0.4)),
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
                        shadowColor: AppTheme.accentTeal.withOpacity(0.25),
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

  Widget _adminChannelListTile(MapEntry<dynamic, dynamic> entry, {int? position}) {
    final key = '${entry.key}';
    final val = entry.value as Map;
    final logo = val['logo'] ?? val['icon_url'];
    final name = '${val['name'] ?? 'Untitled'}';
    final grp = '${val['group'] ?? val['category'] ?? 'General'}';
    final url = '${val['url'] ?? ''}';
    final isSelected = _selectedKeys.contains(key);

    return Material(
      color: isSelected ? AppTheme.accentTeal.withOpacity(0.12) : AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showEditChannelDialog(key, val),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: AppTheme.primaryGold,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedKeys.add(key);
                    } else {
                      _selectedKeys.remove(key);
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
              if (position != null) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    '#$position',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.accentTeal : AppTheme.primaryGold.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: logo != null && '$logo'.isNotEmpty
                    ? ChannelLogoImage(
                        logo: '$logo',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        fallback: _channelPlaceholder(),
                      )
                    : _channelPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isSelected ? AppTheme.accentTeal : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        grp,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentTeal.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _tileActions(key, name, val, url),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileActions(String key, String name, Map val, String url) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_groupFilter != null && _channelSearchQuery.isEmpty)
          Icon(Icons.drag_handle_rounded, color: Colors.white.withOpacity(0.3), size: 18),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Copy URL',
          icon: Icon(Icons.copy_rounded, color: AppTheme.primaryGold.withOpacity(0.85), size: 20),
          onPressed: url.isEmpty ? null : () => _copyUrl(url),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Duplicate',
          icon: const Icon(Icons.control_point_duplicate_rounded, size: 20),
          onPressed: () => _prefillAddFromChannel(val),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          onPressed: () => _deleteChannel(key, name),
        ),
      ],
    );
  }

  Widget _channelPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.white.withOpacity(0.06),
      child: Icon(Icons.tv_rounded, color: Colors.white.withOpacity(0.25)),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Tab: Publish
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPublishTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withOpacity(0.4)],
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
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
          ),
          const SizedBox(height: 24),
          _card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    prefixIcon: Icon(Icons.category_rounded, color: AppTheme.primaryGold.withOpacity(0.85)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
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
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45)),
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
        prefixIcon: Icon(icon, color: AppTheme.primaryGold.withOpacity(0.85)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
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
            Text('Quick pick group', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: names
                  .map(
                    (n) => ActionChip(
                      label: Text(n),
                      onPressed: () => setState(() => _channelGroupController.text = n),
                      backgroundColor: Colors.white.withOpacity(0.06),
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Tab: Import (M3U file / URL / Xtream Codes)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildImportTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withOpacity(0.4)],
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
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── M3U File ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.file_present_rounded, color: AppTheme.primaryGold, size: 22),
                    const SizedBox(width: 10),
                    Text('From file', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick a .m3u or .m3u8 file from your device.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
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

          // ── M3U URL ──
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

          // ── Xtream Codes ──
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

          // ── Status / Loading ──
          if (_importBusy)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primaryGold),
                    const SizedBox(height: 12),
                    Text(_importStatus, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
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

          // ── Preview ──
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
                          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                      itemBuilder: (context, i) {
                        final ch = _importPreview![i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.06),
                            radius: 16,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryGold.withOpacity(0.7),
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
                            style: TextStyle(fontSize: 10, color: AppTheme.accentTeal.withOpacity(0.7)),
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
                          onPressed: () => setState(() {
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

  // ═══════════════════════════════════════════════════════════════
  //  Tab: Health Check
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHealthTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withOpacity(0.35)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Channel health',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Check all channel URLs to find broken or unavailable streams.',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
          ),
          const SizedBox(height: 24),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _healthCheckRunning ? null : _runHealthCheck,
                  icon: _healthCheckRunning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.health_and_safety_rounded),
                  label: Text(_healthCheckRunning ? 'Checking...' : 'Check all channels'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                if (_healthCheckRunning || _healthProgress > 0) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _healthProgress,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation(
                        _healthCheckRunning ? AppTheme.primaryGold : AppTheme.accentTeal,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_healthProgress * 100).toInt()}% complete',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          if (_healthResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Summary
            _card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _healthSummaryChip(
                    '✅ OK',
                    _healthResults.values.where((h) => h.status == _HealthStatus.ok).length,
                    Colors.green,
                  ),
                  _healthSummaryChip(
                    '⚠️ Warn',
                    _healthResults.values.where((h) => h.status == _HealthStatus.warning).length,
                    Colors.orange,
                  ),
                  _healthSummaryChip(
                    '❌ Broken',
                    _healthResults.values.where((h) => h.status == _HealthStatus.broken).length,
                    Colors.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Filter
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Show all'),
                  selected: !_showBrokenOnly,
                  onSelected: (_) => setState(() => _showBrokenOnly = false),
                  selectedColor: AppTheme.primaryGold.withOpacity(0.35),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Broken only'),
                  selected: _showBrokenOnly,
                  onSelected: (_) => setState(() => _showBrokenOnly = true),
                  selectedColor: Colors.redAccent.withOpacity(0.35),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Results list
            ..._healthResults.entries
                .where((e) => !_showBrokenOnly || e.value.status != _HealthStatus.ok)
                .map((e) => _buildHealthResultTile(e.key, e.value)),
          ],
        ],
      ),
    );
  }

  Widget _healthSummaryChip(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildHealthResultTile(String key, _ChannelHealthStatus health) {
    final color = switch (health.status) {
      _HealthStatus.ok => Colors.green,
      _HealthStatus.warning => Colors.orange,
      _HealthStatus.broken => Colors.redAccent,
    };
    final icon = switch (health.status) {
      _HealthStatus.ok => Icons.check_circle_rounded,
      _HealthStatus.warning => Icons.warning_rounded,
      _HealthStatus.broken => Icons.error_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: health.status != _HealthStatus.ok
              ? () async {
                  // Fetch the latest data for this channel and open edit dialog.
                  final snap = await _playlistRef.child(key).get();
                  if (snap.value is Map && mounted) {
                    _showEditChannelDialog(key, snap.value as Map);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        health.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        health.message,
                        style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                if (health.status != _HealthStatus.ok)
                  Icon(Icons.edit_rounded, size: 16, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Tab: Access (Groups + Login codes)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAccessTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withOpacity(0.35)],
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
              mainAxisSize: MainAxisSize.min,
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
                      return Text('No saved groups', style: TextStyle(color: Colors.white.withOpacity(0.35)));
                    }
                    final value = snapshot.data!.snapshot.value;
                    if (value is! Map || value.isEmpty) {
                      return Text('No saved groups', style: TextStyle(color: Colors.white.withOpacity(0.35)));
                    }
                    final entries = value.entries.toList()
                      ..sort((a, b) {
                        final an = (a.value is Map) ? '${(a.value as Map)['name']}' : '';
                        final bn = (b.value is Map) ? '${(b.value as Map)['name']}' : '';
                        return an.compareTo(bn);
                      });
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: entries.map((e) {
                        final m = e.value;
                        final label = (m is Map) ? '${m['name'] ?? e.key}' : '${e.key}';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentTeal.withOpacity(0.2),
                            child: Icon(Icons.folder_rounded, color: AppTheme.accentTeal.withOpacity(0.9)),
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
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Duration: ', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _durationChip('Day', _LoginDuration.day),
                            _durationChip('Week', _LoginDuration.week),
                            _durationChip('Month', _LoginDuration.month),
                            _durationChip('Year', _LoginDuration.year),
                            _durationChip('Never', _LoginDuration.never),
                          ],
                        ),
                      ),
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
                        style: TextStyle(color: Colors.white.withOpacity(0.35)),
                      );
                    }
                    final value = snapshot.data!.snapshot.value;
                    if (value is! Map || value.isEmpty) {
                      return Text(
                        'No codes — users cannot sign in.',
                        style: TextStyle(color: Colors.white.withOpacity(0.35)),
                      );
                    }
                    final entries = value.entries.toList()
                      ..sort((a, b) {
                        final ac = (a.value is Map) ? '${(a.value as Map)['code']}' : '';
                        final bc = (b.value is Map) ? '${(b.value as Map)['code']}' : '';
                        return ac.compareTo(bc);
                      });
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: entries.map((e) {
                        final m = e.value;
                        final code = (m is Map) ? '${m['code'] ?? e.key}' : '${e.key}';
                        final active = (m is Map) && m['active'] != false;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Material(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.key_rounded, color: AppTheme.primaryGold.withOpacity(0.8), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(
                                          _formatExpiry(m is Map ? m['expiresAt'] : null),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _isCodeExpired(m is Map ? m['expiresAt'] : null)
                                                ? Colors.redAccent
                                                : Colors.white.withOpacity(0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: active,
                                    activeTrackColor: AppTheme.primaryGold.withOpacity(0.45),
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

  // ═══════════════════════════════════════════════════════════════
  //  Tab: Announcements (Broadcast)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _publishGlobalNotification() async {
    final title = _notifTitleController.text.trim();
    final body = _notifBodyController.text.trim();
    final img = _notifImageController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _snack('Title and Content are required', error: true);
      return;
    }

    try {
      final notifObj = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'image': img.isEmpty ? null : img,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      // 1. Broadcast to all active units
      await _notifBroadcastRef.set(notifObj);
      
      // 2. Save to history
      await _notifHistoryRef.push().set(notifObj);

      _notifTitleController.clear();
      _notifBodyController.clear();
      _notifImageController.clear();
      
      _snack('Notification broadcasted to all units!');
    } catch (e) {
      _snack('Broadcast failed: $e', error: true);
    }
  }

  Future<void> _clearActiveNotification() async {
    final ok = await _confirmDelete('Clear active alert?', 'All units will stop showing the current broadcast immediately.');
    if (!ok) return;
    try {
      await _notifBroadcastRef.remove();
      _snack('Active broadcast retracted');
    } catch (e) {
      _snack('Action failed: $e', error: true);
    }
  }

  Future<void> _deleteNotificationFromHistory(String key) async {
    try {
      await _notifHistoryRef.child(key).remove();
      _snack('Notification removed from history');
    } catch (e) {
      _snack('Delete failed: $e', error: true);
    }
  }

  Widget _buildAnnouncementTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withOpacity(0.35)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Part 1: Scrolling Announcement
          Text(
            'Scrolling Home Header',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          StreamBuilder<DatabaseEvent>(
            stream: _announcementRef.onValue,
            builder: (context, snapshot) {
              final data = snapshot.data?.snapshot.value as Map? ?? {};
              final currentText = '${data['text'] ?? ''}';
              final active = data['active'] == true;

              if (_announcementController.text != currentText && !_announcementController.selection.isValid) {
                _announcementController.text = currentText;
              }

              return _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sheetField(
                      _announcementController,
                      'Announcement text',
                      Icons.chat_bubble_outline_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            active ? 'Live and scrolling' : 'Currently hidden',
                            style: TextStyle(
                              fontSize: 12,
                              color: active ? AppTheme.accentTeal : Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: active,
                          activeTrackColor: AppTheme.accentTeal.withOpacity(0.45),
                          onChanged: (val) {
                            _announcementRef.update({'active': val});
                          },
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            final txt = _announcementController.text.trim();
                            await _announcementRef.update({'text': txt});
                            _snack('Announcement updated');
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Update'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Part 2: Notification Studio
          Text(
            'Notification Studio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Push alerts directly to users\' screens. Users only see each one once.',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sheetField(_notifTitleController, 'Message Title', Icons.title_rounded),
                const SizedBox(height: 12),
                _sheetField(_notifBodyController, 'Body Content', Icons.message_rounded, maxLines: 3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _sheetField(_notifImageController, 'Image URL (optional)', Icons.image_rounded)),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () => _pickLogoInto(_notifImageController),
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _publishGlobalNotification,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Publish Broadcast'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearActiveNotification,
                        icon: const Icon(Icons.backspace_rounded),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Part 3: History
          Text(
            'Broadcast History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          StreamBuilder<DatabaseEvent>(
            stream: _notifHistoryRef.onValue,
            builder: (context, snapshot) {
              final val = snapshot.data?.snapshot.value;
              if (val == null || val is! Map) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Opacity(opacity: 0.4, child: Text('No previous broadcasts'))),
                );
              }
              final items = val.entries.toList()
                ..sort((a, b) => (b.value['timestamp'] ?? '').compareTo(a.value['timestamp'] ?? ''));

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final k = items[i].key;
                  final v = items[i].value;
                  final ts = DateTime.tryParse(v['timestamp'] ?? '')?.toLocal();
                  final dateStr = ts != null ? '${ts.day}/${ts.month} ${ts.hour}:${ts.minute}' : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (v['image'] != null)
                          Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(image: NetworkImage(v['image']), fit: BoxFit.cover),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(v['body'] ?? '', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(dateStr, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.3))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteNotificationFromHistory(k),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Tab: Movies
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMoviesTab() {
    return StreamBuilder<DatabaseEvent>(
      stream: _playlistRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
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
                      label: const Text('Add New Movie'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
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

// ═══════════════════════════════════════════════════════════════════
//  Helper types
// ═══════════════════════════════════════════════════════════════════

enum _HealthStatus { ok, warning, broken }

class _ChannelHealthStatus {
  final String name;
  final String url;
  final _HealthStatus status;
  final String message;

  _ChannelHealthStatus({
    required this.name,
    required this.url,
    required this.status,
    required this.message,
  });
}

/// Keeps admin [TabBarView] pages alive when switching tabs (avoids grey flicker / rebuild races).
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
