// lib/services/attendance_service.dart
//
// Drop-in companion to your existing ApiService.
// Handles all attendance-related API calls.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // your existing file
import '../models/attendance_model.dart';
import 'dart:convert';

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
      debugPrint('📡 getHistory status: ${res.statusCode}');
      debugPrint('📡 getHistory body: ${res.body}');
      debugPrint(
          '📡 getHistory ok=${data['ok']}  records is List=${data['records'] is List}');

      if (data['ok'] == true && data['records'] is List) {
        return (data['records'] as List)
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e, st) {
      debugPrint('❌ getHistory error: $e');
      debugPrint('❌ getHistory stacktrace: $st');
      return [];
    }
  }

  // ── NEW: unified report endpoint ──────────────────────────────────────────

  /// Reports an attendance issue for any status:
  ///   reportType: 'late' | 'absent' | 'missed_clock_out'
  ///   date:       'YYYY-MM-DD'
  ///   reason:     free-text (required, 5–500 chars)
  ///
  /// For 'absent' the backend upserts the attendance row automatically.
  /// For 'late' and 'missed_clock_out' an existing row is required.
  static Future<Map<String, dynamic>> reportAttendanceIssue({
    required String date,
    required String reportType,
    required String reason,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/attendance/report'),
        headers: {
          ...await ApiService.authHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': date,
          'report_type': reportType,
          'reason': reason,
        }),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  /// Legacy shim — keeps existing callers working.
  static Future<Map<String, dynamic>> reportMissedClockOut(
    String recordId, {
    String reason = 'Forgot to clock out',
  }) async {
    // The old endpoint is still available on the backend; we just call it.
    try {
      final res = await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/attendance/$recordId/report-missed-clockout'),
        headers: {
          ...await ApiService.authHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }
}
