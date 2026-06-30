import 'package:pocketbase/pocketbase.dart';

void main() async {
  final pb = PocketBase('http://64.225.76.43');
  try {
    final record = await pb.collection('announcements').create(body: {
      'id': 'globalannounce12',
      'active': true,
      'text': 'Test Announcement'
    });
    print('Success: ${record.id}');
  } catch (e) {
    print('Failed with 16 char ID: $e');
  }

  try {
    final record2 = await pb.collection('announcements').create(body: {
      'id': 'globalannounce1',
      'active': true,
      'text': 'Test Announcement 15'
    });
    print('Success 15 char: ${record2.id}');
  } catch (e) {
    print('Failed with 15 char ID: $e');
  }
}
