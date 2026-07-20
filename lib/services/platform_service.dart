import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceType { phone, tv, web }

class PlatformService {
  static Future<DeviceType> getDeviceType() async {
    if (kIsWeb) return DeviceType.web;

    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('device_mode');
      if (mode == 'tv') return DeviceType.tv;
      if (mode == 'phone') return DeviceType.phone;
    } catch (e) { debugPrint('Caught error in platform_service.dart: $e'); }

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

  // Comprehensive blacklist of packet sniffers, MITM proxies, and VPN apps
  static const _blacklistedPackages = [
    // ── Packet Capture / Sniffer Apps ──────────────────────────────────
    // HttpCanary (used in the screenshot)
    'com.guoshi.httpcanary',
    'com.guoshi.httpcanary.premium',
    // PCAPdroid variants
    'com.emanuelef.remote_capture',
    'com.egorovandmax.android.pcapreader',
    'com.egorovandmax.pcapdroid',
    // Packet Capture (no-root MITM via local VPN)
    'app.greyshirts.sslcapture',
    // Kismet Android packet capture
    'com.kismetwireless.android.pcapcapture',
    // EvBad Packet Capture
    'com.evbadroid.packetcapture',
    // tPacketCapture
    'jp.co.taosoftware.android.packetcapture',
    // Koushik Dutta tether (often used as traffic relay)
    'com.koushikdutta.tether',
    // Network Packet Capture
    'com.minhui.networkcapture',
    // PCAPRemote (Wireshark remote capture)
    'com.egorovandreyrm.pcapremote',

    // ── MITM Proxy / Debugging Tools ───────────────────────────────────
    // Reqable (modern HTTPS sniffer/debugger)
    'com.reqable.android',
    // Proxyman
    'com.proxyman.android',
    // HTTP Toolkit (multiple package variants)
    'tech.httptoolkit.android',
    'tech.httptoolkit.android.v1',
    'com.netsparker.httptoolkit',
    // GrayMitten Proxy Capture
    'com.greaymitten.proxycapture',
    // JRummy Network Monitor
    'com.jrummyapps.network.monitor',
    // HTTP Capture
    'com.daasuu.httpcapture',
    // Fiddler Everywhere
    'com.telerik.fiddler',
    // Burp Suite
    'net.portswigger.burp',

    // ── VPN-based Traffic Analyzers ────────────────────────────────────
    // Nighthawk VPN Pro (traffic analyzer)
    'com.nighthawkapps.vpnpro',
    // Sniffer VPN Capture
    'com.sniffer.vpn.capture',
    // Vysor (USB mirror, can relay traffic)
    'com.koushikdutta.vysor',
    // Fingbox / network scanner
    'org.secfirst.fingbox',

    // ── Frida / Dynamic Instrumentation Tools ──────────────────────────
    // Frida server wrappers
    'com.elementary.frida',
    're.frida.server',
    'com.fridatools',
    // Kali NetHunter (full hacking suite)
    'com.offsec.nethunter',
    // Needle (iOS/Android pentest framework)
    'com.sensepost.needle',

    // ── Root / Hook Frameworks ─────────────────────────────────────────
    // Xposed / LSPosed (can hook any method call)
    'de.robv.android.xposed.installer',
    'org.lsposed.manager',
    'io.github.lsposed.manager',

    // ── General Network / SSH Tools (often used in sniffer pipelines) ──
    // Termux (can run tcpdump, mitmproxy, etc.)
    'com.termux',
    // JuiceSSH (SSH tunneling)
    'com.sonelli.juicessh',
    // ConnectBot (SSH tunneling)
    'org.connectbot',
  ];

  /// Uses the native Android ConnectivityManager to check if VPN or
  /// system proxy is active. Far more reliable than Dart's NetworkInterface.
  static Future<bool> isVpnOrProxyActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isVpnOrProxyActive');
      return result ?? false;
    } catch (e) {
      debugPrint('Native VPN check failed, falling back to Dart: $e');
      // Fallback: Dart-level network interface check
      try {
        final interfaces = await NetworkInterface.list(
            includeLoopback: false, type: InternetAddressType.any);
        for (final iface in interfaces) {
          final name = iface.name.toLowerCase();
          if (name.contains('tun') ||
              name.contains('tap') ||
              name.contains('ppp') ||
              name.contains('ipsec') ||
              name.startsWith('utun')) {
            return true;
          }
        }
      } catch (e) { debugPrint('Caught error in platform_service.dart: $e'); }
      return false;
    }
  }

  static Future<List<String>> checkMaliciousApps({bool checkPackages = true}) async {
    final foundApps = <String>[];

    // 1. Native VPN/Proxy check (most reliable)
    try {
      if (await isVpnOrProxyActive()) {
        foundApps.add('VPN/Proxy Detected');
      }
    } catch (e) {
      debugPrint('VPN check failed: $e');
    }

    // 2. Check for sniffing/hacking apps (Android only)
    if (Platform.isAndroid && checkPackages) {
      for (final pkg in _blacklistedPackages) {
        try {
          final isInstalled =
              await _channel.invokeMethod<bool>('isPackageInstalled', {'packageName': pkg});
          if (isInstalled == true) {
            foundApps.add(pkg);
          }
        } catch (e) {
          debugPrint('Failed to check package $pkg: $e');
        }
      }

      // 3. Emulator / Virtual Device Detection (emulators are used for MITM)
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (!androidInfo.isPhysicalDevice) {
          foundApps.add('Emulator/Virtual Device Detected');
        }
      } catch (e) {
        debugPrint('Failed to check physical device: $e');
      }
    }

    return foundApps;
  }
}

final securityCheckProvider = StreamProvider<List<String>>((ref) async* {
  bool isDisposed = false;
  ref.onDispose(() {
    isDisposed = true;
  });

  // Yield initial check immediately (full check)
  try {
    final initial = await SecurityService.checkMaliciousApps(checkPackages: true)
        .timeout(const Duration(seconds: 3), onTimeout: () => <String>[]);
    yield initial;
  } catch (e) {
    debugPrint('Security check failed: $e');
    yield <String>[];
  }

  // Continuously check VPN status every 1 second (optimized)
  int packageCheckCounter = 0;
  while (!isDisposed) {
    await Future.delayed(const Duration(seconds: 1));
    if (isDisposed) break; // Stop loop if provider is disposed
    try {
      packageCheckCounter++;
      final runFullCheck = packageCheckCounter >= 20; // full check every 20s
      if (runFullCheck) {
        packageCheckCounter = 0;
      }

      final current = await SecurityService.checkMaliciousApps(checkPackages: runFullCheck)
          .timeout(const Duration(seconds: 3), onTimeout: () => <String>[]);
      yield current;
    } catch (e) {
      debugPrint('Security loop check failed: $e');
    }
  }
});
