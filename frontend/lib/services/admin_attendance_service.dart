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
  // FIX: Removed the stray ?status=pending query param (backend ignores it,
  //      but it caused confusion). The real fix is the correct list cast below.
  static Future<Map<String, dynamic>> fetchPendingReports() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/admin/attendance/reports');
      final res = await http.get(uri, headers: await ApiService.authHeaders());

      debugPrint('🔔 RAW STATUS: ${res.statusCode}');
      debugPrint('🔔 RAW BODY: ${res.body}');

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['ok'] == true) {
        // FIX: was `res['records'] as List<AdminAttendanceRecord>` which
        //      silently throws a cast exception at runtime because the list
        //      comes back as List<dynamic>.  Cast each element individually.
        final records = (body['records'] as List<dynamic>? ?? [])
            .map((e) =>
                AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'ok': true, 'records': records};
      }
      return {'ok': false, 'error': body['error'] ?? 'Unknown error'};
    } catch (e) {
      debugPrint('🔔 fetchPendingReports error: $e');
      return {'ok': false, 'error': 'Connection error: $e'};
    }
  }

  // ── Resolve an attendance issue ────────────────────────────────────────────
  // resolution: 'set_timeout' | 'excuse' | 'mark_present' | 'adjust_timein' | 'no_action'
  // timeOut / adjustedTimeIn formatted as "HH:MM" (24-hour) — matches backend.
  static Future<Map<String, dynamic>> resolveAttendanceIssue({
    required int recordId,
    required String resolution,
    TimeOfDay? timeOut,
    TimeOfDay? adjustedTimeIn,
    TimeOfDay? creditedTimeIn,
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
      if (resolution == 'excused_credited') {
        if (creditedTimeIn != null)
          body['credited_time_in'] = _fmt(creditedTimeIn);
        if (timeOut != null) body['time_out'] = _fmt(timeOut);
      }
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/attendance/$recordId/resolve'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode(body),
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Update admin remark ────────────────────────────────────────────────────
  // FIX: was sending 'admin_note' but the backend Go struct expects 'remark'.
  //   Backend: var body struct { Remark string `json:"remark"` }
  static Future<Map<String, dynamic>> updateRemark(
    int recordId,
    String remark,
  ) async {
    try {
      final res = await http.patch(
        Uri.parse('${ApiService.baseUrl}/admin/attendance/$recordId/remark'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode({'remark': remark}), // FIX: was 'admin_note'
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }
}
