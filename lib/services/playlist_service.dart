import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kChannelCache = 'channels_cache_v1';

class Channel {
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

  Channel({
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
  });

  factory Channel.fromMap(Map<dynamic, dynamic> map) {
    return Channel(
      name: map['name'] ?? 'Unknown',
      url: map['url'] ?? '',
      group: map['group'] ?? map['category'] ?? 'General',
      logo: map['logo'] ?? map['icon_url'],
      backdrop: map['backdrop'] as String?,
      subtitleUrl: map['subtitleUrl'] as String?,
      description: map['description'] as String?,
      type: map['type'] as String? ?? 'live',
      featured: map['featured'] == true,
      order: map['order'] is int ? map['order'] as int : 999999,
      featuredOrder: map['featured_order'] is int ? map['featured_order'] as int : 999999,
    );
  }

  Map<String, dynamic> toMap() => {
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
        .map((item) => Channel.fromMap(item as Map))
        .toList();
  } else if (data is Map) {
    channels = data.values
        .map((item) => Channel.fromMap(item as Map))
        .toList();
  }
  channels.sort((a, b) {
    if (a.order != b.order) return a.order.compareTo(b.order);
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return channels;
}

Future<List<Channel>> _loadCachedChannels() async {
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
    _prefetchLogos(channels); // Kick off silent aggressive prefetching
  } catch (_) {}
}

bool _isPrefetching = false;
Future<void> _prefetchLogos(List<Channel> channels) async {
  if (_isPrefetching) return;
  _isPrefetching = true;
  
  try {
    final cacheManager = DefaultCacheManager();
    final urlsToFetch = channels
        .map((c) => c.logo)
        .where((logo) => logo != null && logo.isNotEmpty)
        .cast<String>()
        .take(500) // Limit to top 500 to save bandwidth
        .toList();

    int concurrency = 0;
    for (final url in urlsToFetch) {
      // Throttle concurrency to avoid choking the network
      while (concurrency >= 5) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      final fileInfo = await cacheManager.getFileFromMemory(url);
      if (fileInfo == null) {
        concurrency++;
        cacheManager.downloadFile(url).then((_) {
          concurrency--;
        }).catchError((_) {
          concurrency--;
        });
      }
    }
  } catch (e) {
    debugPrint('Logo prefetch error: $e');
  } finally {
    _isPrefetching = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Instant-start: emits cached channels from SharedPreferences IMMEDIATELY
// (no network needed), then updates when Firebase stream arrives.
// Dashboard appears in <100 ms on every launch after the first.
// ─────────────────────────────────────────────────────────────────────────────
final channelsProvider = StreamProvider<List<Channel>>((ref) {
  final controller = StreamController<List<Channel>>();

  // Step 1 — emit cached channels instantly (offline-first)
  _loadCachedChannels().then((cached) {
    if (!controller.isClosed && cached.isNotEmpty) {
      controller.add(cached);
    }
  });

  // Step 2 — subscribe to Firebase; update UI and save new cache when it arrives
  final dbRef = FirebaseDatabase.instance.ref('sync/global/managedPlaylist');
  final sub = dbRef.onValue.listen(
    (event) {
      final channels = _parseChannelData(event.snapshot.value);
      if (!controller.isClosed) {
        controller.add(channels);
        _saveChannelCache(channels); // persist for next launch
      }
    },
    onError: (Object e) {
      if (!controller.isClosed) controller.addError(e);
    },
  );

  ref.onDispose(() {
    sub.cancel();
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
    return ChannelGroup(
      key: key,
      name: map['name'] ?? 'Unknown',
      order: map['order'] is int ? map['order'] as int : 999999,
    );
  }
}

final groupsProvider = StreamProvider<List<ChannelGroup>>((ref) {
  final dbRef = FirebaseDatabase.instance.ref('sync/global/channelGroups');

  return dbRef.onValue.map((event) {
    final data = event.snapshot.value;
    if (data is! Map) return [];

    final list = data.entries.map((e) {
      return ChannelGroup.fromMap(e.key.toString(), e.value as Map);
    }).toList();

    list.sort((a, b) {
      if (a.order != b.order) return a.order.compareTo(b.order);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  });
});

// TV Media Engine Providers
final playerProvider = Provider<Player>((ref) => Player());
final videoControllerProvider = Provider<VideoController>((ref) {
  final player = ref.watch(playerProvider);
  return VideoController(player);
});
