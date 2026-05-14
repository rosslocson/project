// lib/services/admin_attendance_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/attendance_record.dart';
import 'package:flutter/material.dart';

class AdminAttendanceService {
  // ── Fetch records ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchAttendance({
    String? date,
    String? dateFrom,
    String? dateTo,
    String? period,
    bool allDates = false,
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
    int? userId,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (allDates)
          'all_dates': 'true'
        else if (period != null)
          'period': period
        else if (dateFrom != null && dateTo != null) ...<String, String>{
          'date_from': dateFrom,
          'date_to': dateTo,
        } else if (date != null)
          'date': date,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'All') 'status': status,
        if (userId != null) 'user_id': '$userId',
      };

      final uri = Uri.parse('${ApiService.baseUrl}/admin/attendance')
          .replace(queryParameters: params);
      final res = await http.get(uri, headers: await ApiService.authHeaders());
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['ok'] == true) {
        final records = (body['records'] as List? ?? [])
            .map((e) =>
                AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'ok': true,
          'records': records,
          'total': body['total'] as int? ?? 0,
        };
      }
      return {'ok': false, 'error': body['error'] ?? 'Unknown error'};
    } catch (e) {
      return {'ok': false, 'error': 'Connection error: $e'};
    }
  }

  // ── Export URL builder ─────────────────────────────────────────────────────
  static String exportUrl({
    String? date,
    String? dateFrom,
    String? dateTo,
    String? period,
    bool allDates = false,
    String? search,
    String? status,
  }) {
    final params = <String, String>{
      if (allDates)
        'all_dates': 'true'
      else if (period != null)
        'period': period
      else if (dateFrom != null && dateTo != null) ...<String, String>{
        'date_from': dateFrom,
        'date_to': dateTo,
      } else if (date != null)
        'date': date,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != 'All') 'status': status,
    };
    return Uri.parse('${ApiService.baseUrl}/admin/attendance/export')
        .replace(queryParameters: params)
        .toString();
  }

  // ── Fetch pending reports ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchPendingReports() async {
    try {
      final uri = Uri.parse(
          '${ApiService.baseUrl}/admin/attendance/reports?status=pending');
      final res = await http.get(uri, headers: await ApiService.authHeaders());
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['ok'] == true) {
        final records = (body['records'] as List? ?? [])
            .map((e) =>
                AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'ok': true, 'records': records};
      }
      return {'ok': false, 'error': body['error'] ?? 'Unknown error'};
    } catch (e) {
      return {'ok': false, 'error': 'Connection error: $e'};
    }
  }

  // ── Resolve an attendance issue (the ONE resolve method) ──────────────────
  // resolution: 'set_timeout' | 'excuse' | 'mark_present' | 'adjust_timein' | 'no_action'
  // timeOut / adjustedTimeIn formatted as "HH:MM" (24-hour) — matches backend.
  static Future<Map<String, dynamic>> resolveAttendanceIssue({
    required int recordId,
    required String resolution,
    TimeOfDay? timeOut,
    TimeOfDay? adjustedTimeIn,
    String? note,
  }) async {
    try {
      final body = <String, dynamic>{
        'resolution': resolution,
        if (note != null && note.isNotEmpty) 'note': note,
        if (timeOut != null)
          'time_out':
              '${timeOut.hour.toString().padLeft(2, '0')}:${timeOut.minute.toString().padLeft(2, '0')}',
        if (adjustedTimeIn != null)
          'adjusted_time_in':
              '${adjustedTimeIn.hour.toString().padLeft(2, '0')}:${adjustedTimeIn.minute.toString().padLeft(2, '0')}',
      };

      final res = await http.post(
        // ← POST, not PATCH
        Uri.parse('${ApiService.baseUrl}/admin/attendance/$recordId/resolve'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode(body),
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

// Add this back to AdminAttendanceService
  static Future<Map<String, dynamic>> updateRemark(
    int recordId,
    String remark,
  ) async {
    try {
      final res = await http.patch(
        Uri.parse('${ApiService.baseUrl}/admin/attendance/$recordId/remark'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode({
          'admin_note': remark
        }), // ← was 'remark', must match backend column
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }
}
