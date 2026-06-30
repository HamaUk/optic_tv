import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';

void main() async {
  final file = File('assets/json/kobani-noti-service-account.json');
  final serviceAccountJson = await file.readAsString();
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
        'title': 'Test Push',
        'body': 'This is a test'
      },
      'android': {
        'notification': {
          'channel_id': 'high_importance_channel',
        }
      }
    }
  };

  print('Sending to $endpoint');
  
  try {
    final response = await authClient.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  } finally {
    authClient.close();
  }
}
