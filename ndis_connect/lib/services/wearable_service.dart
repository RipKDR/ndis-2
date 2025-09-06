// Fitbit/Wear OS integration placeholder. Requires OAuth2 flow and tokens.
import 'dart:convert';
import 'package:http/http.dart' as http;

class WearableService {
  Future<Map<String, dynamic>> fetchFitbitSteps(String accessToken, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('https://api.fitbit.com/1/user/-/activities/date/$dateStr.json');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
    if (res.statusCode != 200) {
      throw Exception('Fitbit error: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

