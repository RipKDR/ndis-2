import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'error_handling_service.dart';

/// Service for monitoring and optimizing memory usage
class MemoryOptimizationService {
  static final MemoryOptimizationService _instance = MemoryOptimizationService._internal();
  factory MemoryOptimizationService({ErrorHandlingService? errorHandler}) {
    if (errorHandler != null) {
      _instance._errorHandler = errorHandler;
    }
    return _instance;
  }
  MemoryOptimizationService._internal();

  ErrorHandlingService? _errorHandler;

  Timer? _memoryMonitorTimer;
  Timer? _cacheCleanupTimer;
  final Map<String, DateTime> _cacheAccessTimes = {};
  final Map<String, int> _memoryUsageHistory = {};

  bool _isInitialized = false;
  int _maxMemoryUsage = 0;
  int _currentMemoryUsage = 0;

  /// Initialize memory optimization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _startMemoryMonitoring();
      await _startCacheCleanup();
      _isInitialized = true;

      dev.log('Memory optimization service initialized', name: 'MemoryOptimizationService');
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        context: {
          'operation': 'initialize',
          'service': 'MemoryOptimizationService',
        },
      );
    }
  }

  /// Start memory monitoring
  Future<void> _startMemoryMonitoring() async {
    _memoryMonitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkMemoryUsage();
    });
  }

  /// Start cache cleanup
  Future<void> _startCacheCleanup() async {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _cleanupCaches();
    });
  }

  /// Check current memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use platform-specific memory checking
        final memoryInfo = await _getMemoryInfo();
        _currentMemoryUsage = memoryInfo['used'] ?? 0;
        _maxMemoryUsage = memoryInfo['max'] ?? 0;

        // Record memory usage history
        _memoryUsageHistory[DateTime.now().toIso8601String()] = _currentMemoryUsage;

        // Clean up old history (keep only last 24 hours)
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        _memoryUsageHistory.removeWhere((timestamp, usage) {
          return DateTime.parse(timestamp).isBefore(cutoff);
        });

        // Trigger cleanup if memory usage is high
        if (_isMemoryUsageHigh()) {
          await _performMemoryCleanup();
        }
      }
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        context: {
          'operation': 'check_memory_usage',
          'service': 'MemoryOptimizationService',
        },
      );
    }
  }

  /// Get memory information from platform
  Future<Map<String, int>> _getMemoryInfo() async {
    try {
      const platform = MethodChannel('ndis_connect/memory');
      final result = await platform.invokeMethod('getMemoryInfo');
      return Map<String, int>.from(result);
    } catch (e) {
      // Fallback to estimated memory usage
      return {
        'used': _estimateMemoryUsage(),
        'max': 512 * 1024 * 1024, // 512MB default
      };
    }
  }

  /// Estimate memory usage based on app state
  int _estimateMemoryUsage() {
    // Simple estimation based on various factors
    int estimated = 50 * 1024 * 1024; // Base 50MB

    // Add estimation for cached images
    estimated += _cacheAccessTimes.length * 1024 * 1024; // 1MB per cached item

    // Add estimation for Hive boxes
    estimated += 10 * 1024 * 1024; // 10MB for Hive storage

    return estimated;
  }

  /// Check if memory usage is high
  bool _isMemoryUsageHigh() {
    if (_maxMemoryUsage == 0) return false;

    final usagePercentage = (_currentMemoryUsage / _maxMemoryUsage) * 100;
    return usagePercentage > 80; // Consider 80% as high usage
  }

  /// Perform memory cleanup
  Future<void> _performMemoryCleanup() async {
    try {
      dev.log('Performing memory cleanup - usage: ${_currentMemoryUsage ~/ (1024 * 1024)}MB',
          name: 'MemoryOptimizationService');

      await _cleanupImageCache();
      await _cleanupHiveBoxes();
      await _cleanupWidgetCache();
      await _forceGarbageCollection();

      dev.log('Memory cleanup completed', name: 'MemoryOptimizationService');
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        context: {
          'operation': 'perform_memory_cleanup',
          'service': 'MemoryOptimizationService',
        },
      );
    }
  }

  /// Cleanup image cache
  Future<void> _cleanupImageCache() async {
    try {
      // Clear expired cache entries
      final now = DateTime.now();
      final expiredKeys = _cacheAccessTimes.entries
          .where((entry) => now.difference(entry.value).inMinutes > 30)
          .map((entry) => entry.key)
          .toList();

      for (final key in expiredKeys) {
        _cacheAccessTimes.remove(key);
      }

      // Clear system image cache if available
      await _clearSystemImageCache();
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        context: {
          'operation': 'cleanup_image_cache',
          'service': 'MemoryOptimizationService',
        },
      );
    }
  }

  /// Clear system image cache
  Future<void> _clearSystemImageCache() async {
    try {
      // This would typically call platform-specific cache clearing
      // For now, we'll use a placeholder
      if (Platform.isAndroid || Platform.isIOS) {
        const platform = MethodChannel('ndis_connect/cache');
        await platform.invokeMethod('clearImageCache');
      }
    } catch (e) {
      // Silent fail for cache clearing
    }
  }

  /// Cleanup Hive boxes
  Future<void> _cleanupHiveBoxes() async {
    try {
      // Get all open boxes and compact them
      // Note: Hive doesn't provide direct access to all box names
      // We'll need to track box names manually or skip this optimization
      final knownBoxNames = ['user_profile_box', 'tasks_cache_', 'performance_cache'];

      for (final boxName in knownBoxNames) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            if (box.length > 1000) {
              // If box is large
              // Remove oldest entries
              final keysToRemove = box.keys.take(box.length ~/ 2).toList();
              for (final key in keysToRemove) {
                await box.delete(key);
              }
            }
          }
        } catch (e) {
          // Continue with other boxes if one fails
        }
      }
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        context: {
          'operation': 'cleanup_hive_boxes',
          'service': 'MemoryOptimizationService',
        },
      );
    }
  }

  /// Cleanup widget cache
  Future<void> _cleanupWidgetCache() async {
    try {
      // This would cleanup any widget-level caches
      // For now, we'll use a placeholder
      dev.log('Cleaning up widget caches', name: 'MemoryOptimizationService');
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        context: {
          'operation': 'cleanup_widget_cache',
          'service': 'MemoryOptimizationService',
        },
      );
    }
  }

  /// Force garbage collection
  Future<void> _forceGarbageCollection() async {
    try {
      // Trigger garbage collection on supported platforms
      if (Platform.isAndroid || Platform.isIOS) {
        const platform = MethodChannel('ndis_connect/memory');
        await platform.invokeMethod('forceGarbageCollection');
      }
    } catch (e) {
      // Silent fail for garbage collection
    }
  }

  /// Cleanup caches periodically
  Future<void> _cleanupCaches() async {
    try {
      await _cleanupImageCache();
      await _optimizeDataCaches();
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        context: {
          'operation': 'cleanup_caches',
          'service': 'MemoryOptimizationService',
        },
      );
    }
  }

  /// Optimize data caches
  Future<void> _optimizeDataCaches() async {
    try {
      // Remove unused cache entries
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 1));

      _cacheAccessTimes.removeWhere((key, accessTime) {
        return accessTime.isBefore(cutoff);
      });
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.unknown,
        severity: ErrorSeverity.low,
        context: {
          'operation': 'optimize_data_caches',
          'service': 'MemoryOptimizationService',
        },
      );
    }
  }

  /// Record cache access
  void recordCacheAccess(String key) {
    _cacheAccessTimes[key] = DateTime.now();
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'current_usage_mb': _currentMemoryUsage ~/ (1024 * 1024),
      'max_usage_mb': _maxMemoryUsage ~/ (1024 * 1024),
      'usage_percentage': _maxMemoryUsage > 0 ? (_currentMemoryUsage / _maxMemoryUsage) * 100 : 0,
      'cache_entries': _cacheAccessTimes.length,
      'memory_history_entries': _memoryUsageHistory.length,
      'is_memory_high': _isMemoryUsageHigh(),
    };
  }

  /// Optimize memory for specific operations
  Future<T?> optimizeMemoryForOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    bool cleanupBefore = false,
    bool cleanupAfter = true,
  }) async {
    try {
      if (cleanupBefore) {
        await _performMemoryCleanup();
      }

      final result = await operation();

      if (cleanupAfter) {
        // Schedule cleanup after operation
        Timer(const Duration(seconds: 1), () async {
          await _cleanupCaches();
        });
      }

      return result;
    } catch (error, stackTrace) {
      _errorHandler?.handleError(
        error,
        stackTrace: stackTrace,
        context: {
          'operation': operationName,
          'service': 'MemoryOptimizationService',
        },
      );
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    _cacheAccessTimes.clear();
    _memoryUsageHistory.clear();
  }
}
