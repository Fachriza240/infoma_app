import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/local/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Load user from SQLite by ID
  Future<void> loadUser(int userId) async {
    try {
      _setLoading(true);
      _setError(null);

      // ✅ LOAD DARI SQLite DULU
      final map = await _dbHelper.queryById('users', userId);

      if (map != null) {
        // User ada di database
        _currentUser = UserModel.fromDatabase(map);
        print('✅ User loaded from SQLite: ${_currentUser!.name}');
      } else {
        // User belum ada di SQLite, buat default lalu save
        print('⚠️ User not found in SQLite, creating default...');

        // Get data dari SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userDataJson = prefs.getString('user_data');

        if (userDataJson != null) {
          final userData = jsonDecode(userDataJson);
          _currentUser = UserModel.fromJson(userData);

          // Save ke SQLite
          await _dbHelper.insert('users', _currentUser!.toDatabase());
          print('✅ User saved to SQLite: ${_currentUser!.name}');
        } else {
          // Fallback ke default user (seharusnya tidak terjadi)
          _currentUser = UserModel(
            id: userId,
            name: 'User',
            email: 'user@test.com',
            phone: '08123456789',
            address: 'Belum diisi',
            role: 'user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _dbHelper.insert('users', _currentUser!.toDatabase());
        }
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error loading user: $e');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String address,
    String? profilePicture,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_currentUser == null) {
        throw Exception('User not loaded');
      }

      final updatedUser = UserModel(
        id: _currentUser!.id,
        name: name,
        email: _currentUser!.email, // Email tidak bisa diubah
        phone: phone,
        address: address,
        profilePicture: profilePicture,
        role: _currentUser!.role,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update di SQLite
      await _dbHelper.update(
          'users', updatedUser.toDatabase(), _currentUser!.id);

      // Update local state
      _currentUser = updatedUser;

      _setLoading(false);
      print('✅ Profile updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  /// Clear user (saat logout)
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
