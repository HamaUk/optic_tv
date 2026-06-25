import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  factory AppUpdateData.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const AppUpdateData(apkUrl: '', versionCode: 0, versionName: '', releaseNotes: '', isActive: false);
    }
    return AppUpdateData(
      apkUrl: map['apkUrl']?.toString() ?? '',
      versionCode: int.tryParse(map['versionCode']?.toString() ?? '0') ?? 0,
      versionName: map['versionName']?.toString() ?? '',
      releaseNotes: map['releaseNotes']?.toString() ?? '',
      isActive: map['isActive'] == true || map['isActive'] == 'true',
    );
  }
}

final updateManagerProvider = FutureProvider<AppUpdateData>((ref) async {
  try {
    final snap = await FirebaseDatabase.instance
        .ref('sync/global/updateManager')
        .get();
    return AppUpdateData.fromMap(snap.value as Map<dynamic, dynamic>?);
  } catch (_) {
    return const AppUpdateData(apkUrl: '', versionCode: 0, versionName: '', releaseNotes: '', isActive: false);
  }
});

final appVersionCodeProvider = FutureProvider<int>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return int.tryParse(packageInfo.buildNumber) ?? 14;
  } catch (e) {
    return 14; // Fallback to current version (1.2.0+14) if package_info fails
  }
});

final updatePromptTriggerProvider = Provider<AppUpdateData?>((ref) {
  final updateData = ref.watch(updateManagerProvider).asData?.value;
  final localVersionCode = ref.watch(appVersionCodeProvider).asData?.value;

  if (updateData != null && localVersionCode != null) {
    if (updateData.isActive && updateData.versionCode > localVersionCode) {
      return updateData;
    }
  }
  return null;
});
