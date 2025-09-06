import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/models/task.dart';
import 'package:ndis_connect/services/task_service.dart';
import 'package:ndis_connect/viewmodels/task_viewmodel.dart';

import 'task_viewmodel_test.mocks.dart';

@GenerateMocks([TaskService, FirebaseAuth, User, Connectivity])
void main() {
  group('TaskViewModel', () {
    late TaskViewModel taskViewModel;
    late MockTaskService mockTaskService;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockTaskService = MockTaskService();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-uid');

      taskViewModel = TaskViewModel(mockTaskService, mockAuth);
    });

    group('Initialization', () {
      test('should initialize with loading state', () {
        expect(taskViewModel.loading, isTrue);
        expect(taskViewModel.tasks, isEmpty);
        expect(taskViewModel.error, isNull);
      });
    });

    group('fetchTasks', () {
      test('should fetch tasks successfully', () async {
        // Arrange
        final mockTasks = [
          TaskModel(
            id: 'task1',
            ownerUid: 'test-uid',
            title: 'Test Task 1',
            category: TaskCategory.dailyLiving,
            createdAt: DateTime.now(),
          ),
          TaskModel(
            id: 'task2',
            ownerUid: 'test-uid',
            title: 'Test Task 2',
            category: TaskCategory.therapy,
            createdAt: DateTime.now(),
          ),
        ];

        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => mockTasks);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => [mockTasks[0]]);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {
              'total': 2,
              'completed': 0,
              'pending': 2,
              'inProgress': 0,
              'overdue': 0,
              'dueToday': 1,
              'dueThisWeek': 2,
            });

        // Act
        await taskViewModel.refresh();

        // Assert
        expect(taskViewModel.loading, isFalse);
        expect(taskViewModel.tasks, hasLength(2));
        expect(taskViewModel.todayTasks, hasLength(1));
        expect(taskViewModel.overdueTasks, isEmpty);
        expect(taskViewModel.error, isNull);
      });

      test('should handle fetch errors', () async {
        // Arrange
        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenThrow(Exception('Network error'));
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {});

        // Act
        await taskViewModel.refresh();

        // Assert
        expect(taskViewModel.loading, isFalse);
        expect(taskViewModel.tasks, isEmpty);
        expect(taskViewModel.error, isNotNull);
        expect(taskViewModel.error, contains('Network error'));
      });
    });

    group('addTask', () {
      test('should add a new task successfully', () async {
        // Arrange
        final newTask = TaskModel(
          id: '',
          ownerUid: 'test-uid',
          title: 'New Task',
          category: TaskCategory.dailyLiving,
          createdAt: DateTime.now(),
        );

        final createdTask = newTask.copyWith(id: 'new-task-id');

        when(mockTaskService.createTask(any, any)).thenAnswer((_) async => createdTask);
        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => [createdTask]);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {
              'total': 1,
              'completed': 0,
              'pending': 1,
              'inProgress': 0,
              'overdue': 0,
              'dueToday': 0,
              'dueThisWeek': 0,
            });

        // Act
        final result = await taskViewModel.addTask(newTask);

        // Assert
        expect(result, equals(createdTask));
        verify(mockTaskService.createTask('test-uid', newTask)).called(1);
      });
    });

    group('updateTask', () {
      test('should update an existing task successfully', () async {
        // Arrange
        final task = TaskModel(
          id: 'task1',
          ownerUid: 'test-uid',
          title: 'Updated Task',
          category: TaskCategory.dailyLiving,
          createdAt: DateTime.now(),
        );

        when(mockTaskService.updateTask(any, any)).thenAnswer((_) async {});
        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => [task]);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {
              'total': 1,
              'completed': 0,
              'pending': 1,
              'inProgress': 0,
              'overdue': 0,
              'dueToday': 0,
              'dueThisWeek': 0,
            });

        // Act
        await taskViewModel.updateTask(task);

        // Assert
        verify(mockTaskService.updateTask('test-uid', task)).called(1);
      });
    });

    group('deleteTask', () {
      test('should delete a task successfully', () async {
        // Arrange
        const taskId = 'task1';

        when(mockTaskService.deleteTask(any, any)).thenAnswer((_) async {});
        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => []);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {
              'total': 0,
              'completed': 0,
              'pending': 0,
              'inProgress': 0,
              'overdue': 0,
              'dueToday': 0,
              'dueThisWeek': 0,
            });

        // Act
        await taskViewModel.deleteTask(taskId);

        // Assert
        verify(mockTaskService.deleteTask('test-uid', taskId)).called(1);
      });
    });

    group('markTaskComplete', () {
      test('should mark a task as completed', () async {
        // Arrange
        const taskId = 'task1';

        when(mockTaskService.markTaskComplete(any, any)).thenAnswer((_) async {});
        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => []);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {
              'total': 0,
              'completed': 0,
              'pending': 0,
              'inProgress': 0,
              'overdue': 0,
              'dueToday': 0,
              'dueThisWeek': 0,
            });

        // Act
        await taskViewModel.markTaskComplete(taskId);

        // Assert
        verify(mockTaskService.markTaskComplete('test-uid', taskId)).called(1);
      });
    });

    group('searchTasks', () {
      test('should search tasks successfully', () async {
        // Arrange
        const query = 'test';
        final searchResults = [
          TaskModel(
            id: 'task1',
            ownerUid: 'test-uid',
            title: 'Test Task',
            category: TaskCategory.dailyLiving,
            createdAt: DateTime.now(),
          ),
        ];

        when(mockTaskService.searchTasks(any, any)).thenAnswer((_) async => searchResults);

        // Act
        await taskViewModel.searchTasks(query);

        // Assert
        expect(taskViewModel.searchQuery, equals(query));
        expect(taskViewModel.searchResults, equals(searchResults));
        verify(mockTaskService.searchTasks('test-uid', query)).called(1);
      });

      test('should clear search when query is empty', () async {
        // Arrange
        await taskViewModel.searchTasks('previous query');

        // Act
        taskViewModel.clearSearch();

        // Assert
        expect(taskViewModel.searchQuery, isEmpty);
        expect(taskViewModel.searchResults, isEmpty);
      });
    });

    group('filterTasks', () {
      test('should filter tasks by status', () async {
        // Arrange
        const status = TaskStatus.pending;
        final filteredTasks = [
          TaskModel(
            id: 'task1',
            ownerUid: 'test-uid',
            title: 'Pending Task',
            category: TaskCategory.dailyLiving,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
        ];

        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => filteredTasks);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {
              'total': 1,
              'completed': 0,
              'pending': 1,
              'inProgress': 0,
              'overdue': 0,
              'dueToday': 0,
              'dueThisWeek': 0,
            });

        // Act
        await taskViewModel.setFilter(status: status);

        // Assert
        expect(taskViewModel.filterStatus, equals(status));
        expect(taskViewModel.tasks, equals(filteredTasks));
      });

      test('should filter tasks by category', () async {
        // Arrange
        const category = TaskCategory.therapy;
        final filteredTasks = [
          TaskModel(
            id: 'task1',
            ownerUid: 'test-uid',
            title: 'Therapy Task',
            category: TaskCategory.therapy,
            createdAt: DateTime.now(),
          ),
        ];

        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => filteredTasks);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {
              'total': 1,
              'completed': 0,
              'pending': 1,
              'inProgress': 0,
              'overdue': 0,
              'dueToday': 0,
              'dueThisWeek': 0,
            });

        // Act
        await taskViewModel.setFilter(category: category);

        // Assert
        expect(taskViewModel.filterCategory, equals(category));
        expect(taskViewModel.tasks, equals(filteredTasks));
      });

      test('should clear filters', () async {
        // Arrange
        await taskViewModel.setFilter(status: TaskStatus.pending, category: TaskCategory.therapy);

        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => []);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {
              'total': 0,
              'completed': 0,
              'pending': 0,
              'inProgress': 0,
              'overdue': 0,
              'dueToday': 0,
              'dueThisWeek': 0,
            });

        // Act
        await taskViewModel.clearFilters();

        // Assert
        expect(taskViewModel.filterStatus, isNull);
        expect(taskViewModel.filterCategory, isNull);
      });
    });

    group('statistics', () {
      test('should calculate correct task statistics', () async {
        // Arrange
        final tasks = [
          TaskModel(
            id: 'task1',
            ownerUid: 'test-uid',
            title: 'Completed Task',
            category: TaskCategory.dailyLiving,
            status: TaskStatus.completed,
            createdAt: DateTime.now(),
          ),
          TaskModel(
            id: 'task2',
            ownerUid: 'test-uid',
            title: 'Pending Task',
            category: TaskCategory.dailyLiving,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          TaskModel(
            id: 'task3',
            ownerUid: 'test-uid',
            title: 'In Progress Task',
            category: TaskCategory.dailyLiving,
            status: TaskStatus.inProgress,
            createdAt: DateTime.now(),
          ),
        ];

        // Mock the service to return the tasks
        when(mockTaskService.fetchTasks(any,
                status: anyNamed('status'), category: anyNamed('category')))
            .thenAnswer((_) async => tasks);
        when(mockTaskService.fetchTodayTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.fetchOverdueTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getRecurringTasks(any)).thenAnswer((_) async => []);
        when(mockTaskService.getTaskStatistics(any)).thenAnswer((_) async => {});
        
        await taskViewModel.refresh();

        // Assert
        expect(taskViewModel.totalTasks, equals(3));
        expect(taskViewModel.completedTasks, equals(1));
        expect(taskViewModel.pendingTasks, equals(1));
        expect(taskViewModel.inProgressTasks, equals(1));
        expect(taskViewModel.completionRate, closeTo(0.33, 0.01));
      });
    });
  });
}
