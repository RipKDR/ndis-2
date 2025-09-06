import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Production Monitoring Service
///
/// Comprehensive monitoring service for production environments including:
/// - Performance monitoring
/// - Error tracking and crash reporting
/// - User analytics
/// - Custom metrics
/// - Health checks
class ProductionMonitoringService {
  static final ProductionMonitoringService _instance = ProductionMonitoringService._internal();
  factory ProductionMonitoringService() => _instance;
  ProductionMonitoringService._internal();

  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;

  final Map<String, DateTime> _customMetrics = {};
  final Map<String, int> _performanceCounters = {};
  final StreamController<MonitoringEvent> _eventController =
      StreamController<MonitoringEvent>.broadcast();

  Stream<MonitoringEvent> get eventStream => _eventController.stream;

  /// Initialize the monitoring service
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Configure analytics
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.setSessionTimeoutDuration(const Duration(minutes: 30));

      // Configure crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Set up performance monitoring
      await _setupPerformanceMonitoring();

      // Log initialization
      await logEvent('monitoring_initialized', parameters: {
        'platform': defaultTargetPlatform.name,
        'debug_mode': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
      });

      developer.log('Production monitoring initialized successfully');
    } catch (e) {
      developer.log('Failed to initialize production monitoring: $e');
    }
  }

  /// Set up performance monitoring
  Future<void> _setupPerformanceMonitoring() async {
    // Monitor app startup time
    _startPerformanceMetric('app_startup_time');

    // Monitor memory usage
    _startPerformanceMetric('memory_usage');

    // Monitor network performance
    _startPerformanceMetric('network_performance');
  }

  /// Log custom event with analytics
  Future<void> logEvent(String eventName, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );

      // Also send to custom monitoring
      _eventController.add(MonitoringEvent(
        type: MonitoringEventType.analytics,
        name: eventName,
        data: parameters,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      developer.log('Failed to log analytics event: $e');
    }
  }

  /// Log user action
  Future<void> logUserAction(String action, {Map<String, Object>? context}) async {
    await logEvent('user_action', parameters: {
      'action': action,
      ...?context,
    });
  }

  /// Log performance metric
  Future<void> logPerformanceMetric(String metricName, double value, {String? unit}) async {
    await logEvent('performance_metric', parameters: {
      'metric_name': metricName,
      'value': value,
      if (unit != null) 'unit': unit,
    });

    _performanceCounters[metricName] = (_performanceCounters[metricName] ?? 0) + 1;
  }

  /// Log error with context
  Future<void> logError(
    String error,
    StackTrace? stackTrace, {
    Map<String, Object>? context,
    bool fatal = false,
  }) async {
    try {
      // Log to Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
      );

      // Log to analytics
      await logEvent('error_occurred', parameters: {
        'error': error,
        'fatal': fatal,
        ...?context,
      });

      // Send to custom monitoring
      _eventController.add(MonitoringEvent(
        type: MonitoringEventType.error,
        name: 'error_occurred',
        data: {
          'error': error,
          'fatal': fatal,
          ...?context,
        },
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      developer.log('Failed to log error: $e');
    }
  }

  /// Log custom metric
  Future<void> logCustomMetric(String metricName, Object value, {String? category}) async {
    await logEvent('custom_metric', parameters: {
      'metric_name': metricName,
      'value': value.toString(),
      if (category != null) 'category': category,
    });

    _customMetrics[metricName] = DateTime.now();
  }

  /// Start performance metric timing
  void _startPerformanceMetric(String metricName) {
    _customMetrics[metricName] = DateTime.now();
  }

  /// End performance metric timing and log
  Future<void> endPerformanceMetric(String metricName) async {
    final startTime = _customMetrics[metricName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      await logPerformanceMetric(metricName, duration.inMilliseconds.toDouble(), unit: 'ms');
      _customMetrics.remove(metricName);
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );

    await logEvent('screen_view', parameters: {
      'screen_name': screenName,
      if (screenClass != null) 'screen_class': screenClass,
    });
  }

  /// Log user engagement
  Future<void> logUserEngagement(String engagementType, Duration duration) async {
    await logEvent('user_engagement', parameters: {
      'engagement_type': engagementType,
      'duration_seconds': duration.inSeconds,
    });
  }

  /// Log accessibility usage
  Future<void> logAccessibilityUsage(String feature, bool enabled) async {
    await logEvent('accessibility_usage', parameters: {
      'feature': feature,
      'enabled': enabled,
    });
  }

  /// Log offline usage
  Future<void> logOfflineUsage(String action, bool wasOffline) async {
    await logEvent('offline_usage', parameters: {
      'action': action,
      'was_offline': wasOffline,
    });
  }

  /// Log NDIS-specific events
  Future<void> logNDISEvent(String eventType, {Map<String, Object>? ndisData}) async {
    await logEvent('ndis_event', parameters: {
      'event_type': eventType,
      ...?ndisData,
    });
  }

  /// Log task management events
  Future<void> logTaskEvent(String taskAction, {Map<String, Object>? taskData}) async {
    await logEvent('task_event', parameters: {
      'task_action': taskAction,
      ...?taskData,
    });
  }

  /// Log budget events
  Future<void> logBudgetEvent(String budgetAction, {Map<String, Object>? budgetData}) async {
    await logEvent('budget_event', parameters: {
      'budget_action': budgetAction,
      ...?budgetData,
    });
  }

  /// Log service provider events
  Future<void> logProviderEvent(String providerAction, {Map<String, Object>? providerData}) async {
    await logEvent('provider_event', parameters: {
      'provider_action': providerAction,
      ...?providerData,
    });
  }

  /// Set user properties for analytics
  Future<void> setUserProperties(Map<String, Object> properties) async {
    try {
      for (final entry in properties.entries) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value.toString(),
        );
      }
    } catch (e) {
      developer.log('Failed to set user properties: $e');
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      developer.log('Failed to set user ID: $e');
    }
  }

  /// Get performance counters
  Map<String, int> getPerformanceCounters() => Map.unmodifiable(_performanceCounters);

  /// Get custom metrics
  Map<String, DateTime> getCustomMetrics() => Map.unmodifiable(_customMetrics);

  /// Clear all metrics
  void clearMetrics() {
    _performanceCounters.clear();
    _customMetrics.clear();
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}

