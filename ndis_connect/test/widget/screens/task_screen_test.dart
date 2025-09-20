import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/models/task.dart';
import 'package:ndis_connect/screens/task_screen.dart';
import 'package:ndis_connect/services/task_service.dart';
import 'package:ndis_connect/viewmodels/task_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../../test/utils/firebase_test_utils.dart';
import 'task_screen_test.mocks.dart';

@GenerateMocks([TaskService, FirebaseAuth, User])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskScreen Widget Tests', () {
    late MockTaskService mockTaskService;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUpAll(() async {
      // Initialize Firebase for testing
      await FirebaseTestUtils.initializeFirebaseForTesting();
    });

    setUp(() {
      mockTaskService = MockTaskService();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    tearDownAll(() async {
      await FirebaseTestUtils.cleanupTestEnvironment();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => TaskViewModel(mockTaskService, mockAuth),
            ),
          ],
          child: const TaskScreen(),
        ),
      );
    }

    testWidgets('should display task screen with app bar', (WidgetTester tester) async {
      // Arrange
      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should display search bar', (WidgetTester tester) async {
      // Arrange
      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('Search tasks...'), findsOneWidget);
    });

    testWidgets('should display floating action button', (WidgetTester tester) async {
      // Arrange
      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Task'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (WidgetTester tester) async {
      // Arrange
      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return [];
      });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Don't settle to catch loading state

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no tasks', (WidgetTester tester) async {
      // Arrange
      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No tasks found'), findsOneWidget);
    });

    testWidgets('should display tasks when available', (WidgetTester tester) async {
      // Arrange
      final mockTasks = [
        TaskModel(
          id: 'task-1',
          ownerUid: 'test-user-id',
          title: 'Test Task 1',
          description: 'Test Description 1',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        ),
        TaskModel(
          id: 'task-2',
          ownerUid: 'test-user-id',
          title: 'Test Task 2',
          description: 'Test Description 2',
          category: TaskCategory.therapy,
          priority: TaskPriority.high,
          status: TaskStatus.completed,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        ),
      ];

      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => mockTasks);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Task 1'), findsOneWidget);
      expect(find.text('Test Task 2'), findsOneWidget);
      expect(find.text('Test Description 1'), findsOneWidget);
      expect(find.text('Test Description 2'), findsOneWidget);
    });

    testWidgets('should display task statistics', (WidgetTester tester) async {
      // Arrange
      final mockTasks = [
        TaskModel(
          id: 'task-1',
          ownerUid: 'test-user-id',
          title: 'Completed Task',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.completed,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        ),
        TaskModel(
          id: 'task-2',
          ownerUid: 'test-user-id',
          title: 'Pending Task',
          category: TaskCategory.therapy,
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => mockTasks);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Task Overview'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('should open task form when FAB is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('New Task'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('should display filter menu when filter button is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('All Tasks'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Recurring'), findsOneWidget);
    });

    testWidgets('should allow task completion via checkbox', (WidgetTester tester) async {
      // Arrange
      final mockTasks = [
        TaskModel(
          id: 'task-1',
          ownerUid: 'test-user-id',
          title: 'Test Task',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => mockTasks);
      when(mockTaskService.markTaskComplete(any, any)).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Assert
      verify(mockTaskService.markTaskComplete('test-user-id', 'task-1')).called(1);
    });

    testWidgets('should display task categories and priorities', (WidgetTester tester) async {
      // Arrange
      final mockTasks = [
        TaskModel(
          id: 'task-1',
          ownerUid: 'test-user-id',
          title: 'Therapy Task',
          category: TaskCategory.therapy,
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => mockTasks);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('therapy'), findsOneWidget);
      expect(find.text('high'), findsOneWidget);
    });

    testWidgets('should display progress indicator for in-progress tasks',
        (WidgetTester tester) async {
      // Arrange
      final mockTasks = [
        TaskModel(
          id: 'task-1',
          ownerUid: 'test-user-id',
          title: 'In Progress Task',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
          progress: 50,
        ),
      ];

      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => mockTasks);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50% complete'), findsOneWidget);
    });

    testWidgets('should display due date for tasks with due dates', (WidgetTester tester) async {
      // Arrange
      final dueDate = DateTime.now().add(const Duration(days: 1));
      final mockTasks = [
        TaskModel(
          id: 'task-1',
          ownerUid: 'test-user-id',
          title: 'Task with Due Date',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          dueDate: dueDate,
        ),
      ];

      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => mockTasks);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Due:'), findsOneWidget);
    });

    testWidgets('should allow task editing via tap', (WidgetTester tester) async {
      // Arrange
      final mockTasks = [
        TaskModel(
          id: 'task-1',
          ownerUid: 'test-user-id',
          title: 'Editable Task',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => mockTasks);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editable Task'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Task'), findsOneWidget);
    });

    testWidgets('should allow task deletion via menu', (WidgetTester tester) async {
      // Arrange
      final mockTasks = [
        TaskModel(
          id: 'task-1',
          ownerUid: 'test-user-id',
          title: 'Deletable Task',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockTaskService.fetchTasks(any,
              status: anyNamed('status'), category: anyNamed('category')))
          .thenAnswer((_) async => mockTasks);
      when(mockTaskService.deleteTask(any, any)).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Delete Task'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Deletable Task"?'), findsOneWidget);
    });
  });
}
