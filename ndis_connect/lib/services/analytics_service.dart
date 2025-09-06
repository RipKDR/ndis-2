import 'dart:developer' as dev;
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, {Map<String, Object?>? params}) async {
    await _analytics.logEvent(name: name, parameters: params);
  }

  void logError(String message, StackTrace? stack) {
    dev.log('Error: $message', stackTrace: stack);
  }
}

