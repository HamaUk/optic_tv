import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

class SecurityService {
  static const _channel = MethodChannel('com.optic.iptv/device');
  
  static const _blacklistedPackages = [
    'com.guoshi.httpcanary.premium',
    'com.guoshi.httpcanary',
    'com.reqable.android',
    'com.proxyman.android',
  ];

  static Future<List<String>> checkMaliciousApps() async {
    final foundApps = <String>[];
    
    // 1. Check for VPN/Proxy interfaces
    try {
      final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.any);
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('tun') || name.contains('tap') || name.contains('ppp') || name.contains('ipsec')) {
          foundApps.add('VPN/Proxy Detected (${interface.name})');
        }
      }
    } catch (e) {
      debugPrint('Failed to check network interfaces: $e');
    }

    // 2. Check for sniffing apps (Android only)
    if (Platform.isAndroid) {
      for (final pkg in _blacklistedPackages) {
        try {
          final isInstalled = await _channel.invokeMethod<bool>('isPackageInstalled', {'packageName': pkg});
          if (isInstalled == true) {
            foundApps.add(pkg);
          }
        } catch (e) {
          debugPrint('Failed to check package $pkg: $e');
        }
      }
    }
    
    return foundApps;
  }
}

final securityCheckProvider = FutureProvider<List<String>>((ref) async {
  return SecurityService.checkMaliciousApps();
});
