import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Channel {
  final String name;
  final String url;
  final String group;
  final String? logo;
  final String? backdrop;
  final bool featured;
  final int order;

  Channel({
    required this.name,
    required this.url,
    this.group = 'General',
    this.logo,
    this.backdrop,
    this.featured = false,
    this.order = 999999,
  });

  factory Channel.fromMap(Map<dynamic, dynamic> map) {
    return Channel(
      name: map['name'] ?? 'Unknown',
      url: map['url'] ?? '',
      group: map['group'] ?? map['category'] ?? 'General',
      logo: map['logo'] ?? map['icon_url'],
      backdrop: map['backdrop'] as String?,
      featured: map['featured'] == true,
      order: map['order'] is int ? map['order'] as int : 999999,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel && name == other.name && url == other.url;

  @override
  int get hashCode => Object.hash(name, url);
}

// Provider to stream channels from Firebase Realtime Database
final channelsProvider = StreamProvider<List<Channel>>((ref) {
  // Listening to the 'sync/global/managedPlaylist' path as requested
  final dbRef = FirebaseDatabase.instance.ref('sync/global/managedPlaylist');

  return dbRef.onValue.map((event) {
    List<Channel> remoteChannels = [];
    final data = event.snapshot.value;

    if (data != null) {
      if (data is List) {
        remoteChannels = data
            .where((item) => item != null)
            .map((item) => Channel.fromMap(item as Map))
            .toList();
      } else if (data is Map) {
        remoteChannels = data.values
            .map((item) => Channel.fromMap(item as Map))
            .toList();
      }
    }

    // Sort by order first, then by name alphabetically as fallback.
    remoteChannels.sort((a, b) {
      if (a.order != b.order) return a.order.compareTo(b.order);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return remoteChannels;
  });
});
