import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import 'app_theme.dart';

class AttendanceClockCard extends StatelessWidget {
  final AttendanceSummary? summary;
  final bool isLoading;
  final VoidCallback onTimeIn;
  final VoidCallback onTimeOut;
  final bool isOjtComplete;

  const AttendanceClockCard({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.onTimeIn,
    required this.onTimeOut,
    this.isOjtComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final today = summary?.todayRecord;
    final timedIn = today?.hasTimedIn ?? false;
    final timedOut = today?.hasTimedOut ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0D0F2B), Color(0xFF1A1F5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isDark ? null : theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : theme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : theme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ─────────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.today_rounded,
                color: isDark ? Colors.white70 : theme.mutedText,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _todayLabel(),
                style: TextStyle(
                  color: isDark ? Colors.white70 : theme.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isWeekend) ...[
                const SizedBox(width: 10),
                _Pill(
                  label: 'Weekend – No Attendance',
                  bg: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : theme.border,
                  fg: isDark ? Colors.white60 : theme.mutedText,
                  border: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : theme.border,
                ),
              ],
              if (isOjtComplete) ...[
                const SizedBox(width: 10),
                _Pill(
                  label: 'OJT Complete',
                  bg: Colors.greenAccent.withValues(alpha: 0.15),
                  fg: Colors.greenAccent,
                  border: Colors.greenAccent.withValues(alpha: 0.4),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ── Time chips ────────────────────────────────────────────────────
          Row(
            children: [
              _TimeChip(
                label: 'Time In',
                time: today?.timeIn,
                icon: Icons.login_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _TimeChip(
                label: 'Time Out',
                time: today?.timeOut,
                icon: Icons.logout_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _TimeChip(
                label: "Today's Hours",
                time: null,
                customText: today?.timeIn != null
                    ? (today?.timeOut != null
                        ? _fmtHours(
                            _adjustedHours(today!.timeIn!, today.timeOut!))
                        : 'Ongoing')
                    : '--',
                icon: Icons.access_time_rounded,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Action button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _buildButton(
              timedIn: timedIn,
              timedOut: timedOut,
              isDark: isDark,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isWeekend {
    final wd = DateTime.now().weekday;
    return wd == DateTime.saturday || wd == DateTime.sunday;
  }

  double _adjustedHours(DateTime timeIn, DateTime timeOut) {
    final totalMinutes = timeOut.difference(timeIn).inMinutes.toDouble();
    final lunchStart = DateTime(timeIn.year, timeIn.month, timeIn.day, 12, 0);
    final lunchEnd = DateTime(timeIn.year, timeIn.month, timeIn.day, 13, 0);
    final overlapStart = timeIn.isAfter(lunchStart) ? timeIn : lunchStart;
    final overlapEnd = timeOut.isBefore(lunchEnd) ? timeOut : lunchEnd;
    double deduct = 0;
    if (overlapEnd.isAfter(overlapStart)) {
      deduct = overlapEnd.difference(overlapStart).inMinutes.toDouble();
    }
    return (totalMinutes - deduct) / 60.0;
  }

  Widget _buildButton({
    required bool timedIn,
    required bool timedOut,
    required bool isDark,
    required InternSpaceThemeColors theme,
  }) {
    final defaultBg =
        isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF00022E);
    const defaultFg = Colors.white;
    final defaultBorder =
        isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF00022E);
    final disabledBg =
        isDark ? Colors.white.withValues(alpha: 0.1) : theme.border;
    final disabledFg = isDark ? Colors.white60 : theme.mutedText;
    final disabledBorder =
        isDark ? Colors.white.withValues(alpha: 0.2) : theme.border;

    if (isOjtComplete) {
      return _ActionButton(
        label: 'OJT Hours Completed',
        icon: Icons.verified_rounded,
        enabled: false,
        bg: Colors.greenAccent.withValues(alpha: 0.12),
        fg: Colors.greenAccent.withValues(alpha: 0.7),
        borderColor: Colors.greenAccent.withValues(alpha: 0.3),
        onPressed: null,
        isLoading: false,
      );
    }
    if (_isWeekend) {
      return _ActionButton(
        label: 'No Attendance on Weekends',
        icon: Icons.weekend_rounded,
        enabled: false,
        bg: disabledBg,
        fg: disabledFg,
        borderColor: disabledBorder,
        onPressed: null,
        isLoading: false,
      );
    }
    if (timedIn && timedOut) {
      return _ActionButton(
        label: 'Completed for Today',
        icon: Icons.check_circle_rounded,
        enabled: false,
        bg: disabledBg,
        fg: disabledFg,
        borderColor: disabledBorder,
        onPressed: null,
        isLoading: false,
      );
    }
    if (timedIn && !timedOut) {
      return _ActionButton(
        label: isLoading ? 'Processing...' : 'Time Out',
        icon: Icons.logout_rounded,
        enabled: !isLoading,
        bg: defaultBg,
        fg: defaultFg,
        borderColor: defaultBorder,
        onPressed: onTimeOut,
        isLoading: isLoading,
      );
    }
    return _ActionButton(
      label: isLoading ? 'Processing...' : 'Time In',
      icon: Icons.login_rounded,
      enabled: !isLoading,
      bg: defaultBg,
      fg: defaultFg,
      borderColor: defaultBorder,
      onPressed: onTimeIn,
      isLoading: isLoading,
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _fmtHours(double h) {
    final hh = h.floor();
    final mm = ((h - hh) * 60).round();
    if (mm == 0) return '${hh}h';
    return '${hh}h ${mm}m';
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color bg;
  final Color fg;
  final Color borderColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.bg,
    required this.fg,
    required this.borderColor,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: bg,
        foregroundColor: fg,
        disabledForegroundColor: fg,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}

// ── Small pill label ──────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Time chip ─────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final String label;
  final DateTime? time;
  final String? customText;
  final IconData icon;
  final bool isDark;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.icon,
    required this.isDark,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final display = customText ?? (time != null ? _fmt(time!) : '--:--');

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : theme.border.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : theme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white54 : theme.mutedText,
              size: 14,
            ),
            const SizedBox(height: 4),
            Text(
              display,
              style: TextStyle(
                color: isDark ? Colors.white : theme.surfaceText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white54 : theme.mutedText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = (h % 12 == 0 ? 12 : h % 12).toString();
    return '$hour:$m $period';
  }
}
