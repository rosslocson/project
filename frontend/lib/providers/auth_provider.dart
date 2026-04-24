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
    if (userStr != null && token != null) {
      _user = jsonDecode(userStr);
      notifyListeners();
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
        _user = res['user'];
        await ApiService.saveToken(res['token']);
        await _persistUser();
        // ✅ Fetch full profile immediately after login so extended
        // fields (school, bio, skills, etc.) are available right away
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
        _user = res['user'];
        await ApiService.saveToken(res['token']);
        await _persistUser();
        // ✅ Same as login — fetch full profile after register
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
      debugPrint('🔄 refreshProfile response keys: ${res.keys.toList()}');

      if (res['id'] != null) {
        // ✅ Server data wins — spread LAST so it overwrites any stale
        // locally-cached values. This is the single source of truth.
        _user = {...?_user, ...res};
        await _persistUser();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ refreshProfile error: $e');
    }
  }

  // ✅ Kept for compatibility but now only used for non-profile data
  // (e.g. avatar_url updates). Profile fields always come via refreshProfile.
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
    await prefs.setString('user', jsonEncode(_user));
  }
}