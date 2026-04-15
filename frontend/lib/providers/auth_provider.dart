import 'dart:convert';
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
    final token   = prefs.getString('token');
    if (userStr != null && token != null) {
      _user = jsonDecode(userStr);
      notifyListeners();
      await refreshProfile();
    }
  }

  // ── loginWithDetails: returns raw response map so LoginScreen
  //    can read locked/attempts_left fields ─────────────────────────────────

  Future<Map<String, dynamic>> loginWithDetails(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.login(email, password);
      if (res['ok'] == true) {
        _user = res['user'];
        await ApiService.saveToken(res['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
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

  // ── Kept for compatibility ───────────────────────────────────────────────

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
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
      if (res['ok'] == true) {
        _user = res;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    _user = {...?_user, ...data};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(_user));
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}