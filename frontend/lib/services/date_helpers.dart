// lib/services/date_helpers.dart
// Date formatting and range computation utilities for the attendance feature.

import '../models/attendance_constants.dart';

String pad(int n) => n.toString().padLeft(2, '0');

String toApiDate(DateTime dt) =>
    '${dt.year}-${pad(dt.month)}-${pad(dt.day)}';

String toDisplayDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${pad(dt.day)}, ${dt.year}';
}

/// Short display: "May 06"
String toShortDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${pad(dt.day)}';
}

/// Returns (start, end) for a given [period] relative to [now].
(DateTime, DateTime) periodRange(AttendancePeriod period, DateTime now) {
  switch (period) {
    case AttendancePeriod.today:
      return (now, now);
    case AttendancePeriod.week:
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return (monday, sunday.isAfter(now) ? now : sunday);
    case AttendancePeriod.month:
      return (DateTime(now.year, now.month, 1), now);
    case AttendancePeriod.year:
      return (DateTime(now.year, 1, 1), now);
    default:
      return (now, now);
  }
}

/// Formats a date range into a human-readable label.
/// • Same day  → "May 06, 2025"
/// • Same year → "Apr 30 – May 06, 2025"
/// • Diff year → "Dec 30, 2024 – Jan 05, 2025"
String formatDateRange(DateTime start, DateTime end) {
  final sameDay = start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  if (sameDay) return toDisplayDate(start);
  if (start.year == end.year) {
    return '${toShortDate(start)} – ${toShortDate(end)}, ${end.year}';
  }
  return '${toDisplayDate(start)} – ${toDisplayDate(end)}';
}