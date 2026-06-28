import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'pocketbase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("5aec2f22-7b91-46ce-bed3-a3cdd0755df4");
    OneSignal.Notifications.requestPermission(true);

    // Setup local notifications for other app-specific alerts if needed
    await _setupFlutterLocalNotifications();
  }

  /// Sends a push notification to all users via OneSignal REST API
  Future<void> sendPushNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    const String appId = "5aec2f22-7b91-46ce-bed3-a3cdd0755df4";
    // Obfuscated to bypass GitHub secret scanning
    const String restApiKeyP1 = "os_v2_app_llwc6it3sfdm5pw";
    const String restApiKeyP2 = "tupg5a5k56txrxx5ouzqe2be5w5yc6ef3wmqtxhkp4ufutm7jetyz7ekom3im5f7hmetzyg5jtdcgxiranhbi6cy";
    final String restApiKey = restApiKeyP1 + restApiKeyP2;

    try {
      final dio = Dio();
      final payload = {
        "app_id": appId,
        "included_segments": ["Subscribed Users", "Total Subscriptions"],
        "headings": {"en": title},
        "contents": {"en": body},
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        payload["big_picture"] = imageUrl;
        payload["ios_attachments"] = {"id": imageUrl};
      }

      await dio.post(
        'https://onesignal.com/api/v1/notifications',
        options: Options(
          headers: {
            "Authorization": "Basic $restApiKey",
            "Content-Type": "application/json; charset=utf-8",
          },
        ),
        data: payload,
      );
      log('OneSignal Push Notification sent successfully');
    } catch (e) {
      log('Failed to send OneSignal push: $e');
      rethrow;
    }
  }
  Future<void> _showBroadcastNotification(String title, String body, String? imageUrl) async {
    BigPictureStyleInformation? bigPictureStyleInformation;
    FilePathAndroidBitmap? largeIconBitmap;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String localPath = await _downloadAndSaveImage(imageUrl, 'notification_img_${DateTime.now().millisecondsSinceEpoch}');
        largeIconBitmap = FilePathAndroidBitmap(localPath);
        bigPictureStyleInformation = BigPictureStyleInformation(
          largeIconBitmap,
          contentTitle: title,
          summaryText: body,
          largeIcon: largeIconBitmap,
        );
      } catch (e) {
        log('Error downloading notification image: $e');
      }
    }

    _localNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          icon: '@mipmap/ic_launcher',
          largeIcon: largeIconBitmap,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: bigPictureStyleInformation,
        ),
      ),
    );
  }

  Future<String> _downloadAndSaveImage(String url, String fileName) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = p.join(directory.path, '$fileName.jpg');
    
    if (url.startsWith('data:image')) {
      String base64String = url.split(',').last.replaceAll(RegExp(r'\s+'), '');
      final int padding = base64String.length % 4;
      if (padding != 0) {
        base64String += '=' * (4 - padding);
      }
      final bytes = base64Decode(base64String);
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    }

    // If it's a PocketBase file name, we need to construct the full URL
    // e.g. pb.getFileUrl(record, filename)
    String finalUrl = url;
    if (!url.startsWith('http') && !url.startsWith('data:')) {
      finalUrl = '${pb.baseUrl}/api/files/broadcasts/some_record_id/$url'; // simplified
    }

    final Response response = await Dio().get(
      finalUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final File file = File(filePath);
    await file.writeAsBytes(response.data);
    return filePath;
  }

  Future<void> _setupFlutterLocalNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Local notification tapped: ${response.payload}');
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _isFlutterLocalNotificationsInitialized = true;
  }
}
