import 'package:flutter/foundation.dart';
import 'pocketbase_database_mock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';

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
  // Simply trigger based on isActive flag — no version code gate needed
  // because the admin controls whether to show the popup via the toggle.
  if (updateData != null && updateData.isActive && updateData.apkUrl.isNotEmpty) {
    return updateData;
  }
  return null;
});
