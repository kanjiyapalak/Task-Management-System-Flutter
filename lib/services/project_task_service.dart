import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import 'auth_service.dart';

class ProjectTaskService {
  // Use a runtime-resolved base URL (cannot be const as it depends on platform)
  static String get baseUrl => AuthService.baseUrl;
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> assignTask({
    required String projectId,
    required String title,
    required String description,
    String? assignedUserId,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
    };
    final res = await http.post(
      Uri.parse('$baseUrl/tasks/assign'),
      headers: headers,
      body: jsonEncode({
        'projectId': projectId,
        'title': title,
        'description': description,
        'assignedUserId': assignedUserId,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.toString().split('.').last,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return {'success': true, 'data': data['task']};
    return {'success': false, 'message': data['message'] ?? 'Assign failed'};
  }

  Future<List<Task>> getProjectTasks(String projectId) async {
    final headers = {
      'Content-Type': 'application/json',
      if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
    };
    final res = await http.get(
      Uri.parse('$baseUrl/tasks/project/$projectId'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = (data['tasks'] as List? ?? []);
      return list.map((j) {
        final assignedTo = j['assignedTo'];
        final assignedBy = j['assignedBy'];
        final project = j['project'];
        return Task.fromJson({
          'id': j['_id'],
          'title': j['title'],
          'description': j['description'],
          'status': j['status'],
          'priority': j['priority'],
          'createdAt': j['createdAt'],
          'dueDate': j['dueDate'],
          'assignedTo': assignedTo is Map ? (assignedTo['_id'] ?? '') : (assignedTo ?? ''),
          'assignedBy': assignedBy is Map ? (assignedBy['_id'] ?? '') : (assignedBy ?? ''),
          'tags': List<String>.from(j['tags'] ?? []),
          'projectId': project is Map ? (project['_id'] ?? '') : (project ?? ''),
        });
      }).toList();
    }
    return [];
  }

  Future<bool> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
    };
    final res = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/status'),
      headers: headers,
      body: jsonEncode({'status': status.toString().split('.').last}),
    );
    return res.statusCode == 200;
  }
}