/// Monitoring event types
enum MonitoringEventType {
  analytics,
  error,
  performance,
  custom,
}

/// Monitoring event data class
class MonitoringEvent {
  final MonitoringEventType type;
  final String name;
  final Map<String, Object>? data;
  final DateTime timestamp;

  MonitoringEvent({
    required this.type,
    required this.name,
    this.data,
    required this.timestamp,
  });

  Map<String, Object> toMap() => {
        'type': type.name,
        'name': name,
        'data': data ?? {},
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Performance monitoring mixin
mixin PerformanceMonitoringMixin {
  final ProductionMonitoringService _monitoring = ProductionMonitoringService();

  /// Monitor method execution time
  Future<T> monitorExecution<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    _monitoring._startPerformanceMetric(operationName);
    try {
      final result = await operation();
      await _monitoring.endPerformanceMetric(operationName);
      return result;
    } catch (e, stackTrace) {
      await _monitoring.endPerformanceMetric(operationName);
      await _monitoring.logError(
        'Error in $operationName: $e',
        stackTrace,
        context: {'operation': operationName},
      );
      rethrow;
    }
  }

  /// Monitor synchronous operation
  T monitorSyncExecution<T>(
    String operationName,
    T Function() operation,
  ) {
    _monitoring._startPerformanceMetric(operationName);
    try {
      final result = operation();
      _monitoring.endPerformanceMetric(operationName);
      return result;
    } catch (e, stackTrace) {
      _monitoring.endPerformanceMetric(operationName);
      _monitoring.logError(
        'Error in $operationName: $e',
        stackTrace,
        context: {'operation': operationName},
      );
      rethrow;
    }
  }
}
