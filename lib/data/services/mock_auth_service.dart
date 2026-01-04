import '../models/user_model.dart';
import '../local/database_helper.dart';

class MockAuthService {
  // Simulate network delay
  Future<void> _delay() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  // ✅ Generate unique ID untuk user baru
  Future<int> _generateUniqueId() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final users = await dbHelper.queryAll('users');

      if (users.isEmpty) {
        return 1; // First user
      }

      // Cari ID tertinggi + 1
      final maxId =
          users.map((u) => u['id'] as int).reduce((a, b) => a > b ? a : b);
      return maxId + 1;
    } catch (e) {
      // Fallback: pakai timestamp
      return DateTime.now().millisecondsSinceEpoch % 1000000;
    }
  }

  // Mock Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String address,
    required String role,
  }) async {
    await _delay();

    // Validate
    if (password != passwordConfirmation) {
      throw Exception('Password tidak cocok');
    }

    // ✅ Generate unique ID
    final userId = await _generateUniqueId();

    // Mock response dengan ID unik
    return {
      'user': {
        'id': userId, // ← UNIQUE ID!
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'role': role,
        'profile_picture': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Mock Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await _delay();

    // ✅ CEK DI SQLite DULU (user yang register)
    try {
      final dbHelper = DatabaseHelper.instance;
      final List<Map<String, dynamic>> users = await dbHelper.queryAll('users');

      final sqliteUser = users.where((u) => u['email'] == email).firstOrNull;

      if (sqliteUser != null) {
        print(
            '✅ User found in SQLite: ${sqliteUser['name']} (ID: ${sqliteUser['id']})');

        return {
          'user': sqliteUser, // ← Return data asli dari SQLite dengan ID asli!
          'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        };
      }
    } catch (e) {
      print('⚠️ Error checking SQLite: $e');
    }

    // ✅ Fallback: Hardcoded users dengan ID TINGGI (tidak bentrok)
    final mockUsers = {
      'mahasiswa@test.com': {
        'id': 999, // ← ID tinggi agar tidak bentrok!
        'password': 'password',
        'role': 'user',
        'name': 'Mahasiswa Test',
        'email': 'mahasiswa@test.com',
        'phone': '08123456789',
        'address': 'Alamat Test Mahasiswa',
      },
      'penyedia@test.com': {
        'id': 998, // ← ID tinggi agar tidak bentrok!
        'password': 'password',
        'role': 'provider',
        'name': 'Penyedia Test',
        'email': 'penyedia@test.com',
        'phone': '08987654321',
        'address': 'Alamat Test Penyedia',
      },
    };

    if (mockUsers.containsKey(email)) {
      final user = mockUsers[email]!;

      if (user['password'] != password) {
        throw Exception('Email atau password salah');
      }

      return {
        'user': {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'phone': user['phone'],
          'address': user['address'],
          'role': user['role'],
          'profile_picture': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    throw Exception('Email atau password salah');
  }

  // Mock Logout
  Future<Map<String, dynamic>> logout() async {
    await _delay();
    return {'message': 'Logout berhasil'};
  }

  // Mock Get Profile
  Future<UserModel> getProfile() async {
    await _delay();

    return UserModel(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      phone: '08123456789',
      address: 'Alamat Test',
      role: 'user',
    );
  }
}
