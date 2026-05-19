// lib/widgets/ojt_progress_card.dart
//
// Hours displayed here come from AttendanceSummary.totalHoursRendered,
// which is fetched directly from the database.

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Card widget
// ─────────────────────────────────────────────────────────────────────────────

class OjtProgressCard extends StatelessWidget {
  final AttendanceSummary summary;

  const OjtProgressCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = summary.progressPercent;
    final color = _progressColor(pct);

    return Container(
      padding: const EdgeInsets.all(20),
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
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? color.withValues(alpha: 0.15)
                      : const Color(0xFF460A14).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: isDark
                      ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                      : null,
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: isDark ? color : const Color(0xFF460A14),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'OJT Hours Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.surfaceText,
                ),
              ),
              const Spacer(),
              if (summary.isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark
                        ? Border.all(
                            color: Colors.green.withValues(alpha: 0.4), width: 1)
                        : null,
                  ),
                  child: Text(
                    'Complete!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.greenAccent : Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Stats row ────────────────────────────────────────────────────
          Row(
            children: [
              _StatChip(
                label: 'Rendered',
                value: _fmtHours(summary.totalHoursRendered),
                color: isDark ? Colors.white : const Color(0xFF460A14),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Required',
                value: _fmtHours(summary.requiredHours),
                color: theme.mutedText,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Remaining',
                value: _fmtHours(summary.remainingHours),
                color: color,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Days',
                value: '${summary.totalDays}',
                color: isDark
                    ? Colors.blueAccent.shade100
                    : Colors.blueGrey.shade600,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress bar ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : theme.formFill,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 8),

          // ── Labels ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).toStringAsFixed(1)}% completed',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_fmtHours(summary.totalHoursRendered)} / ${_fmtHours(summary.requiredHours)} hrs',
                style: TextStyle(fontSize: 12, color: theme.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _progressColor(double pct) {
    if (pct >= 1.0) return Colors.greenAccent.shade400;
    if (pct >= 0.75) return Colors.blueAccent.shade200;
    if (pct >= 0.5) return const Color(0xFF7367F0);
    return Colors.orange.shade400;
  }

  String _fmtHours(double h) {
    final hh = h.floor();
    final mm = ((h - hh) * 60).round();
    if (mm == 0) return '${hh}h';
    return '${hh}h ${mm}m';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: theme.mutedText),
          ),
        ],
      ),
    );
  }
}