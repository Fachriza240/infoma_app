import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../local/shared_prefs_helper.dart';
import '../local/database_helper.dart'; // ✅ UNCOMMENT

class AuthRepository {
  final AuthService _authService = AuthService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance; // ✅ UNCOMMENT

  // Register
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String address,
    required String role,
  }) async {
    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        address: address,
        role: role,
      );

      // Extract user and token from response
      final user = UserModel.fromJson(response['user']);
      final token = response['token'];

      // Save to SharedPreferences
      await _saveAuthData(user, token);

      // ✅ ENABLED - Save user to SQLite
      try {
        await _databaseHelper.insert('users', user.toDatabase());
        print('✅ User synced to SQLite: ${user.name}');
      } catch (e) {
        print('⚠️ User already exists in SQLite: $e');
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      // Extract user and token from response
      final user = UserModel.fromJson(response['user']);
      final token = response['token'];

      // Save to SharedPreferences
      await _saveAuthData(user, token);

      // ✅ ENABLED - Sync to SQLite (insert or update)
      try {
        // Cek apakah user sudah ada
        final existingUser = await _databaseHelper.queryById('users', user.id);

        if (existingUser == null) {
          // User belum ada, insert
          await _databaseHelper.insert('users', user.toDatabase());
          print('✅ User synced to SQLite: ${user.name}');
        } else {
          // User sudah ada, update
          await _databaseHelper.update('users', user.toDatabase(), user.id);
          print('✅ User updated in SQLite: ${user.name}');
        }
      } catch (e) {
        print('❌ Error syncing user to SQLite: $e');
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Call logout API
      await _authService.logout();

      // Clear SharedPreferences (tapi JANGAN clear database!)
      await SharedPrefsHelper.clearAll();

      // ⚠️ JANGAN clear database - biar data persist!
      // Data di SQLite tetap ada setelah logout
    } catch (e) {
      // Even if API call fails, clear local data
      await SharedPrefsHelper.clearAll();
      rethrow;
    }
  }

  // Get Current User
  Future<UserModel?> getCurrentUser() async {
    try {
      // Check if logged in
      if (!SharedPrefsHelper.isLoggedIn()) {
        return null;
      }

      // Try to get from SharedPreferences first
      final userData = SharedPrefsHelper.getUserData();
      if (userData != null) {
        return UserModel.fromJson(userData);
      }

      // Get from API
      final user = await _authService.getProfile();

      // Update SQLite
      try {
        await _databaseHelper.update('users', user.toDatabase(), user.id);
        print('✅ User profile updated in SQLite');
      } catch (e) {
        print('⚠️ Error updating user in SQLite: $e');
      }

      return user;
    } catch (e) {
      // If API fails, try to get from SharedPreferences
      final userData = SharedPrefsHelper.getUserData();
      if (userData != null) {
        return UserModel.fromJson(userData);
      }

      return null;
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return SharedPrefsHelper.isLoggedIn();
  }

  // Get user role
  String? getUserRole() {
    return SharedPrefsHelper.getUserRole();
  }

  // Save authentication data
  Future<void> _saveAuthData(UserModel user, String token) async {
    await SharedPrefsHelper.setToken(token);
    await SharedPrefsHelper.setUserId(user.id);
    await SharedPrefsHelper.setUserRole(user.role);
    await SharedPrefsHelper.setUserData(user.toJson());
    await SharedPrefsHelper.setLoggedIn(true);
  }
}
