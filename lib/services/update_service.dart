import 'package:flutter/foundation.dart';
import 'pocketbase_database_mock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// SharedPreferences key used to track which update URL the user already acted on.
const _kDismissedUpdateUrlKey = 'dismissed_update_url';

class AppUpdateData {
  final String apkUrl;
  final int versionCode;
  final String versionName;
  final String releaseNotes;
  final bool isActive;

  const AppUpdateData({
    required this.apkUrl,
    required this.versionCode,
    required this.versionName,
    required this.releaseNotes,
    required this.isActive,
  });
}

/// Saves the update URL locally so we never show the same popup again.
/// Call this when the user taps the update button.
Future<void> markUpdateUrlHandled(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kDismissedUpdateUrlKey, url);
  debugPrint('[UpdateService] Marked update URL as handled: $url');
}

/// Returns the URL the user has already acted on (tapped "Let's update it"),
/// or null if they haven't handled any update yet.
Future<String?> getHandledUpdateUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kDismissedUpdateUrlKey);
}

final updateManagerProvider = StreamProvider<AppUpdateData>((ref) {
  final controller = StreamController<AppUpdateData>();

  final sub = PocketBaseDatabase.instance
      .ref('sync/global/updateManager')
      .onValue
      .listen((event) {
    final val = event.snapshot.value;
    debugPrint('[UpdateService] Raw PocketBase value: $val');
    if (val is Map) {
      // PocketBase toJson() returns full record with id/collectionId/etc.
      // The fields 'active' and 'url' are stored at the top level.
      final active = val['active'] == true;
      final url = (val['url'] ?? '').toString().trim();
      debugPrint('[UpdateService] active=$active url=$url');
      
      if (active && url.isNotEmpty) {
        controller.add(AppUpdateData(
          apkUrl: url,
          versionCode: 999999,
          versionName: "New Update",
          releaseNotes: "A new update is available.",
          isActive: true,
        ));
        return;
      }
    }
    
    // Default inactive state
    controller.add(const AppUpdateData(
      apkUrl: '',
      versionCode: 0,
      versionName: '',
      releaseNotes: '',
      isActive: false,
    ));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

final appVersionCodeProvider = FutureProvider<int>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return int.tryParse(packageInfo.buildNumber) ?? 16;
  } catch (e) {
    return 16; // Fallback to current version (1.3.1+16) if package_info fails
  }
});

final updatePromptTriggerProvider = Provider<AppUpdateData?>((ref) {
  final updateData = ref.watch(updateManagerProvider).asData?.value;
  // Simply trigger based on isActive flag — admin controls the toggle.
  // Version-gating is handled at the UI level via SharedPreferences so that
  // users who already acted on this specific URL won't see the popup again.
  if (updateData != null && updateData.isActive && updateData.apkUrl.isNotEmpty) {
    return updateData;
  }
  return null;
});
