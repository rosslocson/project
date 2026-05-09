// lib/widgets/admin_attendance_widgets/report_issue_dialog.dart
//
// Bottom-sheet modal that lets an intern (or admin) flag an issue on a
// Late / Missed Clock Out / Absent record.
// Call via:  ReportIssueDialog.show(context, record, onReported: () { … });

import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_constants.dart';
import '../../services/admin_attendance_service.dart';
import '../../services/attendance_service.dart';

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

    // ✅ Uses the intern-facing endpoint, not the admin service
    final result = await AttendanceService.reportMissedClockOut(
      widget.record.id.toString(),
      reason: reason, // pass reason if your service supports it,
      // otherwise just the id
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
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title + current status chip
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Report an Issue',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
              ),
              _StatusChip(status: widget.record.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.record.internName} · ${widget.record.formattedDate}',
            style: const TextStyle(fontSize: 13, color: kTextMid),
          ),
          const SizedBox(height: 20),

          // Quick-reason chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              final selected = _selectedPreset == p;
              return ChoiceChip(
                label: Text(p),
                selected: selected,
                onSelected: (_) => setState(() {
                  _selectedPreset = selected ? null : p;
                  if (!selected) {
                    _controller.text = p == 'Other' ? '' : p;
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                  }
                }),
                selectedColor: kAccent.withOpacity(0.15),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? kAccent : kTextMid,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: selected ? kAccent : Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Free-text reason
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Describe the issue in detail…',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kAccent),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Submit Report',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
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
    final color = switch (status) {
      'Late' => const Color(0xFFF59E0B),
      'Missed Clock Out' => const Color(0xFFEA580C),
      _ => const Color(0xFFEF4444),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
