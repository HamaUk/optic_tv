import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/playlist_service.dart';

const _kGroupSort = 'local_group_sort_v1';
const _kChannelSort = 'local_channel_sort_v1';

class LocalSortData {
  final Map<String, int> groupOrder;
  final Map<String, int> channelOrder;

  LocalSortData({
    required this.groupOrder,
    required this.channelOrder,
  });

  LocalSortData copyWith({
    Map<String, int>? groupOrder,
    Map<String, int>? channelOrder,
  }) {
    return LocalSortData(
      groupOrder: groupOrder ?? this.groupOrder,
      channelOrder: channelOrder ?? this.channelOrder,
    );
  }
}

class LocalSortNotifier extends Notifier<LocalSortData> {
  @override
  LocalSortData build() {
    Future.microtask(_reload);
    return LocalSortData(groupOrder: {}, channelOrder: {});
  }

  Future<void> _reload() async {
    final prefs = await SharedPreferences.getInstance();
    
    final groupRaw = prefs.getString(_kGroupSort);
    final groupMap = <String, int>{};
    if (groupRaw != null && groupRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(groupRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          groupMap[entry.key] = entry.value as int;
        }
      } catch (e) { debugPrint('Caught error in local_sort_provider.dart: $e'); }
    }

    final channelRaw = prefs.getString(_kChannelSort);
    final channelMap = <String, int>{};
    if (channelRaw != null && channelRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(channelRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          channelMap[entry.key] = entry.value as int;
        }
      } catch (e) { debugPrint('Caught error in local_sort_provider.dart: $e'); }
    }

    state = LocalSortData(groupOrder: groupMap, channelOrder: channelMap);
  }

  Future<void> saveGroupOrder(List<ChannelGroup> orderedGroups) async {
    final newMap = <String, int>{};
    for (int i = 0; i < orderedGroups.length; i++) {
      newMap[orderedGroups[i].name] = i;
    }
    state = state.copyWith(groupOrder: newMap);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGroupSort, jsonEncode(newMap));
  }

  Future<void> saveChannelOrder(List<Channel> orderedChannels) async {
    final newMap = Map<String, int>.from(state.channelOrder);
    for (int i = 0; i < orderedChannels.length; i++) {
      final key = orderedChannels[i].url.isNotEmpty ? orderedChannels[i].url : orderedChannels[i].name;
      newMap[key] = i;
    }
    state = state.copyWith(channelOrder: newMap);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kChannelSort, jsonEncode(newMap));
  }
  
  Future<void> resetAll() async {
    state = LocalSortData(groupOrder: {}, channelOrder: {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGroupSort);
    await prefs.remove(_kChannelSort);
  }
}

final localSortProvider = NotifierProvider<LocalSortNotifier, LocalSortData>(LocalSortNotifier.new);

final sortedGroupsProvider = Provider<AsyncValue<List<ChannelGroup>>>((ref) {
  final groupsAsync = ref.watch(groupsProvider);
  final sortData = ref.watch(localSortProvider);

  return groupsAsync.whenData((groups) {
    if (sortData.groupOrder.isEmpty) return groups;
    
    final sorted = List<ChannelGroup>.from(groups);
    sorted.sort((a, b) {
      final orderA = sortData.groupOrder[a.name] ?? a.order;
      final orderB = sortData.groupOrder[b.name] ?? b.order;
      return orderA.compareTo(orderB);
    });
    return sorted;
  });
});

final sortedChannelsProvider = Provider<AsyncValue<List<Channel>>>((ref) {
  final channelsAsync = ref.watch(channelsProvider);
  final sortData = ref.watch(localSortProvider);

  return channelsAsync.whenData((channels) {
    if (sortData.channelOrder.isEmpty) return channels;
    
    final sorted = List<Channel>.from(channels);
    sorted.sort((a, b) {
      final keyA = a.url.isNotEmpty ? a.url : a.name;
      final keyB = b.url.isNotEmpty ? b.url : b.name;
      final orderA = sortData.channelOrder[keyA] ?? a.order;
      final orderB = sortData.channelOrder[keyB] ?? b.order;
      return orderA.compareTo(orderB);
    });
    return sorted;
  });
});
