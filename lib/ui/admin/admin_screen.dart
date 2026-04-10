import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const _playlistPath = 'sync/global/managedPlaylist';
  static const _groupsPath = 'sync/global/channelGroups';

  final _channelNameController = TextEditingController();
  final _channelUrlController = TextEditingController();
  final _channelGroupController = TextEditingController();
  final _channelLogoController = TextEditingController();
  final _newGroupController = TextEditingController();

  DatabaseReference get _playlistRef => FirebaseDatabase.instance.ref(_playlistPath);
  DatabaseReference get _groupsRef => FirebaseDatabase.instance.ref(_groupsPath);

  @override
  void dispose() {
    _channelNameController.dispose();
    _channelUrlController.dispose();
    _channelGroupController.dispose();
    _channelLogoController.dispose();
    _newGroupController.dispose();
    super.dispose();
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
    if (logo.isNotEmpty) {
      map['logo'] = logo;
    }
    return map;
  }

  Future<void> _addChannel() async {
    final name = _channelNameController.text.trim();
    final url = _channelUrlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel name and stream URL are required')),
      );
      return;
    }

    try {
      final group = _channelGroupController.text.trim();
      final logo = _channelLogoController.text.trim();
      final newChannelRef = _playlistRef.push();
      await newChannelRef.set(_channelPayload(name: name, url: url, group: group, logo: logo));

      _channelNameController.clear();
      _channelUrlController.clear();
      _channelGroupController.clear();
      _channelLogoController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel saved to Realtime Database')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding channel: $e')),
        );
      }
    }
  }

  Future<void> _addGroup() async {
    final name = _newGroupController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name')),
      );
      return;
    }

    try {
      await _groupsRef.push().set({'name': name});
      _newGroupController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding group: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e')),
        );
      }
    }
  }

  Future<void> _deleteChannel(String key) async {
    try {
      await _playlistRef.child(key).remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  Future<void> _deleteGroup(String key) async {
    try {
      await _groupsRef.child(key).remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group removed from list')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting group: $e')),
        );
      }
    }
  }

  void _showEditChannelDialog(String key, Map<dynamic, dynamic> raw) {
    final nameCtrl = TextEditingController(text: '${raw['name'] ?? ''}');
    final urlCtrl = TextEditingController(text: '${raw['url'] ?? ''}');
    final groupCtrl = TextEditingController(text: '${raw['group'] ?? raw['category'] ?? 'General'}');
    final logoCtrl = TextEditingController(text: '${raw['logo'] ?? raw['icon_url'] ?? ''}');

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D26),
          title: const Text('Edit channel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Name'),
                const SizedBox(height: 12),
                _dialogField(urlCtrl, 'Stream URL'),
                const SizedBox(height: 12),
                _dialogField(groupCtrl, 'Group'),
                const SizedBox(height: 12),
                _dialogField(logoCtrl, 'Logo URL (optional)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                for (final c in [nameCtrl, urlCtrl, groupCtrl, logoCtrl]) {
                  Future.microtask(c.dispose);
                }
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final name = nameCtrl.text.trim();
                final url = urlCtrl.text.trim();
                if (name.isEmpty || url.isEmpty) {
                  for (final c in [nameCtrl, urlCtrl, groupCtrl, logoCtrl]) {
                    Future.microtask(c.dispose);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and URL are required')),
                  );
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: label.contains('URL') ? 3 : 1,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildGroupQuickPick() {
    return StreamBuilder<DatabaseEvent>(
      stream: _groupsRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const SizedBox.shrink();
        }
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
            Text(
              'Tap to use a saved group',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: names
                  .map(
                    (n) => ActionChip(
                      label: Text(n),
                      onPressed: () => _channelGroupController.text = n,
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add channel',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_channelNameController, 'Channel name'),
                  const SizedBox(height: 16),
                  _buildTextField(_channelUrlController, 'Stream URL (M3U8)', maxLines: 3),
                  const SizedBox(height: 16),
                  _buildTextField(_channelGroupController, 'Group (e.g. Sports, Movies)'),
                  const SizedBox(height: 12),
                  _buildGroupQuickPick(),
                  const SizedBox(height: 16),
                  _buildTextField(_channelLogoController, 'Logo URL (optional)', maxLines: 2),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _addChannel,
                      child: const Text('Add channel'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const Text(
                    'Groups',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved groups appear as quick picks when adding or editing channels.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTextField(_newGroupController, 'New group name')),
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: _addGroup,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<DatabaseEvent>(
                    stream: _groupsRef.onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                        return Text(
                          'No saved groups yet.',
                          style: TextStyle(color: Colors.white.withOpacity(0.35)),
                        );
                      }
                      final value = snapshot.data!.snapshot.value;
                      if (value is! Map || value.isEmpty) {
                        return Text(
                          'No saved groups yet.',
                          style: TextStyle(color: Colors.white.withOpacity(0.35)),
                        );
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
                            dense: true,
                            title: Text(label),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteGroup('${e.key}'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Channels in database',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: StreamBuilder<DatabaseEvent>(
              stream: _playlistRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text('No channels yet'));
                }

                final raw = snapshot.data!.snapshot.value;
                List<MapEntry<dynamic, dynamic>> items;
                if (raw is Map) {
                  items = raw.entries.toList();
                } else if (raw is List) {
                  items = <MapEntry<dynamic, dynamic>>[];
                  for (var i = 0; i < raw.length; i++) {
                    final v = raw[i];
                    if (v is Map) items.add(MapEntry('$i', v));
                  }
                } else {
                  return const Center(child: Text('Unexpected playlist format'));
                }

                if (items.isEmpty) {
                  return const Center(child: Text('No channels yet'));
                }

                items.sort((a, b) {
                  final an = (a.value is Map) ? '${(a.value as Map)['name']}' : '';
                  final bn = (b.value is Map) ? '${(b.value as Map)['name']}' : '';
                  return an.compareTo(bn);
                });

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final entry = items[index];
                    final val = entry.value;
                    if (val is! Map) {
                      return const ListTile(title: Text('Invalid entry'));
                    }
                    final logo = val['logo'] ?? val['icon_url'];
                    return ListTile(
                      leading: logo != null && '$logo'.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                '$logo',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.tv),
                              ),
                            )
                          : const Icon(Icons.tv_outlined),
                      title: Text('${val['name'] ?? 'No name'}'),
                      subtitle: Text('${val['group'] ?? val['category'] ?? 'General'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditChannelDialog('${entry.key}', val),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteChannel('${entry.key}'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
