import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Let's find a finished game from a recent date
  final dateStr = "20240714"; // Euro Final or Copa America Final
  final url = "http://site.api.espn.com/apis/site/v2/sports/soccer/all/scoreboard?dates=$dateStr";
  final res = await http.get(Uri.parse(url));
  final data = json.decode(res.body);
  final events = data['events'] as List<dynamic>? ?? [];
  if (events.isEmpty) {
    print("No events");
    return;
  }
  final eventId = events[0]['id'];
  print("Event ID: $eventId");
  
  // Now fetch summary
  final summaryUrl = "http://site.api.espn.com/apis/site/v2/sports/soccer/all/summary?event=$eventId";
  final sumRes = await http.get(Uri.parse(summaryUrl));
  final sumData = json.decode(sumRes.body);
  
  print("Has boxscore: ${sumData.containsKey('boxscore')}");
  print("Has rosters: ${sumData.containsKey('rosters')}");
  
  if (sumData.containsKey('boxscore')) {
    final teams = sumData['boxscore']['teams'] as List<dynamic>? ?? [];
    print("Boxscore teams count: ${teams.length}");
    if (teams.isNotEmpty) {
      print("Has statistics: ${teams[0].containsKey('statistics')}");
      final stats = teams[0]['statistics'] as List<dynamic>? ?? [];
      print("Stats count: ${stats.length}");
    }
  }
}
