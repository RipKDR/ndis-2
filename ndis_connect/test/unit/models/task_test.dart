import 'package:flutter_test/flutter_test.dart';
import 'package:ndis_connect/models/task.dart';

void main() {
  group('Task Model', () {
    test('should create task from map correctly', () {
      // Arrange
      final map = {
        'id': 'test-task-id',
        'ownerUid': 'test-user-id',
        'title': 'Test Task',
        'description': 'Test Description',
        'category': 'dailyLiving',
        'priority': 'high',
        'status': 'pending',
        'dueDate': '2024-12-31T23:59:59.000Z',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'progress': 50,
        'isRecurring': false,
        'recurringPattern': null,
        'tags': ['urgent', 'important'],
        'notes': 'Test notes',
      };

      // Act
      final task = TaskModel.fromMap(map);

      // Assert
      expect(task.id, equals('test-task-id'));
      expect(task.title, equals('Test Task'));
      expect(task.description, equals('Test Description'));
      expect(task.category, equals(TaskCategory.dailyLiving));
      expect(task.priority, equals(TaskPriority.high));
      expect(task.status, equals(TaskStatus.pending));
      expect(task.ownerUid, equals('test-user-id'));
      expect(task.progress, equals(50));
      expect(task.isRecurring, equals(false));
      expect(task.tags, equals(['urgent', 'important']));
      expect(task.notes, equals('Test notes'));
    });

    test('should convert task to map correctly', () {
      // Arrange
      final task = TaskModel(
        id: 'test-task-id',
        ownerUid: 'test-user-id',
        title: 'Test Task',
        description: 'Test Description',
        category: TaskCategory.therapy,
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        createdAt: DateTime.now(),
        dueDate: DateTime.parse('2024-12-31T23:59:59.000Z'),
        progress: 75,
        isRecurring: true,
        recurringPattern: 'weekly',
        tags: ['therapy', 'weekly'],
        notes: 'Weekly therapy session',
      );

      // Act
      final map = task.toMap();

      // Assert
      expect(map['id'], equals('test-task-id'));
      expect(map['title'], equals('Test Task'));
      expect(map['description'], equals('Test Description'));
      expect(map['category'], equals('therapy'));
      expect(map['priority'], equals('medium'));
      expect(map['status'], equals('inProgress'));
      expect(map['ownerUid'], equals('test-user-id'));
      expect(map['progress'], equals(75));
      expect(map['isRecurring'], equals(true));
      expect(map['recurringPattern'], equals('weekly'));
      expect(map['tags'], equals(['therapy', 'weekly']));
      expect(map['notes'], equals('Weekly therapy session'));
    });

    test('should handle null values correctly', () {
      // Arrange
      final map = {
        'id': 'test-task-id',
        'title': 'Test Task',
        'description': null,
        'category': 'dailyLiving',
        'priority': 'low',
        'status': 'pending',
        'dueDate': null,
        'ownerUid': 'test-user-id',
        'createdAt': null,
        'updatedAt': null,
        'progress': null,
        'isRecurring': null,
        'recurringPattern': null,
        'tags': null,
        'notes': null,
      };

      // Act
      final task = TaskModel.fromMap(map);

      // Assert
      expect(task.id, equals('test-task-id'));
      expect(task.title, equals('Test Task'));
      expect(task.description, isNull);
      expect(task.dueDate, isNull);
      expect(task.progress, equals(0));
      expect(task.isRecurring, equals(false));
      expect(task.recurringPattern, isNull);
      expect(task.tags, isEmpty);
      expect(task.notes, isNull);
    });

    test('should validate task categories', () {
      // Test all valid categories
      final categories = [
        TaskCategory.dailyLiving,
        TaskCategory.therapy,
        TaskCategory.appointment,
        TaskCategory.goal,
        TaskCategory.medication,
        TaskCategory.social,
        TaskCategory.exercise,
        TaskCategory.dailyLiving,
        TaskCategory.therapy,
      ];

      for (final category in categories) {
        final task = TaskModel(
          id: 'test-id',
          title: 'Test',
          category: category,
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          ownerUid: 'test-user',
          createdAt: DateTime.now(),
        );
        expect(task.category, equals(category));
      }
    });

    test('should validate task priorities', () {
      // Test all valid priorities
      final priorities = [
        TaskPriority.low,
        TaskPriority.medium,
        TaskPriority.high,
        TaskPriority.urgent,
      ];

      for (final priority in priorities) {
        final task = TaskModel(
          id: 'test-id',
          title: 'Test',
          category: TaskCategory.dailyLiving,
          priority: priority,
          status: TaskStatus.pending,
          ownerUid: 'test-user',
          createdAt: DateTime.now(),
        );
        expect(task.priority, equals(priority));
      }
    });

    test('should validate task statuses', () {
      // Test all valid statuses
      final statuses = [
        TaskStatus.pending,
        TaskStatus.inProgress,
        TaskStatus.completed,
        TaskStatus.overdue,
        TaskStatus.cancelled,
      ];

      for (final status in statuses) {
        final task = TaskModel(
          id: 'test-id',
          title: 'Test',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.low,
          status: status,
          ownerUid: 'test-user',
          createdAt: DateTime.now(),
        );
        expect(task.status, equals(status));
      }
    });

    test('should validate recurrence patterns', () {
      // Test all valid recurrence patterns
      final patterns = [
        'daily',
        'weekly',
        'monthly',
        'yearly',
      ];

      for (final pattern in patterns) {
        final task = TaskModel(
          id: 'test-id',
          title: 'Test',
          category: TaskCategory.dailyLiving,
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          ownerUid: 'test-user',
          createdAt: DateTime.now(),
          isRecurring: true,
          recurringPattern: pattern,
        );
        expect(task.recurringPattern, equals(pattern));
      }
    });

    test('should calculate completion percentage correctly', () {
      // Arrange
      final task = TaskModel(
        id: 'test-id',
        title: 'Test',
        category: TaskCategory.dailyLiving,
        priority: TaskPriority.low,
        status: TaskStatus.inProgress,
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        progress: 75,
      );

      // Act & Assert
      expect(task.progress, equals(75));
      expect(task.status, equals(TaskStatus.inProgress));

      // Test completed task
      final completedTask = TaskModel(
        id: 'test-id',
        title: 'Test',
        category: TaskCategory.dailyLiving,
        priority: TaskPriority.low,
        status: TaskStatus.completed,
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
        progress: 100,
      );
      expect(completedTask.status, equals(TaskStatus.completed));
    });

    test('should handle overdue tasks correctly', () {
      // Arrange
      final overdueDate = DateTime.now().subtract(const Duration(days: 1));
      final task = TaskModel(
        id: 'test-id',
        title: 'Test',
        category: TaskCategory.dailyLiving,
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        dueDate: overdueDate,
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(task.isOverdue, equals(true));
      expect(task.isOverdue, isTrue);
    });

    test('should handle future due dates correctly', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final task = TaskModel(
        id: 'test-id',
        title: 'Test',
        category: TaskCategory.dailyLiving,
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        dueDate: futureDate,
        ownerUid: 'test-user',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(task.isOverdue, equals(false));
      expect(task.isOverdue, isFalse);
      expect(task.isDueToday, isFalse);
    });
  });
}
