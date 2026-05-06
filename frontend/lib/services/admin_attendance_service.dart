// lib/services/admin_attendance_service.dart
// All backend communication for the admin attendance screen.
// The existing attendance_service.dart handles intern-facing endpoints — keep it.

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../models/attendance_record.dart';

class AdminAttendanceService {
  // ── Fetch records ────────────────────────────────────────────────────────

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

      final res =
          await http.get(uri, headers: await ApiService.authHeaders());
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

  // ── Export URL builder ───────────────────────────────────────────────────

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
}