import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dlna_dart/dlna.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dlnaServiceProvider = Provider((ref) => DlnaService());

class DlnaService {
  final DLNAManager _manager = DLNAManager();
  DeviceManager? _deviceManager;
  
  final ValueNotifier<List<DLNADevice>> devicesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isSearching = ValueNotifier(false);
  
  DLNADevice? _connectedDevice;
  StreamSubscription? _deviceSubscription;

  DlnaService();

  Future<void> startDiscovery() async {
    isSearching.value = true;
    devicesNotifier.value = [];
    
    _deviceManager = await _manager.start();
    _deviceSubscription = _deviceManager!.devices.stream.listen((deviceMap) {
      devicesNotifier.value = deviceMap.values.toList();
    });
    
    // Stop search after 15 seconds to save battery
    Timer(const Duration(seconds: 15), () {
      stopDiscovery();
    });
  }

  void stopDiscovery() {
    _manager.stop();
    _deviceSubscription?.cancel();
    isSearching.value = false;
  }

  void connect(DLNADevice device) {
    _connectedDevice = device;
  }

  void disconnect() {
    _connectedDevice = null;
  }

  bool get isConnected => _connectedDevice != null;
  String? get connectedDeviceName => _connectedDevice?.info.friendlyName;

  Future<void> castUrl(String url, {String title = "Optic TV Stream"}) async {
    if (_connectedDevice == null) return;
    try {
      // Cast the raw stream to the TV using the correct API method
      await _connectedDevice!.setUrl(url, title: title);
      await _connectedDevice!.play();
    } catch (e) {
      debugPrint("DLNA Cast Error: $e");
    }
  }

  Future<void> stopCasting() async {
    if (_connectedDevice == null) return;
    try {
      await _connectedDevice!.pause(); // the plugin has pause() and play()
    } catch (e) {
      debugPrint("DLNA Stop Error: $e");
    }
  }
}
