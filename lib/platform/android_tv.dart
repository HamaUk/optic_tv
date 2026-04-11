import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// True when this build runs on an Android TV / leanback style device.
///
/// The system on-screen keyboard on many Android TV builds does not move
/// focus between keys correctly with Flutter text fields; the UI should use
/// an in-app keyboard instead.
Future<bool> queryAndroidTelevisionDevice() async {
  if (kIsWeb) return false;
  if (defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    const channel = MethodChannel('com.optic.iptv/device');
    final result = await channel.invokeMethod<bool>('isTelevision');
    return result == true;
  } catch (_) {
    return false;
  }
}
