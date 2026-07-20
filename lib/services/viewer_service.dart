import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final viewerServiceProvider = Provider((ref) => ViewerService());

final channelViewersProvider = StreamProvider.family<int, String>((ref, channelName) {
  return ref.watch(viewerServiceProvider).getViewersStream(channelName);
});

final globalViewersProvider = StreamProvider<int>((ref) {
  return ref.watch(viewerServiceProvider).getGlobalViewersStream();
});

class ViewerService {
  static String? _deviceId;
  String? _currentChannelName;
  MqttServerClient? _client;
  
  final Map<String, StreamController<int>> _countStreams = {};

  Future<void> _initMqtt() async {
    if (_client != null && _client!.connectionStatus?.state == MqttConnectionState.connected) return;
    
    final deviceId = await _getDeviceId();
    _client = MqttServerClient('145.241.248.219', 'flutter_client_$deviceId');
    _client!.port = 1883;
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20; // Broker fires last-will within ~30s of crash/disconnect
    
    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client_$deviceId')
        .withWillTopic('optic/viewers/disconnect')
        .withWillMessage(deviceId)
        .withWillQos(MqttQos.atMostOnce);
    _client!.connectionMessage = connMess;
    
    _client!.onDisconnected = () {
      if (kDebugMode) print('MQTT Disconnected');
      _client = null;
    };

    try {
      await _client!.connect();
    } catch (e) {
      _client!.disconnect();
      _client = null;
      return;
    }

    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      final topic = c[0].topic;
      if (topic.startsWith('optic/viewers/') && topic.endsWith('/count')) {
        final parts = topic.split('/');
        if (parts.length == 4) {
          final channel = parts[2];
          final count = int.tryParse(payload) ?? 0;
          if (_countStreams.containsKey(channel)) {
            _countStreams[channel]!.add(count);
          }
        }
      }
    });
  }

  static Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    String? id;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor;
      }
    } catch (e) { debugPrint('Caught error in viewer_service.dart: $e'); }

    if (id == null || id.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      id = prefs.getString('viewer_device_id');
      if (id == null) {
        id = 'DEV_${Random().nextInt(9999999).toString().padLeft(7, '0')}';
        await prefs.setString('viewer_device_id', id);
      }
    }
    
    _deviceId = id;
    return id.replaceAll(RegExp(r'[\.#\$\[\]]'), '_');
  }

  Future<void> registerGlobalPresence() async {
    await _initMqtt();
  }

  Future<void> joinChannel(String channelName) async {
    if (channelName.isEmpty) return;

    // Leave the previous channel before joining a new one.
    // Without this, switching channels leaves a zombie viewer on the old channel.
    if (_currentChannelName != null && _currentChannelName != channelName) {
      final old = _currentChannelName!;
      _currentChannelName = null;
      if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
        final builder = MqttClientPayloadBuilder();
        final deviceId = await _getDeviceId();
        builder.addString(deviceId);
        _client!.publishMessage('optic/viewers/$old/leave', MqttQos.atMostOnce, builder.payload!);
      }
    }

    await _initMqtt();
    _currentChannelName = channelName;
    
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      final deviceId = await _getDeviceId();
      builder.addString(deviceId);
      _client!.publishMessage('optic/viewers/$channelName/join', MqttQos.atMostOnce, builder.payload!);
    }
  }

  Future<void> leaveChannel(String channelName) async {
    if (_currentChannelName == null || _currentChannelName != channelName) return;
    _currentChannelName = null;
    
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      final deviceId = await _getDeviceId();
      builder.addString(deviceId);
      _client!.publishMessage('optic/viewers/$channelName/leave', MqttQos.atMostOnce, builder.payload!);
    }
  }

  Stream<int> getViewersStream(String channelName) {
    if (channelName.isEmpty) {
      return Stream.value(0);
    }
    
    if (!_countStreams.containsKey(channelName)) {
      _countStreams[channelName] = StreamController<int>.broadcast(
        onListen: () async {
          await _initMqtt();
          if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
            _client!.subscribe('optic/viewers/$channelName/count', MqttQos.atMostOnce);
          }
        },
        onCancel: () {
          if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
            _client!.unsubscribe('optic/viewers/$channelName/count');
          }
          _countStreams.remove(channelName);
        }
      );
    }
    
    return _countStreams[channelName]!.stream;
  }

  Stream<int> getGlobalViewersStream() async* {
    yield 0;
  }

  Future<void> dispose() async {
    if (_currentChannelName != null) {
      await leaveChannel(_currentChannelName!);
    }
    _client?.disconnect();
    for (final ctrl in _countStreams.values) {
      ctrl.close();
    }
    _countStreams.clear();
  }
}
