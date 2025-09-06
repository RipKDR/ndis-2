import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String _tasksBoxName(String uid) => 'tasks_cache_$uid';
  String _opsBoxName(String uid) => 'tasks_ops_$uid';

  Future<List<TaskModel>> fetchTasks(String uid,
      {TaskStatus? status, TaskCategory? category}) async {
    try {
      Query query = _db.collection('tasks').doc(uid).collection('items');

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      final q = await query
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
      final tasks = q.docs
          .map((d) => TaskModel.fromMap({
                ...d.data() as Map<String, dynamic>,
                'id': d.id,
              }))
          .toList();

      await _saveCache(uid, tasks);
      return tasks;
    } catch (_) {
      // Offline or failed: fall back to cache
      return _readCache(uid).where((task) {
        if (status != null && task.status != status) return false;
        if (category != null && task.category != category) return false;
        return true;
      }).toList();
    }
  }

  Future<List<TaskModel>> fetchOverdueTasks(String uid) async {
    final now = DateTime.now();
    try {
      final q = await _db
          .collection('tasks')
          .doc(uid)
          .collection('items')
          .where('status', whereIn: ['pending', 'in_progress'])
          .where('dueDate', isLessThan: now.toIso8601String())
          .get(const GetOptions(source: Source.server));

      final tasks = q.docs
          .map((d) => TaskModel.fromMap({
                ...d.data(),
                'id': d.id,
              }))
          .toList();

      return tasks;
    } catch (_) {
      // Offline fallback
      return _readCache(uid).where((task) {
        return (task.status == TaskStatus.pending || task.status == TaskStatus.inProgress) &&
            task.dueDate != null &&
            task.dueDate!.isBefore(now);
      }).toList();
    }
  }

  Future<List<TaskModel>> fetchTodayTasks(String uid) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final q = await _db
          .collection('tasks')
          .doc(uid)
          .collection('items')
          .where('dueDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('dueDate', isLessThan: endOfDay.toIso8601String())
          .get(const GetOptions(source: Source.server));

      final tasks = q.docs
          .map((d) => TaskModel.fromMap({
                ...d.data(),
                'id': d.id,
              }))
          .toList();

      return tasks;
    } catch (_) {
      // Offline fallback
      return _readCache(uid).where((task) {
        return task.dueDate != null &&
            task.dueDate!.isAfter(startOfDay.subtract(const Duration(days: 1))) &&
            task.dueDate!.isBefore(endOfDay);
      }).toList();
    }
  }

  Future<TaskModel> createTask(String uid, TaskModel task, {bool enqueueIfOffline = true}) async {
    final id = task.id.isEmpty ? _uuid.v4() : task.id;
    final data = {
      ...task.toMap(),
      'id': id,
    };

    try {
      await _db.collection('tasks').doc(uid).collection('items').doc(id).set(data);
    } catch (_) {
      if (enqueueIfOffline) {
        await _enqueue(uid, {'op': 'create', 'data': data});
      } else {
        rethrow;
      }
    }

    final createdTask = TaskModel.fromMap(data);
    await _upsertCache(uid, createdTask);
    return createdTask;
  }

  Future<void> updateTask(String uid, TaskModel task, {bool enqueueIfOffline = true}) async {
    try {
      await _db
          .collection('tasks')
          .doc(uid)
          .collection('items')
          .doc(task.id)
          .set(task.toMap(), SetOptions(merge: true));
    } catch (_) {
      if (enqueueIfOffline) {
        await _enqueue(uid, {'op': 'update', 'data': task.toMap()});
      } else {
        rethrow;
      }
    }

    await _upsertCache(uid, task);
  }

  Future<void> deleteTask(String uid, String taskId, {bool enqueueIfOffline = true}) async {
    try {
      await _db.collection('tasks').doc(uid).collection('items').doc(taskId).delete();
    } catch (_) {
      if (enqueueIfOffline) {
        await _enqueue(uid, {'op': 'delete', 'id': taskId});
      } else {
        rethrow;
      }
    }

    await _deleteCache(uid, taskId);
  }

  Future<void> markTaskComplete(String uid, String taskId, {bool enqueueIfOffline = true}) async {
    final now = DateTime.now();
    try {
      await _db.collection('tasks').doc(uid).collection('items').doc(taskId).update({
        'status': TaskStatus.completed.name,
        'completedAt': now.toIso8601String(),
        'progress': 100,
      });
    } catch (_) {
      if (enqueueIfOffline) {
        await _enqueue(uid, {
          'op': 'update',
          'data': {
            'id': taskId,
            'status': TaskStatus.completed.name,
            'completedAt': now.toIso8601String(),
            'progress': 100,
          }
        });
      } else {
        rethrow;
      }
    }

    // Update cache
    final cachedTasks = _readCache(uid);
    final taskIndex = cachedTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final updatedTask = cachedTasks[taskIndex].copyWith(
        status: TaskStatus.completed,
        completedAt: now,
        progress: 100,
      );
      await _upsertCache(uid, updatedTask);
    }
  }

  Future<void> updateTaskProgress(String uid, String taskId, int progress,
      {bool enqueueIfOffline = true}) async {
    final status = progress >= 100 ? TaskStatus.completed : TaskStatus.inProgress;
    final completedAt = progress >= 100 ? DateTime.now() : null;

    try {
      await _db.collection('tasks').doc(uid).collection('items').doc(taskId).update({
        'progress': progress,
        'status': status.name,
        if (completedAt != null) 'completedAt': completedAt.toIso8601String(),
      });
    } catch (_) {
      if (enqueueIfOffline) {
        await _enqueue(uid, {
          'op': 'update',
          'data': {
            'id': taskId,
            'progress': progress,
            'status': status.name,
            if (completedAt != null) 'completedAt': completedAt.toIso8601String(),
          }
        });
      } else {
        rethrow;
      }
    }

    // Update cache
    final cachedTasks = _readCache(uid);
    final taskIndex = cachedTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final updatedTask = cachedTasks[taskIndex].copyWith(
        progress: progress,
        status: status,
        completedAt: completedAt,
      );
      await _upsertCache(uid, updatedTask);
    }
  }

  Future<void> processQueue(String uid) async {
    final box = await Hive.openBox<String>(_opsBoxName(uid));
    final ops = (box.get('ops') != null)
        ? (jsonDecode(box.get('ops')!) as List)
            .cast<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    if (ops.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final op in ops) {
      try {
        switch (op['op']) {
          case 'create':
            await _db
                .collection('tasks')
                .doc(uid)
                .collection('items')
                .doc((op['data'] as Map)['id'] as String)
                .set(Map<String, dynamic>.from(op['data'] as Map));
            break;
          case 'update':
            await _db
                .collection('tasks')
                .doc(uid)
                .collection('items')
                .doc((op['data'] as Map)['id'] as String)
                .set(Map<String, dynamic>.from(op['data'] as Map), SetOptions(merge: true));
            break;
          case 'delete':
            await _db
                .collection('tasks')
                .doc(uid)
                .collection('items')
                .doc(op['id'] as String)
                .delete();
            break;
        }
      } catch (_) {
        remaining.add(op); // keep for next retry
      }
    }

    await box.put('ops', jsonEncode(remaining));
  }

  // Cache helpers
  Future<void> _saveCache(String uid, List<TaskModel> tasks) async {
    final box = await Hive.openBox<String>(_tasksBoxName(uid));
    final map = {for (var task in tasks) task.id: jsonEncode(task.toMap())};
    await box.putAll(map);
  }

  Future<void> _upsertCache(String uid, TaskModel task) async {
    final box = await Hive.openBox<String>(_tasksBoxName(uid));
    await box.put(task.id, jsonEncode(task.toMap()));
  }

  Future<void> _deleteCache(String uid, String taskId) async {
    final box = await Hive.openBox<String>(_tasksBoxName(uid));
    await box.delete(taskId);
  }

  List<TaskModel> _readCache(String uid) {
    final box = Hive.isBoxOpen(_tasksBoxName(uid)) ? Hive.box<String>(_tasksBoxName(uid)) : null;
    if (box == null) return [];
    return box.values.map((s) => TaskModel.fromMap(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> _enqueue(String uid, Map<String, dynamic> op) async {
    final box = await Hive.openBox<String>(_opsBoxName(uid));
    final current = box.get('ops');
    final list = current == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(current) as List)
            .cast<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    list.add(op);
    await box.put('ops', jsonEncode(list));
  }

  // Enhanced task management features
  Future<List<TaskModel>> searchTasks(String uid, String query) async {
    final allTasks = await fetchTasks(uid);
    final lowercaseQuery = query.toLowerCase();

    return allTasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          (task.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<List<TaskModel>> getRecurringTasks(String uid) async {
    try {
      final q = await _db
          .collection('tasks')
          .doc(uid)
          .collection('items')
          .where('isRecurring', isEqualTo: true)
          .get(const GetOptions(source: Source.server));

      return q.docs
          .map((d) => TaskModel.fromMap({
                ...d.data(),
                'id': d.id,
              }))
          .toList();
    } catch (_) {
      return _readCache(uid).where((task) => task.isRecurring).toList();
    }
  }

  Future<void> createRecurringTask(String uid, TaskModel task) async {
    if (!task.isRecurring || task.recurringPattern == null) {
      throw ArgumentError('Task must be recurring with a pattern');
    }

    final now = DateTime.now();
    final tasks = <TaskModel>[];

    switch (task.recurringPattern) {
      case 'daily':
        for (int i = 0; i < 30; i++) {
          final dueDate = now.add(Duration(days: i));
          tasks.add(task.copyWith(
            id: _uuid.v4(),
            dueDate: dueDate,
            createdAt: now,
          ));
        }
        break;
      case 'weekly':
        for (int i = 0; i < 12; i++) {
          final dueDate = now.add(Duration(days: i * 7));
          tasks.add(task.copyWith(
            id: _uuid.v4(),
            dueDate: dueDate,
            createdAt: now,
          ));
        }
        break;
      case 'monthly':
        for (int i = 0; i < 12; i++) {
          final dueDate = DateTime(now.year, now.month + i, now.day);
          tasks.add(task.copyWith(
            id: _uuid.v4(),
            dueDate: dueDate,
            createdAt: now,
          ));
        }
        break;
    }

    // Batch create tasks
    final batch = _db.batch();
    for (final taskToCreate in tasks) {
      final docRef = _db.collection('tasks').doc(uid).collection('items').doc(taskToCreate.id);
      batch.set(docRef, taskToCreate.toMap());
    }

    try {
      await batch.commit();
    } catch (_) {
      // If batch fails, enqueue individual operations
      for (final taskToCreate in tasks) {
        await _enqueue(uid, {'op': 'create', 'data': taskToCreate.toMap()});
      }
    }

    // Update cache
    for (final taskToCreate in tasks) {
      await _upsertCache(uid, taskToCreate);
    }
  }

  Future<Map<String, int>> getTaskStatistics(String uid) async {
    final tasks = await fetchTasks(uid);

    return {
      'total': tasks.length,
      'completed': tasks.where((t) => t.status == TaskStatus.completed).length,
      'pending': tasks.where((t) => t.status == TaskStatus.pending).length,
      'inProgress': tasks.where((t) => t.status == TaskStatus.inProgress).length,
      'overdue': tasks.where((t) => t.isOverdue).length,
      'dueToday': tasks.where((t) => t.isDueToday).length,
      'dueThisWeek': tasks.where((t) => t.isDueThisWeek).length,
    };
  }

  Future<List<TaskModel>> getTasksByDateRange(String uid, DateTime start, DateTime end) async {
    try {
      final q = await _db
          .collection('tasks')
          .doc(uid)
          .collection('items')
          .where('dueDate', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('dueDate', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('dueDate')
          .get(const GetOptions(source: Source.server));

      return q.docs
          .map((d) => TaskModel.fromMap({
                ...d.data(),
                'id': d.id,
              }))
          .toList();
    } catch (_) {
      return _readCache(uid).where((task) {
        if (task.dueDate == null) return false;
        return task.dueDate!.isAfter(start.subtract(const Duration(days: 1))) &&
            task.dueDate!.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    }
  }
}
