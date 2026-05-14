// lib/widgets/admin_attendance_widgets/review_report_sheet.dart

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

// Each resolution option shown in the UI
class _ResolutionOption {
  final String value; // sent to backend
  final String label; // shown in chip
  final String hint; // subtitle under chip
  final IconData icon;

  const _ResolutionOption({
    required this.value,
    required this.label,
    required this.hint,
    required this.icon,
  });
}

class _ReviewReportSheetState extends State<ReviewReportSheet> {
  static const _options = [
    _ResolutionOption(
      value: 'set_timeout',
      label: 'Set Time Out',
      hint: 'Manually enter the missing clock-out time',
      icon: Icons.schedule_rounded,
    ),
    _ResolutionOption(
      value: 'mark_present',
      label: 'Mark Present',
      hint: 'Treat as full day (8 AM – 5 PM)',
      icon: Icons.check_circle_outline_rounded,
    ),
    _ResolutionOption(
      value: 'adjust_timein',
      label: 'Adjust Time In',
      hint: 'Correct an erroneous clock-in time',
      icon: Icons.login_rounded,
    ),
    _ResolutionOption(
      value: 'excuse',
      label: 'Excuse',
      hint: 'Accept the report with a note, no time change',
      icon: Icons.thumb_up_alt_outlined,
    ),
    _ResolutionOption(
      value: 'no_action',
      label: 'No Action',
      hint: 'Dismiss the report without changes',
      icon: Icons.block_rounded,
    ),
  ];

  String _selectedResolution = 'set_timeout';
  TimeOfDay? _timeOut;
  TimeOfDay? _adjustedTimeIn;

  // Pre-populate the note field with the existing remark so the admin
  // can see and edit whatever was already there.
  late final TextEditingController _noteCtrl;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill note with existing remark (if any) so admin keeps context
    _noteCtrl = TextEditingController(text: widget.record.remark ?? '');

