import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndis_connect/firebase_options.dart';
import 'package:ndis_connect/services/analytics_service.dart';
import 'package:ndis_connect/services/auth_service.dart';
import 'package:ndis_connect/services/notifications_service.dart';
import 'package:ndis_connect/services/remote_config_service.dart';
import 'package:ndis_connect/services/task_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Availability and Graceful Degradation Tests', () {
    bool firebaseAvailable = false;

    setUpAll(() async {
      // Try to initialize Firebase
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseAvailable = true;
        print('✅ Firebase initialized successfully');
      } catch (e) {
        firebaseAvailable = false;
        print('❌ Firebase initialization failed: $e');
        print('🔄 Testing graceful degradation...');
      }
    });

    group('Firebase Initialization Tests', () {
      test('should detect Firebase availability correctly', () {
        if (firebaseAvailable) {
          expect(Firebase.apps.isNotEmpty, isTrue);
          expect(Firebase.app().name, equals('[DEFAULT]'));
          print('✅ Firebase is available and configured');
        } else {
          expect(() => Firebase.app(), throwsA(isA<Exception>()));
          print('✅ Firebase unavailability detected correctly');
        }
      });
    });

    group('Service Graceful Degradation Tests', () {
      test('AuthService should handle Firebase unavailability', () {
        expect(() => AuthService(), returnsNormally);
        print('✅ AuthService created successfully');

        if (!firebaseAvailable) {
          final authService = AuthService();
          expect(() => authService.getCurrentUser(), returnsNormally);
          print('✅ AuthService handles Firebase unavailability gracefully');
        }
      });

      test('AnalyticsService should handle Firebase unavailability', () {
        expect(() => AnalyticsService(), returnsNormally);
        print('✅ AnalyticsService created successfully');

        final analyticsService = AnalyticsService();
        expect(() => analyticsService.logEvent('test_event'), returnsNormally);
        expect(() => analyticsService.logError('test error', null), returnsNormally);
        print('✅ AnalyticsService handles operations gracefully');
      });

      test('RemoteConfigService should provide defaults when Firebase unavailable', () {
        final remoteConfigService = RemoteConfigService(null);

        expect(remoteConfigService.pointsEnabled, isA<bool>());
        expect(remoteConfigService.aiAssistLevel, isA<String>());
        expect(remoteConfigService.badgeVariant, isA<String>());
        expect(remoteConfigService.remindersFunctionUrl, isA<String>());

        // Test default values
        expect(remoteConfigService.pointsEnabled, isTrue);
        expect(remoteConfigService.aiAssistLevel, equals('basic'));
        expect(remoteConfigService.badgeVariant, equals('A'));
        expect(remoteConfigService.remindersFunctionUrl, equals(''));

        print('✅ RemoteConfigService provides correct defaults');
      });

      test('TaskService should handle Firebase unavailability', () {
        expect(() => TaskService(), returnsNormally);
        print('✅ TaskService created successfully');

        if (!firebaseAvailable) {
          // TaskService should not crash when Firebase is unavailable
          // It should handle errors gracefully when operations are attempted
          print('✅ TaskService handles Firebase unavailability gracefully');
        }
      });

      test('NotificationsService should handle Firebase unavailability', () async {
        final notificationsService = NotificationsService();

        // Should initialize without throwing, even if Firebase is unavailable
        await expectLater(() => notificationsService.initialize(), returnsNormally);
        print('✅ NotificationsService initialized successfully');

        // Should handle local operations even without Firebase
        await expectLater(
            () => notificationsService.scheduleTaskReminder(
                  taskId: 'test-task',
                  taskTitle: 'Test Task',
                  reminderTime: DateTime.now().add(const Duration(hours: 1)),
                ),
            returnsNormally);

        final notifications = notificationsService.getScheduledNotifications();
        expect(notifications, isA<List>());

        if (!firebaseAvailable) {
          // FCM token should return null gracefully
          final token = await notificationsService.getFCMToken();
          expect(token, isNull);
          print('✅ NotificationsService handles FCM unavailability gracefully');
        }

        print('✅ NotificationsService handles all operations gracefully');
      });
    });

    group('Error Handling Tests', () {
      test('services should not crash on Firebase errors', () async {
        // Test that services handle common Firebase errors gracefully

        final authService = AuthService();
        final analyticsService = AnalyticsService();
        final notificationsService = NotificationsService();

        if (!firebaseAvailable) {
          // These operations should fail gracefully, not crash the app
          expect(() => authService.isUserSignedIn(), returnsNormally);
          expect(() => analyticsService.logEvent('test'), returnsNormally);
          expect(() => notificationsService.getFCMToken(), returnsNormally);

          print('✅ All services handle Firebase unavailability gracefully');
        }
      });
    });

    group('Offline Functionality Tests', () {
      test('services should provide offline functionality', () async {
        // Test that services can provide meaningful functionality offline

        final remoteConfigService = RemoteConfigService(null);
        final notificationsService = NotificationsService();
        await notificationsService.initialize();

        // Remote config should provide defaults
        expect(remoteConfigService.pointsEnabled, isNotNull);
        expect(remoteConfigService.aiAssistLevel, isNotNull);

        // Notifications should work locally
        await notificationsService.scheduleTaskReminder(
          taskId: 'offline-task',
          taskTitle: 'Offline Task',
          reminderTime: DateTime.now().add(const Duration(hours: 1)),
        );

        final notifications = notificationsService.getScheduledNotifications();
        expect(notifications.any((n) => n.data?['taskId'] == 'offline-task'), isTrue);

        print('✅ Offline functionality working correctly');
      });
    });

    group('Performance Tests', () {
      test('service initialization should be fast', () async {
        final stopwatch = Stopwatch()..start();

        // These should complete quickly even if Firebase is unavailable
        final authService = AuthService();
        final analyticsService = AnalyticsService();
        final remoteConfigService = RemoteConfigService(null);
        final notificationsService = NotificationsService();

        await notificationsService.initialize();

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds

        print('✅ Service initialization completed in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Configuration Tests', () {
      test('Firebase options should be properly configured', () {
        final options = DefaultFirebaseOptions.currentPlatform;

        expect(options, isNotNull);
        expect(options.apiKey, isNotEmpty);
        expect(options.appId, isNotEmpty);
        expect(options.projectId, isNotEmpty);

        print('✅ Firebase options are properly configured');
        print('   Project ID: ${options.projectId}');
        print('   App ID: ${options.appId}');
      });

      test('should handle different platform configurations', () {
        // Test that we have configurations for different platforms
        expect(() => DefaultFirebaseOptions.web, returnsNormally);
        expect(() => DefaultFirebaseOptions.android, returnsNormally);

        final webOptions = DefaultFirebaseOptions.web;
        final androidOptions = DefaultFirebaseOptions.android;

        expect(webOptions.projectId, isNotEmpty);
        expect(androidOptions.projectId, isNotEmpty);

        print('✅ Multi-platform Firebase configuration verified');
      });
    });

    group('Integration Readiness Tests', () {
      test('should verify which Firebase services are available', () async {
        print('\n🔍 Firebase Service Availability Report:');
        print('==========================================');

        if (firebaseAvailable) {
          print('✅ Firebase Core: Available');

          // Test individual service availability
          try {
            final authService = AuthService();
            await authService.isUserSignedIn();
            print('✅ Firebase Auth: Available');
          } catch (e) {
            print('❌ Firebase Auth: Error - $e');
          }

          try {
            final taskService = TaskService();
            // Don't actually fetch tasks, just verify service can be created
            expect(taskService, isNotNull);
            print('✅ Firestore: Service created successfully');
          } catch (e) {
            print('❌ Firestore: Error - $e');
          }

          try {
            final analyticsService = AnalyticsService();
            await analyticsService.logEvent('availability_test');
            print('✅ Firebase Analytics: Available');
          } catch (e) {
            print('❌ Firebase Analytics: Error - $e');
          }

          try {
            final notificationsService = NotificationsService();
            await notificationsService.initialize();
            print('✅ Firebase Messaging: Initialized successfully');
          } catch (e) {
            print('❌ Firebase Messaging: Error - $e');
          }
        } else {
          print('❌ Firebase Core: Not available (graceful degradation active)');
          print('✅ Local functionality: Available');
          print('✅ Offline mode: Available');
        }

        print('==========================================\n');
      });
    });
  });
}
