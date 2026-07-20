import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pocketbase_service.dart';
import 'pocketbase_database_mock.dart';
import '../services/optic_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kChannelCache = 'channels_cache_v1';

class Channel {
  final String pbId;
  final String name;
  final String url;
  final String group;
  final String? logo;
  final String? backdrop;
  final String? subtitleUrl;
  final String? description;
  final String type; // 'live' or 'movie'
  final bool featured;
  final int order;
  final int featuredOrder;
  final String? userAgent;
  final String? url2;
  final String? url2Name;
  final String? url3;
  final String? url3Name;
  final String? drmScheme;
  final String? drmLicense;
  final String? referer;
  final String? url2DrmScheme;
  final String? url2DrmLicense;
  final String? url2Referer;
  final String? url2UserAgent;
  final String? url3DrmScheme;
  final String? url3DrmLicense;
  final String? url3Referer;
  final String? url3UserAgent;

  Channel({
    this.pbId = '',
    required this.name,
    required this.url,
    this.group = 'General',
    this.logo,
    this.backdrop,
    this.subtitleUrl,
    this.description,
    this.type = 'live',
    this.featured = false,
    this.order = 999999,
    this.featuredOrder = 999999,
    this.userAgent,
    this.url2,
    this.url2Name,
    this.url3,
    this.url3Name,
    this.drmScheme,
    this.drmLicense,
    this.referer,
    this.url2DrmScheme,
    this.url2DrmLicense,
    this.url2Referer,
    this.url2UserAgent,
    this.url3DrmScheme,
    this.url3DrmLicense,
    this.url3Referer,
    this.url3UserAgent,
  });

  static String decrypt(String b64Text) {
    return b64Text;
  }

  static String encrypt(String plainText) {
    return plainText;
  }

  static int _parseInt(dynamic value, [int defaultValue = 999999]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is num) return value == 1;
    return false;
  }

  factory Channel.fromMap(Map<dynamic, dynamic> map) {
    return Channel(
      pbId: map['id']?.toString() ?? map['pbId']?.toString() ?? '',
      name: map['name'] ?? 'Unknown',
      url: decrypt(map['url']?.toString() ?? ''),
      group: map['group'] ?? map['category'] ?? 'General',
      logo: map['logo'] ?? map['icon_url'],
      backdrop: map['backdrop'] as String?,
      subtitleUrl: map['subtitleUrl'] as String?,
      description: map['description'] as String?,
      type: map['type'] as String? ?? 'live',
      featured: _parseBool(map['featured']),
      order: _parseInt(map['order']),
      featuredOrder: _parseInt(map['featured_order']),
      userAgent: map['userAgent'] as String? ?? map['user_agent'] as String?,
      url2: map['url2'] != null ? decrypt(map['url2'] as String) : null,
      url2Name: map['url2Name'] as String?,
      url3: map['url3'] != null ? decrypt(map['url3'] as String) : null,
      url3Name: map['url3Name'] as String?,
      drmScheme: map['drmScheme'] as String?,
      drmLicense: map['drmLicense'] as String?,
      referer: map['referer'] as String?,
      url2DrmScheme: map['url2DrmScheme'] as String?,
      url2DrmLicense: map['url2DrmLicense'] as String?,
      url2Referer: map['url2Referer'] as String?,
      url2UserAgent: map['url2UserAgent'] as String?,
      url3DrmScheme: map['url3DrmScheme'] as String?,
      url3DrmLicense: map['url3DrmLicense'] as String?,
      url3Referer: map['url3Referer'] as String?,
      url3UserAgent: map['url3UserAgent'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'pbId': pbId,
    'name': name,
    'url': url,
    'group': group,
    'logo': logo,
    'backdrop': backdrop,
    'subtitleUrl': subtitleUrl,
    'description': description,
    'type': type,
    'featured': featured,
    'order': order,
    'featured_order': featuredOrder,
    'userAgent': userAgent,
    'url2': url2,
    'url2Name': url2Name,
    'url3': url3,
    'url3Name': url3Name,
    'drmScheme': drmScheme,
    'drmLicense': drmLicense,
    'referer': referer,
    'url2DrmScheme': url2DrmScheme,
    'url2DrmLicense': url2DrmLicense,
    'url2Referer': url2Referer,
    'url2UserAgent': url2UserAgent,
    'url3DrmScheme': url3DrmScheme,
    'url3DrmLicense': url3DrmLicense,
    'url3Referer': url3Referer,
    'url3UserAgent': url3UserAgent,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel && name == other.name && url == other.url;

  @override
  int get hashCode => Object.hash(name, url);
}

List<Channel> _parseChannelData(dynamic data) {
  List<Channel> channels = [];
  if (data == null) return channels;
  if (data is List) {
    channels = data
        .where((item) => item != null)
        .map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          if (!m.containsKey('pbId') && m.containsKey('id')) m['pbId'] = m['id'];
          return Channel.fromMap(m);
        })
        .toList();
  } else if (data is Map) {
    channels = data.entries
        .map((entry) {
          final m = Map<String, dynamic>.from(entry.value as Map);
          m['pbId'] = entry.key; // The key is the ID in Maps
          return Channel.fromMap(m);
        })
        .toList();
  }
  channels.sort((a, b) {
    if (a.order != b.order) return a.order.compareTo(b.order);
    return 0; // preserve original API list order if order fields are identical
  });
  return channels;
}

