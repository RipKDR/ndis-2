import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      authService = AuthService(auth: mockAuth);
    });

    group('signInWithEmailAndPassword', () {
      test('should return user when sign in is successful', () async {
        // Arrange
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn('test@example.com');

        // Act
        final result = await authService.signInWithEmailAndPassword(
          'test@example.com',
          'password123',
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.user?.uid, equals('test-uid'));
        expect(result.user?.email, equals('test@example.com'));
      });

      test('should throw exception when sign in fails', () async {
        // Arrange
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email.',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(
            'invalid@example.com',
            'wrongpassword',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('should return user when sign up is successful', () async {
        // Arrange
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('new-user-uid');
        when(mockUser.email).thenReturn('newuser@example.com');

        // Act
        final result = await authService.signUpWithEmailAndPassword(
          'newuser@example.com',
          'password123',
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.user?.uid, equals('new-user-uid'));
        expect(result.user?.email, equals('newuser@example.com'));
      });

      test('should throw exception when email already exists', () async {
        // Arrange
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The account already exists for that email.',
        ));

        // Act & Assert
        expect(
          () => authService.signUpWithEmailAndPassword(
            'existing@example.com',
            'password123',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {
          return;
        });

        // Act
        await authService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return current user when authenticated', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('current-user-uid');

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result!.uid, equals('current-user-uid'));
      });

      test('should return null when not authenticated', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });
  });
}
