// lib/widgets/admin_attendance_widgets/review_report_sheet.dart
//
// Bottom-sheet for the admin to review a flagged attendance record.
// Admin can override the status, set a corrected time-out, write a remark,
// and mark the report resolved — all in one action.
//
// Usage:
//   ReviewReportSheet.show(context, record, onResolved: () { … });

import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_constants.dart';
import '../../services/admin_attendance_service.dart';

class ReviewReportSheet extends StatefulWidget {
  final AdminAttendanceRecord record;
  final VoidCallback? onResolved;

  const ReviewReportSheet({
    super.key,
    required this.record,
    this.onResolved,
  });

  static Future<void> show(
    BuildContext context,
    AdminAttendanceRecord record, {
    VoidCallback? onResolved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReviewReportSheet(record: record, onResolved: onResolved),
    );
  }

  @override
  State<ReviewReportSheet> createState() => _ReviewReportSheetState();
}

class _ReviewReportSheetState extends State<ReviewReportSheet> {
  static const _statusOptions = [
    'Present',
    'Late',
    'Absent',
    'Missed Clock Out',
    'On Shift',
  ];

  late String _selectedStatus;
  final _remarkCtrl = TextEditingController();
  DateTime? _correctedTimeOut;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.record.status;
    _remarkCtrl.text = widget.record.remark ?? '';
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await AdminAttendanceService.resolveReport(
      widget.record.id,
      newStatus:
          _selectedStatus != widget.record.status ? _selectedStatus : null,
      remark: _remarkCtrl.text.trim(),
      correctedTimeOut: _correctedTimeOut,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['ok'] == true) {
      Navigator.pop(context);
      widget.onResolved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report resolved successfully.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } else {
      setState(
          () => _error = result['error'] as String? ?? 'Failed to resolve');
    }
  }

  Future<void> _pickCorrectedTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null || !mounted) return;
    final now = DateTime.now();
    setState(() {
      _correctedTimeOut =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final r = widget.record;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
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

            // Header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Review Report',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r.internName} · ${r.formattedDate}',
              style: const TextStyle(fontSize: 13, color: kTextMid),
            ),
            const SizedBox(height: 20),

            // Reported reason card
            if (r.reportReason != null) ...[
              _Label('Reported Issue'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reportReason!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF92400E)),
                    ),
                    if (r.reportedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Reported: ${r.reportedAt}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFB45309)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Current status
            _Label('Current Status'),
            Text(
              r.status,
              style: const TextStyle(
                  fontSize: 13,
                  color: kTextDark,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Override status
            _Label('Override Status'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.map((s) {
                final sel = _selectedStatus == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: sel,
                  onSelected: (_) => setState(() => _selectedStatus = s),
                  selectedColor: kAccent.withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: sel ? kAccent : kTextMid,
                    fontWeight:
                        sel ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: sel ? kAccent : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Corrected time-out
            if (_selectedStatus == 'Missed Clock Out' ||
                r.status == 'Missed Clock Out') ...[
              _Label('Set Corrected Time Out'),
              InkWell(
                onTap: _pickCorrectedTime,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 18, color: kTextMid),
                      const SizedBox(width: 10),
                      Text(
                        _correctedTimeOut != null
                            ? TimeOfDay.fromDateTime(_correctedTimeOut!)
                                .format(context)
                            : 'Tap to pick time',
                        style: TextStyle(
                          fontSize: 13,
                          color: _correctedTimeOut != null
                              ? kTextDark
                              : kTextMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Remark
            _Label('Remark (visible in table)'),
            TextField(
              controller: _remarkCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'e.g. Excused – provided valid documentation',
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
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _submitting ? null : _resolve,
                    style: FilledButton.styleFrom(
                      backgroundColor: kAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Resolve & Save',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kTextMid,
            letterSpacing: 0.6,
          ),
        ),
      );
}