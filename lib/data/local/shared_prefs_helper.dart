import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPrefsHelper {
  static SharedPreferences? _prefs;

  // Initialize
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth Token
  static Future<bool> setToken(String token) async {
    return await _prefs!.setString('auth_token', token);
  }

  static String? getToken() {
    return _prefs!.getString('auth_token');
  }

  static Future<bool> removeToken() async {
    return await _prefs!.remove('auth_token');
  }

  // User ID
  static Future<bool> setUserId(int userId) async {
    return await _prefs!.setInt('user_id', userId);
  }

  static int? getUserId() {
    return _prefs!.getInt('user_id');
  }

  // User Role
  static Future<bool> setUserRole(String role) async {
    return await _prefs!.setString('user_role', role);
  }

  static String? getUserRole() {
    return _prefs!.getString('user_role');
  }

  // User Data (JSON)
  static Future<bool> setUserData(Map<String, dynamic> userData) async {
    String userJson = jsonEncode(userData);
    return await _prefs!.setString('user_data', userJson);
  }

  static Map<String, dynamic>? getUserData() {
    String? userJson = _prefs!.getString('user_data');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Login Status
  static Future<bool> setLoggedIn(bool isLoggedIn) async {
    return await _prefs!.setBool('is_logged_in', isLoggedIn);
  }

  static bool isLoggedIn() {
    return _prefs!.getBool('is_logged_in') ?? false;
  }

  // Clear All Data (Logout)
  static Future<bool> clearAll() async {
    return await _prefs!.clear();
  }

  // First Time Launch
  static Future<bool> setFirstTimeLaunch(bool isFirstTime) async {
    return await _prefs!.setBool('first_time_launch', isFirstTime);
  }

  static bool isFirstTimeLaunch() {
    return _prefs!.getBool('first_time_launch') ?? true;
  }
}
