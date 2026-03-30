import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ Change this to your computer's IP if testing on a phone
  static const String baseUrl = 'http://localhost:8080/api';

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

  // ── Config (departments / positions) ──────────────────────────────────────

  static Future<Map<String, dynamic>> getConfig({required String type}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/config?type=$type'),
        headers: await _authHeaders(),
      );
      return _parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createConfig(String name, String type) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/config'),
        headers: await _authHeaders(),
        body: jsonEncode({'name': name, 'type': type}),
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

  // ── Helper ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _parse(http.Response res) {
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    decoded['statusCode'] = res.statusCode;
    decoded['ok'] = res.statusCode >= 200 && res.statusCode < 300;
    return decoded;
  }
}