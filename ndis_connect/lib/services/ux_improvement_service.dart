import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:ndis_connect/services/accessibility_service.dart';
import 'package:ndis_connect/services/error_handling_service.dart';

class UXImprovementService {
  static final UXImprovementService _instance = UXImprovementService._internal();
  factory UXImprovementService() => _instance;
  UXImprovementService._internal();

  final ErrorHandlingService _errorService = ErrorHandlingService();
  final AccessibilityService _accessibilityService = AccessibilityService();

  // UX metrics tracking
  final Map<String, List<Duration>> _interactionTimes = {};
  final Map<String, int> _interactionCounts = {};
  final Map<String, List<String>> _userFlows = {};
  final List<String> _errorMessages = [];

  // Stream controllers for UX events
  final StreamController<UXEvent> _uxEventController = StreamController<UXEvent>.broadcast();

  // Getters
  Stream<UXEvent> get uxEventStream => _uxEventController.stream;

  /// Initialize UX improvement service
  Future<void> initialize() async {
    await _setupUXMonitoring();
    await _setupUserFlowTracking();
  }

  /// Setup UX monitoring
  Future<void> _setupUXMonitoring() async {
    // Monitor app lifecycle for UX insights
    WidgetsBinding.instance.addObserver(_UXObserver(this));
  }

  /// Setup user flow tracking
  Future<void> _setupUserFlowTracking() async {
    // Track common user flows
    _trackUserFlow('app_startup');
  }

  /// Track user flow
  void _trackUserFlow(String flowName) {
    _userFlows.putIfAbsent(flowName, () => []).add(DateTime.now().toIso8601String());
  }

