import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeviceType { phone, tv, web }

class PlatformService {
  static Future<DeviceType> getDeviceType() async {
    if (kIsWeb) return DeviceType.web;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // Traditional TV detection: search for leanback feature
      final isTv = androidInfo.systemFeatures.contains('android.software.leanback');
      if (isTv) return DeviceType.tv;

      // Fallback for some TV boxes that don't report leanback correctly
      // but are significantly larger/landscape focused
      if (androidInfo.model.toLowerCase().contains('tv') || 
          androidInfo.device.toLowerCase().contains('tv')) {
        return DeviceType.tv;
      }
    }

    return DeviceType.phone;
  }
}

final deviceTypeProvider = FutureProvider<DeviceType>((ref) async {
  return PlatformService.getDeviceType();
});
