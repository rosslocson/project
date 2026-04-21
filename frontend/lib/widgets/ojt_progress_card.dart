// lib/widgets/ojt_progress_card.dart
//
// Reusable card showing total OJT hours, required hours, and a progress bar.

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';

class OjtProgressCard extends StatelessWidget {
  final AttendanceSummary summary;

  const OjtProgressCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = summary.progressPercent;
    final color = _progressColor(pct);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF460A14).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFF460A14),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'OJT Hours Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (summary.isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Complete!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Stats row ───────────────────────────────────────────────────
          Row(
            children: [
              _StatChip(
                label: 'Rendered',
                value: _fmtHours(summary.totalHoursRendered),
                color: const Color(0xFF460A14),
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Required',
                value: _fmtHours(summary.requiredHours),
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Remaining',
                value: _fmtHours(summary.remainingHours),
                color: color,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Days',
                value: '${summary.totalDays}',
                color: Colors.blueGrey.shade600,
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
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 8),

          // ── Percentage label ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).toStringAsFixed(1)}% completed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_fmtHours(summary.totalHoursRendered)} / ${_fmtHours(summary.requiredHours)} hrs',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _progressColor(double pct) {
    if (pct >= 1.0) return Colors.green.shade600;
    if (pct >= 0.75) return Colors.blue.shade600;
    if (pct >= 0.5) return const Color(0xFF460A14);
    return Colors.orange.shade600;
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

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}