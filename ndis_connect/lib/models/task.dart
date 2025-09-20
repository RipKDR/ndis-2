enum TaskStatus { pending, inProgress, completed, overdue, cancelled }
enum TaskPriority { low, medium, high, urgent }
enum TaskCategory { dailyLiving, therapy, appointment, goal, medication, exercise, social }

class TaskModel {
  final String id;
  final String ownerUid;
  final String title;
  final String? description;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int progress; // 0-100 percentage
  final String? assignedTo; // Support worker UID
  final String? notes;
  final List<String> tags;
  final bool isRecurring;
  final String? recurringPattern; // daily, weekly, monthly
  final String? reminderTime; // HH:mm format
  final bool isOfflineCreated;

  TaskModel({
    required this.id,
    required this.ownerUid,
    required this.title,
    this.description,
    required this.category,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.progress = 0,
    this.assignedTo,
    this.notes,
    this.tags = const [],
    this.isRecurring = false,
    this.recurringPattern,
    this.reminderTime,
    this.isOfflineCreated = false,
  });

  TaskModel copyWith({
    String? id,
    String? ownerUid,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    int? progress,
    String? assignedTo,
    String? notes,
    List<String>? tags,
    bool? isRecurring,
    String? recurringPattern,
    String? reminderTime,
    bool? isOfflineCreated,
  }) {
    return TaskModel(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      reminderTime: reminderTime ?? this.reminderTime,
      isOfflineCreated: isOfflineCreated ?? this.isOfflineCreated,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    return now.year == due.year && now.month == due.month && now.day == due.day;
  }

  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return dueDate!.isAfter(weekStart.subtract(const Duration(days: 1))) &&
           dueDate!.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  String get statusDisplayName {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case TaskCategory.dailyLiving:
        return 'Daily Living';
      case TaskCategory.therapy:
        return 'Therapy';
      case TaskCategory.appointment:
        return 'Appointment';
      case TaskCategory.goal:
        return 'Goal';
      case TaskCategory.medication:
        return 'Medication';
      case TaskCategory.exercise:
        return 'Exercise';
      case TaskCategory.social:
        return 'Social';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerUid': ownerUid,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'progress': progress,
        'assignedTo': assignedTo,
        'notes': notes,
        'tags': tags,
        'isRecurring': isRecurring,
        'recurringPattern': recurringPattern,
        'reminderTime': reminderTime,
        'isOfflineCreated': isOfflineCreated,
      };

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        id: (map['id'] as String?) ?? '',
        ownerUid: (map['ownerUid'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        description: map['description'] as String?,
        category: TaskCategory.values.firstWhere(
          (e) => e.name == map['category'],
          orElse: () => TaskCategory.dailyLiving,
        ),
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == map['priority'],
          orElse: () => TaskPriority.medium,
        ),
        status: TaskStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => TaskStatus.pending,
        ),
        createdAt: map['createdAt'] != null 
            ? DateTime.parse(map['createdAt'] as String) 
            : DateTime.now(),
        dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
        completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
        progress: (map['progress'] as num?)?.toInt() ?? 0,
        assignedTo: map['assignedTo'] as String?,
        notes: map['notes'] as String?,
        tags: List<String>.from(map['tags'] ?? []),
        isRecurring: (map['isRecurring'] as bool?) ?? false,
        recurringPattern: map['recurringPattern'] as String?,
        reminderTime: map['reminderTime'] as String?,
        isOfflineCreated: (map['isOfflineCreated'] as bool?) ?? false,
      );
}
