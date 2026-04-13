import 'dart:convert';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator uses 10.0.2.2 to reach host machine localhost
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // For multipart requests, only include Authorization (not Content-Type)
  static Future<Map<String, String>> _authHeadersForMultipart() async {
    final token = await getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword, String confirmPassword) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/profile/password'),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> uploadAvatar(XFile imageFile) async {
    try {
      var uri = Uri.parse('$baseUrl/profile/avatar');
      var request = http.MultipartRequest('POST', uri);

      // Add auth headers (without Content-Type, which http will set automatically)
      final headers = await _authHeadersForMultipart();
      request.headers.addAll(headers);

      // Read the file as raw bytes
      final bytes = await imageFile.readAsBytes();

      // Attach the image file using fromBytes
      request.files.add(http.MultipartFile.fromBytes(
        'avatar',
        bytes,
        filename: imageFile.name,
      ));

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload request timed out');
        },
      );
      
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'ok': true,
          'user': data['user'] ?? data,
        };
      } else {
        print('Upload error - Status: ${response.statusCode}, Body: ${response.body}');
        return {
          'ok': false,
          'error': 'Server error: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('Avatar upload exception: $e');
      return {
        'ok': false,
        'error': 'Failed to upload: ${e.toString()}',
      };
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Users (Admin) ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUsers({String? search}) async {
    try {
      var url = '$baseUrl/users';
      if (search != null && search.isNotEmpty) url += '?search=$search';
      final res = await http.get(Uri.parse(url), headers: await _authHeaders());
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: await _authHeaders(),
        body: jsonEncode(data), // data must use typed values (bool not string)
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Departments ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDepartments() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/departments'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createDepartment(String name) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/departments'),
        headers: await _authHeaders(),
        body: jsonEncode({'name': name}),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateDepartment(int id, String name) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/departments/$id'),
        headers: await _authHeaders(),
        body: jsonEncode({'name': name}),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> deleteDepartment(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/departments/$id'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Positions ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPositions() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/positions'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createPosition(String name) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/positions'),
        headers: await _authHeaders(),
        body: jsonEncode({'name': name}),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updatePosition(int id, String name) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/positions/$id'),
        headers: await _authHeaders(),
        body: jsonEncode({'name': name}),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> deletePosition(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/positions/$id'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Legacy getConfig wrapper (used by register/profile dropdowns) ──────────
  static Future<Map<String, dynamic>> getConfig({required String type}) async {
    if (type == 'department') return getDepartments();
    if (type == 'position')   return getPositions();
    return {'ok': false, 'error': 'Unknown type'};
  }

  static Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Config (departments / positions) ─────────────────────────────

static Future<Map<String, dynamic>> updateConfig(int id, String name) async {
  try {
    final res = await http.put(
      Uri.parse('$baseUrl/config/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name}),
    );
    return _parse(res);
  } catch (e) {
    return {'ok': false, 'error': 'Connection error'};
  }
}

static Future<Map<String, dynamic>> deleteConfig(int id) async {
  try {
    final res = await http.delete(
      Uri.parse('$baseUrl/config/$id'),
      headers: await _authHeaders(),
    );
    return _parse(res);
  } catch (e) {
    return {'ok': false, 'error': 'Connection error'};
  }
}

  // ── Activity Logs ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getActivityLogs() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/activity'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchData() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/data'));
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _parse(http.Response res) {
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    decoded['statusCode'] = res.statusCode;
    decoded['ok'] = res.statusCode >= 200 && res.statusCode < 300;
    return decoded;
  }
}