import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../providers/app_locale_provider.dart';
import '../../../providers/ui_settings_provider.dart';
import '../../../providers/local_sort_provider.dart';
import '../../../services/playlist_service.dart';
import '../../../l10n/app_strings.dart';

class ManualSortSettingsPage extends ConsumerStatefulWidget {
  const ManualSortSettingsPage({super.key});

  @override
  ConsumerState<ManualSortSettingsPage> createState() => _ManualSortSettingsPageState();
}

class _ManualSortSettingsPageState extends ConsumerState<ManualSortSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onReorderGroups(int oldIndex, int newIndex, List<ChannelGroup> groups) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = groups.removeAt(oldIndex);
    groups.insert(newIndex, item);
    ref.read(localSortProvider.notifier).saveGroupOrder(groups);
  }

  void _onReorderChannels(int oldIndex, int newIndex, List<Channel> channelsInGroup) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = channelsInGroup.removeAt(oldIndex);
    channelsInGroup.insert(newIndex, item);
    ref.read(localSortProvider.notifier).saveChannelOrder(channelsInGroup);
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);
    final uiSettings = ref.watch(appUiSettingsProvider).asData?.value ?? const AppSettingsData();

    final groupsAsync = ref.watch(sortedGroupsProvider);
    final channelsAsync = ref.watch(sortedChannelsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              title: Text(s.manualSortTitle, style: AppTheme.withRabarIfKurdish(uiLocale, const TextStyle(fontWeight: FontWeight.w900, color: Colors.white))),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.white54,
                labelStyle: AppTheme.withRabarIfKurdish(uiLocale, const TextStyle(fontWeight: FontWeight.bold)),
                tabs: [
                  Tab(text: s.manualSortGroupsTab),
                  Tab(text: s.manualSortChannelsTab),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(localSortProvider.notifier).resetAll();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.manualSortResetMessage, style: AppTheme.withRabarIfKurdish(uiLocale, const TextStyle()))));
                  },
                  child: Text(s.manualSortReset, style: AppTheme.withRabarIfKurdish(uiLocale, const TextStyle(color: Colors.redAccent))),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.settingsBackdropGradient(uiSettings.gradientPreset),
        ),
        child: SafeArea(
          bottom: false,
          child: TabBarView(
            controller: _tabController,
            children: [
              // GROUPS TAB
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) return Center(child: Text(s.manualSortNoGroups, style: AppTheme.withRabarIfKurdish(uiLocale, const TextStyle(color: Colors.white54))));
                  // Use a local copy to allow immediate drag-drop visual update before provider rebuilds
                  final localGroups = List<ChannelGroup>.from(groups);
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: localGroups.length,
                    onReorder: (oldIdx, newIdx) => _onReorderGroups(oldIdx, newIdx, localGroups),
                    proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
                    itemBuilder: (context, index) {
                      final g = localGroups[index];
                      return Container(
                        key: ValueKey(g.name),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.drag_indicator_rounded, color: Colors.white54),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading groups')),
              ),

              // CHANNELS TAB
              channelsAsync.when(
                data: (channels) {
                  if (channels.isEmpty) return Center(child: Text(s.noChannels, style: AppTheme.withRabarIfKurdish(uiLocale, const TextStyle(color: Colors.white54))));
                  
                  final groupNames = channels.map((c) => c.group).toSet().toList();
                  groupNames.sort();
                  
                  if (_selectedGroup == null && groupNames.isNotEmpty) {
                    _selectedGroup = groupNames.first;
                  }

                  final groupChannels = channels.where((c) => c.group == _selectedGroup).toList();

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        color: Colors.black.withValues(alpha: 0.3),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGroup,
                            isExpanded: true,
                            dropdownColor: AppTheme.surfaceElevated,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            items: groupNames.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (val) => setState(() => _selectedGroup = val),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: groupChannels.length,
                          onReorder: (oldIdx, newIdx) => _onReorderChannels(oldIdx, newIdx, groupChannels),
                          proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
                          itemBuilder: (context, index) {
                            final c = groupChannels[index];
                            final key = c.url.isNotEmpty ? c.url : c.name;
                            return Container(
                              key: ValueKey(key),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text(c.type.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                trailing: const Icon(Icons.drag_indicator_rounded, color: Colors.white54),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading channels')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
