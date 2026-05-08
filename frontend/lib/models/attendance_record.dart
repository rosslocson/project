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
  final bool isMissedClockOut;
  final bool isReported;

  // ── New fields ────────────────────────────────────────────────────────────
  final String? remark;          // Admin-written note visible in table
  final String? reportReason;    // Free-text reason submitted by intern/admin
  final String? reportStatus;    // 'pending' | 'reviewed' | 'resolved'
  final String? reportedAt;      // ISO-8601 timestamp of when report was filed

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
    this.isMissedClockOut = false,
    this.isReported = false,
    this.remark,
    this.reportReason,
    this.reportStatus,
    this.reportedAt,
  });

  // ── Deserialization ───────────────────────────────────────────────────────
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
      id:               j['id'] as int? ?? 0,
      userId:           j['user_id'] as int? ?? 0,
      internName:       j['intern_name'] as String? ?? 'Unknown',
      avatarUrl:        resolvedAvatar,
      date:             j['date'] as String? ?? '',
      timeIn:           j['time_in'] as String?,
      timeOut:          j['time_out'] as String?,
      hoursRendered:    (j['hours_rendered'] as num?)?.toDouble(),
      status:           j['status'] as String? ?? 'Absent',
      isMissedClockOut: j['is_missed_clock_out'] == true,
      isReported:       j['is_reported'] == true,
      remark:           j['remark'] as String?,
      reportReason:     j['report_reason'] as String?,
      reportStatus:     j['report_status'] as String?,
      reportedAt:       j['reported_at'] as String?,
    );
  }

  // ── Computed properties ───────────────────────────────────────────────────

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

  /// True when this record has a report that hasn't been resolved yet.
  bool get hasOpenReport =>
      isReported && reportStatus != 'resolved';

  /// True when interns can flag this record (only actionable statuses).
  bool get isReportable =>
      status == 'Late' ||
      status == 'Missed Clock Out' ||
      status == 'Absent';

  // ── Private helpers ───────────────────────────────────────────────────────
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