import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ndis_connect/models/task.dart';
import 'package:ndis_connect/services/error_handling_service.dart';
import 'package:ndis_connect/services/performance_optimization_service.dart';

class OptimizedTaskService with PerformanceOptimizationMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ErrorHandlingService _errorService = ErrorHandlingService();
  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();

  static const String _boxName = 'tasks_cache';
  static const String _syncQueueBoxName = 'task_sync_queue';

  // Cache configuration
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static const int _batchSize = 20;

  /// Get tasks with caching and performance optimization
  Future<List<TaskModel>> getTasks(String userId) async {
    final result = await executeWithPerformanceTracking(
      'get_tasks',
      () => _getTasksOptimized(userId),
      fallback: <TaskModel>[],
    );
    return result ?? <TaskModel>[];
  }

  /// Optimized task retrieval
  Future<List<TaskModel>> _getTasksOptimized(String userId) async {
    try {
      // Try cache first
      final cacheKey = 'tasks_$userId';
      final cachedTaskModels = await _performanceService.cachedNetworkRequest(
        cacheKey,
        () => _fetchTaskModelsFromFirestore(userId),
        cacheDuration: _cacheExpiration,
        fallback: await _getTasksFromCache(userId),
      );

      if (cachedTaskModels != null) {
        return cachedTaskModels;
      }

      // Fallback to cache
      return await _getTasksFromCache(userId);
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        context: {'operation': 'get_tasks', 'user_id': userId},
      );
      return await _getTasksFromCache(userId);
    }
  }

  /// Fetch tasks from Firestore
  Future<List<TaskModel>> _fetchTaskModelsFromFirestore(String userId) async {
    final snapshot = await _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit for performance
        .get();

    final tasks = snapshot.docs
        .map((doc) => TaskModel.fromMap({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();

    // Cache the results
    await _cacheTaskModels(userId, tasks);

    return tasks;
  }

  /// Get tasks from local cache
  Future<List<TaskModel>> _getTasksFromCache(String userId) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final cachedData = box.get('tasks_$userId');

      if (cachedData != null) {
        final List<dynamic> taskMaps = jsonDecode(cachedData);
        return taskMaps.map((map) => TaskModel.fromMap(map as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        context: {'operation': 'get_tasks_from_cache'},
      );
    }

    return [];
  }

  /// Cache tasks locally
  Future<void> _cacheTaskModels(String userId, List<TaskModel> tasks) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final taskMaps = tasks.map((task) => task.toMap()).toList();
      await box.put('tasks_$userId', jsonEncode(taskMaps));
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        context: {'operation': 'cache_tasks'},
      );
    }
  }

  /// Create task with offline support
  Future<TaskModel> createTask(TaskModel task) async {
    final result = await executeWithPerformanceTracking(
      'create_task',
      () => _createTaskOptimized(task),
    );
    return result ?? task;
  }

  /// Optimized task creation
  Future<TaskModel?> _createTaskOptimized(TaskModel task) async {
    try {
      // Add to sync queue for offline support
      await _addToSyncQueue('create', task);

      // Try to create immediately if online
      final docRef = await _db.collection('tasks').add(task.toMap());
      final createdTaskModel = task.copyWith(id: docRef.id);

      // Update cache
      await _invalidateCache(task.ownerUid);

      return createdTaskModel;
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        context: {'operation': 'create_task'},
      );

      // TaskModel will be synced later from queue
      return task;
    }
  }

  /// Update task with offline support
  Future<void> updateTaskModel(TaskModel task) async {
    await executeWithPerformanceTracking(
      'update_task',
      () => _updateTaskModelOptimized(task),
    );
  }

  /// Optimized task update
  Future<void> _updateTaskModelOptimized(TaskModel task) async {
    try {
      // Add to sync queue
      await _addToSyncQueue('update', task);

      // Try to update immediately if online
      await _db.collection('tasks').doc(task.id).update(task.toMap());

      // Update cache
      await _invalidateCache(task.ownerUid);
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        context: {'operation': 'update_task'},
      );
    }
  }

  /// Delete task with offline support
  Future<void> deleteTaskModel(String taskId, String userId) async {
    await executeWithPerformanceTracking(
      'delete_task',
      () => _deleteTaskModelOptimized(taskId, userId),
    );
  }

  /// Optimized task deletion
  Future<void> _deleteTaskModelOptimized(String taskId, String userId) async {
    try {
      // Add to sync queue
      await _addToSyncQueue('delete', {'id': taskId, 'userId': userId});

      // Try to delete immediately if online
      await _db.collection('tasks').doc(taskId).delete();

      // Update cache
      await _invalidateCache(userId);
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        context: {'operation': 'delete_task'},
      );
    }
  }

  /// Get task statistics with caching
  Future<Map<String, int>> getTaskStatistics(String userId) async {
    final result = await executeWithPerformanceTracking(
      'get_task_statistics',
      () => _getTaskStatisticsOptimized(userId),
      fallback: <String, int>{},
    );
    return result ?? <String, int>{};
  }

  /// Optimized task statistics
  Future<Map<String, int>> _getTaskStatisticsOptimized(String userId) async {
    try {
      final tasks = await getTasks(userId);

      final statistics = <String, int>{
        'total': tasks.length,
        'completed': 0,
        'pending': 0,
        'in_progress': 0,
        'overdue': 0,
        'cancelled': 0,
      };

      for (final task in tasks) {
        switch (task.status) {
          case TaskStatus.completed:
            statistics['completed'] = (statistics['completed'] ?? 0) + 1;
            break;
          case TaskStatus.pending:
            statistics['pending'] = (statistics['pending'] ?? 0) + 1;
            break;
          case TaskStatus.inProgress:
            statistics['in_progress'] = (statistics['in_progress'] ?? 0) + 1;
            break;
          case TaskStatus.overdue:
            statistics['overdue'] = (statistics['overdue'] ?? 0) + 1;
            break;
          case TaskStatus.cancelled:
            statistics['cancelled'] = (statistics['cancelled'] ?? 0) + 1;
            break;
        }
      }

      return statistics;
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        context: {'operation': 'get_task_statistics'},
      );
      return <String, int>{};
    }
  }

  /// Batch operations for better performance
  Future<List<TaskModel>> batchCreateTasks(List<TaskModel> tasks) async {
    if (tasks.isEmpty) return [];

    final result = await executeWithPerformanceTracking(
      'batch_create_tasks',
      () => _batchCreateTasksOptimized(tasks),
      fallback: tasks,
    );
    return result ?? tasks;
  }

  /// Optimized batch task creation
  Future<List<TaskModel>> _batchCreateTasksOptimized(List<TaskModel> tasks) async {
    final createdTaskModels = <TaskModel>[];

    // Process in batches
    for (int i = 0; i < tasks.length; i += _batchSize) {
      final batch = tasks.skip(i).take(_batchSize);

      final batchResults = await _performanceService.batchDatabaseOperations(
        batch.map((task) => () => _createTaskOptimized(task)).toList(),
        batchSize: _batchSize,
      );

      createdTaskModels.addAll(batchResults.whereType<TaskModel>());
    }

    return createdTaskModels;
  }

  /// Add operation to sync queue
  Future<void> _addToSyncQueue(String operation, dynamic data) async {
    try {
      final box = await Hive.openBox<String>(_syncQueueBoxName);
      final queueItem = {
        'operation': operation,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
      };

      await box.add(jsonEncode(queueItem));
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        context: {'operation': 'add_to_sync_queue'},
      );
    }
  }

  /// Process sync queue
  Future<void> processSyncQueue() async {
    await executeWithPerformanceTracking(
      'process_sync_queue',
      () => _processSyncQueueOptimized(),
    );
  }

  /// Optimized sync queue processing
  Future<void> _processSyncQueueOptimized() async {
    try {
      final box = await Hive.openBox<String>(_syncQueueBoxName);
      final queueItems = box.values.toList();

      for (int i = 0; i < queueItems.length; i++) {
        final item = jsonDecode(queueItems[i]) as Map<String, dynamic>;
        final operation = item['operation'] as String;
        final data = item['data'];
        final retryCount = item['retry_count'] as int;

        try {
          switch (operation) {
            case 'create':
              await _db.collection('tasks').add(data);
              break;
            case 'update':
              await _db.collection('tasks').doc(data['id']).update(data);
              break;
            case 'delete':
              await _db.collection('tasks').doc(data['id']).delete();
              break;
          }

          // Remove successful item from queue
          await box.deleteAt(i);
        } catch (e) {
          // Increment retry count
          item['retry_count'] = retryCount + 1;

          if (retryCount < 3) {
            await box.putAt(i, jsonEncode(item));
          } else {
            // Remove after max retries
            await box.deleteAt(i);
          }
        }
      }
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        context: {'operation': 'process_sync_queue'},
      );
    }
  }

  /// Invalidate cache for user
  Future<void> _invalidateCache(String userId) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.delete('tasks_$userId');
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        context: {'operation': 'invalidate_cache'},
      );
    }
  }

  /// Clear all caches
  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.clear();
    } catch (e) {
      _errorService.handleException(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        context: {'operation': 'clear_cache'},
      );
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return _performanceService.getPerformanceReport();
  }
}
