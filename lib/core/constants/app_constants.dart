class AppConstants {
  // App Info
  static const String appName = 'InfoMA';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS Simulator
  // static const String baseUrl = 'http://192.168.1.x:8000/api'; // Real Device

  // SharedPreferences Keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Database
  static const String dbName = 'infoma_local.db';
  static const int dbVersion = 1;

  // Pagination
  static const int perPage = 10;

  // Image
  static const int maxImageSize = 2; // MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Map
  static const double defaultLatitude = -6.9147;
  static const double defaultLongitude = 107.6098; // Bandung
  static const double mapZoom = 15.0;
}
