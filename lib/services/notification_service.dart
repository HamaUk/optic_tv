import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Top-level function for background message handling.
/// Must be outside of any class.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized before handling background message
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // If it's already initialized, this is safe to ignore
  }
  log('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    // 1. Request permission (required for iOS and Android 13+)
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 2. Set up background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup local notifications for foreground popups
    await _setupFlutterLocalNotifications();

    // 4. Handle incoming messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received foreground message: ${message.notification?.title}');
      _showNotification(message);
    });

    // 5. Handle tapping on a notification when the app is in the background
    // 6. Set up Broadcast listener (for Admin Panel notifications)
    _listenToBroadcasts();

    // 7. Get the FCM token
    final token = await _fcm.getToken();
    log('FCM Device Token: $token');
  }

  void _listenToBroadcasts() {
    final broadcastRef = FirebaseDatabase.instance.ref('sync/global/notifications/broadcast');
    
    broadcastRef.onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return;

      final id = data['id']?.toString();
      final title = data['title']?.toString();
      final body = data['body']?.toString();
      final imageUrl = data['image']?.toString();

      if (id == null || title == null || body == null) return;

      // Check if we've already seen this ID
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString('last_broadcast_id');

      if (lastId != id) {
        // New broadcast detected!
        await prefs.setString('last_broadcast_id', id);
        _showBroadcastNotification(title, body, imageUrl);
      }
    });
  }

  Future<void> _showBroadcastNotification(String title, String body, String? imageUrl) async {
    BigPictureStyleInformation? bigPictureStyleInformation;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String localPath = await _downloadAndSaveImage(imageUrl, 'notification_img');
        bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(localPath),
          contentTitle: title,
          summaryText: body,
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
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: bigPictureStyleInformation,
        ),
      ),
    );
  }

  Future<String> _downloadAndSaveImage(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = p.join(directory.path, '$fileName.jpg');
    final Response response = await Dio().get(
      url,
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

    // Currently defaulting to iOS settings if ever building for iOS
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // App opens when a local notification is tapped.
        log('Local notification tapped: ${response.payload}');
      },
    );

    // Create a high importance channel for Android heads-up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // For iOS foreground notifications setup
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  void _showNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}
