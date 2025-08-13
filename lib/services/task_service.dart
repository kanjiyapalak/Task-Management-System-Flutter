import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../services/auth_service.dart';

class TaskService {
  static const String baseUrl =
      'http://localhost:3000/api'; // Replace with your API URL
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  // Get all tasks for current user
  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasksData = data['tasks'] as List;
        return tasksData.map((taskJson) => Task.fromJson(taskJson)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      // For demo purposes, return sample tasks
      return _getSampleTasks();
    }
  }

  // Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    final allTasks = await getTasks();
    return allTasks.where((task) => task.status == status).toList();
  }

  // Create new task
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authService.token}',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'priority': priority.toString().split('.').last,
          'dueDate': dueDate?.toIso8601String(),
          'tags': tags,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Task created successfully'};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Task creation failed',
        };
      }
    } catch (e) {
      // For demo purposes, simulate successful creation
      return {'success': true, 'message': 'Task created successfully'};
    }
  }

  // Update task status
  Future<Map<String, dynamic>> updateTaskStatus(
    String taskId,
    TaskStatus status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authService.token}',
        },
        body: jsonEncode({'status': status.toString().split('.').last}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Task status updated successfully'};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Status update failed',
        };
      }
    } catch (e) {
      // For demo purposes, simulate successful update
      return {'success': true, 'message': 'Task status updated successfully'};
    }
  }

  // Delete task
  Future<Map<String, dynamic>> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authService.token}',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Task deleted successfully'};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Task deletion failed',
        };
      }
    } catch (e) {
      // For demo purposes, simulate successful deletion
      return {'success': true, 'message': 'Task deleted successfully'};
    }
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStats() async {
    final tasks = await getTasks();
    return {
      'total': tasks.length,
      'pending': tasks
          .where((task) => task.status == TaskStatus.pending)
          .length,
      'inProgress': tasks
          .where((task) => task.status == TaskStatus.inProgress)
          .length,
      'completed': tasks
          .where((task) => task.status == TaskStatus.completed)
          .length,
      'overdue': tasks
          .where(
            (task) =>
                task.dueDate != null &&
                task.dueDate!.isBefore(DateTime.now()) &&
                task.status != TaskStatus.completed,
          )
          .length,
    };
  }

  // Sample tasks for demo
  List<Task> _getSampleTasks() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return [];

    return [
      Task(
        id: '1',
        title: 'Complete Login Page Design',
        description:
            'Design and implement the user login page with proper validation',
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        assignedTo: currentUser.id,
        assignedBy: currentUser.id,
        tags: ['UI/UX', 'Frontend'],
      ),
      Task(
        id: '2',
        title: 'Implement User Authentication',
        description: 'Set up JWT authentication system for secure user login',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        assignedTo: currentUser.id,
        assignedBy: currentUser.id,
        tags: ['Backend', 'Security'],
      ),
      Task(
        id: '3',
        title: 'Create Dashboard Layout',
        description:
            'Design and implement the main dashboard with task overview',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        dueDate: DateTime.now().add(const Duration(days: 5)),
        assignedTo: currentUser.id,
        assignedBy: currentUser.id,
        tags: ['UI/UX', 'Dashboard'],
      ),
      Task(
        id: '4',
        title: 'Setup Database Schema',
        description: 'Create database tables for users, tasks, and projects',
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        dueDate: DateTime.now().subtract(const Duration(days: 4)),
        assignedTo: currentUser.id,
        assignedBy: currentUser.id,
        tags: ['Database', 'Backend'],
      ),
      Task(
        id: '5',
        title: 'Write API Documentation',
        description: 'Document all REST API endpoints with examples',
        status: TaskStatus.pending,
        priority: TaskPriority.low,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        dueDate: DateTime.now().add(const Duration(days: 10)),
        assignedTo: currentUser.id,
        assignedBy: currentUser.id,
        tags: ['Documentation', 'API'],
      ),
    ];
  }
}
