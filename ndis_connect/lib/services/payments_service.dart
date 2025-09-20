import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'error_handling_service.dart';

enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  requiresAction,
}

class PaymentResult {
  final PaymentStatus status;
  final String? paymentIntentId;
  final String? error;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.status,
    this.paymentIntentId,
    this.error,
    this.metadata,
  });
}

class PaymentsService {
  final ErrorHandlingService _errorHandler;
  bool _isInitialized = false;

  PaymentsService({
    String? publishableKey,
    ErrorHandlingService? errorHandler,
  }) : _errorHandler = errorHandler ?? ErrorHandlingService() {
    if (publishableKey != null && publishableKey.isNotEmpty) {
      try {
        Stripe.publishableKey = publishableKey;
        _isInitialized = true;
      } catch (error, stackTrace) {
        _errorHandler.handleError(
          error,
          type: ErrorType.validation,
          severity: ErrorSeverity.high,
          stackTrace: stackTrace,
          context: {
            'operation': 'stripe_initialization',
            'service': 'PaymentsService',
          },
        );
      }
    }
  }

  /// Check if the payments service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Start subscription checkout process with comprehensive error handling
  Future<PaymentResult> startSubscriptionCheckout(
    Uri backendCreateIntentEndpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? requestBody,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) {
      final error = 'Stripe not initialized - missing or invalid publishable key';
      _errorHandler.handleError(
        error,
        type: ErrorType.validation,
        severity: ErrorSeverity.high,
        context: {
          'operation': 'startSubscriptionCheckout',
          'service': 'PaymentsService',
        },
      );
      return PaymentResult(
        status: PaymentStatus.failed,
        error: error,
      );
    }

    try {
      // Step 1: Create Payment Intent
      final paymentIntent = await _createPaymentIntent(
        backendCreateIntentEndpoint,
        headers: headers,
        requestBody: requestBody,
        timeout: timeout,
      );

      if (paymentIntent == null) {
        return PaymentResult(
          status: PaymentStatus.failed,
          error: 'Failed to create payment intent',
        );
      }

      // Step 2: Initialize Payment Sheet
      await _initializePaymentSheet(paymentIntent['clientSecret'] as String);

      // Step 3: Present Payment Sheet
      await _presentPaymentSheet();
      
      return PaymentResult(
        status: PaymentStatus.succeeded,
        paymentIntentId: paymentIntent['id'] as String?,
        metadata: paymentIntent,
      );

    } on StripeException catch (error, stackTrace) {
      return _handleStripeError(error, stackTrace);
    } on SocketException catch (error) {
      _errorHandler.handleNetworkError(
        error,
        context: {
          'operation': 'startSubscriptionCheckout',
          'endpoint': backendCreateIntentEndpoint.toString(),
          'service': 'PaymentsService',
        },
      );
      return PaymentResult(
        status: PaymentStatus.failed,
        error: 'Network connection failed. Please check your internet connection.',
      );
    } on HttpException catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        type: ErrorType.network,
        stackTrace: stackTrace,
        context: {
          'operation': 'startSubscriptionCheckout',
          'endpoint': backendCreateIntentEndpoint.toString(),
          'service': 'PaymentsService',
        },
      );
      return PaymentResult(
        status: PaymentStatus.failed,
        error: 'Payment server error. Please try again later.',
      );
    } catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: {
          'operation': 'startSubscriptionCheckout',
          'endpoint': backendCreateIntentEndpoint.toString(),
          'service': 'PaymentsService',
        },
      );
      return PaymentResult(
        status: PaymentStatus.failed,
        error: 'An unexpected error occurred during payment processing.',
      );
    }
  }

  /// Create payment intent with backend
  Future<Map<String, dynamic>?> _createPaymentIntent(
    Uri endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? requestBody,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final request = http.Request('POST', endpoint);
      
      // Set headers
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      });

      // Set body if provided
      if (requestBody != null) {
        request.body = jsonEncode(requestBody);
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        _errorHandler.handleError(
          'Payment intent creation failed: ${response.statusCode} - ${response.body}',
          type: ErrorType.serverError,
          severity: ErrorSeverity.high,
          context: {
            'operation': '_createPaymentIntent',
            'status_code': response.statusCode,
            'response_body': response.body,
            'service': 'PaymentsService',
          },
        );
        return null;
      }
    } on TimeoutException catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        type: ErrorType.timeout,
        stackTrace: stackTrace,
        context: {
          'operation': '_createPaymentIntent',
          'endpoint': endpoint.toString(),
          'timeout_seconds': timeout.inSeconds,
          'service': 'PaymentsService',
        },
      );
      return null;
    }
  }

  /// Initialize payment sheet
  Future<void> _initializePaymentSheet(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'NDIS Connect',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(),
        ),
      );
    } catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: {
          'operation': '_initializePaymentSheet',
          'service': 'PaymentsService',
        },
      );
      rethrow;
    }
  }

  /// Present payment sheet to user
  Future<void> _presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: {
          'operation': '_presentPaymentSheet',
          'service': 'PaymentsService',
        },
      );
      rethrow;
    }
  }

  /// Handle Stripe-specific errors
  PaymentResult _handleStripeError(StripeException error, StackTrace stackTrace) {
    _errorHandler.handleError(
      error,
      stackTrace: stackTrace,
      context: {
        'operation': 'stripe_payment',
        'stripe_code': error.error.code.name,
        'stripe_message': error.error.message,
        'service': 'PaymentsService',
      },
    );

    // Handle different Stripe error types
    final errorMessage = error.error.message ?? 'Payment processing error';
    final errorCode = error.error.code.toString();
    
    if (errorCode.contains('cancelled')) {
      return PaymentResult(
        status: PaymentStatus.cancelled,
        error: 'Payment was cancelled',
      );
    } else if (errorCode.contains('failed')) {
      return PaymentResult(
        status: PaymentStatus.failed,
        error: errorMessage,
      );
    } else {
      return PaymentResult(
        status: PaymentStatus.failed,
        error: errorMessage,
      );
    }
  }

  /// Validate payment configuration
  bool validateConfiguration() {
    try {
      if (!_isInitialized) {
        _errorHandler.handleError(
          'Stripe not initialized',
          type: ErrorType.validation,
          severity: ErrorSeverity.high,
          context: {
            'operation': 'validateConfiguration',
            'service': 'PaymentsService',
          },
        );
        return false;
      }
      return true;
    } catch (error, stackTrace) {
      _errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: {
          'operation': 'validateConfiguration',
          'service': 'PaymentsService',
        },
      );
      return false;
    }
  }
}

