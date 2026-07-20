import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminAccessTabExt on _AdminScreenState {
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
                      return Text('No saved groups', style: TextStyle(color: Colors.white.withValues(alpha: 0.35)));
                    }
                    final value = snapshot.data!.snapshot.value;
                    if (value is! Map || value.isEmpty) {
                      return Text('No saved groups', style: TextStyle(color: Colors.white.withValues(alpha: 0.35)));
                    }
                    final entries = value.entries.toList()
                      ..sort((a, b) {
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
                    return ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) => _moveGroup(entries, oldIndex, newIndex),
                      children: entries.map((e) {
                        final m = e.value;
                        final label = (m is Map) ? '${m['name'] ?? e.key}' : '${e.key}';
                        return ListTile(
                          key: ValueKey(e.key),
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.2),
                            child: Icon(Icons.folder_rounded, color: AppTheme.accentTeal.withValues(alpha: 0.9)),
                          ),
                          title: Text(label),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.drag_indicator_rounded, color: Colors.white24),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () => _deleteGroup('${e.key}', label),
                              ),
                            ],
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
                    Text('Duration: ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
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
                        'No codes ÔÇö users cannot sign in.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                      );
                    }
                    final value = snapshot.data!.snapshot.value;
                    if (value is! Map || value.isEmpty) {
                      return Text(
                        'No codes ÔÇö users cannot sign in.',
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  Icon(Icons.key_rounded, color: Theme.of(context).primaryColor.withValues(alpha: 0.8), size: 20),
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
                                                : Colors.white.withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: active,
                                    activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.45),
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


  Future<void> _moveGroup(
    List<MapEntry<dynamic, dynamic>> groupEntries,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = groupEntries.removeAt(oldIndex);
    groupEntries.insert(newIndex, item);

    final updates = <String, dynamic>{};
    for (var i = 0; i < groupEntries.length; i++) {
      updates['${groupEntries[i].key}/order'] = i;
    }
    try {
      await _groupsRef.update(updates);
    } catch (e) {
      _snack('Group reorder failed: $e', error: true);
    }
  }


}
