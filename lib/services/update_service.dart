import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final updateManagerProvider = StreamProvider<AppUpdateData>((ref) {
  return FirebaseDatabase.instance
      .ref('sync/global/updateManager')
      .onValue
      .map((event) => AppUpdateData.fromMap(event.snapshot.value as Map<dynamic, dynamic>?));
});
