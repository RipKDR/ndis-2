import 'dart:async';
import 'dart:developer' as dev;

import 'package:connectivity_plus/connectivity_plus.dart';
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

    // Parse common error patterns
    if (message.contains('network') || message.contains('connection')) {
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
      case ErrorType.unknown:
      default:
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
  void dispose() {
    _errorController.close();
  }
}
