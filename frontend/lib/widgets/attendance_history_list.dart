// lib/widgets/attendance_history_list.dart
//
// Scrollable list of past attendance records.
// - Weekends are excluded from the list.
// - Past records where the user timed in but never timed out show "Missed Clock Out".

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';

class AttendanceHistoryList extends StatelessWidget {
  final List<AttendanceRecord> records;
  final bool isLoading;

  const AttendanceHistoryList({
    super.key,
    required this.records,
    required this.isLoading,
  });

  /// Returns only weekday records (Mon–Fri), sorted newest first.
  List<AttendanceRecord> get _weekdayRecords {
    return records
        .where((r) =>
            r.date.weekday != DateTime.saturday &&
            r.date.weekday != DateTime.sunday)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _weekdayRecords;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: Color(0xFF460A14), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} record${filtered.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          // ── Body ────────────────────────────────────────────────────────
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'No attendance records yet',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20),
                itemBuilder: (context, i) =>
                    _AttendanceRow(record: filtered[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceRecord record;

  const _AttendanceRow({required this.record});

  /// A record is "missed clock out" when:
  ///   - The user timed in (has a timeIn value)
  ///   - The user never timed out (no timeOut value)
  ///   - The date is in the past (not today)
  bool get _isMissedClockOut {
    final today = DateTime.now();
    final isToday = record.date.year == today.year &&
        record.date.month == today.month &&
        record.date.day == today.day;
    return record.hasTimedIn && !record.hasTimedOut && !isToday;
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = record.isComplete;
    final isOngoing =
        record.hasTimedIn && !record.hasTimedOut && !_isMissedClockOut;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // ── Date badge ─────────────────────────────────────────────────
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF460A14).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  _monthAbbr(record.date.month),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF460A14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.date.day.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF460A14),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ── Time In / Out ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayName(record.date.weekday),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.login_rounded,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      record.timeIn != null ? _fmtTime(record.timeIn!) : '--',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.logout_rounded,
                        size: 12,
                        // Highlight the missing clock-out in red
                        color: _isMissedClockOut
                            ? Colors.red.shade300
                            : Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      record.timeOut != null
                          ? _fmtTime(record.timeOut!)
                          : (_isMissedClockOut ? 'Missing' : '--'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isMissedClockOut
                            ? Colors.red.shade400
                            : Colors.grey.shade600,
                        fontWeight: _isMissedClockOut
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Hours + status ─────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.hoursRendered != null
                    ? _fmtHours(record.hoursRendered!)
                    : '--',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              _StatusBadge(
                isComplete: isComplete,
                isOngoing: isOngoing,
                isMissedClockOut: _isMissedClockOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = (h % 12 == 0 ? 12 : h % 12).toString();
    return '$hour:$m $period';
  }

  String _fmtHours(double h) {
    final hh = h.floor();
    final mm = ((h - hh) * 60).round();
    return '${hh}h ${mm.toString().padLeft(2, '0')}m';
  }

  String _monthAbbr(int m) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[m - 1];
  }

  String _dayName(int wd) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[wd - 1];
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isComplete;
  final bool isOngoing;
  final bool isMissedClockOut;

  const _StatusBadge({
    required this.isComplete,
    required this.isOngoing,
    this.isMissedClockOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    final IconData icon;

    if (isComplete) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = 'Complete';
      icon = Icons.check_circle_rounded;
    } else if (isOngoing) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
      label = 'Ongoing';
      icon = Icons.timelapse_rounded;
    } else if (isMissedClockOut) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = 'Missed Clock Out';
      icon = Icons.alarm_off_rounded;
    } else {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
      label = 'Incomplete';
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style:
                TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
