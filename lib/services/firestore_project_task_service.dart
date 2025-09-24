import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class FirestoreProjectTaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksCol(String projectId) =>
      _db.collection('projects').doc(projectId).collection('tasks');

  Future<List<Task>> getProjectTasks(String projectId) async {
    final q = await _tasksCol(projectId)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map(_fromDoc).toList();
  }

  Future<bool> assignTask({
    required String projectId,
    required String title,
    required String description,
    required String assignedUserId,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    required String assignedBy,
  }) async {
    try {
      await _tasksCol(projectId).add({
        'title': title,
        'description': description,
        'status': TaskStatus.pending.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'assignedTo': assignedUserId,
        'assignedBy': assignedBy,
        'tags': <String>[],
        'projectId': projectId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTaskStatus({
    required String projectId,
    required String taskId,
    required TaskStatus status,
  }) async {
    try {
      await _tasksCol(projectId).doc(taskId).update({
        'status': status.toString().split('.').last,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Task _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data();
    return Task.fromJson({
      'id': d.id,
      'title': j['title'],
      'description': j['description'],
      'status': j['status'],
      'priority': j['priority'],
      'createdAt': (j['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
      'dueDate': (j['dueDate'] as Timestamp?)?.toDate().toIso8601String(),
      'assignedTo': j['assignedTo'],
      'assignedBy': j['assignedBy'],
      'tags': List<String>.from(j['tags'] ?? const []),
      'projectId': j['projectId'] ?? '',
    });
  }
}
