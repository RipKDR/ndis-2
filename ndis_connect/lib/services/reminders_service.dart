// Placeholder to schedule event reminders via a Cloud Function.
// Backend should accept {eventId, uid, title, timestamp, token} and schedule FCM.
import 'dart:convert';
import 'package:http/http.dart' as http;

class RemindersService {
  final Uri functionEndpoint; // e.g., https://<region>-<project>.cloudfunctions.net/scheduleReminder
  RemindersService(this.functionEndpoint);

  Future<void> scheduleReminder({
    required String eventId,
    required String uid,
    required String title,
    required int timestampMs,
    required String token,
  }) async {
    final res = await http.post(functionEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': eventId,
          'uid': uid,
          'title': title,
          'timestampMs': timestampMs,
          'token': token,
        }));
    if (res.statusCode != 200) {
      throw Exception('Failed to schedule reminder: ${res.statusCode} ${res.body}');
    }
  }
}

