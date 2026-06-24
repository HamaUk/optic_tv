import 'dart:convert';
import 'package:http/http.dart' as http;

class WorldCupService {
  static const String baseUrl = 'https://worldcup26.ir/get';

  /// Fetches all matches
  static Future<List<dynamic>> fetchGames() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/games'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['games'] ?? [];
      }
    } catch (e) {
      print('Error fetching WC games: $e');
    }
    return [];
  }

  /// Fetches group standings
  static Future<List<dynamic>> fetchGroups() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/groups'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['groups'] ?? [];
      }
    } catch (e) {
      print('Error fetching WC groups: $e');
    }
    return [];
  }
}
