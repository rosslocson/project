// lib/widgets/attendance_history_list.dart
//
// Display: records grouped by Mon–Fri work week.
// Most recent week shown first; user taps ← / → to move between weeks.
// Within a week, days are sorted Mon → Fri (ascending).

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import 'app_theme.dart';

// ── Theme constants matching MyProfileScreen dark blue palette ────────────
const _kNavy = Color(0xFF0B132B); // card dark blue — primary bg
const _kAccent = Color(0xFF4F8EF7); // bright blue — active states
const _kBorder = Color(0xFF1E2D50); // subtle border
const _kTextHead = Color(0xFF0B132B); // dark headings (on white surface)
const _kTextSub = Color(0xFF64748B); // muted body (on white surface)

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

DateTime _weekStart(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
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

// e.g. "Tuesday, May 19"
String _fmtToday(DateTime dt) {
  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  return '${days[dt.weekday - 1]}, ${_monthAbbr(dt.month)} ${dt.day}';
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
  int _weekIndex = 0;
  List<DateTime> _weeks = [];
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final grouped = <String, List<AttendanceRecord>>{};
    for (final r in widget.records) {
      // Never show records dated after today.
      final recordDate = DateTime(r.date.year, r.date.month, r.date.day);
      if (recordDate.isAfter(today)) continue;

      final monday = _weekStart(r.date);
      final key = _weekKey(monday);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
    }

    // Always ensure the current week slot exists so today is always visible.
    final thisWeekKey = _weekKey(_weekStart(now));
    grouped.putIfAbsent(thisWeekKey, () => []);

    // _weeks[0] = most recent week, _weeks[last] = oldest week.
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
    final records = _grouped[_weekKey(_weeks[_weekIndex])] ?? [];

    // For the current week, exclude any records dated after today.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekMonday = _weekStart(now);
    final isCurrentWeek = _weeks.isNotEmpty &&
        _weekKey(_weeks[_weekIndex]) == _weekKey(thisWeekMonday);

    if (isCurrentWeek) {
      return records
          .where((r) =>
              !DateTime(r.date.year, r.date.month, r.date.day).isAfter(today))
          .toList();
    }

    return records;
  }

  /// Whether today already has an attendance record in the current week.
  bool get _todayHasRecord {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _currentRecords.any((r) =>
        DateTime(r.date.year, r.date.month, r.date.day) == today);
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
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;

    final totalWeeks = _weeks.length;
    final monday = _weeks.isNotEmpty ? _weeks[_weekIndex] : null;
    // _weekIndex == 0  → newest week (no "newer" to go to)
    // _weekIndex == totalWeeks-1 → oldest week (no "older" to go to)
    final isNewestWeek = _weekIndex == 0;
    final isOldestWeek = _weekIndex >= totalWeeks - 1;

    final now = DateTime.now();
    final thisWeekMonday = _weekStart(now);
    final isCurrentWeek =
        monday != null && _weekKey(monday) == _weekKey(thisWeekMonday);

    // Accent color: maroon in light, purple/indigo in dark (matches Departments)
    final accentColor =
        isDark ? theme.sidebarActiveForeground : const Color(0xFF460A14);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: theme.border) : null,
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: _kNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (isCurrentWeek)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.green.shade300.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'This Week',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4ADE80),
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
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: _kAccent),
              ),
            )
          else if (_weeks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded,
                        size: 48, color: theme.mutedText),
                    const SizedBox(height: 8),
                    Text(
                      'No attendance records yet',
                      style: TextStyle(color: theme.mutedText),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // ── Week navigator bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  // ← goes to an OLDER week (higher index)
                  _NavArrow(
                    icon: Icons.chevron_left_rounded,
                    enabled: !isOldestWeek,
                    onTap: () => _goTo(_weekIndex + 1),
                    tooltip: 'Previous week',
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          monday != null ? _fmtWeekRange(monday) : '—',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : _kTextHead,
                          ),
                        ),
                        // ── Today label (current week only) ───────────
                        if (isCurrentWeek) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Today: ${_fmtToday(now)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SummaryChip(
                              label: '$_presentCount Present',
                              color: Colors.green,
                              isDark: isDark,
                            ),
                            if (_lateCount > 0) ...[
                              const SizedBox(width: 6),
                              _SummaryChip(
                                label: '$_lateCount Late',
                                color: Colors.orange,
                                isDark: isDark,
                              ),
                            ],
                            if (_absentCount > 0) ...[
                              const SizedBox(width: 6),
                              _SummaryChip(
                                label: '$_absentCount Absent',
                                color: Colors.grey,
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // → goes to a NEWER week (lower index)
                  _NavArrow(
                    icon: Icons.chevron_right_rounded,
                    enabled: !isNewestWeek,
                    onTap: () => _goTo(_weekIndex - 1),
                    tooltip: 'Next week',
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Colors.grey.shade100),

            // ── Day rows ──────────────────────────────────────────────────
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
                child: Builder(builder: (context) {
                  // Build the combined item list:
                  // real records + optional today-placeholder at the right position.
                  final records = _currentRecords;
                  final showTodayPlaceholder =
                      isCurrentWeek && !_todayHasRecord;

                  // Items: each is either an AttendanceRecord or a sentinel
                  // DateTime (today placeholder).
                  final items = <Object>[...records];
                  if (showTodayPlaceholder) {
                    // Insert today in sorted position among existing records.
                    final todayDate = DateTime(now.year, now.month, now.day);
                    int insertAt = items.indexWhere((item) =>
                        item is AttendanceRecord &&
                        item.date.isAfter(todayDate));
                    if (insertAt == -1) insertAt = items.length;
                    items.insert(insertAt, todayDate);
                  }

                  if (items.isEmpty) {
                    // Shouldn't happen (today placeholder always shows on
                    // current week), but guard just in case.
                    return Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'No records for this week',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, indent: 20, color: Colors.grey.shade100),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      if (item is DateTime) {
                        // Today placeholder — no record yet.
                        return _TodayPlaceholderRow(
                          date: item,
                          isDark: isDark,
                        );
                      }
                      return _AttendanceRow(
                        record: item as AttendanceRecord,
                        accentColor: accentColor,
                      );
                    },
                  );
                }),
              ),
            ),

            // ── Week dot indicators ──────────────────────────────────────
            // Dots: left = oldest week, right = newest week.
            // ← (older) moves left along the dots; → (newer) moves right.
            if (totalWeeks > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalWeeks, (i) {
                    // i=0 here = leftmost dot = OLDEST week (highest _weekIndex)
                    final dotWeekIndex = (totalWeeks - 1) - i;
                    final active = dotWeekIndex == _weekIndex;
                    return GestureDetector(
                      onTap: () => _goTo(dotWeekIndex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? _kAccent : Colors.grey.shade300,
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
  final Color accentColor;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
    required this.accentColor,
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
              color: _kAccent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 18, color: _kAccent),
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
  final bool isDark;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.15) : color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? color.shade200 : color.shade700,
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
  final Color accentColor;

  const _AttendanceRow({
    required this.record,
    required this.accentColor,
  });

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
    return local.hour > 8 || (local.hour == 8 && local.minute > 15);
  }

  bool get _isAbsent => record.isAbsent;

  // ── Excused helpers ───────────────────────────────────────────────────────

  bool get _isExcusedCredited =>
      record.status == 'Excused – Credited' ||
      record.status == 'excused_credited';

  bool get _isExcusedUncredited =>
      record.status == 'Excused – Uncredited' ||
      record.status == 'excused_uncredited';

  bool get _isExcused => _isExcusedCredited || _isExcusedUncredited;

  // ── Report type ───────────────────────────────────────────────────────────

  String? get _reportType {
    if (record.isReported) return null;
    // Excused records are already resolved — nothing left to dispute.
    if (_isExcused) return null;
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
    final isDark = context.isDarkInternTheme;

    final isComplete = record.isComplete;
    final isOngoing =
        record.hasTimedIn && !record.hasTimedOut && !_isMissedClockOut;
    final rt = _reportType;

    // Excused-uncredited days render like absent (greyed out date tile).
    final bool greyDate = _isAbsent || _isExcusedUncredited;

    // ── Is this row today? ─────────────────────────────────────────────────
    final now = DateTime.now();
    final isToday = record.date.year == now.year &&
        record.date.month == now.month &&
        record.date.day == now.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // ── Date tile ──────────────────────────────────────────────
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: greyDate
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : _kNavy.withValues(alpha: 0.07)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: greyDate
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200)
                    : _kBorder.withValues(alpha: isDark ? 0.6 : 0.4),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _monthAbbr(record.date.month),
                  style: TextStyle(
                    fontSize: 10,
                    color: greyDate
                        ? (isDark ? Colors.white30 : Colors.grey.shade400)
                        : _kAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.date.day.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: greyDate
                        ? (isDark ? Colors.white30 : Colors.grey.shade400)
                        : (isDark ? Colors.white : _kNavy),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Day + times ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _dayName(record.date.weekday),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: greyDate
                            ? (isDark ? Colors.white30 : Colors.grey.shade400)
                            : (isDark ? Colors.white : _kTextHead),
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _kAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
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
                        style: const TextStyle(fontSize: 12, color: _kTextSub),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.logout_rounded,
                        size: 12,
                        color: _isMissedClockOut
                            ? Colors.red.shade300
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
                              : _kTextSub,
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

          // ── Hours + status ─────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                // Uncredited excused: hours don't count → show 0
                // Credited excused: hours count → show actual or implied 8h
                // Absent: always 0
                _isAbsent || _isExcusedUncredited
                    ? '0h 00m'
                    : _isExcusedCredited
                        // Credited: use computed hours if available, else imply a full 8h day.
                        ? _fmtHours(
                            record.hoursWorked ?? record.hoursRendered ?? 8.0)
                        : ((record.hoursWorked ?? record.hoursRendered) != null
                            ? _fmtHours(
                                record.hoursWorked ?? record.hoursRendered!)
                            : '--'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _isAbsent || _isExcusedUncredited
                      ? Colors.grey.shade400
                      : _isExcusedCredited
                          ? const Color(0xFF047857) // teal — credited
                          : _kTextHead,
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
                isExcusedCredited: _isExcusedCredited,
                isExcusedUncredited: _isExcusedUncredited,
                isDark: isDark,
              ),
              if (rt != null) ...[
                const SizedBox(height: 6),
                _ReportButton(
                  recordId: record.id,
                  date: _dateKey(record.date),
                  reportType: rt,
                  accentColor: accentColor,
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
// Today placeholder row (shown when today has no attendance record yet)
// ─────────────────────────────────────────────────────────────────────────────

class _TodayPlaceholderRow extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const _TodayPlaceholderRow({required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      'Saturday', 'Sunday',
    ];
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // ── Date tile (today accent) ──────────────────────────────
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kAccent.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Text(
                  months[date.month - 1],
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _kNavy,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Day name + "Today" pill ───────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      days[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _kAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'No clock-in recorded',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // ── Hours + status ────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '0h 00m',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 4),
              _StatusBadge(
                isAbsent: true,
                isComplete: false,
                isOngoing: false,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isAbsent;
  final bool isComplete;
  final bool isOngoing;
  final bool isMissedClockOut;
  final bool isLate;
  final bool isReported;
  final bool isExcusedCredited;
  final bool isExcusedUncredited;
  final bool isDark;

  const _StatusBadge({
    this.isAbsent = false,
    required this.isComplete,
    required this.isOngoing,
    this.isMissedClockOut = false,
    this.isLate = false,
    this.isReported = false,
    this.isExcusedCredited = false,
    this.isExcusedUncredited = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    final IconData icon;

    // ── Excused – Credited (teal/green) ───────────────────────────────────
    // Checked first so it is never masked by isComplete or isAbsent.
    if (isExcusedCredited) {
      bg = isDark
          ? const Color(0xFF34D399).withValues(alpha: 0.15)
          : const Color(0xFFECFDF5);
      fg = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
      label = 'Excused – Credited';
      icon = Icons.verified_rounded;
    }
    // ── Excused – Uncredited (purple/violet) ──────────────────────────────
    else if (isExcusedUncredited) {
      bg = isDark
          ? const Color(0xFFA78BFA).withValues(alpha: 0.15)
          : const Color(0xFFF5F3FF);
      fg = isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9);
      label = 'Excused – Uncredited';
      icon = Icons.remove_circle_outline_rounded;
    }
    // ── Absent ────────────────────────────────────────────────────────────
    else if (isAbsent) {
      bg = isDark ? Colors.grey.withValues(alpha: 0.15) : Colors.grey.shade100;
      fg = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
      label = 'Absent';
      icon = Icons.person_off_rounded;
    }
    // ── Late ──────────────────────────────────────────────────────────────
    else if (isComplete && isLate) {
      bg = isDark
          ? Colors.orange.withValues(alpha: 0.15)
          : Colors.orange.shade50;
      fg = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      label = 'Late';
      icon = Icons.schedule_rounded;
    }
    // ── Complete ──────────────────────────────────────────────────────────
    else if (isComplete) {
      bg = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
      fg = isDark ? Colors.greenAccent : Colors.green.shade700;
      label = 'Complete';
      icon = Icons.check_circle_rounded;
    }
    // ── On Shift ──────────────────────────────────────────────────────────
    else if (isOngoing) {
      bg = _kAccent.withValues(alpha: 0.1);
      fg = _kAccent;
      label = 'On Shift';
      icon = Icons.timelapse_rounded;
    }
    // ── Reported ──────────────────────────────────────────────────────────
    else if (isReported) {
      bg = isDark
          ? Colors.purple.withValues(alpha: 0.15)
          : Colors.purple.shade50;
      fg = isDark ? Colors.purpleAccent : Colors.purple.shade700;
      label = 'Reported';
      icon = Icons.flag_rounded;
    }
    // ── Missed Clock Out ──────────────────────────────────────────────────
    else if (isMissedClockOut) {
      bg = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
      fg = isDark ? Colors.red.shade300 : Colors.red.shade700;
      label = 'Missed Clock Out';
      icon = Icons.alarm_off_rounded;
    }
    // ── Incomplete (fallback) ─────────────────────────────────────────────
    else {
      bg = isDark
          ? Colors.orange.withValues(alpha: 0.15)
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
        border: Border.all(color: fg.withValues(alpha: 0.3)),
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
  final Color accentColor;

  const _ReportButton({
    required this.recordId,
    required this.date,
    required this.reportType,
    required this.accentColor,
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
      builder: (_) => _ReportIssueDialog(
        reportType: widget.reportType,
        accentColor: widget.accentColor,
      ),
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
              ? _kAccent.withValues(alpha: 0.08)
              : _kNavy.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kAccent.withValues(alpha: 0.35)),
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
                  color: _kAccent.withValues(alpha: 0.7),
                ),
              )
            else
              const Icon(Icons.flag_rounded, size: 10, color: _kAccent),
            const SizedBox(width: 4),
            Text(
              _submitting ? 'Submitting…' : _buttonLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kAccent,
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
  final Color accentColor;

  const _ReportIssueDialog({
    required this.reportType,
    this.accentColor = _kAccent,
  });

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _kNavy.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Dark header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                color: _kNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(_icon, color: _kAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bodyText,
                      style: const TextStyle(
                          fontSize: 13, color: _kTextSub, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextHead,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _ctrl,
                      maxLines: 3,
                      maxLength: 300,
                      autofocus: true,
                      style: const TextStyle(fontSize: 13, color: _kTextHead),
                      decoration: InputDecoration(
                        hintText: _hint,
                        hintStyle: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _kAccent, width: 1.5),
                        ),
                        counterStyle: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400),
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
            ),

            // ── Actions ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: _kTextSub,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.pop(context, _ctrl.text.trim());
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 15),
                    label: const Text('Submit Report'),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
                              ? _kAccent.withValues(alpha: 0.4)
                              : _kAccent),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      elevation: WidgetStateProperty.all(0),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}