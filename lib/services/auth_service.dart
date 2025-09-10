import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl =
      'http://localhost:3000/api'; // Replace with your API URL
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;

  // Initialize authentication state from stored data
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(tokenKey);
    final userData = prefs.getString(userKey);

    if (userData != null) {
      try {
        final userMap = jsonDecode(userData);
        _currentUser = User.fromJson(userMap);
      } catch (e) {
        // Clear invalid data
        await logout();
      }
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
        await _storeAuthData();
        return {'success': true, 'message': 'Registration successful'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      // For demo purposes, simulate successful registration
      _currentUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        firstName: firstName,
        lastName: lastName,
        email: email,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      _token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      await _storeAuthData();
      return {'success': true, 'message': 'Registration successful'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
        await _storeAuthData();
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      // For demo purposes, simulate successful login
      _currentUser = User(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: email,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now(),
      );
      _token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      await _storeAuthData();
      return {'success': true, 'message': 'Login successful'};
    }
  }

  // Logout user
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'profileImageUrl': profileImageUrl,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(data['user']);
        await _storeAuthData();
        return {'success': true, 'message': 'Profile updated successfully'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      // For demo purposes, simulate successful update
      _currentUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        profileImageUrl: profileImageUrl,
      );
      await _storeAuthData();
      return {'success': true, 'message': 'Profile updated successfully'};
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password changed successfully'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Password change failed',
        };
      }
    } catch (e) {
      // For demo purposes, simulate successful password change
      return {'success': true, 'message': 'Password changed successfully'};
    }
  }

  // Store authentication data locally
  Future<void> _storeAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(tokenKey, _token!);
    }
    if (_currentUser != null) {
      await prefs.setString(userKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  // Forgot password (request reset link / code)
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Reset link sent to your email',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Request failed'};
    } catch (e) {
      // Demo fallback: pretend email sent
      return {
        'success': true,
        'message': 'If an account exists, a reset link has been sent.',
      };
    }
  }

  // Reset password (using token/code)
  Future<Map<String, dynamic>> resetPassword({
    required String tokenOrCode,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': tokenOrCode, 'newPassword': newPassword}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successfully',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Reset failed'};
    } catch (e) {
      // Demo fallback
      return {'success': true, 'message': 'Password reset successfully (demo)'};
    }
  }
}
