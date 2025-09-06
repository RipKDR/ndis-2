import 'package:cloud_firestore/cloud_firestore.dart';
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
  WriteBatch
])
void main() {
  group('TaskService', () {
    late TaskService taskService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late MockWriteBatch mockBatch;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockQuery = MockQuery();
      mockQuerySnapshot = MockQuerySnapshot();
      mockDocumentSnapshot = MockDocumentSnapshot();
      mockBatch = MockWriteBatch();

      taskService = TaskService();
    });

    group('fetchTasks', () {
      test('should return tasks from Firestore when online', () async {
        // Arrange
        const uid = 'test-user-id';
        final mockTaskData = {
          'id': 'task-1',
          'ownerUid': uid,
          'title': 'Test Task',
          'description': 'Test Description',
          'category': 'dailyLiving',
          'priority': 'medium',
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
          'progress': 0,
          'tags': [],
          'isRecurring': false,
          'isOfflineCreated': false,
        };

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(const GetOptions(source: Source.server)))
            .thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(mockTaskData);
        when(mockDocumentSnapshot.id).thenReturn('task-1');

        // Act
        final result = await taskService.fetchTasks(uid);

        // Assert
        expect(result, isA<List<TaskModel>>());
        expect(result.length, 1);
        expect(result.first.title, 'Test Task');
        expect(result.first.ownerUid, uid);
      });

      test('should filter tasks by status', () async {
        // Arrange
        const uid = 'test-user-id';
        const status = TaskStatus.completed;

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.where('status', isEqualTo: 'completed')).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(const GetOptions(source: Source.server)))
            .thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await taskService.fetchTasks(uid, status: status);

        // Assert
        expect(result, isA<List<TaskModel>>());
        verify(mockCollection.where('status', isEqualTo: 'completed')).called(1);
      });

      test('should filter tasks by category', () async {
        // Arrange
        const uid = 'test-user-id';
        const category = TaskCategory.therapy;

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.where('category', isEqualTo: 'therapy')).thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(const GetOptions(source: Source.server)))
            .thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await taskService.fetchTasks(uid, category: category);

        // Assert
        expect(result, isA<List<TaskModel>>());
        verify(mockCollection.where('category', isEqualTo: 'therapy')).called(1);
      });
    });

    group('createTask', () {
      test('should create a new task successfully', () async {
        // Arrange
        const uid = 'test-user-id';
        final task = TaskModel(
          id: '',
          ownerUid: uid,
          title: 'New Task',
          description: 'New Description',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.doc(any)).thenReturn(mockDocument);
        when(mockDocument.set(any)).thenAnswer((_) async {});

        // Act
        final result = await taskService.createTask(uid, task);

        // Assert
        expect(result, isA<TaskModel>());
        expect(result.title, 'New Task');
        expect(result.id, isNotEmpty);
        verify(mockDocument.set(any)).called(1);
      });
    });

    group('updateTask', () {
      test('should update an existing task', () async {
        // Arrange
        const uid = 'test-user-id';
        final task = TaskModel(
          id: 'task-1',
          ownerUid: uid,
          title: 'Updated Task',
          description: 'Updated Description',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.high,
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
          progress: 50,
        );

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.doc('task-1')).thenReturn(mockDocument);
        when(mockDocument.set(any, any)).thenAnswer((_) async {});

        // Act
        await taskService.updateTask(uid, task);

        // Assert
        verify(mockDocument.set(any, any)).called(1);
      });
    });

    group('deleteTask', () {
      test('should delete a task successfully', () async {
        // Arrange
        const uid = 'test-user-id';
        const taskId = 'task-1';

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.doc(taskId)).thenReturn(mockDocument);
        when(mockDocument.delete()).thenAnswer((_) async {});

        // Act
        await taskService.deleteTask(uid, taskId);

        // Assert
        verify(mockDocument.delete()).called(1);
      });
    });

    group('markTaskComplete', () {
      test('should mark a task as completed', () async {
        // Arrange
        const uid = 'test-user-id';
        const taskId = 'task-1';

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.doc(taskId)).thenReturn(mockDocument);
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await taskService.markTaskComplete(uid, taskId);

        // Assert
        verify(mockDocument.update(any)).called(1);
      });
    });

    group('updateTaskProgress', () {
      test('should update task progress', () async {
        // Arrange
        const uid = 'test-user-id';
        const taskId = 'task-1';
        const progress = 75;

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.doc(taskId)).thenReturn(mockDocument);
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await taskService.updateTaskProgress(uid, taskId, progress);

        // Assert
        verify(mockDocument.update(any)).called(1);
      });

      test('should mark task as completed when progress reaches 100', () async {
        // Arrange
        const uid = 'test-user-id';
        const taskId = 'task-1';
        const progress = 100;

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.doc(taskId)).thenReturn(mockDocument);
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await taskService.updateTaskProgress(uid, taskId, progress);

        // Assert
        verify(mockDocument.update(any)).called(1);
      });
    });

    group('searchTasks', () {
      test('should search tasks by title', () async {
        // Arrange
        const uid = 'test-user-id';
        const query = 'test';

        // Mock fetchTasks to return sample tasks
        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(const GetOptions(source: Source.server)))
            .thenAnswer((_) async => mockQuerySnapshot);

        final mockTaskData = {
          'id': 'task-1',
          'ownerUid': uid,
          'title': 'Test Task',
          'description': 'Test Description',
          'category': 'dailyLiving',
          'priority': 'medium',
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
          'progress': 0,
          'tags': [],
          'isRecurring': false,
          'isOfflineCreated': false,
        };

        when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
        when(mockDocumentSnapshot.data()).thenReturn(mockTaskData);
        when(mockDocumentSnapshot.id).thenReturn('task-1');

        // Act
        final result = await taskService.searchTasks(uid, query);

        // Assert
        expect(result, isA<List<TaskModel>>());
        expect(result.length, 1);
        expect(result.first.title.toLowerCase(), contains('test'));
      });
    });

    group('getTaskStatistics', () {
      test('should return correct task statistics', () async {
        // Arrange
        const uid = 'test-user-id';

        // Mock fetchTasks to return sample tasks with different statuses
        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.get(const GetOptions(source: Source.server)))
            .thenAnswer((_) async => mockQuerySnapshot);

        final mockTasksData = [
          {
            'id': 'task-1',
            'ownerUid': uid,
            'title': 'Completed Task',
            'category': 'dailyLiving',
            'priority': 'medium',
            'status': 'completed',
            'createdAt': DateTime.now().toIso8601String(),
            'progress': 100,
            'tags': [],
            'isRecurring': false,
            'isOfflineCreated': false,
          },
          {
            'id': 'task-2',
            'ownerUid': uid,
            'title': 'Pending Task',
            'category': 'therapy',
            'priority': 'high',
            'status': 'pending',
            'createdAt': DateTime.now().toIso8601String(),
            'progress': 0,
            'tags': [],
            'isRecurring': false,
            'isOfflineCreated': false,
          },
        ];

        final mockDocs = mockTasksData.map((data) {
          final mockDoc = MockDocumentSnapshot();
          when(mockDoc.data()).thenReturn(data);
          when(mockDoc.id).thenReturn(data['id'] as String);
          return mockDoc;
        }).toList();

        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // Act
        final result = await taskService.getTaskStatistics(uid);

        // Assert
        expect(result, isA<Map<String, int>>());
        expect(result['total'], 2);
        expect(result['completed'], 1);
        expect(result['pending'], 1);
        expect(result['inProgress'], 0);
      });
    });

    group('createRecurringTask', () {
      test('should create multiple recurring tasks', () async {
        // Arrange
        const uid = 'test-user-id';
        final task = TaskModel(
          id: '',
          ownerUid: uid,
          title: 'Daily Task',
          description: 'Daily Description',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          isRecurring: true,
          recurringPattern: 'daily',
        );

        when(mockFirestore.collection('tasks')).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocument);
        when(mockDocument.collection('items')).thenReturn(mockCollection);
        when(mockCollection.doc(any)).thenReturn(mockDocument);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.set(any, any)).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});

        // Act
        await taskService.createRecurringTask(uid, task);

        // Assert
        verify(mockBatch.set(any, any)).called(30); // 30 daily tasks
        verify(mockBatch.commit()).called(1);
      });
    });
  });
}
