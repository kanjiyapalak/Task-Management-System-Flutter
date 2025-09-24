import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'firebase_auth_service.dart';

class FirebaseTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Singleton pattern
  static final FirebaseTaskService _instance = FirebaseTaskService._internal();
  factory FirebaseTaskService() => _instance;
  FirebaseTaskService._internal();

  // Get tasks collection reference for current user
  CollectionReference get _tasksCollection {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // Get all tasks for current user
  Future<List<Task>> getTasks() async {
    try {
      final snapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Task.fromJson({
          'id': doc.id,
          ...data,
          // Convert Firestore Timestamps to DateTime
          'createdAt': (data['createdAt'] as Timestamp?)
              ?.toDate()
              .toIso8601String(),
          'dueDate': (data['dueDate'] as Timestamp?)
              ?.toDate()
              .toIso8601String(),
        });
      }).toList();
    } catch (e) {
  debugPrint('Error getting tasks: $e');
      return [];
    }
  }

  // Get tasks stream for real-time updates
  Stream<List<Task>> getTasksStream() {
    try {
      return _tasksCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Task.fromJson({
                'id': doc.id,
                ...data,
                'createdAt': (data['createdAt'] as Timestamp?)
                    ?.toDate()
                    .toIso8601String(),
                'dueDate': (data['dueDate'] as Timestamp?)
                    ?.toDate()
                    .toIso8601String(),
              });
            }).toList();
          });
    } catch (e) {
  debugPrint('Error getting tasks stream: $e');
      return Stream.value([]);
    }
  }

  // Create new task
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? dueDate,
    List<String> tags = const [],
    String? projectId,
  }) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final taskData = {
        'title': title,
        'description': description,
        'status': TaskStatus.pending.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'assignedTo': userId,
        'assignedBy': userId,
        'tags': tags,
        'projectId': projectId,
      };

      final docRef = await _tasksCollection.add(taskData);

      return {
        'success': true,
        'message': 'Task created successfully',
        'taskId': docRef.id,
      };
    } catch (e) {
  debugPrint('Error creating task: $e');
      return {'success': false, 'message': 'Failed to create task: $e'};
    }
  }

  // Update task
  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _tasksCollection.doc(taskId).update(updates);
      return {'success': true, 'message': 'Task updated successfully'};
    } catch (e) {
  debugPrint('Error updating task: $e');
      return {'success': false, 'message': 'Failed to update task: $e'};
    }
  }

  // Update task status
  Future<Map<String, dynamic>> updateTaskStatus(
    String taskId,
    TaskStatus status,
  ) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'status': status.toString().split('.').last,
      });
      return {'success': true, 'message': 'Task status updated successfully'};
    } catch (e) {
  debugPrint('Error updating task status: $e');
      return {'success': false, 'message': 'Failed to update task status: $e'};
    }
  }

  // Delete task
  Future<Map<String, dynamic>> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
      return {'success': true, 'message': 'Task deleted successfully'};
    } catch (e) {
  debugPrint('Error deleting task: $e');
      return {'success': false, 'message': 'Failed to delete task: $e'};
    }
  }

  // Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final doc = await _tasksCollection.doc(taskId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Task.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)
              ?.toDate()
              .toIso8601String(),
          'dueDate': (data['dueDate'] as Timestamp?)
              ?.toDate()
              .toIso8601String(),
        });
      }
    } catch (e) {
  debugPrint('Error getting task by ID: $e');
    }
    return null;
  }

  // Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      final snapshot = await _tasksCollection
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Task.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)
              ?.toDate()
              .toIso8601String(),
          'dueDate': (data['dueDate'] as Timestamp?)
              ?.toDate()
              .toIso8601String(),
        });
      }).toList();
    } catch (e) {
  debugPrint('Error getting tasks by status: $e');
      return [];
    }
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStats() async {
    try {
      final tasks = await getTasks();
      final now = DateTime.now();

      return {
        'total': tasks.length,
        'pending': tasks.where((t) => t.status == TaskStatus.pending).length,
        'inProgress': tasks
            .where((t) => t.status == TaskStatus.inProgress)
            .length,
        'completed': tasks
            .where((t) => t.status == TaskStatus.completed)
            .length,
        'overdue': tasks
            .where(
              (t) =>
                  t.dueDate != null &&
                  t.dueDate!.isBefore(now) &&
                  t.status != TaskStatus.completed,
            )
            .length,
      };
    } catch (e) {
  debugPrint('Error getting task stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'inProgress': 0,
        'completed': 0,
        'overdue': 0,
      };
    }
  }
}
