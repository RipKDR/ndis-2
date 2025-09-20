import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/firebase_options.dart';
import 'package:ndis_connect/services/analytics_service.dart';
import 'package:ndis_connect/services/auth_service.dart';
import 'package:ndis_connect/services/notifications_service.dart';
import 'package:ndis_connect/services/remote_config_service.dart';

import 'firebase_test_utils.mocks.dart';

// Generate mocks for Firebase services
@GenerateMocks([
  FirebaseAuth,
  User,
  UserCredential,
])
class FirebaseTestUtils {
  static bool _firebaseInitialized = false;

  /// Initialize Firebase for testing if not already initialized
  static Future<void> initializeFirebaseForTesting() async {
    if (_firebaseInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseInitialized = true;
      print('Firebase initialized for testing');
    } catch (e) {
      print('Firebase initialization failed in testing: $e');
      // Continue with mock services
    }
  }

  /// Create a test-ready AuthService with optional mocking
  static AuthService createTestAuthService({FirebaseAuth? mockAuth}) {
    return AuthService(auth: mockAuth);
  }

  /// Create a test-ready AnalyticsService
  static AnalyticsService createTestAnalyticsService() {
    return AnalyticsService();
  }

  /// Create a test-ready RemoteConfigService with null config (uses defaults)
  static RemoteConfigService createTestRemoteConfigService() {
    return RemoteConfigService(null);
  }

  /// Create a test-ready NotificationsService
  static Future<NotificationsService> createTestNotificationsService() async {
    final service = NotificationsService();
    try {
      await service.initialize();
    } catch (e) {
      print('Notifications service initialization failed: $e');
    }
    return service;
  }

  /// Setup common test environment for Firebase services
  static Future<Map<String, dynamic>> setupTestEnvironment() async {
    await initializeFirebaseForTesting();

    return {
      'authService': createTestAuthService(),
      'analyticsService': createTestAnalyticsService(),
      'remoteConfigService': createTestRemoteConfigService(),
      'notificationsService': await createTestNotificationsService(),
      'firebaseAvailable': _firebaseInitialized,
    };
  }

  /// Create a mock user for testing
  static User createMockUser({
    String uid = 'test-user-123',
    String email = 'test@example.com',
    bool isAnonymous = false,
    String displayName = 'Test User',
  }) {
    final mockUser = MockUser();
    when(mockUser.uid).thenReturn(uid);
    when(mockUser.email).thenReturn(email);
    when(mockUser.isAnonymous).thenReturn(isAnonymous);
    when(mockUser.displayName).thenReturn(displayName);
    when(mockUser.delete()).thenAnswer((_) async {});
    when(mockUser.updateDisplayName(any)).thenAnswer((_) async {});
    when(mockUser.updatePhotoURL(any)).thenAnswer((_) async {});
    return mockUser;
  }

  /// Create a mock UserCredential for testing
  static UserCredential createMockUserCredential({User? user}) {
    final mockCredential = MockUserCredential();
    when(mockCredential.user).thenReturn(user ?? createMockUser());
    return mockCredential;
  }

  /// Setup mock FirebaseAuth for testing
  static FirebaseAuth createMockFirebaseAuth({
    User? currentUser,
    Stream<User?>? authStateChanges,
  }) {
    final mockAuth = MockFirebaseAuth();

    when(mockAuth.currentUser).thenReturn(currentUser);
    when(mockAuth.authStateChanges()).thenAnswer(
      (_) => authStateChanges ?? Stream.value(currentUser),
    );

    // Setup common auth methods
    when(mockAuth.signInAnonymously()).thenAnswer(
      (_) async => createMockUserCredential(user: createMockUser(isAnonymous: true)),
    );

    when(mockAuth.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => createMockUserCredential());

    when(mockAuth.createUserWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => createMockUserCredential());

    when(mockAuth.signOut()).thenAnswer((_) async {});
    when(mockAuth.sendPasswordResetEmail(email: anyNamed('email'))).thenAnswer((_) async {});

    return mockAuth;
  }

  /// Test helper to verify Firebase service graceful degradation
  static Future<void> testServiceGracefulDegradation({
    required Future<void> Function() serviceCall,
    required String serviceName,
  }) async {
    try {
      await serviceCall();
      print('$serviceName: Operation completed successfully');
    } catch (e) {
      print('$serviceName: Graceful degradation - $e');
      // Services should handle Firebase unavailability gracefully
      expect(e, isA<Exception>());
    }
  }

  /// Cleanup test environment
  static Future<void> cleanupTestEnvironment() async {
    try {
      if (_firebaseInitialized && FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      print('Test cleanup failed: $e');
    }
  }

  /// Generate test data for various scenarios
  static Map<String, dynamic> generateTestData() {
    final now = DateTime.now();
    return {
      'testUserId': 'test-user-${now.millisecondsSinceEpoch}',
      'testEmail': 'test${now.millisecondsSinceEpoch}@example.com',
      'testPassword': 'TestPassword123!',
      'testTaskTitle': 'Test Task ${now.millisecondsSinceEpoch}',
      'testTaskDescription': 'Test task created at $now',
      'timestamp': now,
    };
  }

  /// Verify Firebase configuration is valid
  static bool isFirebaseConfigured() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Create test environment with proper error handling
  static Future<TestEnvironment> createTestEnvironment() async {
    final testData = generateTestData();
    final services = await setupTestEnvironment();

    return TestEnvironment(
      services: services,
      testData: testData,
      firebaseAvailable: services['firebaseAvailable'] as bool,
    );
  }
}

/// Test environment container class
class TestEnvironment {
  final Map<String, dynamic> services;
  final Map<String, dynamic> testData;
  final bool firebaseAvailable;

  TestEnvironment({
    required this.services,
    required this.testData,
    required this.firebaseAvailable,
  });

  AuthService get authService => services['authService'] as AuthService;
  AnalyticsService get analyticsService => services['analyticsService'] as AnalyticsService;
  RemoteConfigService get remoteConfigService =>
      services['remoteConfigService'] as RemoteConfigService;
  NotificationsService get notificationsService =>
      services['notificationsService'] as NotificationsService;

  String get testUserId => testData['testUserId'] as String;
  String get testEmail => testData['testEmail'] as String;
  String get testPassword => testData['testPassword'] as String;
  String get testTaskTitle => testData['testTaskTitle'] as String;
  String get testTaskDescription => testData['testTaskDescription'] as String;
  DateTime get timestamp => testData['timestamp'] as DateTime;

  Future<void> cleanup() async {
    await FirebaseTestUtils.cleanupTestEnvironment();
  }
}
