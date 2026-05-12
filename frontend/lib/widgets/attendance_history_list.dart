// lib/widgets/attendance_history_list.dart
//
// Changes vs original:
//   • _AttendanceRow now shows a "Report to Admin" button for Late and
//     Absent rows (not just Missed Clock-Out).
//   • _ReportButton accepts reportType + date so the new unified endpoint
//     is used for all three statuses.
//   • _ReportIssueDialog replaces _ReportConfirmDialog — it collects a
//     free-text reason and adapts its copy to the report type.
//   • AdminAttendanceRecord.remark field rendering unchanged.

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceHistoryList extends StatelessWidget {
  final List<AttendanceRecord> records;
  final bool isLoading;

  const AttendanceHistoryList({
    super.key,
    required this.records,
    required this.isLoading,
  });

  List<AttendanceRecord> get _sortedRecords {
    final copy = [...records];
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _sortedRecords;

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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Row
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceRow extends StatelessWidget {
  final AttendanceRecord record;
  const _AttendanceRow({required this.record});

  // ── Status helpers ────────────────────────────────────────────────────────

  bool get _isMissedClockOut {
    final today = DateTime.now();
    final isToday = record.date.year == today.year &&
        record.date.month == today.month &&
        record.date.day == today.day;
    return record.hasTimedIn && !record.hasTimedOut && !isToday;
  }

  bool get _isLate {
    if (!record.isComplete) return false;
    final local = record.timeIn!.toLocal();
    // After 08:15 Manila time is considered Late (mirrors backend logic).
    return local.hour > 8 || (local.hour == 8 && local.minute > 15);
  }

  bool get _isAbsent => record.isAbsent;

  /// Returns the report_type string expected by the backend, or null if this
  /// record is not reportable by the intern.
  String? get _reportType {
    if (record.isReported) return null; // already reported
    if (_isMissedClockOut) return 'missed_clock_out';
    if (_isAbsent) return 'absent';
    if (_isLate) return 'late';
    return null;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isComplete = record.isComplete;
    final isOngoing =
        record.hasTimedIn && !record.hasTimedOut && !_isMissedClockOut;
    final rt = _reportType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // ── Date badge ─────────────────────────────────────────────────
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _isAbsent
                  ? Colors.grey.shade100
                  : const Color(0xFF460A14).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  _monthAbbr(record.date.month),
                  style: TextStyle(
                    fontSize: 10,
                    color: _isAbsent
                        ? Colors.grey.shade400
                        : const Color(0xFF460A14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.date.day.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _isAbsent
                        ? Colors.grey.shade400
                        : const Color(0xFF460A14),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isAbsent
                        ? Colors.grey.shade400
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                if (!_isAbsent)
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
                      Icon(
                        Icons.logout_rounded,
                        size: 12,
                        color: _isMissedClockOut
                            ? Colors.red.shade300
                            : Colors.grey.shade400,
                      ),
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
                  )
                else
                  Text(
                    'No clock-in recorded',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),

          // ── Hours + status + report button ─────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isAbsent
                    ? '0h 00m'
                    : ((record.hoursWorked ?? record.hoursRendered) != null
                        ? _fmtHours(
                            record.hoursWorked ?? record.hoursRendered!)
                        : '--'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _isAbsent
                      ? Colors.grey.shade400
                      : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              _StatusBadge(
                isAbsent: _isAbsent,
                isComplete: isComplete,
                isOngoing: isOngoing,
                isMissedClockOut: _isMissedClockOut,
                isLate: _isLate,
                isReported: record.isReported,
              ),
              // ── Report button (shown for Late, Absent, Missed Clock-Out) ──
              if (rt != null) ...[
                const SizedBox(height: 6),
                _ReportButton(
                  recordId: record.id,
                  date: _dateKey(record.date),
                  reportType: rt,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmtTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _fmtHours(double h) {
    final hh = h.floor();
    final mm = ((h - hh) * 60).round();
    return '${hh}h ${mm.toString().padLeft(2, '0')}m';
  }

  String _monthAbbr(int m) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return months[m - 1];
  }

  String _dayName(int wd) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return days[wd - 1];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isAbsent;
  final bool isComplete;
  final bool isOngoing;
  final bool isMissedClockOut;
  final bool isLate;
  final bool isReported;

  const _StatusBadge({
    this.isAbsent = false,
    required this.isComplete,
    required this.isOngoing,
    this.isMissedClockOut = false,
    this.isLate = false,
    this.isReported = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    final IconData icon;

    if (isAbsent) {
      bg    = Colors.grey.shade100;
      fg    = Colors.grey.shade500;
      label = 'Absent';
      icon  = Icons.person_off_rounded;
    } else if (isComplete && isLate) {
      bg    = Colors.orange.shade50;
      fg    = Colors.orange.shade700;
      label = 'Late';
      icon  = Icons.schedule_rounded;
    } else if (isComplete) {
      bg    = Colors.green.shade50;
      fg    = Colors.green.shade700;
      label = 'Complete';
      icon  = Icons.check_circle_rounded;
    } else if (isOngoing) {
      bg    = Colors.blue.shade50;
      fg    = Colors.blue.shade700;
      label = 'On Shift';
      icon  = Icons.timelapse_rounded;
    } else if (isReported) {
      bg    = Colors.purple.shade50;
      fg    = Colors.purple.shade700;
      label = 'Reported';
      icon  = Icons.flag_rounded;
    } else if (isMissedClockOut) {
      bg    = Colors.red.shade50;
      fg    = Colors.red.shade700;
      label = 'Missed Clock Out';
      icon  = Icons.alarm_off_rounded;
    } else {
      bg    = Colors.orange.shade50;
      fg    = Colors.orange.shade700;
      label = 'Incomplete';
      icon  = Icons.warning_amber_rounded;
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
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report button — works for all three reportable statuses
// ─────────────────────────────────────────────────────────────────────────────

class _ReportButton extends StatefulWidget {
  final int recordId;
  final String date;       // "YYYY-MM-DD"
  final String reportType; // 'late' | 'absent' | 'missed_clock_out'

  const _ReportButton({
    required this.recordId,
    required this.date,
    required this.reportType,
  });

  @override
  State<_ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<_ReportButton> {
  bool _submitting = false;

  String get _buttonLabel {
    switch (widget.reportType) {
      case 'late':
        return 'Dispute Late Mark';
      case 'absent':
        return 'Dispute Absence';
      case 'missed_clock_out':
      default:
        return 'Report to Admin';
    }
  }

  Future<void> _submit() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReportIssueDialog(reportType: widget.reportType),
    );
    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _submitting = true);

    final res = await AttendanceService.reportAttendanceIssue(
      date: widget.date,
      reportType: widget.reportType,
      reason: reason,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['ok'] == true
              ? 'Report submitted. Admin will review your record.'
              : res['error'] ?? 'Failed to submit report.',
        ),
        backgroundColor: res['ok'] == true
            ? Colors.green.shade700
            : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: _submitting
              ? Colors.orange.shade50
              : const Color(0xFF460A14).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF460A14).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_submitting)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: const Color(0xFF460A14).withValues(alpha: 0.6),
                ),
              )
            else
              const Icon(Icons.flag_rounded,
                  size: 10, color: Color(0xFF460A14)),
            const SizedBox(width: 4),
            Text(
              _submitting ? 'Submitting…' : _buttonLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF460A14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report issue dialog — collects a reason, adapts copy per status
// ─────────────────────────────────────────────────────────────────────────────

class _ReportIssueDialog extends StatefulWidget {
  final String reportType; // 'late' | 'absent' | 'missed_clock_out'

  const _ReportIssueDialog({required this.reportType});

  @override
  State<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<_ReportIssueDialog> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Copy helpers ──────────────────────────────────────────────────────────

  String get _title {
    switch (widget.reportType) {
      case 'late':
        return 'Dispute Late Mark';
      case 'absent':
        return 'Dispute Absence';
      case 'missed_clock_out':
      default:
        return 'Report Missed Clock-Out';
    }
  }

  IconData get _icon {
    switch (widget.reportType) {
      case 'late':
        return Icons.schedule_rounded;
      case 'absent':
        return Icons.person_off_rounded;
      case 'missed_clock_out':
      default:
        return Icons.alarm_off_rounded;
    }
  }

  String get _bodyText {
    switch (widget.reportType) {
      case 'late':
        return 'If you believe your late mark is incorrect (e.g. you clocked in on time but the system recorded it late), explain below. The admin will review and may adjust your time-in.';
      case 'absent':
        return 'If you were present but have no clock-in on record (e.g. forgot to clock in, biometric error), explain below. The admin can mark you present or excuse the absence.';
      case 'missed_clock_out':
      default:
        return 'This will notify the admin that you forgot to clock out. They will review and set your time-out manually.';
    }
  }

  String get _hint {
    switch (widget.reportType) {
      case 'late':
        return 'e.g. I was in the office at 8:00 AM but the system logged 8:45 AM…';
      case 'absent':
        return 'e.g. I reported to the office but forgot to clock in…';
      case 'missed_clock_out':
      default:
        return 'e.g. I left at 5 PM but forgot to clock out…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Row(
        children: [
          Icon(_icon, color: const Color(0xFF460A14), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Explainer ──────────────────────────────────────────────
            Text(
              _bodyText,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 14),

            // ── Reason field ───────────────────────────────────────────
            Text(
              'Reason',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ctrl,
              maxLines: 3,
              maxLength: 300,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _hint,
                hintStyle:
                    TextStyle(fontSize: 12, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF460A14), width: 1.5),
                ),
                counterStyle:
                    TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
              style: const TextStyle(fontSize: 13),
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Please enter at least 5 characters.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.black45)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _ctrl.text.trim());
            }
          },
          icon: const Icon(Icons.send_rounded, size: 15),
          label: const Text('Submit Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF460A14),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}