// lib/services/attendance_service.dart
//
// Drop-in companion to your existing ApiService.
// Handles all attendance-related API calls.

import 'package:http/http.dart' as http;
import 'api_service.dart';           // your existing file
import '../models/attendance_model.dart';

class AttendanceService {
  // ── Time In ────────────────────────────────────────────────────────────────

  /// POST /api/attendance/time-in
  /// Creates a new attendance record for today with time_in = NOW().
  static Future<Map<String, dynamic>> timeIn() async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/attendance/time-in'),
        headers: await ApiService.authHeaders(),
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Time Out ───────────────────────────────────────────────────────────────

  /// PATCH /api/attendance/time-out
  /// Updates today's record with time_out = NOW().
  static Future<Map<String, dynamic>> timeOut() async {
    try {
      final res = await http.patch(
        Uri.parse('${ApiService.baseUrl}/attendance/time-out'),
        headers: await ApiService.authHeaders(),
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Summary ────────────────────────────────────────────────────────────────

  /// GET /api/attendance/summary
  /// Returns total hours, required hours, today's record.
  static Future<AttendanceSummary?> getSummary() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/attendance/summary'),
        headers: await ApiService.authHeaders(),
      );
      final data = ApiService.parse(res);
      if (data['ok'] == true) {
        return AttendanceSummary.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── History ────────────────────────────────────────────────────────────────

  /// GET /api/attendance/history?page=1&limit=20
  /// Returns a paginated list of the user's attendance records.
  static Future<List<AttendanceRecord>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/attendance/history?page=$page&limit=$limit'),
        headers: await ApiService.authHeaders(),
      );
      final data = ApiService.parse(res);
      if (data['ok'] == true && data['records'] is List) {
        return (data['records'] as List)
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}