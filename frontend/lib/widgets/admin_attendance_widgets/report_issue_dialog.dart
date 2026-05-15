// lib/widgets/admin_attendance_widgets/report_issue_dialog.dart
//
// Bottom-sheet modal that lets an intern (or admin) flag an issue on a
// Late / Missed Clock Out / Absent record.
// Call via:  ReportIssueDialog.show(context, record, onReported: () { … });

import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_service.dart';

// ── Theme constants matching MyProfileScreen / ProfileLeftPanel dark blue ──
const _kSheetBg     = Color(0xFF0B132B);   // card dark blue
const _kSheetDeep   = Color(0xFF060A17);   // card darker blue
const _kAccentBlue  = Color(0xFF4F8EF7);   // readable accent on dark bg
const _kTextPrimary = Color(0xFFFFFFFF);   // white headings
const _kTextSub     = Color(0xFFB0BAD3);   // muted body text
const _kBorderBlue  = Color(0xFF1E2D50);   // subtle border

class ReportIssueDialog extends StatefulWidget {
  final AdminAttendanceRecord record;
  final VoidCallback? onReported;

  const ReportIssueDialog({
    super.key,
    required this.record,
    this.onReported,
  });

  static Future<void> show(
    BuildContext context,
    AdminAttendanceRecord record, {
    VoidCallback? onReported,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportIssueDialog(record: record, onReported: onReported),
    );
  }

  @override
  State<ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<ReportIssueDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _selectedPreset;

  static const _presets = [
    'Internet / power outage',
    'Device issue',
    'Medical / health emergency',
    'Family emergency',
    'Transportation delay',
    'System clock error',
    'Forgot to clock in / out',
    'Other',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Please describe the issue.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await AttendanceService.reportMissedClockOut(
      widget.record.id.toString(),
      reason: reason,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['ok'] == true) {
      Navigator.pop(context);
      widget.onReported?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue reported. Admin will review it shortly.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } else {
      setState(() => _error = result['error'] as String? ?? 'Failed to report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dark header band ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: const BoxDecoration(
              color: _kSheetDeep,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _kBorderBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title + status chip
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Report an Issue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                        ),
                      ),
                    ),
                    _StatusChip(status: widget.record.status),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.record.internName} · ${widget.record.formattedDate}',
                  style: const TextStyle(fontSize: 13, color: _kTextSub),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section label
                const Text(
                  'QUICK REASON',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _kTextSub,
                  ),
                ),
                const SizedBox(height: 10),

                // Quick-reason chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((p) {
                    final selected = _selectedPreset == p;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedPreset = selected ? null : p;
                        if (!selected) {
                          _controller.text = p == 'Other' ? '' : p;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: _controller.text.length),
                          );
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? _kAccentBlue.withOpacity(0.18)
                              : _kSheetDeep,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? _kAccentBlue : _kBorderBlue,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? _kAccentBlue : _kTextSub,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Section label
                const Text(
                  'DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _kTextSub,
                  ),
                ),
                const SizedBox(height: 10),

                // Free-text reason
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  maxLength: 300,
                  style: const TextStyle(
                      fontSize: 13, color: _kTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue in detail…',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: _kTextSub),
                    errorText: _error,
                    errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
                    counterStyle:
                        const TextStyle(color: _kTextSub, fontSize: 11),
                    filled: true,
                    fillColor: _kSheetDeep,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _kBorderBlue),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _kBorderBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: _kAccentBlue, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFFF6B6B)),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccentBlue,
                      disabledBackgroundColor:
                          _kAccentBlue.withOpacity(0.4),
                      padding:
                          const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color border, Color text, Color bg) = switch (status) {
      'Late' => (
          const Color(0xFFF59E0B),
          const Color(0xFFF59E0B),
          const Color(0xFFF59E0B).withOpacity(0.15),
        ),
      'Missed Clock Out' => (
          const Color(0xFFEA580C),
          const Color(0xFFEA580C),
          const Color(0xFFEA580C).withOpacity(0.15),
        ),
      _ => (
          const Color(0xFFEF4444),
          const Color(0xFFEF4444),
          const Color(0xFFEF4444).withOpacity(0.15),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 11, color: text, fontWeight: FontWeight.w700),
      ),
    );
  }
}