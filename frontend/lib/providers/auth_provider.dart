import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  /// Prevent race conditions between storage restore + refresh.
  Future<void>? _refreshFuture;

  bool _isAuthInitialized = false;
  bool get isAuthInitialized => _isAuthInitialized;


  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => (_user?['role'] ?? '') == 'admin';

  AuthProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    final token = prefs.getString('token');

    final hadToken = token != null && token.isNotEmpty;
    debugPrint('🔐 Auth init: token present = $hadToken');

    if (userStr != null) {
      try {
        final decoded = jsonDecode(userStr);
        if (decoded is Map<String, dynamic>) {
          _user = _normalizeCachedUser(decoded);
          notifyListeners();
          debugPrint('📦 _loadFromStorage: restored ${_user!.keys.length} keys from cache');
        } else {
          await prefs.remove('user');
          debugPrint('📥 _loadFromStorage: cache corrupted, cleared (not a map)');
        }
      } catch (_) {
        await prefs.remove('user');
        debugPrint('💥 _loadFromStorage: cache corrupted, cleared');
      }
    }

    await validateTokenAndFetchProfile();

    _isAuthInitialized = true;
    notifyListeners();
    debugPrint('✅ Auth init finished. isLoggedIn=${isLoggedIn}');
  }


  Future<void> validateTokenAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      _user = null;
      notifyListeners();
      return;
    }

    try {
      final res = await ApiService.getProfile();


      if (res['ok'] == true) {
        _user = Map<String, dynamic>.from(res['user'] as Map? ?? {});
        _user = _normalizeCachedUser(_user!);
        await _persistUser();
        notifyListeners();
      } else {
        _user = null;
        await prefs.remove('token');
        notifyListeners();
      }
    } catch (e) {
      _user = null;
      await prefs.remove('token');
      notifyListeners();
    }
  }

  Map<String, dynamic> _normalizeCachedUser(Map<String, dynamic> input) {
    // Normalize only the high-risk fields; keep backward compatibility.
    final out = Map<String, dynamic>.from(input);

    dynamic normalizeNullableString(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return null;
        if (s.toLowerCase() == 'null') return null;
        // Common placeholder for empty dates.
        if (s.startsWith('0001-01-01')) return null;
        return s;
      }
      return v;
    }

    // Normalize known date-ish placeholders that can appear as strings.
    for (final k in [
      'locked_until',
      'updated_at',
      'created_at',
      'start_date',
      'end_date',
      'estimated_end_date',
      'last_login_at',
    ]) {
      if (out.containsKey(k)) {
        out[k] = normalizeNullableString(out[k]);
      }
    }

    // Normalize role (empty strings -> null).
    if (out.containsKey('role')) {
      out['role'] = normalizeNullableString(out['role']);
    }

    // For numeric fields that might be cached as strings, only trim; don't force defaults.
    for (final k in ['required_ojt_hours', 'failed_attempts']) {
      if (!out.containsKey(k)) continue;
      final v = out[k];
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) out[k] = null;
      }
    }

    return out;
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
        _user = _normalizeCachedUser(_user!);
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
        // NEW FLOW: Registration just validates and sends OTP.
        // No user/token yet - user is only created after OTP verification.
        // Clear any previous user state
        _user = null;
        await ApiService.clearToken();
        
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
    // Ensure deterministic final state under concurrent calls.
    if (_refreshFuture != null) return _refreshFuture!;

    _refreshFuture = () async {
      try {
        final res = await ApiService.getProfile();

        Map<String, dynamic> profile;
        if (res['id'] != null) {
          profile = res;
        } else if (res['data'] is Map && (res['data'] as Map)['id'] != null) {
          profile = Map<String, dynamic>.from(res['data'] as Map);
        } else if (res['user'] is Map && (res['user'] as Map)['id'] != null) {
          profile = Map<String, dynamic>.from(res['user'] as Map);
        } else {
          debugPrint('⚠️ refreshProfile: no id found — skipping merge.');
          return;
        }

        final cached = Map<String, dynamic>.from(_user ?? {});
        final merged = Map<String, dynamic>.from(cached);

        final overwritten = <String, Map<String, dynamic>>{};

        bool isServerValid(dynamic v) {
          if (v == null) return false;
          if (v is String) {
            final s = v.trim();
            if (s.isEmpty) return false;
            if (s.toLowerCase() == 'null') return false;
            if (s.startsWith('0001-01-01')) return false;
          }
          return true;
        }

        for (final entry in profile.entries) {
          final key = entry.key;
          final serverVal = entry.value;
          final cachedVal = merged[key];

          // Priority rules:
          // 1) Server value only when it's valid (non-null, non-empty, non-placeholder)
          // 2) Otherwise keep cached value as-is
          if (!isServerValid(serverVal)) {
            continue;
          }

          if (cachedVal != serverVal) {
            overwritten[key] = {
              'cached': cachedVal,
              'server': serverVal,
            };
          }

          merged[key] = serverVal;
        }

        _user = merged;
        await _persistUser();
        notifyListeners();

        if (overwritten.isNotEmpty) {
          final keys = overwritten.keys.take(8).toList();
          debugPrint(
              '🔄 refreshProfile: merged ${overwritten.length} updated fields (sample: $keys)');
        } else {
          debugPrint('✅ refreshProfile complete: no meaningful changes');
        }
      } catch (e, st) {
        debugPrint('⚠️ refreshProfile error: $e\n$st');
      } finally {
        _refreshFuture = null;
      }
    }();

    return _refreshFuture!;
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    _user = {...?_user, ...data};
    _user = _normalizeCachedUser(_user!);
    await _persistUser();
    notifyListeners();
  }

  Future<bool> verifyRegistrationOTP(String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.verifyRegistrationOtp(otp);

      if (res['ok'] == true) {
        // Account created and verified - save token and user
        await ApiService.saveToken(res['token']);
        _user = Map<String, dynamic>.from(res['user'] as Map? ?? {});
        _user = _normalizeCachedUser(_user!);
        await _persistUser();
        notifyListeners();

        // Fetch full profile to ensure everything is up-to-date
        await refreshProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['error'] ?? 'OTP verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