    // Default resolution based on status
    _selectedResolution =
        widget.record.status == 'Missed Clock Out' ? 'set_timeout' : 'excuse';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? get _validationError {
    if (_selectedResolution == 'set_timeout' && _timeOut == null) {
      return 'Please pick a time-out before saving.';
    }
    if (_selectedResolution == 'adjust_timein' && _adjustedTimeIn == null) {
      return 'Please pick the corrected time-in before saving.';
    }
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _resolve() async {
    final validationErr = _validationError;
    if (validationErr != null) {
      setState(() => _error = validationErr);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final noteText = _noteCtrl.text.trim();

    // 1. Resolve the report (sets status, time adjustments, closes the report)
    final result = await AdminAttendanceService.resolveAttendanceIssue(
      recordId: widget.record.id,
      resolution: _selectedResolution,
      timeOut: _selectedResolution == 'set_timeout' ? _timeOut : null,
      adjustedTimeIn:
          _selectedResolution == 'adjust_timein' ? _adjustedTimeIn : null,
      note: noteText.isEmpty ? null : noteText,
    );

    if (!mounted) return;

    if (result['ok'] != true) {
      setState(() {
        _submitting = false;
        _error = result['error'] as String? ?? 'Failed to resolve';
      });
      return;
    }

    // 2. If the admin typed a note, persist it as the visible remark so it
    //    appears in the table's Remark column immediately after refresh.
    if (noteText.isNotEmpty) {
      await AdminAttendanceService.updateRemark(
        widget.record.id,
        noteText,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.pop(context);
    widget.onResolved?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report resolved successfully.'),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Time pickers ───────────────────────────────────────────────────────────

  Future<void> _pickTimeOut() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOut ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null && mounted) setState(() => _timeOut = picked);
  }

  Future<void> _pickAdjustedTimeIn() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _adjustedTimeIn ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && mounted) setState(() => _adjustedTimeIn = picked);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
            // ── Drag handle ────────────────────────────────────────────
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

            // ── Header ────────────────────────────────────────────────
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

            // ── Intern's report reason ────────────────────────────────
            // Always shown when present — this is what the intern filed.
            if (r.reportReason != null && r.reportReason!.isNotEmpty) ...[
              const _Label('Intern\'s Reported Reason'),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.flag_rounded,
                              size: 14, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.reportReason!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF92400E),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (r.reportedAt != null) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFFCD34D)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: Color(0xFFB45309)),
                          const SizedBox(width: 4),
                          Text(
                            'Reported: ${r.reportedAt}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Current status ────────────────────────────────────────
            const _Label('Current Status'),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.status,
                style: const TextStyle(
                  fontSize: 13,
                  color: kTextDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // ── Resolution selector ───────────────────────────────────
            const _Label('Resolution Action'),
            ...(_options.map((opt) => _ResolutionTile(
                  option: opt,
                  selected: _selectedResolution == opt.value,
                  onTap: () => setState(() {
                    _selectedResolution = opt.value;
                    _error = null;
                  }),
                ))),
            const SizedBox(height: 20),

            // ── Time-out picker ───────────────────────────────────────
            if (_selectedResolution == 'set_timeout') ...[
              const _Label('Corrected Time Out'),
              _TimePicker(
                time: _timeOut,
                placeholder: 'Tap to set time out',
                onTap: _pickTimeOut,
                hasError: _error != null && _timeOut == null,
              ),
              const SizedBox(height: 20),
            ],

            // ── Adjusted time-in picker ───────────────────────────────
            if (_selectedResolution == 'adjust_timein') ...[
              const _Label('Corrected Time In'),
              _TimePicker(
                time: _adjustedTimeIn,
                placeholder: 'Tap to set corrected time in',
                onTap: _pickAdjustedTimeIn,
                hasError: _error != null && _adjustedTimeIn == null,
              ),
              const SizedBox(height: 20),
            ],

            // ── Admin note / remark ───────────────────────────────────
            // This note is saved both as the resolve note AND as the
            // visible remark in the attendance table.
            const _Label('Admin Note / Remark'),
            const _FieldHint(
              'This will appear in the Remark column of the attendance table.',
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText:
                    'e.g. Confirmed with supervisor — clock-out recorded manually',
                hintStyle:
                    TextStyle(fontSize: 12, color: Colors.grey.shade400),
                errorText: _error,
                filled: true,
                fillColor: const Color(0xFFF9F9FB),
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
                  borderSide: const BorderSide(color: kAccent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
                counterStyle:
                    TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Resolve & Save',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
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

// ── Resolution tile ────────────────────────────────────────────────────────

class _ResolutionTile extends StatelessWidget {
  final _ResolutionOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ResolutionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? kAccent.withOpacity(0.07)
              : const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? kAccent : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(option.icon,
                size: 18, color: selected ? kAccent : kTextMid),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? kAccent : kTextDark,
                    ),
                  ),
                  Text(
                    option.hint,
                    style: const TextStyle(fontSize: 11, color: kTextMid),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: kAccent),
          ],
        ),
      ),
    );
  }
}

// ── Time picker display ────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  final TimeOfDay? time;
  final String placeholder;
  final VoidCallback onTap;
  final bool hasError;

  const _TimePicker({
    required this.time,
    required this.placeholder,
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError ? Colors.red : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 18,
                color: hasError ? Colors.red : kTextMid),
            const SizedBox(width: 10),
            Text(
              time != null ? time!.format(context) : placeholder,
              style: TextStyle(
                fontSize: 13,
                color: time != null
                    ? kTextDark
                    : (hasError ? Colors.red : kTextMid),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Label ──────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
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

// ── Field hint ─────────────────────────────────────────────────────────────

class _FieldHint extends StatelessWidget {
  final String text;
  const _FieldHint(this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 12, color: kTextLight),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: kTextLight),
            ),
          ),
        ],
      );
}