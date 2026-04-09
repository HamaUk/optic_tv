import 'dart:async';
import 'package:dio/dio.dart';
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Channel {
  final String name;
  final String url;
  final String? logo;
  final String group;

  Channel({
    required this.name,
    required this.url,
    this.logo,
    required this.group,
  });
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, AsyncValue<List<Channel>>>((ref) {
  return PlaylistNotifier();
});

class PlaylistNotifier extends StateNotifier<AsyncValue<List<Channel>>> {
  PlaylistNotifier() : super(const AsyncValue.loading());

  Future<void> loadPlaylist(String url) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await Dio().get(url);
      final m3uContent = response.data.toString();
      
      // Advanced parsing using the m3u_nullsafe library
      final m3u = await M3uParser.parse(m3uContent);
      
      final channels = m3u.map((entry) {
        return Channel(
          name: entry.title ?? 'Unknown Channel',
          url: entry.link ?? '',
          logo: entry.attributes['tvg-logo'],
          group: entry.attributes['group-title'] ?? 'General',
        );
      }).toList();

      state = AsyncValue.data(channels);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
