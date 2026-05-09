// lib/widgets/admin_attendance_widgets/review_attendance_dialog.dart
//
// Modal dialog for reviewing and modifying flagged attendance records.
// Handles: Missed Clock Out (set time-out), Absent (mark present / excuse),
//          Late (adjust time-in, add excuse note).
//
// Usage:
//   await showDialog(
//     context: context,
//     builder: (_) => ReviewAttendanceDialog(
//       record: record,
//       onSaved: () => _load(page: _page),
//     ),
//   );

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_constants.dart';
import '../../services/admin_attendance_service.dart';

// ─── Palette (mirrors your existing constants) ────────────────────────────────

const _kSurface   = kSurface;
const _kBorder    = kBorder;
const _kCardBg    = kCardBg;
const _kTextDark  = kTextDark;
const _kTextMid   = kTextMid;
const _kTextLight = kTextLight;
const _kAccent    = kAccent;
const _kButtonDark = kButtonDark;

// ─── Entry point ──────────────────────────────────────────────────────────────

class ReviewAttendanceDialog extends StatefulWidget {
  const ReviewAttendanceDialog({
    super.key,
    required this.record,
    required this.onSaved,
  });

  final AdminAttendanceRecord record;
  final VoidCallback onSaved;

  @override
  State<ReviewAttendanceDialog> createState() => _ReviewAttendanceDialogState();
}

