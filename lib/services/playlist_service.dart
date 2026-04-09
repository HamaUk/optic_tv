import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Channel {
  final String name;
  final String url;
  final String group;
  final String? logo;

  Channel({
    required this.name,
    required this.url,
    this.group = 'General',
    this.logo,
  });

  factory Channel.fromMap(Map<dynamic, dynamic> map) {
    return Channel(
      name: map['name'] ?? 'Unknown',
      url: map['url'] ?? '',
      group: map['group'] ?? map['category'] ?? 'General',
      logo: map['logo'] ?? map['icon_url'],
    );
  }
}

// Provider to stream channels from Firebase Realtime Database
final channelsProvider = StreamProvider<List<Channel>>((ref) {
  // Listening to the 'sync/global/managedPlaylist' path as requested
  final dbRef = FirebaseDatabase.instance.ref('sync/global/managedPlaylist');
  
  return dbRef.onValue.map((event) {
    final data = event.snapshot.value;
    if (data == null) return [];

    if (data is List) {
      return data
          .where((item) => item != null)
          .map((item) => Channel.fromMap(item as Map))
          .toList();
    } else if (data is Map) {
      return data.values
          .map((item) => Channel.fromMap(item as Map))
          .toList();
    }
    return [];
  });
});
