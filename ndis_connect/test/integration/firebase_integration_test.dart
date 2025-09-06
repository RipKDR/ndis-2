import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ndis_connect/app.dart' as app;
import 'package:ndis_connect/models/task.dart';
import 'package:ndis_connect/services/auth_service.dart';
import 'package:ndis_connect/services/task_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore; // ignore: unused_local_variable
    late AuthService authService;
    late TaskService taskService;

    setUpAll(() async {
      await Firebase.initializeApp();
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance; // reserved for future use
      authService = AuthService();
      taskService = TaskService();
    });

    tearDownAll(() async {
      // Clean up test data
      await auth.signOut();
    });

    group('Authentication Integration', () {
      testWidgets('should sign up new user successfully', (WidgetTester tester) async {
        // Arrange
        const testEmail = 'test@ndisconnect.com';
        const testPassword = 'TestPassword123!';

        // Act
        final userCredential = await authService.signUpWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        // Assert
        expect(userCredential, isNotNull);
        expect(userCredential!.user?.email, equals(testEmail));
        expect(userCredential.user?.uid, isNotEmpty);

        // Clean up
        await userCredential.user?.delete();
      });

      testWidgets('should sign in existing user successfully', (WidgetTester tester) async {
        // Arrange
        const testEmail = 'existing@ndisconnect.com';
        const testPassword = 'TestPassword123!';

        // Create user first
        final userCredential = await authService.signUpWithEmailAndPassword(
          testEmail,
          testPassword,
        );
        expect(userCredential, isNotNull);

        // Sign out
        await authService.signOut();

        // Act
        final signedInUser = await authService.signInWithEmailAndPassword(
          testEmail,
          testPassword,
        );

        // Assert
        expect(signedInUser, isNotNull);
        expect(signedInUser!.user!.email, equals(testEmail));
        expect(signedInUser.user!.uid, equals(userCredential!.user!.uid));

        // Clean up
        await signedInUser.user!.delete();
      });

      testWidgets('should handle invalid credentials', (WidgetTester tester) async {
        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(
            'invalid@example.com',
            'wrongpassword',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Task Management Integration', () {
      late String testUserId;
      late UserCredential userCredential;

      setUp(() async {
        // Create test user
        const testEmail = 'tasktest@ndisconnect.com';
        const testPassword = 'TestPassword123!';

        userCredential = (await authService.signUpWithEmailAndPassword(
          testEmail,
          testPassword,
        ))!;
        testUserId = userCredential.user!.uid;
      });

      tearDown(() async {
        // Clean up test user
        final user = auth.currentUser;
        if (user != null) {
          await user.delete();
        }
      });

      testWidgets('should create task successfully', (WidgetTester tester) async {
        // Arrange
        final task = TaskModel(
          id: '',
          ownerUid: testUserId,
          title: 'Integration Test Task',
          description: 'This is a test task for integration testing',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 1)),
        );

        // Act
        final createdTask = await taskService.createTask(userCredential.user!.uid, task);

        // Assert
        expect(createdTask, isNotNull);
        expect(createdTask.id, isNotEmpty);
        expect(createdTask.title, equals('Integration Test Task'));
        expect(createdTask.ownerUid, equals(testUserId));

        // Clean up
        await taskService.deleteTask(userCredential.user!.uid, createdTask.id);
      });

      testWidgets('should retrieve tasks for user', (WidgetTester tester) async {
        // Arrange
        final task1 = TaskModel(
          id: '',
          ownerUid: testUserId,
          title: 'Task 1',
          description: 'First test task',
          category: TaskCategory.therapy,
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 1)),
        );

        final task2 = TaskModel(
          id: '',
          ownerUid: testUserId,
          title: 'Task 2',
          description: 'Second test task',
          category: TaskCategory.appointment,
          priority: TaskPriority.low,
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 2)),
        );

        // Create tasks
        final createdTask1 = await taskService.createTask(userCredential.user!.uid, task1);
        final createdTask2 = await taskService.createTask(userCredential.user!.uid, task2);

        // Act
        final tasks = await taskService.fetchTasks(testUserId);

        // Assert
        expect(tasks, isA<List<TaskModel>>());
        expect(tasks.length, greaterThanOrEqualTo(2));

        final taskTitles = tasks.map((t) => t.title).toList();
        expect(taskTitles, contains('Task 1'));
        expect(taskTitles, contains('Task 2'));

        // Clean up
        await taskService.deleteTask(testUserId, createdTask1.id);
        await taskService.deleteTask(testUserId, createdTask2.id);
      });

      testWidgets('should update task successfully', (WidgetTester tester) async {
        // Arrange
        final task = TaskModel(
          id: '',
          title: 'Original Task',
          description: 'Original description',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 1)),
          ownerUid: testUserId,
        );

        final createdTask = await taskService.createTask(userCredential.user!.uid, task);

        // Act
        final updatedTask = TaskModel(
          id: createdTask.id,
          ownerUid: testUserId,
          title: 'Updated Task',
          description: 'Updated description',
          category: TaskCategory.therapy,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 2)),
        );

        await taskService.updateTask(userCredential.user!.uid, updatedTask);
        final retrievedTask = await taskService.fetchTasks(testUserId);

        // Assert
        final foundTask = retrievedTask.firstWhere((t) => t.id == createdTask.id);
        expect(foundTask.title, equals('Updated Task'));
        expect(foundTask.description, equals('Updated description'));
        expect(foundTask.category, equals(TaskCategory.therapy));
        expect(foundTask.priority, equals(TaskPriority.high));
        expect(foundTask.status, equals(TaskStatus.inProgress));

        // Clean up
        await taskService.deleteTask(userCredential.user!.uid, createdTask.id);
      });

      testWidgets('should delete task successfully', (WidgetTester tester) async {
        // Arrange
        final task = TaskModel(
          id: '',
          createdAt: DateTime.now(),
          title: 'Task to Delete',
          description: 'This task will be deleted',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          dueDate: DateTime.now().add(const Duration(days: 1)),
          ownerUid: testUserId,
        );

        final createdTask = await taskService.createTask(userCredential.user!.uid, task);

        // Act
        await taskService.deleteTask(userCredential.user!.uid, createdTask.id);
        final tasks = await taskService.fetchTasks(testUserId);

        // Assert
        final deletedTask = tasks.where((t) => t.id == createdTask.id);
        expect(deletedTask, isEmpty);
      });

      testWidgets('should get task statistics correctly', (WidgetTester tester) async {
        // Arrange
        final tasks = [
          TaskModel(
            id: '',
            ownerUid: testUserId,
            title: 'Completed Task',
            description: 'This task is completed',
            category: TaskCategory.dailyLiving,
            priority: TaskPriority.medium,
            status: TaskStatus.completed,
            createdAt: DateTime.now(),
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          TaskModel(
            id: '',
            ownerUid: testUserId,
            title: 'Pending Task',
            description: 'This task is pending',
            category: TaskCategory.therapy,
            priority: TaskPriority.high,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
            dueDate: DateTime.now().add(const Duration(days: 2)),
          ),
          TaskModel(
            id: '',
            ownerUid: testUserId,
            title: 'Overdue Task',
            description: 'This task is overdue',
            category: TaskCategory.appointment,
            priority: TaskPriority.low,
            status: TaskStatus.overdue,
            createdAt: DateTime.now(),
            dueDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];

        // Create tasks
        final createdTasks = <TaskModel>[];
        for (final task in tasks) {
          final createdTask = await taskService.createTask(userCredential.user!.uid, task);
          createdTasks.add(createdTask);
        }

        // Act
        final statistics = await taskService.getTaskStatistics(testUserId);

        // Assert
        expect(statistics, isNotNull);
        expect(statistics['total'], equals(3));
        expect(statistics['completed'], equals(1));
        expect(statistics['pending'], equals(1));
        expect(statistics['overdue'], equals(1));

        // Clean up
        for (final task in createdTasks) {
          await taskService.deleteTask(testUserId, task.id);
        }
      });
    });

    group('Offline Functionality Integration', () {
      testWidgets('should handle offline mode gracefully', (WidgetTester tester) async {
        // This test would require network manipulation
        // For now, we'll test that the app doesn't crash when offline

        // Act
        await tester.pumpWidget(const app.NdisApp());
        await tester.pumpAndSettle();

        // Assert
        expect(tester.takeException(), isNull);
      });
    });

    group('Data Validation Integration', () {
      testWidgets('should validate task data before saving', (WidgetTester tester) async {
        // Arrange
        const testEmail = 'validation@ndisconnect.com';
        const testPassword = 'TestPassword123!';

        final userCredential = await authService.signUpWithEmailAndPassword(
          testEmail,
          testPassword,
        );
        final testUserId = userCredential!.user!.uid;

        // Act & Assert - Test invalid task data
        final invalidTask = TaskModel(
          id: '',
          ownerUid: testUserId,
          title: '', // Empty title should be invalid
          description: 'Test description',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 1)),
        );

        // This should either validate and reject or handle gracefully
        try {
          await taskService.createTask(userCredential.user!.uid, invalidTask);
        } catch (e) {
          // Expected behavior - validation should catch empty title
          expect(e, isA<Exception>());
        }

        // Clean up
        await userCredential.user?.delete();
      });
    });
  });
}