class _ReviewAttendanceDialogState extends State<ReviewAttendanceDialog>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // Shared
  late String _resolution; // 'set_timeout' | 'excuse' | 'mark_present' | 'adjust_timein' | 'no_action'
  final TextEditingController _noteCtrl = TextEditingController();

  // Missed Clock-Out
  TimeOfDay? _timeOut;

  // Late / Adjust Time-In
  TimeOfDay? _adjustedTimeIn;

  // Absent
  //String _absentAction = 'excuse'; // 'excuse' | 'mark_present'

  // ── Network ────────────────────────────────────────────────────────────────
  bool _saving = false;
  String? _saveError;

  // ── Derived helpers ────────────────────────────────────────────────────────
  bool get _isMissedClockOut =>
      widget.record.isReported && widget.record.timeOut == null;

  bool get _isAbsent =>
      (widget.record.status ?? '').toLowerCase() == 'absent';

  bool get _isLate =>
      (widget.record.status ?? '').toLowerCase() == 'late';

  String get _issueLabel {
    if (_isMissedClockOut) return 'Missed Clock-Out';
    if (_isAbsent) return 'Absent';
    if (_isLate) return 'Late';
    return 'Flagged Record';
  }

  Color get _issueColor {
    if (_isMissedClockOut) return Colors.purple;
    if (_isAbsent) return Colors.red;
    if (_isLate) return Colors.orange;
    return Colors.blue;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();

    // Pre-set sensible defaults
    if (_isMissedClockOut) {
      _resolution = 'set_timeout';
    } else if (_isAbsent) {
      _resolution = 'excuse';
    } else if (_isLate) {
      _resolution = 'adjust_timein';
    } else {
      _resolution = 'no_action';
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Extra validation
    if (_resolution == 'set_timeout' && _timeOut == null) {
      setState(() => _saveError = 'Please select a time-out.');
      return;
    }
    if (_resolution == 'adjust_timein' && _adjustedTimeIn == null) {
      setState(() => _saveError = 'Please select the corrected time-in.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    final result = await AdminAttendanceService.resolveAttendanceIssue(
      recordId: widget.record.id,
      resolution: _resolution,
      timeOut: _timeOut,
      adjustedTimeIn: _adjustedTimeIn,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;

    if (result['ok'] == true) {
      widget.onSaved();
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _saveError = result['error'] as String? ?? 'An error occurred.';
      });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: _kSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: SizedBox(
            width: 560,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  _buildRecordSummary(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildResolutionSection(),
                          const SizedBox(height: 16),
                          _buildNoteField(),
                          if (_saveError != null) ...[
                            const SizedBox(height: 12),
                            _buildErrorBanner(),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: const BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Issue icon pill
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _issueColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isMissedClockOut
                  ? Icons.flag_rounded
                  : _isAbsent
                      ? Icons.person_off_rounded
                      : Icons.schedule_rounded,
              color: _issueColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review Attendance Report',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _IssuePill(label: _issueLabel, color: _issueColor),
                  ],
                ),
              ],
            ),
          ),
          // Close
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Cancel',
            style: IconButton.styleFrom(
              foregroundColor: _kTextLight,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Record summary ────────────────────────────────────────────────────────

  Widget _buildRecordSummary() {
    final r = widget.record;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.person_outline_rounded,
            label: 'Employee',
            value: r.internName,
          ),
          const _SummaryDivider(),
          _SummaryRow(
            icon: Icons.badge_outlined,
            label: 'ID',
            value: r.userId.toString(),
          ),
          const _SummaryDivider(),
          _SummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: r.date,
          ),
          const _SummaryDivider(),
          _SummaryRow(
            icon: Icons.login_rounded,
            label: 'Time In',
            value: r.timeIn ?? '—',
          ),
          const _SummaryDivider(),
          _SummaryRow(
            icon: Icons.logout_rounded,
            label: 'Time Out',
            value: r.timeOut ?? '—',
            valueColor: r.timeOut == null ? Colors.red.shade400 : null,
          ),
          const _SummaryDivider(),
          _SummaryRow(
            icon: Icons.info_outline_rounded,
            label: 'Status',
            value: r.status ?? '—',
            valueColor: _issueColor,
          ),
        ],
      ),
    );
  }

  // ── Resolution section ────────────────────────────────────────────────────

  Widget _buildResolutionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Resolution Action'),
        const SizedBox(height: 10),

        // ── Missed Clock-Out ──────────────────────────────────────────────
        if (_isMissedClockOut) ...[
          _ResolutionTile(
            value: 'set_timeout',
            groupValue: _resolution,
            title: 'Set Time-Out',
            subtitle: 'Manually record the employee\'s clock-out time.',
            icon: Icons.logout_rounded,
            color: Colors.purple,
            onChanged: (v) => setState(() => _resolution = v!),
          ),
          const SizedBox(height: 8),
          _ResolutionTile(
            value: 'excuse',
            groupValue: _resolution,
            title: 'Excuse / Waive',
            subtitle: 'Mark the missed clock-out as excused with a note.',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.teal,
            onChanged: (v) => setState(() => _resolution = v!),
          ),
          if (_resolution == 'set_timeout') ...[
            const SizedBox(height: 14),
            _TimePicker(
              label: 'Clock-Out Time',
              selected: _timeOut,
              onPick: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (t != null) setState(() => _timeOut = t);
              },
            ),
          ],
        ],

        // ── Absent ───────────────────────────────────────────────────────
        if (_isAbsent) ...[
          _ResolutionTile(
            value: 'excuse',
            groupValue: _resolution,
            title: 'Excuse Absence',
            subtitle: 'Mark as excused (e.g. sick leave, approved leave).',
            icon: Icons.event_available_rounded,
            color: Colors.blue,
            onChanged: (v) => setState(() => _resolution = v!),
          ),
          const SizedBox(height: 8),
          _ResolutionTile(
            value: 'mark_present',
            groupValue: _resolution,
            title: 'Mark as Present',
            subtitle: 'Override to present if absence was a system error.',
            icon: Icons.how_to_reg_rounded,
            color: Colors.green,
            onChanged: (v) => setState(() => _resolution = v!),
          ),
        ],

        // ── Late ──────────────────────────────────────────────────────────
        if (_isLate) ...[
          _ResolutionTile(
            value: 'adjust_timein',
            groupValue: _resolution,
            title: 'Adjust Time-In',
            subtitle: 'Correct an erroneous clock-in time.',
            icon: Icons.edit_calendar_rounded,
            color: Colors.orange,
            onChanged: (v) => setState(() => _resolution = v!),
          ),
          const SizedBox(height: 8),
          _ResolutionTile(
            value: 'excuse',
            groupValue: _resolution,
            title: 'Excuse Tardiness',
            subtitle: 'Mark lateness as excused with a reason.',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.teal,
            onChanged: (v) => setState(() => _resolution = v!),
          ),
          if (_resolution == 'adjust_timein') ...[
            const SizedBox(height: 14),
            _TimePicker(
              label: 'Corrected Time-In',
              selected: _adjustedTimeIn,
              onPick: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: widget.record.timeIn != null
                      ? _parseTimeOfDay(widget.record.timeIn!)
                      : TimeOfDay.now(),
                );
                if (t != null) setState(() => _adjustedTimeIn = t);
              },
            ),
          ],
        ],

        // ── Fallback (other flagged) ───────────────────────────────────────
        if (!_isMissedClockOut && !_isAbsent && !_isLate) ...[
          _ResolutionTile(
            value: 'excuse',
            groupValue: _resolution,
            title: 'Excuse / Waive',
            subtitle: 'Mark this report as resolved with a note.',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.teal,
            onChanged: (v) => setState(() => _resolution = v!),
          ),
          const SizedBox(height: 8),
          _ResolutionTile(
            value: 'no_action',
            groupValue: _resolution,
            title: 'No Action',
            subtitle: 'Acknowledge without making changes.',
            icon: Icons.remove_circle_outline_rounded,
            color: _kTextLight,
            onChanged: (v) => setState(() => _resolution = v!),
          ),
        ],
      ],
    );
  }

  // ── Note field ────────────────────────────────────────────────────────────

  Widget _buildNoteField() {
    final required = _resolution == 'excuse' ||
        _resolution == 'mark_present' ||
        _resolution == 'adjust_timein';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel('Admin Note'),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '(required)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              const Text(
                '(optional)',
                style: TextStyle(fontSize: 11, color: _kTextLight),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteCtrl,
          maxLines: 3,
          maxLength: 300,
          inputFormatters: [LengthLimitingTextInputFormatter(300)],
          decoration: InputDecoration(
            hintText: required
                ? 'Provide a reason for this action…'
                : 'Add an optional remark…',
            hintStyle: const TextStyle(color: _kTextLight, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF7F8FC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _kAccent, width: 1.5),
            ),
            counterStyle:
                const TextStyle(color: _kTextLight, fontSize: 11),
          ),
          style: const TextStyle(fontSize: 13, color: _kTextDark),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a reason.'
                  : null
              : null,
        ),
      ],
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade500, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _saveError!,
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: const BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: _kTextMid,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),

          // Save
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kButtonDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kButtonDark.withValues(alpha: 0.5),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(
                _saving ? 'Saving…' : 'Save Resolution',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  TimeOfDay _parseTimeOfDay(String hhmm) {
    // Expects "HH:mm" or "h:mm AM/PM"
    try {
      final parts = hhmm.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0].trim()),
        minute: int.parse(parts[1].trim().substring(0, 2)),
      );
    } catch (_) {
      return TimeOfDay.now();
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _IssuePill extends StatelessWidget {
  const _IssuePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _kTextMid,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _kTextLight),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _kTextLight)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _kTextDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: _kBorder);
}

class _ResolutionTile extends StatelessWidget {
  const _ResolutionTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ValueChanged<String?> onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _selected
              ? color.withValues(alpha: 0.07)
              : const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selected ? color.withValues(alpha: 0.5) : _kBorder,
            width: _selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _selected
                    ? color.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon,
                  size: 17,
                  color: _selected ? color : _kTextLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _selected ? color : _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: _kTextLight),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: color,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.selected,
    required this.onPick,
  });

  final String label;
  final TimeOfDay? selected;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected != null ? _kAccent : _kBorder,
                width: selected != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 16,
                    color: selected != null ? _kAccent : _kTextLight),
                const SizedBox(width: 10),
                Text(
                  selected != null
                      ? selected!.format(context)
                      : 'Tap to select time…',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected != null ? _kTextDark : _kTextLight,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: _kTextLight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}