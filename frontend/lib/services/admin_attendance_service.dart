// lib/services/admin_attendance_service.dart
// All backend communication for the admin attendance screen.
// The existing attendance_service.dart handles intern-facing endpoints — keep it.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/attendance_record.dart';

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

  // ── Set time-out (missed clock-out) ───────────────────────────────────────
  static Future<Map<String, dynamic>> setTimeOut(
    int recordId,
    DateTime timeOut,
  ) async {
    try {
      final res = await http.patch(
        Uri.parse(
            '${ApiService.baseUrl}/admin/attendance/$recordId/set-timeout'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode({'time_out': timeOut.toIso8601String()}),
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Report an issue (intern or admin) ─────────────────────────────────────
  static Future<Map<String, dynamic>> reportIssue(
    int recordId,
    String reason,
  ) async {
    try {
      final res = await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/admin/attendance/$recordId/report'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode({'reason': reason}),
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Fetch pending reports (admin inbox) ───────────────────────────────────
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

  // ── Resolve a report (admin action) ───────────────────────────────────────
  static Future<Map<String, dynamic>> resolveReport(
    int recordId, {
    String? newStatus,
    String? remark,
    DateTime? correctedTimeOut,
  }) async {
    try {
      final payload = <String, dynamic>{
        'report_status': 'resolved',
        if (newStatus != null) 'status': newStatus,
        if (remark != null && remark.isNotEmpty) 'remark': remark,
        if (correctedTimeOut != null)
          'time_out': correctedTimeOut.toIso8601String(),
      };

      final res = await http.patch(
        Uri.parse(
            '${ApiService.baseUrl}/admin/attendance/$recordId/resolve'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode(payload),
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }

  // ── Add / edit remark only ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateRemark(
    int recordId,
    String remark,
  ) async {
    try {
      final res = await http.patch(
        Uri.parse(
            '${ApiService.baseUrl}/admin/attendance/$recordId/remark'),
        headers: await ApiService.authHeaders(),
        body: jsonEncode({'remark': remark}),
      );
      return ApiService.parse(res);
    } catch (e) {
      return {'ok': false, 'error': 'Connection error'};
    }
  }
}