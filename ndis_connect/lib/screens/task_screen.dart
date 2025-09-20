import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/error_boundary.dart';

class TaskScreen extends StatelessWidget {
  static const route = '/tasks';
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      context: 'TaskScreen',
      onRetry: () {
        // Retry will recreate the TaskViewModel
      },
      child: ChangeNotifierProvider(
        create: (_) => TaskViewModel(TaskService(), FirebaseAuth.instance),
        child: const _TaskBody(),
      ),
    );
  }
}

class _TaskBody extends StatelessWidget {
  const _TaskBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskViewModel>();
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tasks),
        actions: [
          IconButton(
            onPressed: vm.loading ? null : () => vm.refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: s.retry,
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleFilter(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Tasks')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'overdue', child: Text('Overdue')),
              const PopupMenuItem(value: 'recurring', child: Text('Recurring')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: 'Search tasks...',
              leading: const Icon(Icons.search),
              trailing: vm.searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        onPressed: () => vm.clearSearch(),
                        icon: const Icon(Icons.clear),
                      ),
                    ]
                  : null,
              onChanged: (value) => vm.searchTasks(value),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(vm.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => vm.refresh(),
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : _TaskContent(vm: vm),
    );
  }

  void _handleFilter(BuildContext context, String filter) {
    final vm = context.read<TaskViewModel>();
    switch (filter) {
      case 'all':
        vm.clearFilters();
        break;
      case 'pending':
        vm.setFilter(status: TaskStatus.pending);
        break;
      case 'in_progress':
        vm.setFilter(status: TaskStatus.inProgress);
        break;
      case 'completed':
        vm.setFilter(status: TaskStatus.completed);
        break;
      case 'overdue':
        vm.setFilter(status: TaskStatus.overdue);
        break;
      case 'recurring':
        // Show recurring tasks - this would need a special filter
        break;
    }
  }

  Future<void> _showTaskForm(BuildContext context, {TaskModel? existing}) async {
    final s = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    TaskCategory category = existing?.category ?? TaskCategory.dailyLiving;
    TaskPriority priority = existing?.priority ?? TaskPriority.medium;
    DateTime? dueDate = existing?.dueDate;
    String? reminderTime = existing?.reminderTime;
    bool isRecurring = existing?.isRecurring ?? false;
    String? recurringPattern = existing?.recurringPattern;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'New Task' : 'Edit Task',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) => category = value!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskPriority.values.map((pri) {
                    return DropdownMenuItem(
                      value: pri,
                      child: Text(pri.name),
                    );
                  }).toList(),
                  onChanged: (value) => priority = value!,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(dueDate?.toString().split(' ').first ?? 'No due date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dueDate = date;
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Recurring Task'),
                  subtitle: const Text('Create multiple instances of this task'),
                  value: isRecurring,
                  onChanged: (value) {
                    isRecurring = value;
                    if (value && recurringPattern == null) {
                      recurringPattern = 'daily';
                    }
                  },
                ),
                if (isRecurring) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: recurringPattern,
                    decoration: const InputDecoration(
                      labelText: 'Recurring Pattern',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (value) => recurringPattern = value,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (existing != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await context.read<TaskViewModel>().deleteTask(existing.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete),
                          label: Text(s.delete),
                        ),
                      ),
                    if (existing != null) const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final uid = FirebaseAuth.instance.currentUser!.uid;
                          final task = TaskModel(
                            id: existing?.id ?? '',
                            ownerUid: uid,
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                            category: category,
                            priority: priority,
                            dueDate: dueDate,
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            isRecurring: isRecurring,
                            recurringPattern: recurringPattern,
                            reminderTime: reminderTime,
                            createdAt: existing?.createdAt ?? DateTime.now(),
                          );

                          if (existing == null) {
                            if (isRecurring) {
                              await context.read<TaskViewModel>().createRecurringTask(task);
                            } else {
                              await context.read<TaskViewModel>().addTask(task);
                            }
                          } else {
                            await context.read<TaskViewModel>().updateTask(task);
                          }

                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save),
                        label: Text(s.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskContent extends StatelessWidget {
  final TaskViewModel vm;
  const _TaskContent({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TaskStats(vm: vm),
        Expanded(
          child: vm.tasks.isEmpty
              ? const Center(child: Text('No tasks found'))
              : ListView.builder(
                  itemCount: vm.tasks.length,
                  itemBuilder: (context, index) {
                    final task = vm.tasks[index];
                    return _TaskCard(task: task, vm: vm);
                  },
                ),
        ),
      ],
    );
  }
}

class _TaskStats extends StatelessWidget {
  final TaskViewModel vm;
  const _TaskStats({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total',
                  value: vm.totalTasks.toString(),
                  color: Colors.blue,
                ),
                _StatItem(
                  label: 'Completed',
                  value: vm.completedTasks.toString(),
                  color: Colors.green,
                ),
                _StatItem(
                  label: 'Pending',
                  value: vm.pendingTasks.toString(),
                  color: Colors.orange,
                ),
                _StatItem(
                  label: 'Overdue',
                  value: vm.overdueTasksCount.toString(),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: vm.completionRate,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                vm.completionRate > 0.7 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(vm.completionRate * 100).toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskViewModel vm;

  const _TaskCard({required this.task, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.status == TaskStatus.completed,
          onChanged: (value) {
            if (value == true) {
              vm.markTaskComplete(task.id);
            } else {
              vm.updateTaskProgress(task.id, 0);
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) Text(task.description!),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(task.category.name),
                  backgroundColor: _getCategoryColor(task.category).withAlpha(51),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(task.priority.name),
                  backgroundColor: _getPriorityColor(task.priority).withAlpha(51),
                ),
              ],
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Due: ${task.dueDate!.toString().split(' ').first}',
                style: TextStyle(
                  color: task.isOverdue ? Colors.red : null,
                  fontWeight: task.isOverdue ? FontWeight.bold : null,
                ),
              ),
            ],
            if (task.progress > 0 && task.progress < 100) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: task.progress / 100,
                backgroundColor: Colors.grey[300],
              ),
              Text('${task.progress}% complete'),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showTaskForm(context, existing: task),
      ),
    );
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.dailyLiving:
        return Colors.blue;
      case TaskCategory.therapy:
        return Colors.green;
      case TaskCategory.appointment:
        return Colors.purple;
      case TaskCategory.goal:
        return Colors.orange;
      case TaskCategory.medication:
        return Colors.red;
      case TaskCategory.exercise:
        return Colors.teal;
      case TaskCategory.social:
        return Colors.pink;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showTaskForm(context, existing: task);
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  vm.deleteTask(task.id);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }

  Future<void> _showTaskForm(BuildContext context, {TaskModel? existing}) async {
    // This would be the same form as in the main screen
    // For brevity, we'll just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit task functionality would open here')),
    );
  }
}
