// lib/widgets/attendance_history_list.dart

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import 'app_theme.dart';

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
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _sortedRecords;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : theme.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFF00022E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: isDark ? Colors.white60 : const Color(0xFF00022E),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.surfaceText,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : theme.formFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.border),
                  ),
                  child: Text(
                    '${filtered.length} record${filtered.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  color: isDark
                      ? const Color(0xFF7367F0)
                      : const Color(0xFF00022E),
                ),
              ),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : theme.formFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_busy_rounded,
                        size: 36,
                        color: theme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No attendance records yet',
                      style: TextStyle(
                        color: theme.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
                    Divider(height: 1, color: theme.border),
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
    return local.hour > 8 || (local.hour == 8 && local.minute > 15);
  }

  bool get _isAbsent => record.isAbsent;

  String? get _reportType {
    if (record.isReported) return null;
    if (_isMissedClockOut) return 'missed_clock_out';
    if (_isAbsent) return 'absent';
    if (_isLate) return 'late';
    return null;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isComplete = record.isComplete;
    final isOngoing =
        record.hasTimedIn && !record.hasTimedOut && !_isMissedClockOut;
    final rt = _reportType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // ── Date badge ──────────────────────────────────────────────────
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _isAbsent
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade100)
                  : (isDark
                      ? const Color(0xFF7367F0).withValues(alpha: 0.12)
                      : const Color(0xFF00022E).withValues(alpha: 0.07)),
              borderRadius: BorderRadius.circular(10),
              border: isDark
                  ? Border.all(
                      color: _isAbsent
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFF7367F0).withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  _monthAbbr(record.date.month),
                  style: TextStyle(
                    fontSize: 10,
                    color: _isAbsent
                        ? theme.mutedText
                        : (isDark
                            ? const Color(0xFF9F8FFF)
                            : const Color(0xFF00022E)),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.date.day.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _isAbsent
                        ? theme.mutedText
                        : (isDark ? Colors.white : const Color(0xFF00022E)),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ── Day / times ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayName(record.date.weekday),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isAbsent ? theme.mutedText : theme.surfaceText,
                  ),
                ),
                const SizedBox(height: 2),
                if (!_isAbsent)
                  Row(
                    children: [
                      Icon(Icons.login_rounded,
                          size: 12, color: theme.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        record.timeIn != null ? _fmtTime(record.timeIn!) : '--',
                        style: TextStyle(fontSize: 12, color: theme.mutedText),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.logout_rounded,
                        size: 12,
                        color: _isMissedClockOut
                            ? Colors.red.shade400
                            : theme.mutedText,
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
                              : theme.mutedText,
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
                    style: TextStyle(fontSize: 12, color: theme.mutedText),
                  ),
              ],
            ),
          ),

          // ── Hours + badge + report ───────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isAbsent
                    ? '0h 00m'
                    : ((record.hoursWorked ?? record.hoursRendered) != null
                        ? _fmtHours(record.hoursWorked ?? record.hoursRendered!)
                        : '--'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _isAbsent ? theme.mutedText : theme.surfaceText,
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
                isDark: isDark,
              ),
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
      'DEC',
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
      'Sunday',
    ];
    return days[wd - 1];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge — glass-aware
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isAbsent;
  final bool isComplete;
  final bool isOngoing;
  final bool isMissedClockOut;
  final bool isLate;
  final bool isReported;
  final bool isDark;

  const _StatusBadge({
    this.isAbsent = false,
    required this.isComplete,
    required this.isOngoing,
    this.isMissedClockOut = false,
    this.isLate = false,
    this.isReported = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    final IconData icon;

    if (isAbsent) {
      bg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100;
      fg = isDark ? Colors.white38 : Colors.grey.shade500;
      label = 'Absent';
      icon = Icons.person_off_rounded;
    } else if (isComplete && isLate) {
      bg = isDark
          ? Colors.orange.withValues(alpha: 0.15)
          : Colors.orange.shade50;
      fg = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      label = 'Late';
      icon = Icons.schedule_rounded;
    } else if (isComplete) {
      bg = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
      fg = isDark ? Colors.greenAccent : Colors.green.shade700;
      label = 'Complete';
      icon = Icons.check_circle_rounded;
    } else if (isOngoing) {
      bg = isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50;
      fg = isDark ? Colors.blueAccent.shade100 : Colors.blue.shade700;
      label = 'On Shift';
      icon = Icons.timelapse_rounded;
    } else if (isReported) {
      bg = isDark
          ? Colors.purple.withValues(alpha: 0.15)
          : Colors.purple.shade50;
      fg = isDark ? Colors.purpleAccent.shade100 : Colors.purple.shade700;
      label = 'Reported';
      icon = Icons.flag_rounded;
    } else if (isMissedClockOut) {
      bg = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
      fg = isDark ? Colors.red.shade300 : Colors.red.shade700;
      label = 'Missed Clock Out';
      icon = Icons.alarm_off_rounded;
    } else {
      bg = isDark
          ? Colors.orange.withValues(alpha: 0.12)
          : Colors.orange.shade50;
      fg = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      label = 'Incomplete';
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: fg.withValues(alpha: 0.25), width: 1)
            : null,
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

// ─────────────────────────────────────────────────────────────────────────────
// Report button
// ─────────────────────────────────────────────────────────────────────────────

class _ReportButton extends StatefulWidget {
  final int recordId;
  final String date;
  final String reportType;

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
        backgroundColor:
            res['ok'] == true ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFF460A14).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : const Color(0xFF460A14).withValues(alpha: 0.25),
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
                  color: isDark
                      ? Colors.white54
                      : const Color(0xFF460A14).withValues(alpha: 0.6),
                ),
              )
            else
              Icon(
                Icons.flag_rounded,
                size: 10,
                color: isDark ? Colors.white54 : const Color(0xFF460A14),
              ),
            const SizedBox(width: 4),
            Text(
              _submitting ? 'Submitting…' : _buttonLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : const Color(0xFF460A14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report dialog — glass-aware
// ─────────────────────────────────────────────────────────────────────────────

class _ReportIssueDialog extends StatefulWidget {
  final String reportType;
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

  String get _title {
    switch (widget.reportType) {
      case 'late':
        return 'Dispute Late Mark';
      case 'absent':
        return 'Dispute Absence';
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
      default:
        return Icons.alarm_off_rounded;
    }
  }

  String get _bodyText {
    switch (widget.reportType) {
      case 'late':
        return 'If you believe your late mark is incorrect, explain below. The admin will review and may adjust your time-in.';
      case 'absent':
        return 'If you were present but have no clock-in on record, explain below. The admin can mark you present or excuse the absence.';
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
      default:
        return 'e.g. I left at 5 PM but forgot to clock out…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF7367F0) : const Color(0xFF460A14);

    return AlertDialog(
      backgroundColor: theme.dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark
            ? BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)
            : BorderSide.none,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Row(
        children: [
          Icon(_icon, color: accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.surfaceText,
              ),
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
            Text(
              _bodyText,
              style: TextStyle(
                fontSize: 13,
                color: theme.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Reason',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.surfaceText,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ctrl,
              maxLines: 3,
              maxLength: 300,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: theme.surfaceText),
              decoration: InputDecoration(
                hintText: _hint,
                hintStyle: TextStyle(fontSize: 12, color: theme.mutedText),
                filled: true,
                fillColor: theme.formFill,
                contentPadding: const EdgeInsets.all(12),
                counterStyle: TextStyle(fontSize: 10, color: theme.mutedText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
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
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.mutedText),
          ),
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
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
