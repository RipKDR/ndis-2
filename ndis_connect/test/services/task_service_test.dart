import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/models/task.dart';
import 'package:ndis_connect/services/task_service.dart';

import 'task_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  FirebaseAuth,
  User
])
void main() {
  group('TaskService', () {
    late TaskService taskService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockTasksCollection;
    late MockDocumentReference<Map<String, dynamic>> mockUserDoc;
    late MockCollectionReference<Map<String, dynamic>> mockItemsCollection;
    late MockDocumentReference<Map<String, dynamic>> mockItemDoc;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTasksCollection = MockCollectionReference<Map<String, dynamic>>();
      mockUserDoc = MockDocumentReference<Map<String, dynamic>>();
      mockItemsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockItemDoc = MockDocumentReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      taskService = TaskService();
    });

    group('fetchTasks', () {
      test('should fetch tasks from Firestore successfully', () async {
        // Arrange
        const uid = 'test-uid';
        final mockTasks = [
          TaskModel(
            id: 'task1',
            ownerUid: uid,
            title: 'Test Task 1',
            category: TaskCategory.dailyLiving,
            createdAt: DateTime.now(),
          ),
          TaskModel(
            id: 'task2',
            ownerUid: uid,
            title: 'Test Task 2',
            category: TaskCategory.therapy,
            createdAt: DateTime.now(),
          ),
        ];

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(any)).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);

        // Act
        final result = await taskService.fetchTasks(uid);

        // Assert
        expect(result, isA<List<TaskModel>>());
        verify(mockFirestore.collection('tasks')).called(1);
      });

      test('should filter tasks by status', () async {
        // Arrange
        const uid = 'test-uid';
        const status = TaskStatus.pending;

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.where('status', isEqualTo: status.name)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(any)).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);

        // Act
        await taskService.fetchTasks(uid, status: status);

        // Assert
        verify(mockItemsCollection.where('status', isEqualTo: status.name)).called(1);
      });

      test('should filter tasks by category', () async {
        // Arrange
        const uid = 'test-uid';
        const category = TaskCategory.therapy;

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.where('category', isEqualTo: category.name)).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(any)).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);

        // Act
        await taskService.fetchTasks(uid, category: category);

        // Assert
        verify(mockItemsCollection.where('category', isEqualTo: category.name)).called(1);
      });
    });

    group('createTask', () {
      test('should create a new task successfully', () async {
        // Arrange
        const uid = 'test-uid';
        final task = TaskModel(
          id: '',
          ownerUid: uid,
          title: 'New Task',
          category: TaskCategory.dailyLiving,
          createdAt: DateTime.now(),
        );

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.doc(any)).thenReturn(mockItemDoc);
        when(mockItemDoc.set(any)).thenAnswer((_) async {});

        // Act
        final result = await taskService.createTask(uid, task);

        // Assert
        expect(result, isA<TaskModel>());
        expect(result.title, equals('New Task'));
        verify(mockItemDoc.set(any)).called(1);
      });
    });

    group('updateTask', () {
      test('should update an existing task successfully', () async {
        // Arrange
        const uid = 'test-uid';
        final task = TaskModel(
          id: 'task1',
          ownerUid: uid,
          title: 'Updated Task',
          category: TaskCategory.dailyLiving,
          createdAt: DateTime.now(),
        );

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.doc(task.id)).thenReturn(mockItemDoc);
        when(mockItemDoc.set(any, any)).thenAnswer((_) async {});

        // Act
        await taskService.updateTask(uid, task);

        // Assert
        verify(mockItemDoc.set(any, any)).called(1);
      });
    });

    group('deleteTask', () {
      test('should delete a task successfully', () async {
        // Arrange
        const uid = 'test-uid';
        const taskId = 'task1';

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.doc(taskId)).thenReturn(mockItemDoc);
        when(mockItemDoc.delete()).thenAnswer((_) async {});

        // Act
        await taskService.deleteTask(uid, taskId);

        // Assert
        verify(mockItemDoc.delete()).called(1);
      });
    });

    group('markTaskComplete', () {
      test('should mark a task as completed', () async {
        // Arrange
        const uid = 'test-uid';
        const taskId = 'task1';

        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.doc(taskId)).thenReturn(mockItemDoc);
        when(mockItemDoc.update(any)).thenAnswer((_) async {});

        // Act
        await taskService.markTaskComplete(uid, taskId);

        // Assert
        verify(mockItemDoc.update(any)).called(1);
      });
    });

    group('searchTasks', () {
      test('should search tasks by title', () async {
        // Arrange
        const uid = 'test-uid';
        const query = 'test';

        // Mock fetchTasks to return test data
        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(any)).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);

        // Act
        final result = await taskService.searchTasks(uid, query);

        // Assert
        expect(result, isA<List<TaskModel>>());
      });
    });

    group('getTaskStatistics', () {
      test('should return correct task statistics', () async {
        // Arrange
        const uid = 'test-uid';

        // Mock fetchTasks to return test data
        when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
        when(mockTasksCollection.doc(uid)).thenReturn(mockUserDoc);
        when(mockUserDoc.collection('items')).thenReturn(mockItemsCollection);
        when(mockItemsCollection.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(any)).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);

        // Act
        final result = await taskService.getTaskStatistics(uid);

        // Assert
        expect(result, isA<Map<String, int>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('completed'), isTrue);
        expect(result.containsKey('pending'), isTrue);
        expect(result.containsKey('inProgress'), isTrue);
        expect(result.containsKey('overdue'), isTrue);
      });
    });
  });
}
