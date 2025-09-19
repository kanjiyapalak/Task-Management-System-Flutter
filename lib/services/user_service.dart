import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class UserService {
  // Use a runtime-resolved base URL (cannot be const as it depends on platform)
  static String get baseUrl => AuthService.baseUrl;
  final AuthService _auth = AuthService();

  // Search user by email. Returns null if not found.
  Future<Map<String, dynamic>?> findByEmail(String email) async {
    final url = Uri.parse('$baseUrl/users?email=${Uri.encodeQueryComponent(email)}');
    final headers = {
      'Content-Type': 'application/json',
      if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
    };
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final users = (data['users'] as List? ?? []);
      if (users.isEmpty) return null;
      return users.first as Map<String, dynamic>;
    }
    return null;
  }
}
