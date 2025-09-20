import 'dart:developer' as dev;
import 'package:firebase_analytics/firebase_analytics.dart';

/// AnalyticsService wraps FirebaseAnalytics but tolerates missing Firebase by
/// becoming a no-op implementation when FirebaseAnalytics isn't available.
class AnalyticsService {
  FirebaseAnalytics? _analytics;

  AnalyticsService() {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (_) {
      _analytics = null;
    }
  }

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: params);
    } catch (e) {
      dev.log('Analytics logEvent failed: $e');
    }
  }

  void logError(String message, StackTrace? stack) {
    dev.log('Error: $message', stackTrace: stack);
  }
}
