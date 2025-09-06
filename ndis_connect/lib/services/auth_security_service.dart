import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ndis_connect/services/error_handling_service.dart';

class AuthSecurityService {
  static final AuthSecurityService _instance = AuthSecurityService._internal();
  factory AuthSecurityService() => _instance;
  AuthSecurityService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final ErrorHandlingService _errorService = ErrorHandlingService();

  // Security configuration
  static const int _maxLoginAttempts = 5;
  static const int _lockoutDurationMinutes = 15;
  static const int _sessionTimeoutMinutes = 30;
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastLoginAttemptKey = 'last_login_attempt';
  static const String _sessionStartKey = 'session_start';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Track login attempts
  int _currentLoginAttempts = 0;
  DateTime? _lastLoginAttempt;
  Timer? _sessionTimer;

  /// Initialize authentication security
  Future<void> initialize() async {
    await _loadLoginAttempts();
    await _checkSessionTimeout();
    await _setupSessionMonitoring();
  }

  /// Enhanced sign in with security checks
  Future<UserCredential?> signInWithSecurity({
    required String email,
    required String userPassword,
    bool useBiometric = false,
  }) async {
    try {
      // Check if account is locked
      if (await _isAccountLocked()) {
        throw FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Account temporarily locked due to too many failed attempts.',
        );
      }

      // Check session timeout
      if (await _isSessionExpired()) {
        await _clearSession();
      }

      // Attempt biometric authentication if enabled
      if (useBiometric && await _isBiometricEnabled()) {
        final biometricResult = await _authenticateWithBiometric();
        if (!biometricResult) {
          throw FirebaseAuthException(
            code: 'biometric-failed',
            message: 'Biometric authentication failed.',
          );
        }
      }

      // Attempt Firebase authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: userPassword,
      );

      // Reset login attempts on successful login
      await _resetLoginAttempts();
      await _startSession();
      
