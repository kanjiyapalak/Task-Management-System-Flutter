import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InviteService {
  // Use a runtime-resolved base URL (cannot be const as it depends on platform)
  static String get baseUrl => AuthService.baseUrl;
  final AuthService _auth = AuthService();

  // Send invites for a project (leader only)
  Future<Map<String, dynamic>> sendInvites({
    required String projectId,
    required List<String> emails,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
    };
    final res = await http.post(
      Uri.parse('$baseUrl/invites/$projectId/send'),
      headers: headers,
      body: jsonEncode({'emails': emails}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'data': data};
    }
    return {'success': false, 'message': data['message'] ?? 'Failed to send invites'};
  }

  // List invites for a project
  Future<List<Map<String, dynamic>>> getProjectInvites(String projectId) async {
    final headers = {
      'Content-Type': 'application/json',
      if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
    };
    final res = await http.get(
      Uri.parse('$baseUrl/invites/project/$projectId'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['invites'] ?? []);
    }
    return [];
  }

  // List invites addressed to current user
  Future<List<Map<String, dynamic>>> getMyInvites() async {
    final headers = {
      'Content-Type': 'application/json',
      if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
    };
    final res = await http.get(
      Uri.parse('$baseUrl/invites/me'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['invites'] ?? []);
    }
    return [];
  }

  // Accept or decline
  Future<bool> respondToInvite({required String inviteId, required bool accept}) async {
    final headers = {
      'Content-Type': 'application/json',
      if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
    };
    final res = await http.post(
      Uri.parse('$baseUrl/invites/$inviteId/respond'),
      headers: headers,
      body: jsonEncode({'action': accept ? 'accept' : 'decline'}),
    );
    return res.statusCode == 200;
  }
}
