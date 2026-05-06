// lib/models/attendance_record.dart
// Admin-facing attendance record model.
// Distinct from attendance_model.dart which is used by intern-facing screens.

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminAttendanceRecord {
  final int id;
  final int userId;
  final String internName;
  final String avatarUrl;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final double? hoursRendered;
  final String status;

  const AdminAttendanceRecord({
    required this.id,
    required this.userId,
    required this.internName,
    required this.avatarUrl,
    required this.date,
    this.timeIn,
    this.timeOut,
    this.hoursRendered,
    required this.status,
  });

  // ── Deserialization ──────────────────────────────────────────────────────

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> j) {
    final rawAvatar = j['avatar_url'] as String? ?? '';
    String resolvedAvatar = rawAvatar;

    if (rawAvatar.isNotEmpty &&
        !rawAvatar.startsWith('http://') &&
        !rawAvatar.startsWith('https://')) {
      final staticBase = ApiService.baseUrl
          .replaceAll(RegExp(r'/api/?$'), '')
          .replaceAll(RegExp(r'/$'), '');
      final cleanPath =
          rawAvatar.startsWith('/') ? rawAvatar : '/$rawAvatar';
      resolvedAvatar = '$staticBase$cleanPath';
    }

    return AdminAttendanceRecord(
      id:            j['id'] as int? ?? 0,
      userId:        j['user_id'] as int? ?? 0,
      internName:    j['intern_name'] as String? ?? 'Unknown',
      avatarUrl:     resolvedAvatar,
      date:          j['date'] as String? ?? '',
      timeIn:        j['time_in'] as String?,
      timeOut:       j['time_out'] as String?,
      hoursRendered: (j['hours_rendered'] as num?)?.toDouble(),
      status:        j['status'] as String? ?? 'Absent',
    );
  }

  // ── Computed properties ──────────────────────────────────────────────────

  /// True if intern clocked in at or before 8:00 AM.
  bool get isOnTime {
    final minutes = _toMinutes(timeIn);
    if (minutes == null) return false;
    return minutes <= 8 * 60;
  }

  String get formattedHours {
    if (hoursRendered == null) return '--';
    final h = hoursRendered!.floor();
    final m = ((hoursRendered! - h) * 60).round();
    return '${h}h ${m}m';
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      return '${_pad(dt.month)}/${_pad(dt.day)}/${dt.year}';
    } catch (_) {
      return date;
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static int? _toMinutes(String? time) {
    if (time == null) return null;
    try {
      final iso = DateTime.tryParse(time);
      if (iso != null) {
        final local = iso.toLocal();
        return local.hour * 60 + local.minute;
      }
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return null;
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}