      // Log successful authentication
      await _logSecurityEvent('successful_login', {
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
        'biometric_used': useBiometric,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _handleFailedLogin();
      await _logSecurityEvent('failed_login', {
        'email': email,
        'error_code': e.code,
        'error_message': e.message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      rethrow;
    } catch (e) {
      await _handleFailedLogin();
      _errorService.handleException(
        e,
        type: ErrorType.authentication,
        severity: ErrorSeverity.high,
        context: {'operation': 'signInWithSecurity'},
      );
      rethrow;
    }
  }

  /// Enhanced sign up with security validation
  Future<UserCredential?> signUpWithSecurity({
    required String email,
    required String userPassword,
    required String displayName,
  }) async {
    try {
      // Validate password strength
      if (!_isPasswordStrong(userPassword)) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password must be at least 8 characters with uppercase, lowercase, number, and special character.',
        );
      }

      // Validate email format
      if (!_isValidEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address.',
        );
      }

      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: userPassword,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Start session
      await _startSession();

      // Log successful registration
      await _logSecurityEvent('successful_registration', {
        'email': email,
        'display_name': displayName,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _logSecurityEvent('failed_registration', {
        'email': email,
        'error_code': e.code,
        'error_message': e.message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      rethrow;
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.authentication,
        severity: ErrorSeverity.high,
        context: {'operation': 'signUpWithSecurity'},
      );
      rethrow;
    }
  }

  /// Secure sign out
  Future<void> signOutWithSecurity() async {
    try {
      await _logSecurityEvent('user_signout', {
        'user_id': _auth.currentUser?.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _clearSession();
      await _auth.signOut();
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.authentication,
        severity: ErrorSeverity.medium,
        context: {'operation': 'signOutWithSecurity'},
      );
      rethrow;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return false;
      }

      final isAuthenticated = await _authenticateWithBiometric();
      if (isAuthenticated) {
        await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
        await _logSecurityEvent('biometric_enabled', {
          'timestamp': DateTime.now().toIso8601String(),
        });
        return true;
      }
      return false;
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.authentication,
        severity: ErrorSeverity.medium,
        context: {'operation': 'enableBiometric'},
      );
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _logSecurityEvent('biometric_disabled', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.authentication,
        severity: ErrorSeverity.low,
        context: {'operation': 'disableBiometric'},
      );
    }
  }

  /// Check if biometric is enabled
  Future<bool> _isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Authenticate with biometric
  Future<bool> _authenticateWithBiometric() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      final result = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your NDIS Connect account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return result;
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.authentication,
        severity: ErrorSeverity.medium,
        context: {'operation': 'authenticateWithBiometric'},
      );
      return false;
    }
  }

  /// Check if account is locked
  Future<bool> _isAccountLocked() async {
    if (_currentLoginAttempts >= _maxLoginAttempts) {
      if (_lastLoginAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(_lastLoginAttempt!);
        if (timeSinceLastAttempt.inMinutes < _lockoutDurationMinutes) {
          return true;
        } else {
          // Reset attempts after lockout period
          await _resetLoginAttempts();
        }
      }
    }
    return false;
  }

  /// Check if session is expired
  Future<bool> _isSessionExpired() async {
    final sessionStart = await _secureStorage.read(key: _sessionStartKey);
    if (sessionStart != null) {
      final sessionStartTime = DateTime.parse(sessionStart);
      final sessionDuration = DateTime.now().difference(sessionStartTime);
      return sessionDuration.inMinutes > _sessionTimeoutMinutes;
    }
    return true;
  }

  /// Handle failed login attempt
  Future<void> _handleFailedLogin() async {
    _currentLoginAttempts++;
    _lastLoginAttempt = DateTime.now();
    await _saveLoginAttempts();

    if (_currentLoginAttempts >= _maxLoginAttempts) {
      await _logSecurityEvent('account_locked', {
        'attempts': _currentLoginAttempts,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Reset login attempts
  Future<void> _resetLoginAttempts() async {
    _currentLoginAttempts = 0;
    _lastLoginAttempt = null;
    await _secureStorage.delete(key: _loginAttemptsKey);
    await _secureStorage.delete(key: _lastLoginAttemptKey);
  }

  /// Load login attempts from storage
  Future<void> _loadLoginAttempts() async {
    final attempts = await _secureStorage.read(key: _loginAttemptsKey);
    final lastAttempt = await _secureStorage.read(key: _lastLoginAttemptKey);

    if (attempts != null) {
      _currentLoginAttempts = int.parse(attempts);
    }

    if (lastAttempt != null) {
      _lastLoginAttempt = DateTime.parse(lastAttempt);
    }
  }

  /// Save login attempts to storage
  Future<void> _saveLoginAttempts() async {
    await _secureStorage.write(key: _loginAttemptsKey, value: _currentLoginAttempts.toString());
    if (_lastLoginAttempt != null) {
      await _secureStorage.write(key: _lastLoginAttemptKey, value: _lastLoginAttempt!.toIso8601String());
    }
  }

  /// Start user session
  Future<void> _startSession() async {
    await _secureStorage.write(key: _sessionStartKey, value: DateTime.now().toIso8601String());
    await _setupSessionMonitoring();
  }

  /// Clear user session
  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _sessionStartKey);
    _sessionTimer?.cancel();
  }

  /// Setup session monitoring
  Future<void> _setupSessionMonitoring() async {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (await _isSessionExpired()) {
        await _clearSession();
        await _auth.signOut();
        await _logSecurityEvent('session_expired', {
          'timestamp': DateTime.now().toIso8601String(),
        });
        timer.cancel();
      }
    });
  }

  /// Check session timeout
  Future<void> _checkSessionTimeout() async {
    if (await _isSessionExpired()) {
      await _clearSession();
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
    }
  }

  /// Validate password strength
  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUpperCase && hasLowerCase && hasDigits && hasSpecialCharacters;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Log security events
  Future<void> _logSecurityEvent(String event, Map<String, dynamic> data) async {
    try {
      // In a real implementation, this would log to a secure logging service
      // For now, we'll use the error handling service
      _errorService.handleException(
        'Security Event: $event',
        type: ErrorType.authentication,
        severity: ErrorSeverity.low,
        context: data,
      );
    } catch (e) {
      // Silent fail for logging
    }
  }

  /// Get security status
  Future<Map<String, dynamic>> getSecurityStatus() async {
    return {
      'is_authenticated': _auth.currentUser != null,
      'login_attempts': _currentLoginAttempts,
      'is_locked': await _isAccountLocked(),
      'biometric_enabled': await _isBiometricEnabled(),
      'session_active': !await _isSessionExpired(),
      'last_login_attempt': _lastLoginAttempt?.toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
  }
}
