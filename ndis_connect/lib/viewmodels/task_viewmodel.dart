import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskService _service;
  final FirebaseAuth _auth;
  final _conn = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  List<TaskModel> _tasks = [];
  List<TaskModel> _todayTasks = [];
  List<TaskModel> _overdueTasks = [];
  List<TaskModel> _recurringTasks = [];
  List<TaskModel> _searchResults = [];
  bool _loading = true;
  String? _error;
  TaskStatus? _filterStatus;
  TaskCategory? _filterCategory;
  String _searchQuery = '';
  Map<String, int> _statistics = {};

  TaskViewModel(this._service, this._auth) {
    _sub = _conn.onConnectivityChanged.listen((_) => _onConnectivity());
    _bootstrap();
  }

  List<TaskModel> get tasks => _searchQuery.isNotEmpty ? _searchResults : _tasks;
  List<TaskModel> get todayTasks => _todayTasks;
  List<TaskModel> get overdueTasks => _overdueTasks;
  List<TaskModel> get recurringTasks => _recurringTasks;
  List<TaskModel> get searchResults => _searchResults;
  bool get loading => _loading;
  String? get error => _error;
  TaskStatus? get filterStatus => _filterStatus;
  TaskCategory? get filterCategory => _filterCategory;
  String get searchQuery => _searchQuery;
  Map<String, int> get statistics => _statistics;

  // Task statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.status == TaskStatus.completed).length;
  int get pendingTasks => _tasks.where((t) => t.status == TaskStatus.pending).length;
  int get inProgressTasks => _tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get overdueTasksCount => _tasks.where((t) => t.isOverdue).length;
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  Future<void> _bootstrap() async {
    await refresh();
  }

  Future<void> refresh() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      _tasks = await _service.fetchTasks(uid, status: _filterStatus, category: _filterCategory);
      _todayTasks = await _service.fetchTodayTasks(uid);
      _overdueTasks = await _service.fetchOverdueTasks(uid);
      _recurringTasks = await _service.getRecurringTasks(uid);
      _statistics = await _service.getTaskStatistics(uid);
      
      // Update search results if there's an active search
      if (_searchQuery.isNotEmpty) {
        _searchResults = await _service.searchTasks(uid, _searchQuery);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setFilter({TaskStatus? status, TaskCategory? category}) async {
    _filterStatus = status;
    _filterCategory = category;
    await refresh();
  }

  Future<void> clearFilters() async {
    _filterStatus = null;
    _filterCategory = null;
    await refresh();
  }

  Future<TaskModel> addTask(TaskModel task) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    
    final created = await _service.createTask(uid, task);
    await refresh();
    return created;
  }

  Future<void> updateTask(TaskModel task) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _service.updateTask(uid, task);
    await refresh();
  }

  Future<void> deleteTask(String taskId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _service.deleteTask(uid, taskId);
    await refresh();
  }

  Future<void> markTaskComplete(String taskId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _service.markTaskComplete(uid, taskId);
    await refresh();
  }

  Future<void> updateTaskProgress(String taskId, int progress) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _service.updateTaskProgress(uid, taskId, progress);
    await refresh();
  }

  Future<void> _onConnectivity() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _service.processQueue(uid);
    await refresh();
  }

  // Helper methods for UI
  List<TaskModel> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  List<TaskModel> getTasksByCategory(TaskCategory category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  List<TaskModel> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  List<TaskModel> getUpcomingTasks({int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(now) && 
             task.dueDate!.isBefore(future) &&
             task.status != TaskStatus.completed;
    }).toList();
  }

  // Search functionality
  Future<void> searchTasks(String query) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = await _service.searchTasks(uid, query);
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // Recurring tasks
  Future<void> createRecurringTask(TaskModel task) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    
    await _service.createRecurringTask(uid, task);
    await refresh();
  }

  // Date range queries
  Future<List<TaskModel>> getTasksByDateRange(DateTime start, DateTime end) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    
    return await _service.getTasksByDateRange(uid, start, end);
  }

  // Enhanced statistics
  int getStatistic(String key) => _statistics[key] ?? 0;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
