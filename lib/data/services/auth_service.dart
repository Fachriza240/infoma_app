import '../models/user_model.dart';
import 'api_service.dart';
import 'mock_auth_service.dart'; // ← TAMBAH INI
import '../../core/constants/api_endpoints.dart';

class AuthService {
  final ApiService _apiService = ApiService.instance;
  final MockAuthService _mockAuthService = MockAuthService(); // ← TAMBAH INI

  // Toggle antara Mock atau Real API
  final bool useMockApi =
      true; // ← TAMBAH INI - Set true untuk mock, false untuk real API

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String address,
    required String role,
  }) async {
    try {
      // Gunakan Mock jika enabled
      if (useMockApi) {
        return await _mockAuthService.register(
          name: name,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
          phone: phone,
          address: address,
          role: role,
        );
      }

      // Real API
      final response = await _apiService.post(
        ApiEndpoints.register,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone,
          'address': address,
          'role': role,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Gunakan Mock jika enabled
      if (useMockApi) {
        return await _mockAuthService.login(
          email: email,
          password: password,
        );
      }

      // Real API
      final response = await _apiService.post(
        ApiEndpoints.login,
        body: {
          'email': email,
          'password': password,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      if (useMockApi) {
        return await _mockAuthService.logout();
      }

      final response = await _apiService.post(ApiEndpoints.logout);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get Profile
  Future<UserModel> getProfile() async {
    try {
      if (useMockApi) {
        return await _mockAuthService.getProfile();
      }

      final response = await _apiService.get(ApiEndpoints.profile);
      return UserModel.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Update Profile (tidak perlu diubah, tetap sama)
  Future<UserModel> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.profile,
        body: {
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
        },
      );

      return UserModel.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }
}
