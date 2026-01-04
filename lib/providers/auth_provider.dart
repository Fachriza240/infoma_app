import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isProvider => _user?.role == 'provider';
  bool get isStudent => _user?.role == 'user';

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize - Check if user already logged in
  Future<void> initialize() async {
    try {
      _setLoading(true);

      if (_authRepository.isLoggedIn()) {
        _user = await _authRepository.getCurrentUser();
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('Error initializing auth: $e');
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String address,
    required String role,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      _user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        address: address,
        role: role,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      _user = await _authRepository.login(
        email: email,
        password: password,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authRepository.logout();
      _user = null;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('Error logout: $e');
      // Force logout even if API fails
      _user = null;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      _user = await _authRepository.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }
}
