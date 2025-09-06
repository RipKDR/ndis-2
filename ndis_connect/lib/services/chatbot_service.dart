// Dialogflow integration placeholder.
// In production, consider calling Dialogflow via Cloud Functions for secure API key handling.
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  final Uri functionEndpoint; // Cloud Function HTTPS endpoint proxying Dialogflow
  ChatbotService(this.functionEndpoint);

  Future<String> sendMessage(String text, {String? sessionId}) async {
    final res = await http.post(
      functionEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        if (sessionId != null) 'sessionId': sessionId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Chatbot error: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['reply'] as String? ?? '';
    }
}

