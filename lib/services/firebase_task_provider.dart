import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/firebase_task_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseTaskService _taskService = FirebaseTaskService();
  List<Task> _tasks = [];
  bool _loading = false;
  Map<String, int> _stats = {};

  List<Task> get tasks => _tasks;
  bool get isLoading => _loading;
  Map<String, int> get stats => _stats;

  void _recomputeStats() {
    final now = DateTime.now();
    _stats = {
      'total': _tasks.length,
      'pending': _tasks.where((t) => t.status == TaskStatus.pending).length,
      'inProgress': _tasks
          .where((t) => t.status == TaskStatus.inProgress)
          .length,
      'completed': _tasks.where((t) => t.status == TaskStatus.completed).length,
      'overdue': _tasks
          .where(
            (t) =>
                t.dueDate != null &&
                t.dueDate!.isBefore(now) &&
                t.status != TaskStatus.completed,
          )
          .length,
    };
  }

  Future<void> loadTasks({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    try {
      _tasks = await _taskService.getTasks();
      _recomputeStats();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Listen to real-time task updates
  void startListening() {
    _taskService.getTasksStream().listen(
      (tasks) {
        _tasks = tasks;
        _recomputeStats();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error in task stream: $error');
      },
    );
  }

  Future<bool> updateStatus(String id, TaskStatus status) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return false;

    final prev = _tasks[idx];
    _tasks[idx] = prev.copyWith(status: status);
    _recomputeStats();
    notifyListeners(); // optimistic update

    try {
      final result = await _taskService.updateTaskStatus(id, status);
      if (result['success'] != true) {
        // Revert on failure
        _tasks[idx] = prev;
        _recomputeStats();
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      // Revert on error
      _tasks[idx] = prev;
      _recomputeStats();
      notifyListeners();
  debugPrint('Error updating task status: $e');
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return false;

    final removed = _tasks[idx];
    _tasks.removeAt(idx);
    _recomputeStats();
    notifyListeners(); // optimistic update

    try {
      final result = await _taskService.deleteTask(id);
      if (result['success'] != true) {
        // Revert on failure
        _tasks.insert(idx, removed);
        _recomputeStats();
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      // Revert on error
      _tasks.insert(idx, removed);
      _recomputeStats();
      notifyListeners();
  debugPrint('Error deleting task: $e');
      return false;
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? dueDate,
    List<String> tags = const [],
    String? projectId,
  }) async {
    try {
      final result = await _taskService.createTask(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        tags: tags,
        projectId: projectId,
      );

      if (result['success'] == true) {
        // Task will be automatically added through the real-time listener
        // or we can manually add it for immediate feedback
        final newTask = Task(
          id:
              result['taskId'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: description,
          status: TaskStatus.pending,
          priority: priority,
          createdAt: DateTime.now(),
          dueDate: dueDate,
          tags: tags,
          assignedTo: 'self',
          assignedBy: 'self',
          projectId: projectId,
        );

        _tasks.insert(0, newTask);
        _recomputeStats();
        notifyListeners();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating task: $e');
      return false;
    }
  }

  Task? getById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshStats() async {
    try {
      _stats = await _taskService.getTaskStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing stats: $e');
    }
  }
}
