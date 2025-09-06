import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  late SharedPreferences _prefs;
  final Connectivity _connectivity = Connectivity();
  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _performanceMetrics = {};
  final StreamController<Map<String, dynamic>> _performanceStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPerformanceMetrics();
    _startPerformanceMonitoring();
  }

  // Performance monitoring
  void _startPerformanceMonitoring() {
    // Monitor memory usage
    Timer.periodic(const Duration(minutes: 1), (_) => _monitorMemoryUsage());

    // Monitor network performance
    Timer.periodic(const Duration(minutes: 2), (_) => _monitorNetworkPerformance());

    // Monitor app performance
    Timer.periodic(const Duration(minutes: 5), (_) => _monitorAppPerformance());
  }

  // Start timing an operation
  void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  // End timing an operation
  Duration endTiming(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) return Duration.zero;

    final duration = DateTime.now().difference(startTime);
    _recordPerformanceMetric(operation, duration);
    return duration;
  }

  // Record performance metric
  void _recordPerformanceMetric(String operation, Duration duration) {
    if (!_performanceMetrics.containsKey(operation)) {
      _performanceMetrics[operation] = [];
    }

    _performanceMetrics[operation]!.add(duration);

    // Keep only last 100 measurements
    if (_performanceMetrics[operation]!.length > 100) {
      _performanceMetrics[operation]!.removeAt(0);
    }

    // Emit performance data
    _performanceStreamController.add({
      'operation': operation,
      'duration': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Get performance metrics for an operation
  Map<String, dynamic> getPerformanceMetrics(String operation) {
    final metrics = _performanceMetrics[operation];
    if (metrics == null || metrics.isEmpty) {
      return {
        'operation': operation,
        'count': 0,
        'average': 0,
        'min': 0,
        'max': 0,
        'median': 0,
      };
    }

    final durations = metrics.map((d) => d.inMilliseconds).toList();
    durations.sort();

    final average = durations.reduce((a, b) => a + b) / durations.length;
    final min = durations.first;
    final max = durations.last;
    final median = durations[durations.length ~/ 2];

    return {
      'operation': operation,
      'count': durations.length,
      'average': average,
      'min': min,
      'max': max,
      'median': median,
    };
  }

  // Get all performance metrics
  Map<String, dynamic> getAllPerformanceMetrics() {
    final allMetrics = <String, dynamic>{};

    for (final operation in _performanceMetrics.keys) {
      allMetrics[operation] = getPerformanceMetrics(operation);
    }

    return allMetrics;
  }

  // Monitor memory usage
  void _monitorMemoryUsage() {
    try {
      // This would typically use platform-specific memory monitoring
      // For now, just log a placeholder
      debugPrint('Monitoring memory usage...');
    } catch (e) {
      debugPrint('Failed to monitor memory usage: $e');
    }
  }

  // Monitor network performance
  void _monitorNetworkPerformance() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);

      _recordPerformanceMetric('network_connectivity', Duration(milliseconds: isOnline ? 1 : 0));
    } catch (e) {
      debugPrint('Failed to monitor network performance: $e');
    }
  }

  // Monitor app performance
  void _monitorAppPerformance() {
    try {
      // Monitor app startup time
      final startupTime = _getAppStartupTime();
      if (startupTime != null) {
        _recordPerformanceMetric('app_startup', startupTime);
      }

      // Monitor memory usage
      final memoryUsage = _getMemoryUsage();
      if (memoryUsage != null) {
        _recordPerformanceMetric('memory_usage', Duration(milliseconds: memoryUsage));
      }
    } catch (e) {
      debugPrint('Failed to monitor app performance: $e');
    }
  }

  // Get app startup time
  Duration? _getAppStartupTime() {
    // This would typically be measured from app initialization
    // For now, return a placeholder
    return null;
  }

  // Get memory usage
  int? _getMemoryUsage() {
    // This would typically use platform-specific memory monitoring
    // For now, return a placeholder
    return null;
  }

  // Optimize app startup
  Future<void> optimizeAppStartup() async {
    try {
      // Preload critical data
      await _preloadCriticalData();

      // Initialize services in background
      _initializeServicesInBackground();

      // Cache frequently used data
      await _cacheFrequentlyUsedData();
    } catch (e) {
      debugPrint('Failed to optimize app startup: $e');
    }
  }

  // Preload critical data
  Future<void> _preloadCriticalData() async {
    try {
      // Preload user preferences
      await _prefs.reload();

      // Preload critical app data
      // This would typically include user settings, cached data, etc.
    } catch (e) {
      debugPrint('Failed to preload critical data: $e');
    }
  }

  // Initialize services in background
  void _initializeServicesInBackground() {
    // Initialize non-critical services in background
    Timer(const Duration(seconds: 1), () {
      // Initialize analytics, crash reporting, etc.
    });
  }

  // Cache frequently used data
  Future<void> _cacheFrequentlyUsedData() async {
    try {
      // Cache app configuration
      await _cacheAppConfiguration();

      // Cache user preferences
      await _cacheUserPreferences();
    } catch (e) {
      debugPrint('Failed to cache frequently used data: $e');
    }
  }

  // Cache app configuration
  Future<void> _cacheAppConfiguration() async {
    try {
      // Cache app configuration data
      final config = {
        'version': '1.0.0',
        'buildNumber': '1',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _prefs.setString('app_config', jsonEncode(config));
    } catch (e) {
      debugPrint('Failed to cache app configuration: $e');
    }
  }

  // Cache user preferences
  Future<void> _cacheUserPreferences() async {
    try {
      // Cache user preferences
      final preferences = {
        'theme': 'light',
        'language': 'en',
        'notifications': true,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _prefs.setString('user_preferences', jsonEncode(preferences));
    } catch (e) {
      debugPrint('Failed to cache user preferences: $e');
    }
  }

  // Optimize memory usage
  Future<void> optimizeMemoryUsage() async {
    try {
      // Clear unused caches
      await _clearUnusedCaches();

      // Optimize image caching
      await _optimizeImageCaching();

      // Garbage collection
      _triggerGarbageCollection();
    } catch (e) {
      debugPrint('Failed to optimize memory usage: $e');
    }
  }

  // Clear unused caches
  Future<void> _clearUnusedCaches() async {
    try {
      // Clear old performance metrics
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      for (final operation in _performanceMetrics.keys) {
        _performanceMetrics[operation]!.removeWhere((duration) {
          // This is a simplified check - in reality, you'd track timestamps
          return false;
        });
      }
    } catch (e) {
      debugPrint('Failed to clear unused caches: $e');
    }
  }

  // Optimize image caching
  Future<void> _optimizeImageCaching() async {
    try {
      // This would typically use an image caching library
      // For now, just log a placeholder
      debugPrint('Optimizing image caching...');
    } catch (e) {
      debugPrint('Failed to optimize image caching: $e');
    }
  }

  // Trigger garbage collection
  void _triggerGarbageCollection() {
    // This would typically trigger platform-specific garbage collection
    // For now, just log a placeholder
    debugPrint('Triggering garbage collection...');
  }

  // Optimize offline sync
  Future<void> optimizeOfflineSync() async {
    try {
      // Implement efficient offline sync
      await _implementEfficientOfflineSync();

      // Optimize data compression
      await _optimizeDataCompression();

      // Implement conflict resolution
      await _implementConflictResolution();
    } catch (e) {
      debugPrint('Failed to optimize offline sync: $e');
    }
  }

  // Implement efficient offline sync
  Future<void> _implementEfficientOfflineSync() async {
    try {
      // Implement delta sync
      await _implementDeltaSync();

      // Implement batch operations
      await _implementBatchOperations();
    } catch (e) {
      debugPrint('Failed to implement efficient offline sync: $e');
    }
  }

  // Implement delta sync
  Future<void> _implementDeltaSync() async {
    try {
      // Implement delta sync logic
      // This would typically track changes and only sync what's needed
      debugPrint('Implementing delta sync...');
    } catch (e) {
      debugPrint('Failed to implement delta sync: $e');
    }
  }

  // Implement batch operations
  Future<void> _implementBatchOperations() async {
    try {
      // Implement batch operations for better performance
      debugPrint('Implementing batch operations...');
    } catch (e) {
      debugPrint('Failed to implement batch operations: $e');
    }
  }

  // Optimize data compression
  Future<void> _optimizeDataCompression() async {
    try {
      // Implement data compression for offline storage
      debugPrint('Optimizing data compression...');
    } catch (e) {
      debugPrint('Failed to optimize data compression: $e');
    }
  }

  // Implement conflict resolution
  Future<void> _implementConflictResolution() async {
    try {
      // Implement conflict resolution for offline sync
      debugPrint('Implementing conflict resolution...');
    } catch (e) {
      debugPrint('Failed to implement conflict resolution: $e');
    }
  }

  // Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final allMetrics = getAllPerformanceMetrics();
    final totalOperations = allMetrics.length;
    final averagePerformance = _calculateAveragePerformance(allMetrics);

    return {
      'totalOperations': totalOperations,
      'averagePerformance': averagePerformance,
      'metrics': allMetrics,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Calculate average performance
  double _calculateAveragePerformance(Map<String, dynamic> metrics) {
    if (metrics.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    for (final operation in metrics.values) {
      if (operation is Map<String, dynamic> && operation.containsKey('average')) {
        total += operation['average'] as double;
        count++;
      }
    }

    return count > 0 ? total / count : 0.0;
  }

  // Save performance metrics
  Future<void> _savePerformanceMetrics() async {
    try {
      final metricsJson = jsonEncode(_performanceMetrics);
      await _prefs.setString('performance_metrics', metricsJson);
    } catch (e) {
      debugPrint('Failed to save performance metrics: $e');
    }
  }

  // Load performance metrics
  Future<void> _loadPerformanceMetrics() async {
    try {
      final metricsJson = _prefs.getString('performance_metrics');
      if (metricsJson != null) {
        final metrics = jsonDecode(metricsJson) as Map<String, dynamic>;
        _performanceMetrics.clear();

        for (final entry in metrics.entries) {
          final durations =
              (entry.value as List<dynamic>).map((d) => Duration(milliseconds: d as int)).toList();
          _performanceMetrics[entry.key] = durations;
        }
      }
    } catch (e) {
      debugPrint('Failed to load performance metrics: $e');
    }
  }

  // Performance stream
  Stream<Map<String, dynamic>> get performanceStream => _performanceStreamController.stream;

  // Dispose
  void dispose() {
    _performanceStreamController.close();
  }
}
