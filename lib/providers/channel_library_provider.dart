import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/playlist_service.dart';

const _kFavoritesJson = 'library_favorites_v1';
const _kRecentJson = 'library_recent_v1';

List<Channel> _decodeChannelList(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final out = <Channel>[];
    for (final item in decoded) {
      if (item is Map) {
        out.add(Channel.fromMap(item));
      }
    }
    return out;
  } catch (_) {
    return [];
  }
}

String _encodeChannelList(List<Channel> list) {
  return jsonEncode(
    list
        .map(
          (c) => {
            'name': c.name,
            'url': c.url,
            'group': c.group,
            'logo': c.logo,
          },
        )
        .toList(),
  );
}

/// Starred channels (device-local), similar to KRD-style favorites.
class FavoritesNotifier extends Notifier<List<Channel>> {
  @override
  List<Channel> build() {
    Future.microtask(_reload);
    return [];
  }

  Future<void> _reload() async {
    final p = await SharedPreferences.getInstance();
    state = _decodeChannelList(p.getString(_kFavoritesJson));
  }

  bool isFavorite(Channel c) => state.any((e) => e.url == c.url);

  Future<void> toggle(Channel c) async {
    var next = List<Channel>.from(state);
    final i = next.indexWhere((e) => e.url == c.url);
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next = [c, ...next];
    }
    if (next.length > 200) next = next.sublist(0, 200);
    state = next;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFavoritesJson, _encodeChannelList(next));
  }

  Future<void> clearAll() async {
    state = [];
    final p = await SharedPreferences.getInstance();
    await p.remove(_kFavoritesJson);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Channel>>(FavoritesNotifier.new);

/// Recently opened channels (most recent first).
class RecentChannelsNotifier extends Notifier<List<Channel>> {
  @override
  List<Channel> build() {
    Future.microtask(_reload);
    return [];
  }

  Future<void> _reload() async {
    final p = await SharedPreferences.getInstance();
    state = _decodeChannelList(p.getString(_kRecentJson));
  }

  Future<void> record(Channel c) async {
    if (c.url.isEmpty) return;
    var next = List<Channel>.from(state);
    next.removeWhere((e) => e.url == c.url);
    next.insert(0, c);
    if (next.length > 40) next = next.sublist(0, 40);
    state = next;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRecentJson, _encodeChannelList(next));
  }

  Future<void> clearAll() async {
    state = [];
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRecentJson);
  }
}

final recentChannelsProvider = NotifierProvider<RecentChannelsNotifier, List<Channel>>(RecentChannelsNotifier.new);
