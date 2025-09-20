import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import 'error_handling_service.dart';

class UserService {
  static const _boxName = 'user_profile_box';
  final FirebaseFirestore? _db;
  final bool _isFirebaseAvailable;
  final ErrorHandlingService _errorHandler;

  UserService({ErrorHandlingService? errorHandler})
      : _isFirebaseAvailable = _checkFirebaseAvailability(),
        _db = _checkFirebaseAvailability() ? FirebaseFirestore.instance : null,
        _errorHandler = errorHandler ?? ErrorHandlingService();

  static bool _checkFirebaseAvailability() {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<UserProfile?> getLocal(String uid) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final raw = box.get(uid);
      if (raw == null) return null;
      return UserProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        type: ErrorType.database,
        stackTrace: stackTrace,
        context: {
          'operation': 'getLocal',
          'uid': uid,
          'service': 'UserService',
        },
      );
      return null;
    }
  }

  Future<void> saveLocal(UserProfile profile) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(profile.uid, jsonEncode(profile.toMap()));
    } catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        type: ErrorType.database,
        stackTrace: stackTrace,
        context: {
          'operation': 'saveLocal',
          'uid': profile.uid,
          'service': 'UserService',
        },
      );
      rethrow; // Re-throw since this is a critical operation
    }
  }

  Future<UserProfile?> fetchRemote(String uid) async {
    if (!_isFirebaseAvailable || _db == null) {
      _errorHandler.handleError(
        'Firebase not available for remote user fetch',
        type: ErrorType.firebase,
        context: {
          'operation': 'fetchRemote',
          'uid': uid,
          'service': 'UserService',
        },
      );
      return await getLocal(uid); // Fallback to local
    }

    try {
      final snap = await _db.collection('users').doc(uid).get(const GetOptions(source: Source.server));
      if (!snap.exists) {
        _errorHandler.handleError(
          'User profile not found in remote database',
          type: ErrorType.database,
          severity: ErrorSeverity.low,
          context: {
            'operation': 'fetchRemote',
            'uid': uid,
            'service': 'UserService',
          },
        );
        return await getLocal(uid); // Fallback to local
      }

      final data = snap.data()!;
      final profile = UserProfile(
        uid: uid,
        role: (data['role'] as String?) ?? '',
        displayName: data['displayName'] as String?,
        email: data['email'] as String?,
        createdAt: DateTime.tryParse((data['createdAt'] as String?) ?? ''),
      );
      
      await saveLocal(profile);
      return profile;
    } catch (error) {
      _errorHandler.handleFirebaseError(
        error is FirebaseException ? error : FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unknown',
          message: error.toString(),
        ),
        context: {
          'operation': 'fetchRemote',
          'uid': uid,
          'service': 'UserService',
        },
      );
      
      // Fallback to local data
      return await getLocal(uid);
    }
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    // Always save locally first
    await saveLocal(profile);

    if (!_isFirebaseAvailable || _db == null) {
      _errorHandler.handleError(
        'Firebase not available for profile upsert - saved locally only',
        type: ErrorType.firebase,
        severity: ErrorSeverity.low,
        context: {
          'operation': 'upsertProfile',
          'uid': profile.uid,
          'service': 'UserService',
        },
      );
      return profile; // Return profile even if remote save failed
    }

    try {
      await _db.collection('users').doc(profile.uid).set({
        'displayName': profile.displayName,
        'email': profile.email,
        'role': profile.role,
        'createdAt': (profile.createdAt ?? DateTime.now()).toIso8601String(),
      }, SetOptions(merge: true));
      
      return profile;
    } catch (error) {
      _errorHandler.handleFirebaseError(
        error is FirebaseException ? error : FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unknown',
          message: error.toString(),
        ),
        context: {
          'operation': 'upsertProfile',
          'uid': profile.uid,
          'service': 'UserService',
        },
      );
      
      // Profile is already saved locally, so return it
      return profile;
    }
  }

  /// Get user profile with automatic fallback logic
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      // Try remote first if available
      if (_isFirebaseAvailable) {
        final remoteProfile = await fetchRemote(uid);
        if (remoteProfile != null) return remoteProfile;
      }
      
      // Fallback to local
      return await getLocal(uid);
    } catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: {
          'operation': 'getUserProfile',
          'uid': uid,
          'service': 'UserService',
        },
      );
      return null;
    }
  }

  /// Check if user profile exists locally or remotely
  Future<bool> userExists(String uid) async {
    try {
      final profile = await getUserProfile(uid);
      return profile != null;
    } catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: {
          'operation': 'userExists',
          'uid': uid,
          'service': 'UserService',
        },
      );
      return false;
    }
  }
}

