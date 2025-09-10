import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class LocalStorageService {
  static const String _tasksKey = 'tasks_data';

  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // Save tasks to local storage
  Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      await prefs.setString(_tasksKey, jsonEncode(tasksJson));
    } catch (e) {
      print('Error saving tasks to local storage: $e');
    }
  }

  // Load tasks from local storage
  Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString(_tasksKey);

      if (tasksString != null && tasksString.isNotEmpty) {
        final tasksJson = jsonDecode(tasksString) as List;
        return tasksJson.map((taskJson) => Task.fromJson(taskJson)).toList();
      }
    } catch (e) {
      print('Error loading tasks from local storage: $e');
    }
    return [];
  }

  // Save a single task
  Future<void> saveTask(Task task) async {
    final tasks = await loadTasks();

    // Check if task already exists (update) or add new
    final existingIndex = tasks.indexWhere((t) => t.id == task.id);
    if (existingIndex != -1) {
      tasks[existingIndex] = task;
    } else {
      tasks.insert(0, task); // Add new task at the beginning
    }

    await saveTasks(tasks);
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    final tasks = await loadTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await saveTasks(tasks);
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final tasks = await loadTasks();
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);

    if (taskIndex != -1) {
      final updatedTask = Task(
        id: tasks[taskIndex].id,
        title: tasks[taskIndex].title,
        description: tasks[taskIndex].description,
        status: status,
        priority: tasks[taskIndex].priority,
        createdAt: tasks[taskIndex].createdAt,
        dueDate: tasks[taskIndex].dueDate,
        assignedTo: tasks[taskIndex].assignedTo,
        assignedBy: tasks[taskIndex].assignedBy,
        tags: tasks[taskIndex].tags,
      );

      tasks[taskIndex] = updatedTask;
      await saveTasks(tasks);
    }
  }

  // Clear all tasks
  Future<void> clearTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
  }

  // Check if we have any saved tasks
  Future<bool> hasSavedTasks() async {
    final tasks = await loadTasks();
    return tasks.isNotEmpty;
  }

  // Initialize with sample data if no tasks exist
  Future<void> initializeWithSampleData() async {
    final hasTasks = await hasSavedTasks();
    if (!hasTasks) {
      final sampleTasks = _getSampleTasks();
      await saveTasks(sampleTasks);
    }
  }

  List<Task> _getSampleTasks() {
    return [
      Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Complete Login Page Design',
        description:
            'Design and implement the user login page with proper validation',
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        assignedTo: 'user1',
        assignedBy: 'user1',
        tags: ['UI/UX', 'Frontend'],
      ),
      Task(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        title: 'Implement User Authentication',
        description: 'Set up JWT authentication system for secure user login',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        assignedTo: 'user1',
        assignedBy: 'user1',
        tags: ['Backend', 'Security'],
      ),
      Task(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        title: 'Create Dashboard Layout',
        description:
            'Design and implement the main dashboard with task overview',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        dueDate: DateTime.now().add(const Duration(days: 5)),
        assignedTo: 'user1',
        assignedBy: 'user1',
        tags: ['UI/UX', 'Dashboard'],
      ),
      Task(
        id: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
        title: 'Setup Database Schema',
        description: 'Create database tables for users, tasks, and projects',
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        dueDate: DateTime.now().subtract(const Duration(days: 4)),
        assignedTo: 'user1',
        assignedBy: 'user1',
        tags: ['Database', 'Backend'],
      ),
      Task(
        id: (DateTime.now().millisecondsSinceEpoch + 4).toString(),
        title: 'Write API Documentation',
        description: 'Document all REST API endpoints with examples',
        status: TaskStatus.pending,
        priority: TaskPriority.low,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        dueDate: DateTime.now().add(const Duration(days: 10)),
        assignedTo: 'user1',
        assignedBy: 'user1',
        tags: ['Documentation', 'API'],
      ),
    ];
  }
}