Future<List<Channel>> loadCachedChannels() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kChannelCache);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Channel.fromMap(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

Future<void> _saveChannelCache(List<Channel> channels) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kChannelCache,
      jsonEncode(channels.map((c) => c.toMap()).toList()),
    );
  } catch (e) { debugPrint('Caught error in playlist_service.dart: $e'); }
}

// ─────────────────────────────────────────────────────────────────────────────
// Instant-start: emits cached channels from SharedPreferences IMMEDIATELY
// (no network needed), then updates when PocketBase data arrives.
// Dashboard appears in <100 ms on every launch after the first.
// ─────────────────────────────────────────────────────────────────────────────
final channelsProvider = StreamProvider<List<Channel>>((ref) {
  final controller = StreamController<List<Channel>>();

  // Step 1 — emit cached channels instantly (offline-first)
  loadCachedChannels().then((cached) {
    if (!controller.isClosed && cached.isNotEmpty) {
      controller.add(cached);
    }
  });

  void fetchChannels() async {
    try {
      final response = await pb.send('/api/kobani-init');
      final List<dynamic> data = response as List<dynamic>;

      // The custom /api/kobani-init route misses the 'order' field.
      // We fetch it natively and merge it back into the payload.
      final rawRecords = await pb.collection('managedPlaylist').getFullList(fields: 'id,name,order,url');
      final orderMap = { for (var r in rawRecords) r.getStringValue('url').trim(): r.getIntValue('order', 999999) };
      
      for (var item in data) {
        if (item is Map) {
          final url = item['url']?.toString().trim();
          if (url != null && orderMap.containsKey(url)) {
            item['order'] = orderMap[url];
          } else {
            // Fallback to name if url matching fails
            final name = item['name']?.toString().trim();
            final fallbackMap = { for (var r in rawRecords) r.getStringValue('name').trim(): r.getIntValue('order', 999999) };
            if (name != null && fallbackMap.containsKey(name)) {
              item['order'] = fallbackMap[name];
            }
          }
        }
      }

      final channels = _parseChannelData(data);
      if (!controller.isClosed) {
        controller.add(channels);
        _saveChannelCache(channels);
      }
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  // Step 2 — fetch from encrypted route
  fetchChannels();

  // Listen to custom mock events (local app changes)
  final sub = PocketBaseDatabase.instance.ref('managedPlaylist').onValue.listen((_) {
    fetchChannels();
  });

  // Listen to NATIVE PocketBase realtime events (for web panel changes)
  try {
    pb.collection('managedPlaylist').subscribe('*', (e) {
      fetchChannels();
    });
  } catch (e) { debugPrint('Caught error in playlist_service.dart: $e'); }

  ref.onDispose(() {
    sub.cancel();
    try { pb.collection('managedPlaylist').unsubscribe('*'); } catch (e) { debugPrint('Caught error in playlist_service.dart: $e'); }
    controller.close();
  });

  return controller.stream;
});

class ChannelGroup {
  final String key;
  final String name;
  final int order;

  ChannelGroup({
    required this.key,
    required this.name,
    this.order = 999999,
  });

  factory ChannelGroup.fromMap(String key, Map<dynamic, dynamic> map) {
    int parsedOrder = 999999;
    final orderVal = map['order'];
    if (orderVal is int) parsedOrder = orderVal;
    else if (orderVal is double) parsedOrder = orderVal.toInt();
    else if (orderVal is String) parsedOrder = int.tryParse(orderVal) ?? 999999;

    return ChannelGroup(
      key: key,
      name: map['name'] ?? 'Unknown',
      order: parsedOrder,
    );
  }
}

final groupsProvider = StreamProvider<List<ChannelGroup>>((ref) {
  final controller = StreamController<List<ChannelGroup>>();

  void fetchGroups() async {
    try {
      final records = await pb.collection('channelGroups').getFullList();
      final list = records.map((e) {
        return ChannelGroup.fromMap(e.id, e.toJson());
      }).toList();

      list.sort((a, b) {
        if (a.order != b.order) return a.order.compareTo(b.order);
        return 0;
      });

      if (!controller.isClosed) controller.add(list);
    } catch (_) {
      if (!controller.isClosed) controller.add([]);
    }
  }

  fetchGroups();

  final sub = PocketBaseDatabase.instance.ref('channelGroups').onValue.listen((_) {
    fetchGroups();
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});


// ExoPlayer-backed player provider (replaces the former media_kit/mpv provider)
final playerProvider = Provider<OpticPlayer>((ref) {
  final player = OpticPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

