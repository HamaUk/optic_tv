import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final now = DateTime.now();
  final today = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
  print("Fetching for: $today");
  final res = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard?dates=$today'));
  print(res.statusCode);
  if(res.statusCode == 200) {
    final data = jsonDecode(res.body);
    print("Events: ${data['events']?.length}");
  }
}
