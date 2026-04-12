import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../platform/android_tv.dart';

/// Provider that detects if the current device is an Android TV / Leanback device.
/// 
/// This is used to switch between the Phone and TV UI layouts.
final isTvProvider = FutureProvider<bool>((ref) async {
  return await queryAndroidTelevisionDevice();
});
