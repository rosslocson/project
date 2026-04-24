import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?['role'] == 'admin';

  AuthProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    final token = prefs.getString('token');

    if (userStr != null) {
      try {
        _user = jsonDecode(userStr) as Map<String, dynamic>;
        notifyListeners();
        debugPrint('📦 _loadFromStorage: restored ${_user!.keys.length} keys from cache');
        debugPrint('📦 cached keys: ${_user!.keys.toList()}');
      } catch (_) {
        await prefs.remove('user');
        debugPrint('💥 _loadFromStorage: cache corrupted, cleared');
      }
    }

    if (token != null && token.isNotEmpty) {
      await refreshProfile();
    }
  }

  Future<Map<String, dynamic>> loginWithDetails(
      String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.login(email, password);

      if (res['ok'] == true) {
        // Save token FIRST so refreshProfile() is authenticated
        await ApiService.saveToken(res['token']);

        _user = Map<String, dynamic>.from(res['user'] as Map? ?? {});
        await _persistUser();
        notifyListeners();

        // Fetch the full profile now that the token is saved
        await refreshProfile();
      } else {
        _error = res['error'] ?? 'Login failed';
      }

      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _error = 'Connection error. Is the backend running?';
      _isLoading = false;
      notifyListeners();
      return {'ok': false, 'error': _error};
    }
  }

  Future<bool> login(String email, String password) async {
    final res = await loginWithDetails(email, password);
    return res['ok'] == true;
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.register(data);

      if (res['ok'] == true) {
        await ApiService.saveToken(res['token']);
        _user = Map<String, dynamic>.from(res['user'] as Map? ?? {});
        await _persistUser();
        notifyListeners();

        await refreshProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['error'] ?? res['details'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Is the backend running?';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await ApiService.getProfile();

      // ── DIAGNOSTIC — remove these prints once the bug is confirmed fixed ─
      debugPrint('🔄 refreshProfile raw response: $res');
      debugPrint('🔄 refreshProfile keys: ${res.keys.toList()}');
      if (res['data'] != null) debugPrint('⚠️  server wraps data under "data" key');
      if (res['user'] != null) debugPrint('⚠️  server wraps data under "user" key');
      for (final k in [
        'linked_in', 'linkedin', 'git_hub', 'github',
        'bio', 'technical_skills', 'soft_skills',
        'school', 'program', 'department', 'position'
      ]) {
        if (res.containsKey(k)) debugPrint('  field "$k" = ${res[k]}');
      }
      // ─────────────────────────────────────────────────────────────────────

      // Handle backends that wrap the user in { data: {...} } or { user: {...} }
      Map<String, dynamic> profile;
      if (res['id'] != null) {
        profile = res;
      } else if (res['data'] is Map && (res['data'] as Map)['id'] != null) {
        profile = Map<String, dynamic>.from(res['data'] as Map);
        debugPrint('🔄 unwrapped profile from res["data"]');
      } else if (res['user'] is Map && (res['user'] as Map)['id'] != null) {
        profile = Map<String, dynamic>.from(res['user'] as Map);
        debugPrint('🔄 unwrapped profile from res["user"]');
      } else {
        debugPrint('⚠️ refreshProfile: no id found — skipping merge. Full response: $res');
        return;
      }

      // FIX: Only merge keys whose server value is non-null.
      // When a backend returns null for extended fields (bio, school, etc.)
      // on a fresh login response, those nulls must NOT overwrite the
      // correctly saved values in the local cache.
      final merged = Map<String, dynamic>.from(_user ?? {});
      for (final entry in profile.entries) {
        if (entry.value != null) {
          merged[entry.key] = entry.value;
        } else {
          debugPrint('  ⚠️ server null for "${entry.key}" — keeping cached value');
        }
      }

      _user = merged;
      await _persistUser();
      notifyListeners();
      debugPrint('✅ refreshProfile complete — ${_user!.keys.length} keys in user');
    } catch (e, st) {
      debugPrint('⚠️ refreshProfile error: $e\n$st');
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    _user = {...?_user, ...data};
    await _persistUser();
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _persistUser() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString('user', jsonEncode(_user));
    } catch (e) {
      debugPrint('⚠️ _persistUser encode error: $e');
    }
  }
}