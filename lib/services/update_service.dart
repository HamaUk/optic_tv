import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'pocketbase_service.dart';

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

  factory AppUpdateData.fromRecord(RecordModel record) {
    return AppUpdateData(
      apkUrl: record.getStringValue('apkUrl'),
      versionCode: record.getIntValue('versionCode'),
      versionName: record.getStringValue('versionName'),
      releaseNotes: record.getStringValue('releaseNotes'),
      isActive: record.getBoolValue('isActive'),
    );
  }
}

final updateManagerProvider = FutureProvider<AppUpdateData>((ref) async {
  try {
    // PocketBase expects a valid filter expression. 'id != ""' gets any record.
    final record = await pb.collection('updateManager').getFirstListItem('id != ""');
    return AppUpdateData.fromRecord(record);
  } catch (_) {
    return const AppUpdateData(apkUrl: '', versionCode: 0, versionName: '', releaseNotes: '', isActive: false);
  }
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
  final localVersionCode = ref.watch(appVersionCodeProvider).asData?.value;

  if (updateData != null && localVersionCode != null) {
    if (updateData.isActive && updateData.versionCode > localVersionCode) {
      return updateData;
    }
  }
  return null;
});
