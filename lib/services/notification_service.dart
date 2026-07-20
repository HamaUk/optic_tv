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
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'pocketbase_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pocketbase_database_mock.dart';
import 'login_codes_service.dart';
import '../main.dart';
import 'playlist_service.dart';
import '../ui/player/player_screen.dart';
import '../ui/dashboard/movie_details_screen.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  log("Handling a background message: ${message.messageId}");
  
  if (message.data['action'] == 'refresh') {
    final collection = message.data['collection'] as String?;
    if (collection == 'loginCodes') {
      LoginCodesService.triggerRefresh();
    } else if (collection != null) {
      PocketBaseDatabase.instance.notify(collection);
    }
  }
}

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

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['target'] != null) {
         _handleDeepLink(message.data['target'].toString());
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data['target'] != null) {
         Future.delayed(const Duration(seconds: 1), () {
           _handleDeepLink(message.data['target'].toString());
         });
      }
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['action'] == 'refresh') {
        final collection = message.data['collection'] as String?;
        if (collection == 'loginCodes') {
          LoginCodesService.triggerRefresh();
        } else if (collection != null) {
          PocketBaseDatabase.instance.notify(collection);
        }
      }

      if (message.notification != null) {
        _showBroadcastNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
          message.notification!.android?.imageUrl,
          payload: message.data['target']?.toString(),
        );
      }
    });

    // Listen to Firebase RTDB for broadcasts from the Web Admin panel
    // (Since Web Admin cannot securely authenticate with PocketBase without a backend)
    try {
      FirebaseDatabase.instance.ref('sync/global/notifications/broadcast').onValue.listen((event) async {
        final data = event.snapshot.value as Map?;
        if (data != null && data['id'] != null) {
          final id = data['id'].toString();
          final prefs = await SharedPreferences.getInstance();
          final lastId = prefs.getString('last_broadcast_id');
          if (lastId != id) {
            await prefs.setString('last_broadcast_id', id);
            final title = data['title']?.toString() ?? '';
            final body = data['body']?.toString() ?? '';
            final image = data['image']?.toString();
            final target = data['target']?.toString();
            if (title.isNotEmpty) {
               _showBroadcastNotification(title, body, image, payload: target);
            }
          }
        }
      });
    } catch (e) { debugPrint('Caught error in notification_service.dart: $e'); }

    // Listen to PocketBase for broadcasts from the Flutter App Admin panel
    try {
      PocketBaseDatabase.instance.ref('sync/global/notifications/broadcast').onValue.listen((event) async {
        final data = event.snapshot.value as Map?;
        if (data != null && data['id'] != null) {
          final id = data['id'].toString();
          final prefs = await SharedPreferences.getInstance();
          final lastId = prefs.getString('last_broadcast_id');
          if (lastId != id) {
            await prefs.setString('last_broadcast_id', id);
            final title = data['title']?.toString() ?? '';
            final body = data['body']?.toString() ?? '';
            final image = data['image']?.toString();
            final target = data['target']?.toString();
            if (title.isNotEmpty) {
               _showBroadcastNotification(title, body, image, payload: target);
            }
          }
        }
      });
    } catch (e) { debugPrint('Caught error in notification_service.dart: $e'); }
  }

  /// Sends a push notification to all users via FCM HTTP v1 API
  Future<void> sendPushNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? targetUrl,
  }) async {
    try {
      final serviceAccountJson = await rootBundle.loadString('assets/json/kobani-4k-service-account.json');
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
          'data': {
            if (targetUrl != null && targetUrl.isNotEmpty) 'target': targetUrl,
          },
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'high_importance_channel',
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'content-available': 1,
              }
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

  /// Sends a silent FCM data message to trigger a refresh for all clients
  Future<void> sendSilentRefreshPulse(String collection) async {
    try {
      final serviceAccountJson = await rootBundle.loadString('assets/json/kobani-4k-service-account.json');
      final serviceAccountMap = jsonDecode(serviceAccountJson) as Map<String, dynamic>;
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      final projectId = serviceAccountMap['project_id'] as String;
      final endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final message = {
        'message': {
          'topic': 'all',
          'data': {
            'action': 'refresh',
            'collection': collection,
          },
          'android': {
            'priority': 'HIGH'
          },
          'apns': {
            'payload': {
              'aps': {
                'content-available': 1,
              }
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
        log('Silent FCM pulse sent for $collection');
      } else {
        log('Failed to send silent pulse: ${response.body}');
      }
    } catch (e) {
      log('Failed to send silent pulse: $e');
    }
  }
  Future<void> _showBroadcastNotification(
    String title,
    String body,
    String? imageUrl, {
    String? payload,
  }) async {
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

    try {
      _localNotificationsPlugin.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: 'ic_stat_logo',
            largeIcon: largeIconBitmap,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: bigPictureStyleInformation,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      log('Failed to show foreground local notification: $e');
    }
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
        AndroidInitializationSettings('ic_stat_logo');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Local notification tapped: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleDeepLink(response.payload!);
        }
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

  Future<void> _handleDeepLink(String target) async {
    log('Handling Deep Link for target: $target');
    
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      log('Cannot handle deep link: navigator context is null');
      return;
    }

    final channels = await loadCachedChannels();
    final lowercaseTarget = target.toLowerCase();
    
    final targetIndex = channels.indexWhere((c) => c.name.toLowerCase() == lowercaseTarget);
    
    if (targetIndex != -1) {
      final channel = channels[targetIndex];
      if (channel.type == 'movie') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(allChannels: channels, channel: channel)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channels: channels, initialIndex: targetIndex)));
      }
    } else {
      log('Deep link target channel "$target" not found in cached channels.');
    }
  }
}
