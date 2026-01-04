import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../local/shared_prefs_helper.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  // Base Headers
  Map<String, String> get _headers {
    final token = SharedPrefsHelper.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET Request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      print('📡 GET: $url');

      final response = await http.get(url, headers: _headers);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // POST Request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      print('📡 POST: $url');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // PUT Request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      print('📡 PUT: $url');

      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // DELETE Request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      print('📡 DELETE: $url');

      final response = await http.delete(url, headers: _headers);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Handle Response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      // Success
      return body;
    } else if (statusCode == 401) {
      // Unauthorized - Token expired
      throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
    } else if (statusCode == 404) {
      // Not Found
      throw Exception('Data tidak ditemukan');
    } else if (statusCode == 422) {
      // Validation Error
      final errors = body['errors'] as Map<String, dynamic>?;
      if (errors != null) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first);
        }
      }
      throw Exception(body['message'] ?? 'Validasi gagal');
    } else if (statusCode >= 500) {
      // Server Error
      throw Exception('Terjadi kesalahan pada server');
    } else {
      // Other errors
      throw Exception(body['message'] ?? 'Terjadi kesalahan');
    }
  }

  // Upload File (untuk foto profil, dokumen, dll)
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      print('📡 UPLOAD: $url');

      final request = http.MultipartRequest('POST', url);

      // Add headers
      final token = SharedPrefsHelper.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } catch (e) {
      throw Exception('Error upload file: $e');
    }
  }
}
