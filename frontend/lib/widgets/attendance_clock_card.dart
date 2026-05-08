import 'package:flutter/material.dart';
import '../models/attendance_model.dart';

class AttendanceClockCard extends StatelessWidget {
  final AttendanceSummary? summary;
  final bool isLoading;
  final VoidCallback onTimeIn;
  final VoidCallback onTimeOut;
  final bool isOjtComplete; // ← NEW: true when required OJT hours are fulfilled

  const AttendanceClockCard({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.onTimeIn,
    required this.onTimeOut,
    this.isOjtComplete = false, // ← defaults to false
  });

  @override
  Widget build(BuildContext context) {
    final today = summary?.todayRecord;
    final timedIn = today?.hasTimedIn ?? false;
    final timedOut = today?.hasTimedOut ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00022E), Color(0xFF1A1F5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00022E).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.today_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                _todayLabel(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Weekend indicator pill
              if (_isWeekend) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'Weekend – No Attendance',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              // ── OJT Complete pill ──────────────────────────────────────
              if (isOjtComplete) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'OJT Complete',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ── Time In / Out info ─────────────────────────────────────────
          Row(
            children: [
              _TimeChip(
                label: 'Time In',
                time: today?.timeIn,
                icon: Icons.login_rounded,
              ),
              const SizedBox(width: 12),
              _TimeChip(
                label: 'Time Out',
                time: today?.timeOut,
                icon: Icons.logout_rounded,
              ),
              const SizedBox(width: 12),
              _TimeChip(
                label: "Today's Hours",
                time: null,
                // ── Use lunch-adjusted hours ───────────────────────────
                customText: today?.timeIn != null
                    ? (today?.timeOut != null
                        ? _fmtHours(
                            _adjustedHours(today!.timeIn!, today.timeOut!))
                        : 'Ongoing')
                    : '--',
                icon: Icons.access_time_rounded,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Action Button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _buildButton(
              context,
              timedIn: timedIn,
              timedOut: timedOut,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isWeekend {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Computes worked hours between [timeIn] and [timeOut],
  /// deducting the 1-hour lunch break if the window overlaps 12:00–13:00.
  double _adjustedHours(DateTime timeIn, DateTime timeOut) {
    final totalMinutes = timeOut.difference(timeIn).inMinutes.toDouble();

    // Build today's lunch window: 12:00 PM – 1:00 PM
    final lunchStart = DateTime(
        timeIn.year, timeIn.month, timeIn.day, 12, 0);
    final lunchEnd = DateTime(
        timeIn.year, timeIn.month, timeIn.day, 13, 0);

    // Overlap = max(0, min(timeOut, lunchEnd) - max(timeIn, lunchStart))
    final overlapStart =
        timeIn.isAfter(lunchStart) ? timeIn : lunchStart;
    final overlapEnd =
        timeOut.isBefore(lunchEnd) ? timeOut : lunchEnd;

    double deductMinutes = 0;
    if (overlapEnd.isAfter(overlapStart)) {
      deductMinutes = overlapEnd.difference(overlapStart).inMinutes.toDouble();
    }

    final workedMinutes = totalMinutes - deductMinutes;
    return workedMinutes / 60.0;
  }

  Widget _buildButton(
    BuildContext context, {
    required bool timedIn,
    required bool timedOut,
  }) {
    // ── OJT Complete guard — block all clocking ────────────────────────
    if (isOjtComplete) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.verified_rounded),
        label: const Text('OJT Hours Completed'),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.greenAccent.withValues(alpha: 0.12),
          disabledForegroundColor: Colors.greenAccent.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3)),
          ),
        ),
      );
    }

    // ── Weekend guard ──────────────────────────────────────────────────
    if (_isWeekend) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.weekend_rounded),
        label: const Text('No Attendance on Weekends'),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
          disabledForegroundColor: Colors.white60,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
        ),
      );
    }

    // Already timed out for today
    if (timedIn && timedOut) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Completed for Today'),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
          disabledForegroundColor: Colors.white60,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
        ),
      );
    }

    // Time Out button
    if (timedIn && !timedOut) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onTimeOut,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF00022E)),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(isLoading ? 'Processing...' : 'Time Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF00022E),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      );
    }

    // Time In button
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onTimeIn,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF00022E)),
            )
          : const Icon(Icons.login_rounded),
      label: Text(isLoading ? 'Processing...' : 'Time In'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00022E),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _fmtHours(double h) {
    final hh = h.floor();
    final mm = ((h - hh) * 60).round();
    if (mm == 0) return '${hh}h';
    return '${hh}h ${mm}m';
  }
}

// ── Small chip showing a labelled time ──────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final String label;
  final DateTime? time;
  final String? customText;
  final IconData icon;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.icon,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final display = customText ?? (time != null ? _fmt(time!) : '--:--');

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(height: 4),
            Text(
              display,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
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