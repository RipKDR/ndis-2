import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/models/chat_message.dart';
import 'package:ndis_connect/services/chatbot_service.dart';

import 'chatbot_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, Connectivity])
void main() {
  group('ChatbotService', () {
    late ChatbotService chatbotService;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockConnectivity = MockConnectivity();

      when(mockUser.uid).thenReturn('test-user-id');
      when(mockAuth.currentUser).thenReturn(mockUser);

      chatbotService = ChatbotService(
        auth: mockAuth,
        connectivity: mockConnectivity,
      );
    });

    group('sendMessage', () {
      test('should return bot response for greeting', () async {
        // Arrange
        const message = 'Hello';
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.sendMessage(message, sessionId: sessionId);

        // Assert
        expect(result, isA<ChatMessage>());
        expect(result.type, ChatMessageType.bot);
        expect(result.intent, ChatbotIntent.greeting);
        expect(result.text, isNotEmpty);
      });

      test('should return bot response for help request', () async {
        // Arrange
        const message = 'I need help';
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.sendMessage(message, sessionId: sessionId);

        // Assert
        expect(result, isA<ChatMessage>());
        expect(result.type, ChatMessageType.bot);
        expect(result.intent, ChatbotIntent.help);
        expect(result.text, isNotEmpty);
      });

      test('should return bot response for task management', () async {
        // Arrange
        const message = 'I want to create a task';
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.sendMessage(message, sessionId: sessionId);

        // Assert
        expect(result, isA<ChatMessage>());
        expect(result.type, ChatMessageType.bot);
        expect(result.intent, ChatbotIntent.task_management);
        expect(result.text, isNotEmpty);
      });

      test('should return bot response for service finder', () async {
        // Arrange
        const message = 'Find me a therapist';
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.sendMessage(message, sessionId: sessionId);

        // Assert
        expect(result, isA<ChatMessage>());
        expect(result.type, ChatMessageType.bot);
        expect(result.intent, ChatbotIntent.service_finder);
        expect(result.text, isNotEmpty);
      });

      test('should return bot response for budget info', () async {
        // Arrange
        const message = 'Show me my budget';
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.sendMessage(message, sessionId: sessionId);

        // Assert
        expect(result, isA<ChatMessage>());
        expect(result.type, ChatMessageType.bot);
        expect(result.intent, ChatbotIntent.budget_info);
        expect(result.text, isNotEmpty);
      });

      test('should return bot response for appointment booking', () async {
        // Arrange
        const message = 'Schedule an appointment';
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.sendMessage(message, sessionId: sessionId);

        // Assert
        expect(result, isA<ChatMessage>());
        expect(result.type, ChatMessageType.bot);
        expect(result.intent, ChatbotIntent.appointment_booking);
        expect(result.text, isNotEmpty);
      });

      test('should return bot response for emergency', () async {
        // Arrange
        const message = 'I need emergency help';
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.sendMessage(message, sessionId: sessionId);

        // Assert
        expect(result, isA<ChatMessage>());
        expect(result.type, ChatMessageType.bot);
        expect(result.intent, ChatbotIntent.emergency);
        expect(result.text, isNotEmpty);
      });

      test('should return general response for unknown intent', () async {
        // Arrange
        const message = 'Random text that does not match any intent';
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.sendMessage(message, sessionId: sessionId);

        // Assert
        expect(result, isA<ChatMessage>());
        expect(result.type, ChatMessageType.bot);
        expect(result.intent, ChatbotIntent.general);
        expect(result.text, isNotEmpty);
      });
    });

    group('getChatHistory', () {
      test('should return empty list when no history exists', () async {
        // Arrange
        const sessionId = 'test-session';

        // Act
        final result = await chatbotService.getChatHistory(sessionId: sessionId);

        // Assert
        expect(result, isA<List<ChatMessage>>());
        expect(result, isEmpty);
      });

      test('should return chat history when it exists', () async {
        // Arrange
        const sessionId = 'test-session';
        const message = 'Hello';

        // Send a message first to create history
        await chatbotService.sendMessage(message, sessionId: sessionId);

        // Act
        final result = await chatbotService.getChatHistory(sessionId: sessionId);

        // Assert
        expect(result, isA<List<ChatMessage>>());
        expect(result.length, 2); // User message + bot response
        expect(result.first.type, ChatMessageType.user);
        expect(result.last.type, ChatMessageType.bot);
      });
    });

    group('clearChatHistory', () {
      test('should clear chat history', () async {
        // Arrange
        const sessionId = 'test-session';
        const message = 'Hello';

        // Send a message first to create history
        await chatbotService.sendMessage(message, sessionId: sessionId);

        // Verify history exists
        var history = await chatbotService.getChatHistory(sessionId: sessionId);
        expect(history.length, 2);

        // Act
        await chatbotService.clearChatHistory(sessionId: sessionId);

        // Assert
        history = await chatbotService.getChatHistory(sessionId: sessionId);
        expect(history, isEmpty);
      });
    });

    group('createNewSession', () {
      test('should create a new session with unique ID', () async {
        // Act
        final sessionId1 = await chatbotService.createNewSession();
        final sessionId2 = await chatbotService.createNewSession();

        // Assert
        expect(sessionId1, isNotEmpty);
        expect(sessionId2, isNotEmpty);
        expect(sessionId1, isNot(equals(sessionId2)));
      });
    });

    group('getSessions', () {
      test('should return list of sessions', () async {
        // Arrange
        final sessionId1 = await chatbotService.createNewSession();
        final sessionId2 = await chatbotService.createNewSession();

        // Act
        final sessions = await chatbotService.getSessions();

        // Assert
        expect(sessions, isA<List<Map<String, dynamic>>>());
        expect(sessions.length, 2);
        expect(sessions.any((s) => s['id'] == sessionId1), isTrue);
        expect(sessions.any((s) => s['id'] == sessionId2), isTrue);
      });
    });

    group('deleteSession', () {
      test('should delete a session', () async {
        // Arrange
        final sessionId = await chatbotService.createNewSession();

        // Verify session exists
        var sessions = await chatbotService.getSessions();
        expect(sessions.length, 1);

        // Act
        await chatbotService.deleteSession(sessionId);

        // Assert
        sessions = await chatbotService.getSessions();
        expect(sessions, isEmpty);
      });
    });

    group('getQuickActions', () {
      test('should return list of quick actions', () {
        // Act
        final quickActions = chatbotService.getQuickActions();

        // Assert
        expect(quickActions, isA<List<Map<String, dynamic>>>());
        expect(quickActions.length, 5);

        final actionTitles = quickActions.map((a) => a['title'] as String).toList();
        expect(actionTitles, contains('Help with tasks'));
        expect(actionTitles, contains('Find services'));
        expect(actionTitles, contains('Budget info'));
        expect(actionTitles, contains('Appointments'));
        expect(actionTitles, contains('Emergency help'));
      });
    });

    group('getChatAnalytics', () {
      test('should return analytics for empty chat', () async {
        // Arrange
        const sessionId = 'test-session';

        // Act
        final analytics = await chatbotService.getChatAnalytics(sessionId: sessionId);

        // Assert
        expect(analytics, isA<Map<String, dynamic>>());
        expect(analytics['totalMessages'], 0);
        expect(analytics['userMessages'], 0);
        expect(analytics['botMessages'], 0);
        expect(analytics['intentCounts'], isA<Map<String, dynamic>>());
      });

      test('should return analytics for chat with messages', () async {
        // Arrange
        const sessionId = 'test-session';
        await chatbotService.sendMessage('Hello', sessionId: sessionId);
        await chatbotService.sendMessage('Help me', sessionId: sessionId);

        // Act
        final analytics = await chatbotService.getChatAnalytics(sessionId: sessionId);

        // Assert
        expect(analytics, isA<Map<String, dynamic>>());
        expect(analytics['totalMessages'], 4); // 2 user + 2 bot messages
        expect(analytics['userMessages'], 2);
        expect(analytics['botMessages'], 2);
        expect(analytics['intentCounts'], isA<Map<String, dynamic>>());
        expect(analytics['lastActivity'], isNotNull);
      });
    });

    group('ChatMessage', () {
      test('should create ChatMessage with all properties', () {
        // Arrange
        final timestamp = DateTime.now();
        const intent = ChatbotIntent.greeting;
        final metadata = {'test': 'value'};

        // Act
        final message = ChatMessage(
          id: 'test-id',
          text: 'Test message',
          type: ChatMessageType.user,
          timestamp: timestamp,
          intent: intent,
          metadata: metadata,
        );

        // Assert
        expect(message.id, 'test-id');
        expect(message.text, 'Test message');
        expect(message.type, ChatMessageType.user);
        expect(message.timestamp, timestamp);
        expect(message.intent, intent);
        expect(message.metadata, metadata);
      });

      test('should serialize and deserialize ChatMessage', () {
        // Arrange
        final originalMessage = ChatMessage(
          id: 'test-id',
          text: 'Test message',
          type: ChatMessageType.bot,
          timestamp: DateTime.now(),
          intent: ChatbotIntent.help,
          metadata: {'test': 'value'},
        );

        // Act
        final map = originalMessage.toMap();
        final deserializedMessage = ChatMessage.fromMap(map);

        // Assert
        expect(deserializedMessage.id, originalMessage.id);
        expect(deserializedMessage.text, originalMessage.text);
        expect(deserializedMessage.type, originalMessage.type);
        expect(deserializedMessage.intent, originalMessage.intent);
        expect(deserializedMessage.metadata, originalMessage.metadata);
      });
    });
  });
}
