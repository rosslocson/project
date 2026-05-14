// lib/widgets/attendance_history_list.dart
//
// Display: records grouped by Mon–Fri work week.
// Most recent week shown first; user taps ← / → to move between weeks.
// Within a week, days are sorted Mon → Fri (ascending).

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the Monday of the ISO week that [date] belongs to.
DateTime _weekStart(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1)); // weekday: 1=Mon … 7=Sun
}

String _weekKey(DateTime monday) =>
    '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

String _monthAbbr(int m) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[m - 1];
}

String _fmtWeekRange(DateTime monday) {
  final friday = monday.add(const Duration(days: 4));
  if (monday.month == friday.month) {
    return '${_monthAbbr(monday.month)} ${monday.day} – ${friday.day}, ${friday.year}';
  }
  return '${_monthAbbr(monday.month)} ${monday.day} – ${_monthAbbr(friday.month)} ${friday.day}, ${friday.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceHistoryList extends StatefulWidget {
  final List<AttendanceRecord> records;
  final bool isLoading;

  const AttendanceHistoryList({
    super.key,
    required this.records,
    required this.isLoading,
  });

  @override
  State<AttendanceHistoryList> createState() => _AttendanceHistoryListState();
}

class _AttendanceHistoryListState extends State<AttendanceHistoryList> {
  /// Index into [_weeks]; 0 = most recent week.
  int _weekIndex = 0;

  /// Sorted list of week-start Mondays, descending (newest first).
  List<DateTime> _weeks = [];

  /// Map from weekKey → records for that week, sorted Mon→Fri.
  Map<String, List<AttendanceRecord>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(AttendanceHistoryList old) {
    super.didUpdateWidget(old);
    if (old.records != widget.records) _rebuild();
  }

  void _rebuild() {
    final grouped = <String, List<AttendanceRecord>>{};
    for (final r in widget.records) {
      final monday = _weekStart(r.date);
      final key = _weekKey(monday);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    // Sort records within each week Mon→Fri
    for (final list in grouped.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
    }
    // Sort weeks newest first
    final weeks = grouped.keys.map((k) => DateTime.parse(k)).toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      _weeks = weeks;
      _grouped = grouped;
      if (_weekIndex >= weeks.length) _weekIndex = 0;
    });
  }

  List<AttendanceRecord> get _currentRecords {
    if (_weeks.isEmpty) return [];
    return _grouped[_weekKey(_weeks[_weekIndex])] ?? [];
  }

  void _goTo(int index) {
    final clamped = index.clamp(0, (_weeks.length - 1).clamp(0, 9999));
    if (clamped != _weekIndex) setState(() => _weekIndex = clamped);
  }

  int get _presentCount =>
      _currentRecords.where((r) => !r.isAbsent && r.hasTimedIn).length;

  int get _absentCount => _currentRecords.where((r) => r.isAbsent).length;

  int get _lateCount => _currentRecords.where((r) {
        if (!r.isComplete) return false;
        final local = r.timeIn!.toLocal();
        return local.hour > 8 || (local.hour == 8 && local.minute > 15);
      }).length;

  @override
  Widget build(BuildContext context) {
    final totalWeeks = _weeks.length;
    final monday = _weeks.isNotEmpty ? _weeks[_weekIndex] : null;
    final isNewestWeek = _weekIndex == 0;
    final isOldestWeek = _weekIndex >= totalWeeks - 1;

    final now = DateTime.now();
    final thisWeekMonday = _weekStart(now);
    final isCurrentWeek =
        monday != null && _weekKey(monday) == _weekKey(thisWeekMonday);

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
          // ── Header ────────────────────────────────────────────────────
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
                if (isCurrentWeek)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'This Week',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    totalWeeks > 0
                        ? 'Week ${_weekIndex + 1} of $totalWeeks'
                        : '—',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          // ── Body ──────────────────────────────────────────────────────
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_weeks.isEmpty)
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
          else ...[
            // ── Week navigator bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  _NavArrow(
                    icon: Icons.chevron_left_rounded,
                    enabled: !isOldestWeek,
                    onTap: () => _goTo(_weekIndex + 1),
                    tooltip: 'Previous week',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          monday != null ? _fmtWeekRange(monday) : '—',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SummaryChip(
                              label: '$_presentCount Present',
                              color: Colors.green,
                            ),
                            if (_lateCount > 0) ...[
                              const SizedBox(width: 6),
                              _SummaryChip(
                                label: '$_lateCount Late',
                                color: Colors.orange,
                              ),
                            ],
                            if (_absentCount > 0) ...[
                              const SizedBox(width: 6),
                              _SummaryChip(
                                label: '$_absentCount Absent',
                                color: Colors.grey,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _NavArrow(
                    icon: Icons.chevron_right_rounded,
                    enabled: !isNewestWeek,
                    onTap: () => _goTo(_weekIndex - 1),
                    tooltip: 'Next week',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, indent: 20, endIndent: 20),

            // ── Day rows ──────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: ClipRRect(
                key: ValueKey<int>(_weekIndex),
                borderRadius: totalWeeks <= 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(16))
                    : BorderRadius.zero,
                child: _currentRecords.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'No records for this week',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _currentRecords.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 20),
                        itemBuilder: (context, i) =>
                            _AttendanceRow(record: _currentRecords[i]),
                      ),
              ),
            ),

            // ── Week dot indicators ────────────────────────────────────
            if (totalWeeks > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalWeeks, (i) {
                    final active = i == _weekIndex;
                    return GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF460A14)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav arrow
// ─────────────────────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.25,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF460A14).withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF460A14).withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF460A14)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary chip
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final MaterialColor color;

  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.shade700,
        ),
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
    final isComplete = record.isComplete;
    final isOngoing =
        record.hasTimedIn && !record.hasTimedOut && !_isMissedClockOut;
    final rt = _reportType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
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
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
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
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade500;
      label = 'Absent';
      icon = Icons.person_off_rounded;
    } else if (isComplete && isLate) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
      label = 'Late';
      icon = Icons.schedule_rounded;
    } else if (isComplete) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = 'Complete';
      icon = Icons.check_circle_rounded;
    } else if (isOngoing) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
      label = 'On Shift';
      icon = Icons.timelapse_rounded;
    } else if (isReported) {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade700;
      label = 'Reported';
      icon = Icons.flag_rounded;
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
// Report issue dialog
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
        return 'If you believe your late mark is incorrect (e.g. you clocked in on time but the system recorded it late), explain below. The admin will review and may adjust your time-in.';
      case 'absent':
        return 'If you were present but have no clock-in on record (e.g. forgot to clock in, biometric error), explain below. The admin can mark you present or excuse the absence.';
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
            child: Text(_title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_bodyText,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black54, height: 1.5)),
            const SizedBox(height: 14),
            Text('Reason',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ctrl,
              maxLines: 3,
              maxLength: 300,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _hint,
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
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
                  borderSide:
                      const BorderSide(color: Color(0xFF460A14), width: 1.5),
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
          child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
