import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'pocketbase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    // Setup local notifications for foreground popups
    await _setupFlutterLocalNotifications();

    // Listen to PocketBase broadcasts via Realtime SSE
    _listenToBroadcasts();
  }

  void _listenToBroadcasts() {
    // Subscribe to PocketBase broadcasts collection
    pb.collection('broadcasts').subscribe('*', (event) async {
      if (event.action == 'create' || event.action == 'update') {
        final data = event.record;
        if (data == null) return;

        final id = data.id;
        final title = data.getStringValue('title');
        final body = data.getStringValue('body');
        final imageUrl = data.getStringValue('image');

        if (title.isEmpty || body.isEmpty) return;

        // Check if we've already seen this ID
        final prefs = await SharedPreferences.getInstance();
        final lastId = prefs.getString('last_broadcast_id');

        if (lastId != id) {
          // New broadcast detected!
          await prefs.setString('last_broadcast_id', id);
          _showBroadcastNotification(title, body, imageUrl);
        }
      }
    }).catchError((e) {
      log('Error subscribing to PocketBase broadcasts: $e');
    });
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
