import 'dart:async';
import 'dart:developer' as dev;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/environment.dart';

enum ErrorType {
  network,
  authentication,
  database,
  validation,
  permission,
  unknown,
  offline,
  timeout,
  rateLimit,
  serverError,
  firebase,
  firestore,
  storage,
}

enum ErrorSeverity { low, medium, high, critical }

class AppError {
  final String message;
  final String? code;
  final ErrorType type;
  final ErrorSeverity severity;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  final bool isRetryable;

  AppError({
    required this.message,
    this.code,
    required this.type,
    required this.severity,
    this.stackTrace,
    this.context,
    DateTime? timestamp,
    this.isRetryable = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'message': message,
        'code': code,
        'type': type.name,
        'severity': severity.name,
        'stackTrace': stackTrace?.toString(),
        'context': context,
        'timestamp': timestamp.toIso8601String(),
        'isRetryable': isRetryable,
      };
}

class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final Connectivity _connectivity = Connectivity();
  final List<AppError> _errorHistory = [];
  final StreamController<AppError> _errorController = StreamController<AppError>.broadcast();

  bool _isInitialized = false;
  bool _isOnline = true;

  Stream<AppError> get errorStream => _errorController.stream;
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Monitor connectivity
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
    });

    // Set up global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(
        AppError(
          message: details.exception.toString(),
          type: ErrorType.unknown,
          severity: ErrorSeverity.high,
          stackTrace: details.stack,
          context: {
            'library': details.library,
            'context': details.context?.toString(),
          },
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _handleError(
        AppError(
          message: error.toString(),
          type: ErrorType.unknown,
          severity: ErrorSeverity.critical,
          stackTrace: stack,
        ),
      );
      return true;
    };

    _isInitialized = true;
  }

  void _handleError(AppError error) {
    // Add to history
    _errorHistory.add(error);

    // Keep only last 100 errors
    if (_errorHistory.length > 100) {
      _errorHistory.removeAt(0);
    }

    // Emit to stream
    _errorController.add(error);

    // Log to console in debug mode
    if (AppConfig.enableDebugLogs) {
      dev.log(
        'Error: ${error.message}',
        error: error.stackTrace,
        stackTrace: error.stackTrace,
      );
    }

    // Report to Crashlytics in production
    if (AppConfig.enableCrashlytics && error.severity.index >= ErrorSeverity.medium.index) {
      _crashlytics.recordError(
        error.message,
        error.stackTrace,
        fatal: error.severity == ErrorSeverity.critical,
        information:
            error.context?.entries.map((e) => DiagnosticsProperty(e.key, e.value)).toList() ?? [],
      );
    }
  }

  // Public error handling methods
  void handleError(
    dynamic error, {
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    bool isRetryable = false,
  }) {
    String message;
    String? code;

    if (error is AppError) {
      _handleError(error);
      return;
    } else if (error is Exception) {
      message = error.toString();
    } else if (error is String) {
      message = error;
    } else {
      message = error.toString();
    }

    // Parse Firebase-specific errors first
    if (error is FirebaseAuthException) {
      type = ErrorType.authentication;
      code = error.code;
      message = _getFirebaseAuthErrorMessage(error);
      severity = _getFirebaseAuthErrorSeverity(error);
      isRetryable = _isFirebaseAuthErrorRetryable(error);
    } else if (error is FirebaseException) {
      if (error.plugin == 'cloud_firestore') {
        type = ErrorType.firestore;
      } else if (error.plugin == 'firebase_storage') {
        type = ErrorType.storage;
      } else {
        type = ErrorType.firebase;
      }
      code = error.code;
      message = _getFirebaseErrorMessage(error);
      severity = _getFirebaseErrorSeverity(error);
      isRetryable = _isFirebaseErrorRetryable(error);
    }
    // Parse common error patterns
    else if (message.contains('network') || message.contains('connection')) {
      type = ErrorType.network;
      severity = ErrorSeverity.medium;
      isRetryable = true;
    } else if (message.contains('permission') || message.contains('unauthorized')) {
      type = ErrorType.permission;
      severity = ErrorSeverity.high;
    } else if (message.contains('timeout')) {
      type = ErrorType.timeout;
      severity = ErrorSeverity.medium;
      isRetryable = true;
    } else if (message.contains('validation') || message.contains('invalid')) {
      type = ErrorType.validation;
      severity = ErrorSeverity.low;
    }

    final appError = AppError(
      message: message,
      code: code,
      type: type,
      severity: severity,
      stackTrace: stackTrace ?? StackTrace.current,
      context: context,
      isRetryable: isRetryable,
    );

    _handleError(appError);
  }

  // Alias for handleError to maintain compatibility
  void handleException(
    dynamic error, {
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    bool isRetryable = false,
  }) {
    handleError(
      error,
      type: type,
      severity: severity,
      stackTrace: stackTrace,
      context: context,
      isRetryable: isRetryable,
    );
  }

  // Specific error handlers
  void handleNetworkError(dynamic error, {Map<String, dynamic>? context}) {
    handleError(
      error,
      type: ErrorType.network,
      severity: _isOnline ? ErrorSeverity.medium : ErrorSeverity.low,
      context: context,
      isRetryable: true,
    );
  }

  void handleAuthError(dynamic error, {Map<String, dynamic>? context}) {
    handleError(
      error,
      type: ErrorType.authentication,
      severity: ErrorSeverity.high,
      context: context,
    );
  }

  void handleDatabaseError(dynamic error, {Map<String, dynamic>? context}) {
    handleError(
      error,
      type: ErrorType.database,
      severity: ErrorSeverity.medium,
      context: context,
      isRetryable: true,
    );
  }

  void handleValidationError(dynamic error, {Map<String, dynamic>? context}) {
    handleError(
      error,
      type: ErrorType.validation,
      severity: ErrorSeverity.low,
      context: context,
    );
  }

  void handleOfflineError(dynamic error, {Map<String, dynamic>? context}) {
    handleError(
      error,
      type: ErrorType.offline,
      severity: ErrorSeverity.low,
      context: context,
      isRetryable: true,
    );
  }

  // User-friendly error messages
  String getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return _isOnline
            ? 'Unable to connect to the server. Please check your internet connection.'
            : 'You\'re currently offline. Some features may not be available.';
      case ErrorType.authentication:
        return 'Please sign in again to continue.';
      case ErrorType.permission:
        return 'You don\'t have permission to perform this action.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.timeout:
        return 'The request timed out. Please try again.';
      case ErrorType.rateLimit:
        return 'Too many requests. Please wait a moment and try again.';
      case ErrorType.serverError:
        return 'Server error occurred. Please try again later.';
      case ErrorType.offline:
        return 'This feature requires an internet connection.';
      case ErrorType.database:
        return 'Unable to save data. Please try again.';
      case ErrorType.firebase:
        return 'Firebase service error. Please try again.';
      case ErrorType.firestore:
        return 'Unable to access data. Please check your connection.';
      case ErrorType.storage:
        return 'File operation failed. Please try again.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  // Error recovery suggestions
  List<String> getRecoverySuggestions(AppError error) {
    final suggestions = <String>[];

    switch (error.type) {
      case ErrorType.network:
        suggestions.addAll([
          'Check your internet connection',
          'Try switching between WiFi and mobile data',
          'Restart the app',
        ]);
        break;
      case ErrorType.authentication:
        suggestions.addAll([
          'Sign out and sign in again',
          'Check your credentials',
        ]);
        break;
      case ErrorType.permission:
        suggestions.addAll([
          'Check app permissions in settings',
          'Contact support if the issue persists',
        ]);
        break;
      case ErrorType.timeout:
        suggestions.addAll([
          'Try again in a few moments',
          'Check your internet connection',
        ]);
        break;
      case ErrorType.offline:
        suggestions.addAll([
          'Connect to the internet',
          'Use offline features while available',
        ]);
        break;
      default:
        suggestions.add('Try again later');
        if (error.isRetryable) {
          suggestions.insert(0, 'Try again');
        }
    }

    return suggestions;
  }

  // Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  // Get errors by type
  List<AppError> getErrorsByType(ErrorType type) {
    return _errorHistory.where((error) => error.type == type).toList();
  }

  // Get errors by severity
  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorHistory.where((error) => error.severity == severity).toList();
  }

  // Get recent errors
  List<AppError> getRecentErrors({int count = 10}) {
    final sorted = List<AppError>.from(_errorHistory);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(count).toList();
  }

  // Check if error is retryable
  bool isRetryable(AppError error) {
    return error.isRetryable && _isOnline;
  }

  // Dispose resources
  // Firebase-specific error handlers
  String _getFirebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      default:
        return error.message ?? 'Authentication error occurred.';
    }
  }

  ErrorSeverity _getFirebaseAuthErrorSeverity(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-disabled':
      case 'too-many-requests':
        return ErrorSeverity.high;
      case 'network-request-failed':
      case 'requires-recent-login':
        return ErrorSeverity.medium;
      default:
        return ErrorSeverity.low;
    }
  }

  bool _isFirebaseAuthErrorRetryable(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
      case 'too-many-requests':
        return true;
      case 'user-disabled':
      case 'email-already-in-use':
        return false;
      default:
        return false;
    }
  }

  String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to access this data.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'The data already exists.';
      case 'resource-exhausted':
        return 'Service quota exceeded. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed due to invalid state.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Request was out of valid range.';
      case 'unimplemented':
        return 'This feature is not yet implemented.';
      case 'internal':
        return 'Internal server error. Please try again later.';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again later.';
      case 'data-loss':
        return 'Data corruption detected. Please contact support.';
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'cancelled':
        return 'Operation was cancelled.';
      default:
        return error.message ?? 'Firebase error occurred.';
    }
  }

  ErrorSeverity _getFirebaseErrorSeverity(FirebaseException error) {
    switch (error.code) {
      case 'data-loss':
      case 'internal':
        return ErrorSeverity.critical;
      case 'permission-denied':
      case 'unauthenticated':
      case 'resource-exhausted':
        return ErrorSeverity.high;
      case 'unavailable':
      case 'deadline-exceeded':
      case 'aborted':
        return ErrorSeverity.medium;
      default:
        return ErrorSeverity.low;
    }
  }

  bool _isFirebaseErrorRetryable(FirebaseException error) {
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'aborted':
      case 'resource-exhausted':
      case 'internal':
        return true;
      case 'permission-denied':
      case 'not-found':
      case 'already-exists':
      case 'unauthenticated':
        return false;
      default:
        return false;
    }
  }

  // Firebase-specific error handling methods
  void handleFirebaseError(FirebaseException error, {Map<String, dynamic>? context}) {
    handleError(
      error,
      context: {
        ...?context,
        'firebase_plugin': error.plugin,
        'firebase_code': error.code,
      },
    );
  }

  void handleFirebaseAuthError(FirebaseAuthException error, {Map<String, dynamic>? context}) {
    handleError(
      error,
      context: {
        ...?context,
        'auth_code': error.code,
        'auth_credential': error.credential?.toString(),
      },
    );
  }

  void dispose() {
    _errorController.close();
  }
}
