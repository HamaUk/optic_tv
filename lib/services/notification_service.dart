import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart' hide ResponseType;
import 'pocketbase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    // Initialize Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await messaging.subscribeToTopic('all');

    // Setup local notifications for other app-specific alerts if needed
    await _setupFlutterLocalNotifications();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showBroadcastNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
          message.notification!.android?.imageUrl,
        );
      }
    });
  }

  /// Sends a push notification to all users via FCM HTTP v1 API
  Future<void> sendPushNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final serviceAccountJson = await rootBundle.loadString('assets/json/kobani-noti-service-account.json');
      final serviceAccountMap = jsonDecode(serviceAccountJson) as Map<String, dynamic>;
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final authClient = await clientViaServiceAccount(accountCredentials, scopes);

      final projectId = serviceAccountMap['project_id'] as String;
      final endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final message = {
        'message': {
          'topic': 'all',
          'notification': {
            'title': title,
            'body': body,
            if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
          },
          'android': {
            'notification': {
              'channel_id': 'high_importance_channel',
            }
          }
        }
      };

      final response = await authClient.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      authClient.close();

      if (response.statusCode == 200) {
        log('FCM Push Notification sent successfully');
      } else {
        log('Failed to send FCM push: ${response.body}');
        throw Exception('FCM push failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Failed to send FCM push: $e');
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
          icon: 'ic_notification',
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
        AndroidInitializationSettings('ic_notification');

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
