import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class ChatbotService {
  final Uri? functionEndpoint; // Cloud Function HTTPS endpoint proxying Dialogflow
  final FirebaseAuth _auth;
  final Connectivity _conn;
  final _uuid = const Uuid();

  final String _chatBoxName = 'chat_history';
  final String _sessionBoxName = 'chat_sessions';

  // Fallback responses for offline mode
  final Map<ChatbotIntent, List<String>> _fallbackResponses = {
    ChatbotIntent.greeting: [
      'Hello! I\'m your NDIS Connect assistant. How can I help you today?',
      'Hi there! I\'m here to help with your NDIS journey. What would you like to know?',
      'Welcome to NDIS Connect! I can help you with tasks, services, and more.',
    ],
    ChatbotIntent.help: [
      'I can help you with:\n• Managing your tasks and goals\n• Finding service providers\n• Budget tracking\n• Appointment scheduling\n• General NDIS information\n\nWhat would you like help with?',
      'Here\'s what I can assist you with:\n• Task management and reminders\n• Service provider search\n• Budget and plan information\n• Emergency support\n\nHow can I help you today?',
    ],
    ChatbotIntent.task_management: [
      'I can help you manage your tasks! You can:\n• Create new tasks\n• Set reminders\n• Track progress\n• View upcoming tasks\n\nWould you like to create a new task or view your existing ones?',
      'For task management, you can:\n• Add tasks with due dates\n• Set recurring tasks\n• Mark tasks as complete\n• Get reminders\n\nWhat would you like to do with your tasks?',
    ],
    ChatbotIntent.service_finder: [
      'I can help you find NDIS service providers! You can:\n• Search by location\n• Filter by service type\n• View provider details\n• Get directions\n\nWhat type of service are you looking for?',
      'To find service providers:\n• Use the map to see nearby providers\n• Filter by category (therapy, support work, etc.)\n• Check ratings and reviews\n• Contact providers directly\n\nWhat service do you need?',
    ],
    ChatbotIntent.budget_info: [
      'I can help with your NDIS budget! You can:\n• View your plan details\n• Track spending\n• Check remaining funds\n• Get budget alerts\n\nWould you like to see your current budget status?',
      'For budget information:\n• Check your plan categories (Core, Capacity, Capital)\n• Monitor spending patterns\n• Set budget alerts\n• View payment history\n\nWhat budget information do you need?',
    ],
    ChatbotIntent.appointment_booking: [
      'I can help you manage appointments! You can:\n• View upcoming appointments\n• Set reminders\n• Reschedule if needed\n• Add new appointments\n\nWould you like to see your upcoming appointments?',
      'For appointments:\n• Check your calendar\n• Set reminders\n• Contact service providers\n• Manage recurring appointments\n\nHow can I help with your appointments?',
    ],
    ChatbotIntent.emergency: [
      'For emergencies, please:\n• Call 000 for immediate help\n• Contact your support coordinator\n• Use the emergency support feature in the app\n• Reach out to family or carers\n\nIs this an emergency situation?',
      'Emergency support options:\n• 000 for life-threatening emergencies\n• Your support coordinator\n• Emergency contacts in the app\n• Local emergency services\n\nDo you need immediate help?',
    ],
    ChatbotIntent.general: [
      'I\'m here to help with your NDIS journey. You can ask me about:\n• Tasks and goals\n• Service providers\n• Budget information\n• Appointments\n• General NDIS questions\n\nWhat would you like to know?',
      'I can assist with various aspects of your NDIS plan. Feel free to ask about:\n• Managing your daily tasks\n• Finding services\n• Understanding your budget\n• Scheduling appointments\n\nHow can I help you today?',
    ],
  };

  ChatbotService({
    this.functionEndpoint,
    FirebaseAuth? auth,
    Connectivity? connectivity,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _conn = connectivity ?? Connectivity();

  Future<ChatMessage> sendMessage(String text, {String? sessionId}) async {
    final messageId = _uuid.v4();
    final timestamp = DateTime.now();

    // Create user message
    final userMessage = ChatMessage(
      id: messageId,
      text: text,
      type: ChatMessageType.user,
      timestamp: timestamp,
    );

    // Save user message
    await _saveMessage(userMessage, sessionId);

    try {
      // Check connectivity
      final connectivity = await _conn.checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      String botResponse;
      ChatbotIntent? intent;

      if (isOnline && functionEndpoint != null) {
        // Try online chatbot
        try {
          final response = await _callOnlineChatbot(text, sessionId);
          botResponse = response['text'] as String;
          intent = response['intent'] != null
              ? ChatbotIntent.values.firstWhere(
                  (e) => e.name == response['intent'],
                  orElse: () => ChatbotIntent.general,
                )
              : null;
        } catch (e) {
          // Fallback to offline mode
          final offlineResponse = _getOfflineResponse(text);
          botResponse = offlineResponse['text'] as String;
          intent = offlineResponse['intent'] as ChatbotIntent;
        }
      } else {
        // Use offline mode
        final offlineResponse = _getOfflineResponse(text);
        botResponse = offlineResponse['text'] as String;
        intent = offlineResponse['intent'] as ChatbotIntent;
      }

      // Create bot message
      final botMessage = ChatMessage(
        id: _uuid.v4(),
        text: botResponse,
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        intent: intent,
        metadata: {
          'sessionId': sessionId,
          'userMessageId': messageId,
        },
      );

      // Save bot message
      await _saveMessage(botMessage, sessionId);

      return botMessage;
    } catch (e) {
      // Error response
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        text:
            'I\'m sorry, I\'m having trouble right now. Please try again later or contact support.',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        intent: ChatbotIntent.general,
        metadata: {
          'error': e.toString(),
          'sessionId': sessionId,
        },
      );

      await _saveMessage(errorMessage, sessionId);
      return errorMessage;
    }
  }

  Future<Map<String, dynamic>> _callOnlineChatbot(String text, String? sessionId) async {
    final response = await http.post(
      functionEndpoint!,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'sessionId': sessionId ?? _uuid.v4(),
        'userId': _auth.currentUser?.uid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Chatbot API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'text': data['reply'] as String? ?? 'I didn\'t understand that. Can you please rephrase?',
      'intent': data['intent'] as String?,
    };
  }

  Map<String, dynamic> _getOfflineResponse(String text) {
    final lowercaseText = text.toLowerCase();
    ChatbotIntent intent = ChatbotIntent.general;

    // Simple intent detection
    if (lowercaseText
        .contains(RegExp(r'\b(hello|hi|hey|good morning|good afternoon|good evening)\b'))) {
      intent = ChatbotIntent.greeting;
    } else if (lowercaseText.contains(RegExp(r'\b(help|assist|support|how to|what can you)\b'))) {
      intent = ChatbotIntent.help;
    } else if (lowercaseText.contains(RegExp(r'\b(task|todo|reminder|goal|complete|finish)\b'))) {
      intent = ChatbotIntent.task_management;
    } else if (lowercaseText
        .contains(RegExp(r'\b(service|provider|therapist|support worker|find|search)\b'))) {
      intent = ChatbotIntent.service_finder;
    } else if (lowercaseText.contains(RegExp(r'\b(budget|money|fund|cost|price|plan)\b'))) {
      intent = ChatbotIntent.budget_info;
    } else if (lowercaseText
        .contains(RegExp(r'\b(appointment|meeting|schedule|book|calendar)\b'))) {
      intent = ChatbotIntent.appointment_booking;
    } else if (lowercaseText.contains(RegExp(r'\b(emergency|urgent|help|danger|crisis)\b'))) {
      intent = ChatbotIntent.emergency;
    }

    final responses = _fallbackResponses[intent] ?? _fallbackResponses[ChatbotIntent.general]!;
    final randomIndex = math.Random().nextInt(responses.length);

    return {
      'text': responses[randomIndex],
      'intent': intent,
    };
  }

  // Message history management
  Future<List<ChatMessage>> getChatHistory({String? sessionId, int limit = 50}) async {
    try {
      final box = await Hive.openBox<String>(_chatBoxName);
      final key = sessionId ?? 'default';
      final historyJson = box.get(key);

      if (historyJson != null) {
        final history = (jsonDecode(historyJson) as List)
            .map((item) => ChatMessage.fromMap(item as Map<String, dynamic>))
            .toList();

        // Return last N messages
        return history.length > limit ? history.sublist(history.length - limit) : history;
      }
    } catch (e) {
      // Ignore cache errors
    }
    return [];
  }

  Future<void> _saveMessage(ChatMessage message, String? sessionId) async {
    try {
      final box = await Hive.openBox<String>(_chatBoxName);
      final key = sessionId ?? 'default';
      final existingHistory = await getChatHistory(sessionId: sessionId, limit: 1000);

      existingHistory.add(message);

      final historyJson = jsonEncode(existingHistory.map((m) => m.toMap()).toList());
      await box.put(key, historyJson);
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<void> clearChatHistory({String? sessionId}) async {
    try {
      final box = await Hive.openBox<String>(_chatBoxName);
      final key = sessionId ?? 'default';
      await box.delete(key);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Session management
  Future<String> createNewSession() async {
    final sessionId = _uuid.v4();
    final sessionData = {
      'id': sessionId,
      'createdAt': DateTime.now().toIso8601String(),
      'userId': _auth.currentUser?.uid,
    };

    try {
      final box = await Hive.openBox<String>(_sessionBoxName);
      await box.put(sessionId, jsonEncode(sessionData));
    } catch (e) {
      // Ignore cache errors
    }

    return sessionId;
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final box = await Hive.openBox<String>(_sessionBoxName);
      final sessions = <Map<String, dynamic>>[];

      for (final key in box.keys) {
        final sessionJson = box.get(key);
        if (sessionJson != null) {
          final session = jsonDecode(sessionJson) as Map<String, dynamic>;
          sessions.add(session);
        }
      }

      // Sort by creation date (newest first)
      sessions.sort((a, b) => DateTime.parse(b['createdAt'] as String)
          .compareTo(DateTime.parse(a['createdAt'] as String)));

      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      final box = await Hive.openBox<String>(_sessionBoxName);
      await box.delete(sessionId);
      await clearChatHistory(sessionId: sessionId);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Quick actions
  List<Map<String, dynamic>> getQuickActions() {
    return [
      {
        'title': 'Help with tasks',
        'message': 'I need help managing my tasks',
        'intent': ChatbotIntent.task_management,
      },
      {
        'title': 'Find services',
        'message': 'Help me find service providers',
        'intent': ChatbotIntent.service_finder,
      },
      {
        'title': 'Budget info',
        'message': 'Show me my budget information',
        'intent': ChatbotIntent.budget_info,
      },
      {
        'title': 'Appointments',
        'message': 'Help with my appointments',
        'intent': ChatbotIntent.appointment_booking,
      },
      {
        'title': 'Emergency help',
        'message': 'I need emergency support',
        'intent': ChatbotIntent.emergency,
      },
    ];
  }

  // Analytics
  Future<Map<String, dynamic>> getChatAnalytics({String? sessionId}) async {
    try {
      final history = await getChatHistory(sessionId: sessionId, limit: 1000);

      final userMessages = history.where((m) => m.type == ChatMessageType.user).length;
      final botMessages = history.where((m) => m.type == ChatMessageType.bot).length;

      final intentCounts = <ChatbotIntent, int>{};
      for (final message in history) {
        if (message.intent != null) {
          intentCounts[message.intent!] = (intentCounts[message.intent!] ?? 0) + 1;
        }
      }

      return {
        'totalMessages': history.length,
        'userMessages': userMessages,
        'botMessages': botMessages,
        'intentCounts': intentCounts.map((k, v) => MapEntry(k.name, v)),
        'lastActivity': history.isNotEmpty ? history.last.timestamp : null,
      };
    } catch (e) {
      return {};
    }
  }
}
