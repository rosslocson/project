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
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parse(res);
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _authHeaders(),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> changePassword(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile/password'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard/stats'),
      headers: await _authHeaders(),
    );
    return _parse(res);
  }

  // ── Users (Admin) ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUsers({String? search}) async {
    var url = '$baseUrl/users';
    if (search != null && search.isNotEmpty) url += '?search=$search';
    final res = await http.get(Uri.parse(url), headers: await _authHeaders());
    return _parse(res);
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> deleteUser(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _authHeaders(),
    );
    return _parse(res);
  }

  // ── Activity Logs ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getActivityLogs() async {
    final res = await http.get(
      Uri.parse('$baseUrl/activity'),
      headers: await _authHeaders(),
    );
    return _parse(res);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _parse(http.Response res) {
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    decoded['statusCode'] = res.statusCode;
    decoded['ok'] = res.statusCode >= 200 && res.statusCode < 300;
    return decoded;
  }
}