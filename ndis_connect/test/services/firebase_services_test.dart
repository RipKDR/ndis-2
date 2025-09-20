import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/services/analytics_service.dart';
import 'package:ndis_connect/services/auth_service.dart';
import 'package:ndis_connect/services/notifications_service.dart';
import 'package:ndis_connect/services/remote_config_service.dart';
import 'package:ndis_connect/services/task_service.dart';

import '../utils/firebase_test_utils.dart';
import 'firebase_services_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  UserCredential,
  FirebaseRemoteConfig,
  TaskService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Services Unit Tests', () {
    late TestEnvironment testEnv;

    setUpAll(() async {
      testEnv = await FirebaseTestUtils.createTestEnvironment();
    });

    tearDownAll(() async {
      await testEnv.cleanup();
    });

    group('AuthService Tests', () {
      late AuthService authService;
      late MockFirebaseAuth mockAuth;
      late MockUser mockUser;
      late MockUserCredential mockCredential;

      setUp(() {
        mockAuth = MockFirebaseAuth();
        mockUser = MockUser();
        mockCredential = MockUserCredential();
        authService = AuthService(auth: mockAuth);

        // Setup common mock behaviors
        when(mockUser.uid).thenReturn('test-uid-123');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.isAnonymous).thenReturn(false);
        when(mockCredential.user).thenReturn(mockUser);
      });

      test('should sign in anonymously successfully', () async {
        // Arrange
        when(mockAuth.signInAnonymously()).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signInAnonymously();

        // Assert
        expect(result, equals(mockCredential));
        verify(mockAuth.signInAnonymously()).called(1);
      });

      test('should sign in with email and password', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signInWithEmailAndPassword(email, password);

        // Assert
        expect(result, equals(mockCredential));
        verify(mockAuth.signInWithEmailAndPassword(email: email, password: password)).called(1);
      });

      test('should create user with email and password', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'password123';
        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signUpWithEmailAndPassword(email, password);

        // Assert
        expect(result, equals(mockCredential));
        verify(mockAuth.createUserWithEmailAndPassword(email: email, password: password)).called(1);
      });

      test('should get current user', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, equals(mockUser));
        verify(mockAuth.currentUser).called(1);
      });

      test('should sign out successfully', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });

      test('should check if user is signed in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = await authService.isUserSignedIn();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when no user is signed in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = await authService.isUserSignedIn();

        // Assert
        expect(result, isFalse);
      });

      test('should send password reset email', () async {
        // Arrange
        const email = 'test@example.com';
        when(mockAuth.sendPasswordResetEmail(email: email)).thenAnswer((_) async {});

        // Act
        await authService.sendPasswordResetEmail(email);

        // Assert
        verify(mockAuth.sendPasswordResetEmail(email: email)).called(1);
      });

      test('should update user profile', () async {
        // Arrange
        const displayName = 'New Display Name';
        const photoURL = 'https://example.com/photo.jpg';
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.updateDisplayName(displayName)).thenAnswer((_) async {});
        when(mockUser.updatePhotoURL(photoURL)).thenAnswer((_) async {});

        // Act
        await authService.updateUserProfile(displayName: displayName, photoURL: photoURL);

        // Assert
        verify(mockUser.updateDisplayName(displayName)).called(1);
        verify(mockUser.updatePhotoURL(photoURL)).called(1);
      });

      test('should delete user', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.delete()).thenAnswer((_) async {});

        // Act
        await authService.deleteUser();

        // Assert
        verify(mockUser.delete()).called(1);
      });

      test('should handle auth state changes', () {
        // Arrange
        final stream = Stream<User?>.fromIterable([null, mockUser, null]);
        when(mockAuth.authStateChanges()).thenAnswer((_) => stream);

        // Act
        final result = authService.authStateChanges;

        // Assert
        expect(result, equals(stream));
      });
    });

    group('AnalyticsService Tests', () {
      late AnalyticsService analyticsService;

      setUp(() {
        analyticsService = AnalyticsService();
      });

      test('should log events without throwing exceptions', () async {
        // Act & Assert - Should not throw
        await analyticsService.logEvent('test_event', params: {
          'param1': 'value1',
          'param2': 42,
        });
      });

      test('should log errors without throwing exceptions', () {
        // Act & Assert - Should not throw
        analyticsService.logError('Test error message', StackTrace.current);
      });

      test('should handle null parameters gracefully', () async {
        // Act & Assert - Should not throw
        await analyticsService.logEvent('test_event');
      });
    });

    group('RemoteConfigService Tests', () {
      late RemoteConfigService remoteConfigService;
      late MockFirebaseRemoteConfig mockRemoteConfig;

      setUp(() {
        mockRemoteConfig = MockFirebaseRemoteConfig();
        remoteConfigService = RemoteConfigService(mockRemoteConfig);
      });

      test('should return configured boolean values', () {
        // Arrange
        when(mockRemoteConfig.getBool('points_enabled')).thenReturn(true);

        // Act
        final result = remoteConfigService.pointsEnabled;

        // Assert
        expect(result, isTrue);
        verify(mockRemoteConfig.getBool('points_enabled')).called(1);
      });

      test('should return default boolean values when remote config fails', () {
        // Arrange
        when(mockRemoteConfig.getBool('points_enabled'))
            .thenThrow(Exception('Remote config error'));

        // Act
        final result = remoteConfigService.pointsEnabled;

        // Assert
        expect(result, isTrue); // Should return default value
      });

      test('should return configured string values', () {
        // Arrange
        when(mockRemoteConfig.getString('ai_assist_level')).thenReturn('advanced');

        // Act
        final result = remoteConfigService.aiAssistLevel;

        // Assert
        expect(result, equals('advanced'));
        verify(mockRemoteConfig.getString('ai_assist_level')).called(1);
      });

      test('should return default string values when remote config fails', () {
        // Arrange
        when(mockRemoteConfig.getString('ai_assist_level'))
            .thenThrow(Exception('Remote config error'));

        // Act
        final result = remoteConfigService.aiAssistLevel;

        // Assert
        expect(result, equals('basic')); // Should return default value
      });

      test('should handle null remote config gracefully', () {
        // Arrange
        final nullConfigService = RemoteConfigService(null);

        // Act & Assert
        expect(nullConfigService.pointsEnabled, isTrue);
        expect(nullConfigService.aiAssistLevel, equals('basic'));
        expect(nullConfigService.badgeVariant, equals('A'));
        expect(nullConfigService.remindersFunctionUrl, equals(''));
      });
    });

    group('TaskService Integration Tests', () {
      test('should handle Firebase unavailable gracefully', () async {
        // This test verifies that TaskService handles Firebase initialization failure
        // In a real scenario where Firebase is not available, the service should
        // either provide offline functionality or graceful error handling

        final taskService = TaskService();

        // Test that the service doesn't crash when Firebase is unavailable
        expect(() => taskService, returnsNormally);
      });
    });

    group('NotificationsService Tests', () {
      late NotificationsService notificationsService;

      setUp(() async {
        notificationsService = NotificationsService();
        // Initialize without Firebase to test graceful degradation
        await notificationsService.initialize();
      });

      test('should schedule notifications locally', () async {
        // Act
        await notificationsService.scheduleTaskReminder(
          taskId: 'test-task',
          taskTitle: 'Test Task',
          reminderTime: DateTime.now().add(const Duration(hours: 1)),
          description: 'Test reminder',
        );

        // Assert
        final notifications = notificationsService.getScheduledNotifications();
        expect(notifications, isNotEmpty);
        expect(notifications.first.data?['taskId'], equals('test-task'));
      });

      test('should cancel notifications', () async {
        // Arrange
        await notificationsService.scheduleTaskReminder(
          taskId: 'test-task',
          taskTitle: 'Test Task',
          reminderTime: DateTime.now().add(const Duration(hours: 1)),
        );

        final notifications = notificationsService.getScheduledNotifications();
        expect(notifications, isNotEmpty);

        // Act
        await notificationsService.cancelNotification(notifications.first.id);

        // Assert
        final updatedNotifications = notificationsService.getScheduledNotifications();
        expect(updatedNotifications, isEmpty);
      });

      test('should handle FCM token gracefully when Firebase unavailable', () async {
        // Act
        final token = await notificationsService.getFCMToken();

        // Assert
        // Should return null when Firebase is not available, not throw an exception
        expect(token, isNull);
      });
    });

    group('Service Integration Tests', () {
      test('all services should initialize without throwing exceptions', () async {
        // This test ensures that all services can be created and initialized
        // even when Firebase is not fully configured

        expect(() => AuthService(), returnsNormally);
        expect(() => AnalyticsService(), returnsNormally);
        expect(() => RemoteConfigService(null), returnsNormally);
        expect(() => TaskService(), returnsNormally);

        final notificationService = NotificationsService();
        await expectLater(() => notificationService.initialize(), returnsNormally);
      });

      test('services should handle offline scenarios gracefully', () async {
        // Test that services provide meaningful functionality even when offline

        final authService = AuthService();
        final analyticsService = AnalyticsService();
        final remoteConfigService = RemoteConfigService(null);

        // These operations should not throw exceptions
        await expectLater(() => authService.isUserSignedIn(), returnsNormally);
        await expectLater(() => analyticsService.logEvent('test'), returnsNormally);
        expect(() => remoteConfigService.pointsEnabled, returnsNormally);
      });
    });
  });
}
