// lib/models/attendance_model.dart

import 'package:flutter/material.dart';

class AttendanceRecord {
  final int id;
  final int userId;
  final DateTime date;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final double? hoursRendered;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.timeIn,
    this.timeOut,
    this.hoursRendered,
  });

  bool get hasTimedIn => timeIn != null;
  bool get hasTimedOut => timeOut != null;
  bool get isComplete => hasTimedIn && hasTimedOut;

  /// Capped + lunch-deducted duration (mirrors backend computeHours logic).
  Duration? get duration {
debugPrint('⏱ duration: timeIn=$timeIn  timeOut=$timeOut');

    if (timeIn == null || timeOut == null) return null;

    // Ensure we work in local time for wall-clock comparisons.
    final tIn = timeIn!.toLocal();
    final tOut = timeOut!.toLocal();
   
    final cap = DateTime(tIn.year, tIn.month, tIn.day, 17, 0); // 5:00 PM local

    final effectiveOut = tOut.isAfter(cap) ? cap : tOut;
    if (!effectiveOut.isAfter(tIn)) return Duration.zero;

    Duration elapsed = effectiveOut.difference(tIn);

    // Lunch window: 12:00–13:00 local
    final lunchStart = DateTime(tIn.year, tIn.month, tIn.day, 12, 0);
    final lunchEnd = DateTime(tIn.year, tIn.month, tIn.day, 13, 0);

    final overlapStart = tIn.isAfter(lunchStart) ? tIn : lunchStart;
    final overlapEnd =
        effectiveOut.isBefore(lunchEnd) ? effectiveOut : lunchEnd;

    if (overlapEnd.isAfter(overlapStart)) {
      elapsed -= overlapEnd.difference(overlapStart);
    }

    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Convenience: hours as a double (for progress bars, etc.)
  double? get hoursWorked {
    final d = duration;
    if (d == null) return null;
    return d.inSeconds / 3600.0;
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    debugPrint('📋 AttendanceRecord.fromJson: time_in=${json['time_in']}  time_out=${json['time_out']}  hours_rendered=${json['hours_rendered']}  date=${json['date']}');

    return AttendanceRecord(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      date: DateTime.parse(json['date'] as String),

      // Backend returns formatted strings like "08:30 AM" or full ISO strings.
      // _parseTime handles both gracefully.
      timeIn: _parseTime(json['time_in'], json['date'] as String?),
      timeOut: _parseTime(json['time_out'], json['date'] as String?),

      // Backend now computes this in Go; keep reading it in case a future
      // endpoint provides it, but fall back to null — duration getter covers UI.
      hoursRendered: json['hours_rendered'] != null
          ? double.tryParse(json['hours_rendered'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String().split('T').first,
        if (timeIn != null) 'time_in': timeIn!.toUtc().toIso8601String(),
        if (timeOut != null) 'time_out': timeOut!.toUtc().toIso8601String(),
        'hours_rendered': hoursRendered,
      };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Parses either a full ISO timestamp OR a "hh:mm AM" string.
/// When given a short time string, [dateStr] ("YYYY-MM-DD") is used
/// to anchor it to the correct calendar day in local time.
DateTime? _parseTime(dynamic raw, String? dateStr) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  // ISO 8601 — always convert to local so wall-clock comparisons are correct.
  final iso = DateTime.tryParse(s);
  if (iso != null) {
    return iso.toLocal(); // ← already there, confirm it's present
  }

  // "hh:mm AM" short format from admin endpoints.
  if (dateStr != null) {
    try {
      final parts = s.split(RegExp(r'[:\s]'));
      if (parts.length == 3) {
        int hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final isPm = parts[2].toUpperCase() == 'PM';

        if (hour == 12) {
          hour = isPm ? 12 : 0;
        } else if (isPm) hour += 12;

        final d = DateTime.parse(dateStr);
        // Construct as local — no toLocal() needed since no timezone info.
        return DateTime(d.year, d.month, d.day, hour, min);
      }
    } catch (_) {}
  }

  return null;
}

// ── AttendanceSummary ─────────────────────────────────────────────────────────

class AttendanceSummary {
  final double totalHoursRendered;
  final double requiredHours;
  final int totalDays;
  final AttendanceRecord? todayRecord;

  const AttendanceSummary({
    required this.totalHoursRendered,
    required this.requiredHours,
    required this.totalDays,
    this.todayRecord,
  });

  double get progressPercent => requiredHours > 0
      ? (totalHoursRendered / requiredHours).clamp(0.0, 1.0)
      : 0.0;

  double get remainingHours =>
      (requiredHours - totalHoursRendered).clamp(0.0, requiredHours);

  bool get isComplete => totalHoursRendered >= requiredHours;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalHoursRendered:
          double.tryParse(json['total_hours_rendered'].toString()) ?? 0.0,
      requiredHours:
          double.tryParse(json['required_hours'].toString()) ?? 400.0,
      totalDays: _toInt(json['total_days']),
      todayRecord: json['today'] != null
          ? AttendanceRecord.fromJson(json['today'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Shared util ───────────────────────────────────────────────────────────────

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
