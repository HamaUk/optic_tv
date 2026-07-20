import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'base_settings_page.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_strings.dart';
import '../../../providers/app_locale_provider.dart';
import '../../../providers/channel_library_provider.dart';

class StorageSettingsPage extends ConsumerStatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  ConsumerState<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends ConsumerState<StorageSettingsPage> {
  bool _calculatingStorage = true;
  int _posterCacheBytes = 0;
  int _epgCacheBytes = 0;
  int _logsCacheBytes = 0;
      
  @override
  void initState() {
    super.initState();
    _calculateStorage();
  }

  Future<void> _calculateStorage() async {
    if (!mounted) return;
    setState(() => _calculatingStorage = true);
    
    int posters = 0;
    int epg = 0;
    int logs = 0;
    
    try {
      final cacheDir = await getTemporaryDirectory();
      final posterDir = Directory('${cacheDir.path}/libCachedImageData');
      final epgDir = Directory('${cacheDir.path}/epg_data');
      final logDir = Directory('${cacheDir.path}/logs');
      
      posters = await _getDirSize(posterDir);
      epg = await _getDirSize(epgDir);
      logs = await _getDirSize(logDir);
    } catch (e) { debugPrint('Caught error in storage_settings_page.dart: $e'); }
    
    if (mounted) {
      setState(() {
        _posterCacheBytes = posters;
        _epgCacheBytes = epg;
        _logsCacheBytes = logs;
        _calculatingStorage = false;
      });
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int total = 0;
    if (await dir.exists()) {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          total += await file.length();
        }
      }
    }
    return total;
  }

  Future<void> _clearSpecificCache(String type) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (type == 'posters') {
        final dir = Directory('${cacheDir.path}/libCachedImageData');
        if (await dir.exists()) await dir.delete(recursive: true);
      } else if (type == 'epg') {
        final dir = Directory('${cacheDir.path}/epg_data');
        if (await dir.exists()) await dir.delete(recursive: true);
      } else if (type == 'logs') {
        final dir = Directory('${cacheDir.path}/logs');
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    } catch (e) { debugPrint('Caught error in storage_settings_page.dart: $e'); }
    await _calculateStorage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cleared \$type cache')));
    }
  }

  Future<void> _confirmClearLibrary(
    AppStrings s, {
    required String dialogTitle,
    required String dialogBody,
    required Future<void> Function() onClear,
  }) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceElevated,
            title: Text(dialogTitle, style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dialogBody, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(s.clearLibraryConfirmBody, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel, style: const TextStyle(color: Colors.white54))),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.clearButton.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ) ??
        false;
    if (!go || !mounted) return;
    await onClear();
  }

  @override
  Widget build(BuildContext context) {
    final uiLocale = ref.watch(appLocaleProvider);
    final s = AppStrings(uiLocale);

    return BaseSettingsPage(
      title: s.sectionStorage,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          glassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.image_rounded, color: Colors.blueAccent),
                  title: Text(s.storagePosters, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(_calculatingStorage ? s.calculating : "\${(_posterCacheBytes / (1024 * 1024)).toStringAsFixed(1)} MB", style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _clearSpecificCache('posters'),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.list_alt_rounded, color: Colors.greenAccent),
                  title: Text(s.storageEpg, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(_calculatingStorage ? s.calculating : "\${(_epgCacheBytes / (1024 * 1024)).toStringAsFixed(1)} MB", style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _clearSpecificCache('epg'),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report_rounded, color: Colors.orangeAccent),
                  title: Text(s.storageLogs, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(_calculatingStorage ? s.calculating : "\${(_logsCacheBytes / (1024 * 1024)).toStringAsFixed(1)} MB", style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _clearSpecificCache('logs'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            s.sectionLibrary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          glassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded, color: Colors.amberAccent),
                  title: Text(s.clearFavoritesTitle, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.clearFavoritesSub, style: const TextStyle(color: Colors.white70)),
                  onTap: () => _confirmClearLibrary(
                    s,
                    dialogTitle: s.clearFavoritesTitle,
                    dialogBody: s.clearFavoritesSub,
                    onClear: () => ref.read(favoritesProvider.notifier).clearAll(),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: Icon(Icons.history_rounded, color: Colors.white.withValues(alpha: 0.85)),
                  title: Text(s.clearRecentTitle, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.clearRecentSub, style: const TextStyle(color: Colors.white70)),
                  onTap: () => _confirmClearLibrary(
                    s,
                    dialogTitle: s.clearRecentTitle,
                    dialogBody: s.clearRecentSub,
                    onClear: () => ref.read(recentChannelsProvider.notifier).clearAll(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