  /// Track user interaction
  void trackInteraction(String interaction, Duration duration) {
    _interactionTimes.putIfAbsent(interaction, () => []).add(duration);
    _interactionCounts[interaction] = (_interactionCounts[interaction] ?? 0) + 1;

    // Log slow interactions
    if (duration.inMilliseconds > 1000) {
      developer.log(
        'Slow interaction detected: $interaction took ${duration.inMilliseconds}ms',
        name: 'UXImprovementService',
      );
    }

    _uxEventController.add(UXEvent(
      type: UXEventType.interaction,
      data: {
        'interaction': interaction,
        'duration_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Track user flow
  void trackUserFlow(String flowName, {Map<String, dynamic>? data}) {
    _userFlows.putIfAbsent(flowName, () => []).add(DateTime.now().toIso8601String());

    _uxEventController.add(UXEvent(
      type: UXEventType.userFlow,
      data: {
        'flow_name': flowName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    ));
  }

  /// Track error from user perspective
  void trackUserError(String error, {Map<String, dynamic>? context}) {
    _errorMessages.add(error);

    _uxEventController.add(UXEvent(
      type: UXEventType.error,
      data: {
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
        ...?context,
      },
    ));
  }

  /// Track user satisfaction
  void trackUserSatisfaction(String feature, int rating, {String? feedback}) {
    _uxEventController.add(UXEvent(
      type: UXEventType.satisfaction,
      data: {
        'feature': feature,
        'rating': rating,
        'feedback': feedback,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Get interaction metrics
  Map<String, dynamic> getInteractionMetrics(String interaction) {
    final times = _interactionTimes[interaction] ?? [];
    final count = _interactionCounts[interaction] ?? 0;

    if (times.isEmpty) {
      return {
        'interaction': interaction,
        'count': count,
        'average_duration_ms': 0,
        'min_duration_ms': 0,
        'max_duration_ms': 0,
      };
    }

    final average = times.map((d) => d.inMilliseconds).reduce((a, b) => a + b) / times.length;
    final min = times.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final max = times.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

    return {
      'interaction': interaction,
      'count': count,
      'average_duration_ms': average,
      'min_duration_ms': min,
      'max_duration_ms': max,
    };
  }

  /// Get user flow metrics
  Map<String, dynamic> getUserFlowMetrics(String flowName) {
    final flows = _userFlows[flowName] ?? [];

    return {
      'flow_name': flowName,
      'total_flows': flows.length,
      'last_flow': flows.isNotEmpty ? flows.last : null,
      'flows_today': flows.where((f) {
        final flowTime = DateTime.parse(f);
        final today = DateTime.now();
        return flowTime.year == today.year &&
            flowTime.month == today.month &&
            flowTime.day == today.day;
      }).length,
    };
  }

  /// Get UX insights
  Map<String, dynamic> getUXInsights() {
    final slowInteractions = <String, double>{};

    for (final interaction in _interactionTimes.keys) {
      final metrics = getInteractionMetrics(interaction);
      final averageDuration = metrics['average_duration_ms'] as double;

      if (averageDuration > 1000) {
        // More than 1 second
        slowInteractions[interaction] = averageDuration;
      }
    }

    final errorRate = _errorMessages.length / (_interactionCounts.values.fold(0, (a, b) => a + b));

    return {
      'total_interactions': _interactionCounts.values.fold(0, (a, b) => a + b),
      'total_errors': _errorMessages.length,
      'error_rate': errorRate,
      'slow_interactions': slowInteractions,
      'most_used_features': _getMostUsedFeatures(),
      'accessibility_status': _accessibilityService.getAccessibilityStatus(),
    };
  }

  /// Get most used features
  List<Map<String, dynamic>> _getMostUsedFeatures() {
    final features = <String, int>{};

    for (final entry in _interactionCounts.entries) {
      final feature = entry.key.split('_').first; // Extract feature name
      features[feature] = (features[feature] ?? 0) + entry.value;
    }

    final sortedFeatures = features.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedFeatures
        .take(5)
        .map((entry) => {
              'feature': entry.key,
              'usage_count': entry.value,
            })
        .toList();
  }

  /// Generate UX recommendations
  List<String> generateUXRecommendations() {
    final recommendations = <String>[];
    final insights = getUXInsights();

    // Check for slow interactions
    final slowInteractions = insights['slow_interactions'] as Map<String, double>;
    if (slowInteractions.isNotEmpty) {
      recommendations.add('Optimize slow interactions: ${slowInteractions.keys.join(', ')}');
    }

    // Check error rate
    final errorRate = insights['error_rate'] as double;
    if (errorRate > 0.1) {
      // More than 10% error rate
      recommendations.add(
          'High error rate detected (${(errorRate * 100).toStringAsFixed(1)}%). Consider improving error handling.');
    }

    // Check accessibility
    final accessibilityStatus = insights['accessibility_status'] as Map<String, dynamic>;
    if (!(accessibilityStatus['screen_reader_enabled'] as bool)) {
      recommendations.add('Consider testing with screen readers for better accessibility.');
    }

    // Check text scaling
    final textScaleFactor = accessibilityStatus['text_scale_factor'] as double;
    if (textScaleFactor < 1.0) {
      recommendations.add('Text scaling is below 100%. Consider testing with larger text sizes.');
    }

    return recommendations;
  }

  /// Test UX with different scenarios
  Future<void> runUXTests() async {
    // Test loading states
    await _testLoadingStates();

    // Test error states
    await _testErrorStates();

    // Test accessibility
    await _testAccessibility();

    // Test performance
    await _testPerformance();
  }

  /// Test loading states
  Future<void> _testLoadingStates() async {
    final stopwatch = Stopwatch()..start();

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 500));

    stopwatch.stop();
    trackInteraction('loading_test', stopwatch.elapsed);
  }

  /// Test error states
  Future<void> _testErrorStates() async {
    try {
      // Simulate error
      throw Exception('Test error for UX testing');
    } catch (e) {
      trackUserError('Test error: ${e.toString()}');
    }
  }

  /// Test accessibility
  Future<void> _testAccessibility() async {
    final accessibilityStatus = _accessibilityService.getAccessibilityStatus();

    if (!(accessibilityStatus['screen_reader_enabled'] as bool)) {
      trackUserError('Screen reader not enabled for accessibility testing');
    }

    if (accessibilityStatus['text_scale_factor'] as double < 1.0) {
      trackUserError('Text scaling below recommended minimum');
    }
  }

  /// Test performance
  Future<void> _testPerformance() async {
    final stopwatch = Stopwatch()..start();

    // Simulate heavy operation
    await Future.delayed(const Duration(milliseconds: 100));

    stopwatch.stop();
    trackInteraction('performance_test', stopwatch.elapsed);
  }

  /// Clear UX data
  void clearUXData() {
    _interactionTimes.clear();
    _interactionCounts.clear();
    _userFlows.clear();
    _errorMessages.clear();
  }

  /// Dispose resources
  void dispose() {
    _uxEventController.close();
  }
}

/// UX event types
enum UXEventType {
  interaction,
  userFlow,
  error,
  satisfaction,
}

/// UX event class
class UXEvent {
  final UXEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  UXEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// UX observer for app lifecycle
class _UXObserver extends WidgetsBindingObserver {
  final UXImprovementService _service;

  _UXObserver(this._service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _service.trackUserFlow('app_paused');
        break;
      case AppLifecycleState.resumed:
        _service.trackUserFlow('app_resumed');
        break;
      case AppLifecycleState.detached:
        _service.trackUserFlow('app_detached');
        break;
      default:
        break;
    }
  }
}

/// UX improvement mixin for widgets
mixin UXImprovementMixin<T extends StatefulWidget> on State<T> {
  final UXImprovementService _uxService = UXImprovementService();
  final Map<String, Stopwatch> _interactionTimers = {};

  /// Start tracking interaction
  void startInteractionTracking(String interaction) {
    _interactionTimers[interaction] = Stopwatch()..start();
  }

  /// End tracking interaction
  void endInteractionTracking(String interaction) {
    final timer = _interactionTimers[interaction];
    if (timer != null) {
      timer.stop();
      _uxService.trackInteraction(interaction, timer.elapsed);
      _interactionTimers.remove(interaction);
    }
  }

  /// Track user flow
  void trackUserFlow(String flowName, {Map<String, dynamic>? data}) {
    _uxService.trackUserFlow(flowName, data: data);
  }

  /// Track user error
  void trackUserError(String error, {Map<String, dynamic>? context}) {
    _uxService.trackUserError(error, context: context);
  }

  /// Track user satisfaction
  void trackUserSatisfaction(String feature, int rating, {String? feedback}) {
    _uxService.trackUserSatisfaction(feature, rating, feedback: feedback);
  }

  @override
  void dispose() {
    // End any remaining timers
    for (final timer in _interactionTimers.values) {
      timer.stop();
    }
    _interactionTimers.clear();
    super.dispose();
  }
}
