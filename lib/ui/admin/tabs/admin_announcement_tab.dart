import 'package:flutter/material.dart';
part of '../admin_screen.dart';

extension _AdminAnnouncementTabExt on _AdminScreenState {
  Widget _buildAnnouncementTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withValues(alpha: 0.35)],
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
                              color: active ? AppTheme.accentTeal : Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: active,
                          activeTrackColor: AppTheme.accentTeal.withValues(alpha: 0.45),
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
                            backgroundColor: Theme.of(context).primaryColor,
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
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
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
                      color: Colors.white.withValues(alpha: 0.04),
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
                              Text(v['body'] ?? '', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(dateStr, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.3))),
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



  Future<void> _publishGlobalNotification() async {
    final title = _notifTitleController.text.trim();
    final body = _notifBodyController.text.trim();
    final img = _notifImageController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _snack('Title and Content are required', error: true);
      return;
    }

    final notifObj = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'image': img.isEmpty ? null : img,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    bool pushSent = false;

    // 1. Send FCM push notification first (works even if DB write fails)
    try {
      await NotificationService().sendPushNotification(
        title: title,
        body: body,
        imageUrl: img.isNotEmpty ? img : null,
      );
      pushSent = true;
    } catch (e) {
      debugPrint('FCM error: $e');
    }

    // 2. Best-effort PocketBase history save (silently ignore 403 errors)
    try { await _notifBroadcastRef.set(notifObj); } catch (e) { debugPrint('Caught error in admin_announcement_tab.dart: $e'); }
    try { await _notifHistoryRef.push().set(notifObj); } catch (e) { debugPrint('Caught error in admin_announcement_tab.dart: $e'); }

    _notifTitleController.clear();
    _notifBodyController.clear();
    _notifImageController.clear();

    _snack(pushSent ? 'Push sent to all devices! 🎉' : 'Broadcast saved locally');
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


}
