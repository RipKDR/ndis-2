import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ndis_connect/services/error_handling_service.dart';

class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance = PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  final ErrorHandlingService _errorService = ErrorHandlingService();
  
  // Performance monitoring
  final Map<String, Stopwatch> _performanceTimers = {};
  final Map<String, List<int>> _performanceMetrics = {};
  
  // Memory management
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, Timer> _timers = {};

  /// Initialize performance optimization
  Future<void> initialize() async {
    await _setupMemoryMonitoring();
    await _setupPerformanceTracking();
    await _optimizeHiveStorage();
  }

  /// Start performance timing
  void startTimer(String operation) {
    _performanceTimers[operation] = Stopwatch()..start();
  }

  /// End performance timing and record metrics
  void endTimer(String operation) {
    final timer = _performanceTimers[operation];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      
      _performanceMetrics.putIfAbsent(operation, () => []).add(duration);
      
      // Log slow operations
      if (duration > 1000) { // More than 1 second
        developer.log(
          'Slow operation detected: $operation took ${duration}ms',
          name: 'PerformanceOptimizationService',
        );
      }
      
      _performanceTimers.remove(operation);
    }
  }

  /// Get performance metrics for an operation
  List<int> getPerformanceMetrics(String operation) {
    return _performanceMetrics[operation] ?? [];
  }

  /// Get average performance for an operation
  double getAveragePerformance(String operation) {
    final metrics = _performanceMetrics[operation];
    if (metrics == null || metrics.isEmpty) return 0.0;
    
    final sum = metrics.reduce((a, b) => a + b);
    return sum / metrics.length;
  }

  /// Optimize list rendering with lazy loading
  Widget createOptimizedListView({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Add performance tracking
        startTimer('list_item_build_$index');
        
        final widget = itemBuilder(context, index);
        
        // Use automatic disposal for performance
        WidgetsBinding.instance.addPostFrameCallback((_) {
          endTimer('list_item_build_$index');
        });
        
        return widget;
      },
    );
  }

  /// Optimize image loading with caching
  Widget createOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return placeholder ?? const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _errorService.handleException(
          error,
          type: ErrorType.unknown,
          severity: ErrorSeverity.low,
          context: {'operation': 'image_loading', 'url': imageUrl},
        );
        
        return errorWidget ?? const Icon(Icons.error);
      },
      // Enable caching
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }

  /// Optimize database queries with batching
  Future<List<T>> batchDatabaseOperations<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 10,
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      
      startTimer('database_batch_${i ~/ batchSize}');
      
      try {
        final batchResults = await Future.wait(
          batch.map((operation) => operation()),
        );
        results.addAll(batchResults);
      } catch (e) {
        _errorService.handleException(
          e,
          type: ErrorType.database,
          severity: ErrorSeverity.medium,
          context: {'operation': 'batch_database_operations'},
        );
      }
      
      endTimer('database_batch_${i ~/ batchSize}');
      
      // Add small delay between batches to prevent overwhelming
      if (i + batchSize < operations.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    return results;
  }

  /// Optimize network requests with caching
  Future<T?> cachedNetworkRequest<T>(
    String cacheKey,
    Future<T> Function() networkCall, {
    Duration cacheDuration = const Duration(minutes: 5),
    T? fallback,
  }) async {
    try {
      // Check cache first
      final cachedData = await _getCachedData<T>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      
      // Make network request
      startTimer('network_request_$cacheKey');
      final result = await networkCall();
      endTimer('network_request_$cacheKey');
      
      // Cache the result
      await _cacheData(cacheKey, result, cacheDuration);
      
      return result;
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        context: {'operation': 'cached_network_request', 'cache_key': cacheKey},
      );
      
      // Return cached data if available, otherwise fallback
      final cachedData = await _getCachedData<T>(cacheKey);
      return cachedData ?? fallback;
    }
  }

  /// Optimize state management with debouncing
  void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, callback);
  }

  /// Optimize memory usage
  void optimizeMemoryUsage() {
    // Clear old performance metrics
    _performanceMetrics.removeWhere((key, value) {
      if (value.length > 100) {
        value.removeRange(0, value.length - 50); // Keep only last 50 entries
        return false;
      }
      return false;
    });
    
    // Clear completed timers
    _performanceTimers.removeWhere((key, value) => !value.isRunning);
    
    // Cancel unused timers
    _timers.removeWhere((key, value) => !value.isActive);
  }

  /// Setup memory monitoring
  Future<void> _setupMemoryMonitoring() async {
    // Monitor memory usage periodically
    Timer.periodic(const Duration(minutes: 5), (timer) {
      optimizeMemoryUsage();
    });
  }

  /// Setup performance tracking
  Future<void> _setupPerformanceTracking() async {
    // Track app lifecycle for performance
    WidgetsBinding.instance.addObserver(_PerformanceObserver(this));
  }

  /// Optimize Hive storage
  Future<void> _optimizeHiveStorage() async {
    try {
      // Compact Hive boxes to reduce memory usage
      // Note: Hive doesn't provide direct access to all boxes
      // This would need to be implemented with specific box names
      // For now, we'll skip this optimization
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        context: {'operation': 'optimize_hive_storage'},
      );
    }
  }

  /// Cache data with expiration
  Future<void> _cacheData<T>(String key, T data, Duration duration) async {
    try {
      final cacheBox = await Hive.openBox('performance_cache');
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expires_at': DateTime.now().add(duration).millisecondsSinceEpoch,
      };
      await cacheBox.put(key, cacheData);
    } catch (e) {
      // Silent fail for caching
    }
  }

  /// Get cached data if not expired
  Future<T?> _getCachedData<T>(String key) async {
    try {
      final cacheBox = await Hive.openBox('performance_cache');
      final cacheData = cacheBox.get(key);
      
      if (cacheData != null) {
        final expiresAt = cacheData['expires_at'] as int;
        if (DateTime.now().millisecondsSinceEpoch < expiresAt) {
          return cacheData['data'] as T;
        } else {
          // Remove expired data
          await cacheBox.delete(key);
        }
      }
    } catch (e) {
      // Silent fail for caching
    }
    return null;
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    for (final entry in _performanceMetrics.entries) {
      final operation = entry.key;
      final metrics = entry.value;
      
      if (metrics.isNotEmpty) {
        final average = metrics.reduce((a, b) => a + b) / metrics.length;
        final min = metrics.reduce((a, b) => a < b ? a : b);
        final max = metrics.reduce((a, b) => a > b ? a : b);
        
        report[operation] = {
          'average_ms': average,
          'min_ms': min,
          'max_ms': max,
          'count': metrics.length,
        };
      }
    }
    
    return report;
  }

  /// Dispose resources
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    
    for (final timer in _timers.values) {
      timer.cancel();
    }
    
    _subscriptions.clear();
    _timers.clear();
    _performanceTimers.clear();
  }
}

/// Performance observer for app lifecycle
class _PerformanceObserver extends WidgetsBindingObserver {
  final PerformanceOptimizationService _service;
  
  _PerformanceObserver(this._service);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _service.optimizeMemoryUsage();
        break;
      case AppLifecycleState.resumed:
        _service.startTimer('app_resume');
        break;
      case AppLifecycleState.detached:
        _service.dispose();
        break;
      default:
        break;
    }
  }
}

/// Performance optimization mixin for services
mixin PerformanceOptimizationMixin {
  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();

  /// Execute operation with performance tracking
  Future<T?> executeWithPerformanceTracking<T>(
    String operation,
    Future<T> Function() operationFunction, {
    T? fallback,
  }) async {
    _performanceService.startTimer(operation);
    
    try {
      final result = await operationFunction();
      _performanceService.endTimer(operation);
      return result;
    } catch (e) {
      _performanceService.endTimer(operation);
      return fallback;
    }
  }

  /// Debounce operation
  void debounceOperation(String key, VoidCallback callback) {
    _performanceService.debounce(key, callback);
  }
}
