// lib/widgets/attendance_clock_card.dart
//
// Card with the Time In / Time Out button + today's session info.
// Stateless — parent passes in the summary and callbacks.

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';

class AttendanceClockCard extends StatelessWidget {
  final AttendanceSummary? summary;
  final bool isLoading;
  final VoidCallback onTimeIn;
  final VoidCallback onTimeOut;

  const AttendanceClockCard({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.onTimeIn,
    required this.onTimeOut,
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
          colors: [Color(0xFF460A14), Color(0xFF7B1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF460A14).withOpacity(0.35),
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
                customText: today?.hoursRendered != null
                    ? _fmtHours(today!.hoursRendered!)
                    : (timedIn && !timedOut ? 'Ongoing' : '--'),
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

  Widget _buildButton(
    BuildContext context, {
    required bool timedIn,
    required bool timedOut,
  }) {
    // Already timed out for today
    if (timedIn && timedOut) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Completed for Today'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.15),
          foregroundColor: Colors.white70,
          disabledBackgroundColor: Colors.white.withOpacity(0.1),
          disabledForegroundColor: Colors.white60,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      );
    }

    // Time Out button (already timed in, not yet timed out)
    if (timedIn && !timedOut) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onTimeOut,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF460A14),
                ),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(isLoading ? 'Processing...' : 'Time Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF460A14),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      );
    }

    // Time In button (default — no record today yet)
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onTimeIn,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF460A14),
              ),
            )
          : const Icon(Icons.login_rounded),
      label: Text(isLoading ? 'Processing...' : 'Time In'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF460A14),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
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