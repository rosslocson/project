// lib/models/attendance_model.dart

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

  /// Duration of this session. Returns null if incomplete.
  Duration? get duration {
    if (timeIn == null || timeOut == null) return null;
    return timeOut!.difference(timeIn!);
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      date: DateTime.parse(json['date'] as String),
      timeIn: json['time_in'] != null
          ? DateTime.parse(json['time_in'] as String).toLocal()
          : null,
      timeOut: json['time_out'] != null
          ? DateTime.parse(json['time_out'] as String).toLocal()
          : null,
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

/// Summary returned by GET /api/attendance/summary
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

  double get progressPercent =>
      requiredHours > 0
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

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}