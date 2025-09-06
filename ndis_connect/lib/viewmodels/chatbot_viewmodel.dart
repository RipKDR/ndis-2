import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/chatbot_service.dart';

class ChatbotViewModel extends ChangeNotifier {
  final ChatbotService _chatbotService;
  final FirebaseAuth _auth;

  ChatbotViewModel(this._chatbotService, this._auth);

  // State
  List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _loadingHistory = false;
  String? _error;
  String? _currentSessionId;

  // Getters
  List<ChatMessage> get messages => _messages;
  bool get loading => _loading;
  bool get loadingHistory => _loadingHistory;
  String? get error => _error;
  String? get currentSessionId => _currentSessionId;
  ChatbotService get chatbotService => _chatbotService;

  // Methods
  Future<void> sendMessage(String text, {String? sessionId}) async {
    if (text.trim().isEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _chatbotService.sendMessage(
        text,
        sessionId: sessionId ?? _currentSessionId,
      );

      // Add both user and bot messages to the list
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        type: ChatMessageType.user,
        timestamp: DateTime.now(),
      ));
      _messages.add(response);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadChatHistory(String? sessionId) async {
    if (sessionId == null) return;

    _loadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _chatbotService.getChatHistory(sessionId: sessionId);
      _currentSessionId = sessionId;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loadingHistory = false;
      notifyListeners();
    }
  }

  Future<String> createNewSession() async {
    try {
      final sessionId = await _chatbotService.createNewSession();
      _currentSessionId = sessionId;
      _messages = [];
      notifyListeners();
      return sessionId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      return await _chatbotService.getSessions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _chatbotService.deleteSession(sessionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages = [];
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearChatHistory(String? sessionId) async {
    if (sessionId == null) return;

    try {
      await _chatbotService.clearChatHistory(sessionId: sessionId);
      _messages = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getChatAnalytics({String? sessionId}) async {
    try {
      return await _chatbotService.getChatAnalytics(
        sessionId: sessionId ?? _currentSessionId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
