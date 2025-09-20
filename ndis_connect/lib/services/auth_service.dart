import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final bool _isFirebaseAvailable;

  AuthService({FirebaseAuth? auth})
      : _isFirebaseAvailable = _checkFirebaseAvailability(),
        _auth = _checkFirebaseAvailability() ? (auth ?? FirebaseAuth.instance) : null;

  static bool _checkFirebaseAvailability() {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<User?> get authStateChanges {
    if (!_isFirebaseAvailable || _auth == null) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  Future<UserCredential> signInAnonymously() async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception('Firebase authentication is not available');
    }
    return await _auth.signInAnonymously();
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception('Firebase authentication is not available');
    }
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception('Firebase authentication is not available');
    }
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  User? getCurrentUser() {
    if (!_isFirebaseAvailable || _auth == null) {
      return null;
    }
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    if (!_isFirebaseAvailable || _auth == null) {
      return; // No-op when Firebase is not available
    }
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Enhanced methods for better error handling
  Future<bool> isUserSignedIn() async {
    if (!_isFirebaseAvailable || _auth == null) {
      return false;
    }
    return _auth.currentUser != null;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception('Firebase authentication is not available');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception('Firebase authentication is not available');
    }
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> deleteUser() async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception('Firebase authentication is not available');
    }
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } catch (e) {
        rethrow;
      }
    }
  }

  // Utility method to check if Firebase is available
  bool get isFirebaseAvailable => _isFirebaseAvailable;
}
