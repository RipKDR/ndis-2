import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/error_handling_service.dart';

/// A widget that catches and handles errors in its child widget tree
/// Provides a consistent error UI and integrates with ErrorHandlingService
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? context;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.context,
    this.onRetry,
    this.showRetryButton = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(context);
    }

    return ErrorBoundaryWrapper(
      onError: _handleError,
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
    });

    // Report to ErrorHandlingService
    final errorService = context.read<ErrorHandlingService>();
    errorService.handleError(
      error,
      stackTrace: stackTrace,
      context: {
        'widget_context': widget.context ?? 'Unknown',
        'error_boundary': true,
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final errorService = context.read<ErrorHandlingService>();
    
    String errorMessage = 'Something went wrong';
    List<String> suggestions = [];

    // Get user-friendly error message if it's an AppError
    if (_error is AppError) {
      final appError = _error as AppError;
      errorMessage = errorService.getUserFriendlyMessage(appError);
      suggestions = errorService.getRecoverySuggestions(appError);
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Try these solutions:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (widget.showRetryButton)
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _error = null;
    });
    
    if (widget.onRetry != null) {
      widget.onRetry!();
    }
  }
}

/// Internal wrapper that catches errors using Flutter's error handling
class ErrorBoundaryWrapper extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundaryWrapper({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorBoundaryWrapper> createState() => _ErrorBoundaryWrapperState();
}

class _ErrorBoundaryWrapperState extends State<ErrorBoundaryWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.onError(details.exception, details.stack ?? StackTrace.current);
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A mixin that provides error handling utilities for widgets
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  ErrorHandlingService get errorService => context.read<ErrorHandlingService>();

  /// Handle an error with context information
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    bool showSnackBar = true,
  }) {
    errorService.handleError(
      error,
      stackTrace: stackTrace ?? StackTrace.current,
      context: {
        ...?context,
        'widget': T.toString(),
        'screen_context': widget.runtimeType.toString(),
      },
    );

    if (showSnackBar && mounted) {
      _showErrorSnackBar(error);
    }
  }

  /// Show a user-friendly error message in a snack bar
  void _showErrorSnackBar(dynamic error) {
    String message = 'Something went wrong';
    
    if (error is AppError) {
      message = errorService.getUserFriendlyMessage(error);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Execute an async operation with error handling
  Future<T?> executeWithErrorHandling<T>(
    Future<T> operation, {
    String? operationName,
    bool showSnackBarOnError = true,
    T? defaultValue,
  }) async {
    try {
      return await operation;
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': operationName ?? 'unknown'},
        showSnackBar: showSnackBarOnError,
      );
      return defaultValue;
    }
  }

  /// Execute a sync operation with error handling
  T? executeSyncWithErrorHandling<T>(
    T Function() operation, {
    String? operationName,
    bool showSnackBarOnError = true,
    T? defaultValue,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: {'operation': operationName ?? 'unknown'},
        showSnackBar: showSnackBarOnError,
      );
      return defaultValue;
    }
  }
}

/// Extension to add error handling to any widget
extension WidgetErrorHandling on Widget {
  /// Wrap this widget with an ErrorBoundary
  Widget withErrorBoundary({
    String? context,
    VoidCallback? onRetry,
    bool showRetryButton = true,
  }) {
    return ErrorBoundary(
      context: context,
      onRetry: onRetry,
      showRetryButton: showRetryButton,
      child: this,
    );
  }
}
