import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminUpdateTabExt on _AdminScreenState {
  Widget _buildUpdateTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update_rounded, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                Text('Update Manager', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
            const SizedBox(height: 4),
            Text('Push a beautiful update prompt to all users.', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
        const SizedBox(height: 24),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGlassTextField(controller: _updateApkUrlController, label: 'Update Link (Any URL)', icon: Icons.link_rounded),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Push Update Popup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('If ON, users will see the update popup immediately.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: _updateIsActive,
                activeThumbColor: Theme.of(context).primaryColor,
                onChanged: (v) => setAdminState(() => _updateIsActive = v),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _pushUpdate,
                icon: const Icon(Icons.send_rounded),
                label: const Text('PUSH UPDATE TO USERS'),
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        StreamBuilder(
          stream: _updateRef.onValue,
          builder: (context, snap) {
            final val = snap.data?.snapshot.value;
            if (val == null) return const Text('No active update.', style: TextStyle(color: Colors.white54));
            final map = val as Map;
            // PocketBase may store bool or string — handle both
            final isActive = map['active'] == true || map['active'] == 'true';
            final url = (map['url'] ?? '').toString();
            if (!isActive || url.isEmpty) return const Text('No active update.', style: TextStyle(color: Colors.white54));
            
            return _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Currently Active Update', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text('URL: $url', style: const TextStyle(color: Colors.white70)),
                  Text('Status: ACTIVE', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _updateRef.remove(),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('Remove Update'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                  )
                ],
              ),
            );
          }
        ),
      ],
    );
  }

  Future<void> _pushUpdate() async {
    await _updateRef.set({
      'url': _updateApkUrlController.text.trim(),
      'active': _updateIsActive,
    });
    _snack('Update published successfully!');
  }
}
