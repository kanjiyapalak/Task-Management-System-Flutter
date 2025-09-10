import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Get current user data if authenticated
    if (_authService.isAuthenticated) {
      _currentUser = await _authService.getUserData();
      await _authService.updateLastLogin();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.registerWithEmailAndPassword(
        fullName: '$firstName $lastName',
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        _currentUser = await _authService.getUserData();
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        _currentUser = await _authService.getUserData();
        await _authService.updateLastLogin();
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': 'Password reset failed: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    String? profileImageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Firebase profile update
      await Future.delayed(const Duration(seconds: 1)); // Simulated delay

      _isLoading = false;
      notifyListeners();

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': 'Profile update failed: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement Firebase password change
      await Future.delayed(const Duration(seconds: 1)); // Simulated delay

      _isLoading = false;
      notifyListeners();

      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': 'Password change failed: $e'};
    }
  }
}
