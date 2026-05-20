// lib/widgets/admin_attendance_widgets/review_report_sheet.dart

import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_constants.dart';
import '../../services/admin_attendance_service.dart';
import '../app_theme.dart';

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
      builder: (_) => ReviewReportSheet(record: record, onResolved: onResolved),
    );
  }

  @override
  State<ReviewReportSheet> createState() => _ReviewReportSheetState();
}

class _ResolutionOption {
  final String value;
  final String label;
  final String hint;
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
      value: 'excused_credited',
      label: 'Excused – Credited',
      hint: 'Excuse the issue; day counts toward required hours',
      icon: Icons.verified_rounded,
    ),
    _ResolutionOption(
      value: 'excused_uncredited',
      label: 'Excused – Uncredited',
      hint: 'Excuse the issue; day does not count toward hours',
      icon: Icons.remove_circle_outline_rounded,
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
  TimeOfDay? _creditedTimeIn;
  TimeOfDay? _creditedTimeOut;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedResolution = widget.record.status == 'Missed Clock Out'
        ? 'set_timeout'
        : 'excused_credited';
    _creditedTimeIn  = const TimeOfDay(hour: 8, minute: 0);
    _creditedTimeOut = const TimeOfDay(hour: 17, minute: 0);
  }

  // ── Theme builder — mirrors custom_date_picker_dialog._theme ──────────────
  // Passed to showTimePicker/showDatePicker so the native dialog matches
  // the app's dark/light scheme exactly.

  Widget _pickerTheme(BuildContext ctx, Widget? child, bool isDark, Color accentColor) {
    if (isDark) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: accentColor,           // selected ring / header bg
            onPrimary: Colors.white,         // text on selected
            surface: const Color(0xFF0E0E12), // dialog bg
            onSurface: Colors.white,
            surfaceContainerHighest: const Color(0xFF18181E), // input field bg
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: const Color(0xFF0E0E12),
            hourMinuteColor: const Color(0xFF18181E),
            hourMinuteTextColor: Colors.white,
            dayPeriodColor: const Color(0xFF18181E),
            dayPeriodTextColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.white60,
            ),
            dialBackgroundColor: const Color(0xFF18181E),
            dialHandColor: accentColor,
            dialTextColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.white70,
            ),
            entryModeIconColor: Colors.white54,
            helpTextStyle: const TextStyle(color: Colors.white54, fontSize: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: accentColor),
          ),
        ),
        child: child!,
      );
    }

    // ── Light mode ────────────────────────────────────────────────────────
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: ColorScheme.light(
          primary: accentColor,             // selected ring / header bg
          onPrimary: Colors.white,           // text on selected
          surface: Colors.white,             // dialog bg
          onSurface: kTextDark,
          surfaceContainerHighest: const Color(0xFFF4F5F8), // input field bg
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          hourMinuteColor: const Color(0xFFF4F5F8),
          hourMinuteTextColor: kTextDark,
          dayPeriodColor: const Color(0xFFF4F5F8),
          dayPeriodTextColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? accentColor
                : kTextMid,
          ),
          dialBackgroundColor: const Color(0xFFF4F5F8),
          dialHandColor: accentColor,
          dialTextColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : kTextDark,
          ),
          entryModeIconColor: kTextMid,
          helpTextStyle: const TextStyle(color: kTextMid, fontSize: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accentColor),
        ),
      ),
      child: child!,
    );
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? get _validationError {
    if (_selectedResolution == 'set_timeout' && _timeOut == null) {
      return 'Please pick a time-out before saving.';
    }
    if (_selectedResolution == 'excused_credited') {
      if (_creditedTimeIn == null)  return 'Please pick a time-in for credited excusal.';
      if (_creditedTimeOut == null) return 'Please pick a time-out for credited excusal.';
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
    setState(() { _submitting = true; _error = null; });

    final result = await AdminAttendanceService.resolveAttendanceIssue(
      recordId: widget.record.id,
      resolution: _selectedResolution,
      timeOut: _selectedResolution == 'set_timeout'
          ? _timeOut
          : _selectedResolution == 'excused_credited'
              ? _creditedTimeOut
              : null,
      adjustedTimeIn: _selectedResolution == 'adjust_timein' ? _adjustedTimeIn : null,
      creditedTimeIn: _selectedResolution == 'excused_credited' ? _creditedTimeIn : null,
      note: null,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['ok'] != true) {
      setState(() => _error = result['error'] as String? ?? 'An error occurred.');
      return;
    }

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

  // ── Time pickers — all pass _pickerTheme as builder ───────────────────────

  Future<void> _pickTimeOut(bool isDark, Color accent) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOut ?? const TimeOfDay(hour: 17, minute: 0),
      builder: (ctx, child) => _pickerTheme(ctx, child, isDark, accent),
    );
    if (picked != null && mounted) setState(() => _timeOut = picked);
  }

  Future<void> _pickAdjustedTimeIn(bool isDark, Color accent) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _adjustedTimeIn ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => _pickerTheme(ctx, child, isDark, accent),
    );
    if (picked != null && mounted) setState(() => _adjustedTimeIn = picked);
  }

  Future<void> _pickCreditedTimeIn(bool isDark, Color accent) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _creditedTimeIn ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => _pickerTheme(ctx, child, isDark, accent),
    );
    if (picked != null && mounted) setState(() => _creditedTimeIn = picked);
  }

  Future<void> _pickCreditedTimeOut(bool isDark, Color accent) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _creditedTimeOut ?? const TimeOfDay(hour: 17, minute: 0),
      builder: (ctx, child) => _pickerTheme(ctx, child, isDark, accent),
    );
    if (picked != null && mounted) setState(() => _creditedTimeOut = picked);
  }

  // ── Excused helpers ────────────────────────────────────────────────────────

  bool get _isExcusedCredited   => _selectedResolution == 'excused_credited';
  bool get _isExcusedUncredited => _selectedResolution == 'excused_uncredited';
  bool get _isExcused           => _isExcusedCredited || _isExcusedUncredited;

  _ExcusedColors _excusedColors(bool isDark) {
    if (_isExcusedCredited) {
      return _ExcusedColors(
        bg:     isDark ? const Color(0xFF052E16).withValues(alpha: 0.6) : const Color(0xFFECFDF5),
        border: isDark ? const Color(0xFF166534).withValues(alpha: 0.8) : const Color(0xFF6EE7B7),
        fg:     isDark ? const Color(0xFF4ADE80)                        : const Color(0xFF047857),
        icon:   Icons.verified_rounded,
        text:   'This day will count toward the intern\'s required hours. '
                'Their status will show as "Excused – Credited".',
      );
    }
    return _ExcusedColors(
      bg:     isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFFF5F3FF),
      border: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.7) : const Color(0xFFC4B5FD),
      fg:     isDark ? const Color(0xFFA78BFA)                        : const Color(0xFF6D28D9),
      icon:   Icons.remove_circle_outline_rounded,
      text:   'The absence is excused but this day will not count toward '
              'required hours. Status will show as "Excused – Uncredited".',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final theme       = Theme.of(context).extension<InternSpaceThemeColors>() ?? InternSpaceThemeColors.dark;
    final bgColor     = isDark ? const Color(0xFF0E0E12) : theme.dialogBackground;
    final accentColor = isDark ? kAccent : const Color(0xFF00022E);
    final textDark    = isDark ? Colors.white     : kTextDark;
    final textMid     = isDark ? Colors.white60   : kTextMid;
    final fieldBg     = isDark ? const Color(0xFF18181E) : const Color(0xFFF4F5F8);
    final fieldBorder = isDark ? Colors.white.withValues(alpha: 0.1) : kBorder;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : kBorder;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final r = widget.record;
    final excused = _excusedColors(isDark);

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: isDark
            ? Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))
            : null,
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
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.shade300,
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
                Text(
                  'Review Report',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r.internName} · ${r.formattedDate}',
              style: TextStyle(fontSize: 13, color: textMid),
            ),
            const SizedBox(height: 20),

            // ── Report reason ─────────────────────────────────────────
            if (r.reportReason != null && r.reportReason!.isNotEmpty) ...[
              _Label('Intern\'s Reported Reason', textMid),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B2F00).withValues(alpha: 0.4)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                        : const Color(0xFFFCD34D),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.flag_rounded, size: 14,
                              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.reportReason!,
                            style: TextStyle(
                              fontSize: 13, height: 1.5,
                              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (r.reportedAt != null) ...[
                      const SizedBox(height: 8),
                      Divider(height: 1,
                          color: isDark
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                              : const Color(0xFFFCD34D)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 11,
                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                          const SizedBox(width: 4),
                          Text('Reported: ${r.reportedAt}',
                              style: TextStyle(fontSize: 11,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Current status ────────────────────────────────────────
            _Label('Current Status', textMid),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: fieldBorder),
              ),
              child: Text(r.status,
                  style: TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w600)),
            ),

            // ── Resolution selector ───────────────────────────────────
            _Label('Resolution Action', textMid),
            ...(_options.map((opt) => _ResolutionTile(
                  option: opt,
                  selected: _selectedResolution == opt.value,
                  isDark: isDark,
                  accentColor: accentColor,
                  textDark: textDark,
                  textMid: textMid,
                  fieldBg: fieldBg,
                  fieldBorder: fieldBorder,
                  onTap: () => setState(() { _selectedResolution = opt.value; _error = null; }),
                ))),

            // ── Excused callout ───────────────────────────────────────
            if (_isExcused) ...[
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: excused.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: excused.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(excused.icon, size: 14, color: excused.fg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(excused.text,
                          style: TextStyle(fontSize: 12, height: 1.45, color: excused.fg)),
                    ),
                  ],
                ),
              ),
            ],

            // ── Excused – Credited time pickers ───────────────────────
            if (_isExcusedCredited) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Time In', textMid),
                        _TimePicker(
                          time: _creditedTimeIn,
                          placeholder: 'Set time in',
                          onTap: () => _pickCreditedTimeIn(isDark, accentColor),
                          hasError: _error != null && _creditedTimeIn == null,
                          isDark: isDark,
                          accentColor: accentColor,
                          textDark: textDark,
                          textMid: textMid,
                          fieldBg: fieldBg,
                          fieldBorder: fieldBorder,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Time Out', textMid),
                        _TimePicker(
                          time: _creditedTimeOut,
                          placeholder: 'Set time out',
                          onTap: () => _pickCreditedTimeOut(isDark, accentColor),
                          hasError: _error != null && _creditedTimeOut == null,
                          isDark: isDark,
                          accentColor: accentColor,
                          textDark: textDark,
                          textMid: textMid,
                          fieldBg: fieldBg,
                          fieldBorder: fieldBorder,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // ── Set Time-Out picker ───────────────────────────────────
            if (_selectedResolution == 'set_timeout') ...[
              _Label('Corrected Time Out', textMid),
              _TimePicker(
                time: _timeOut,
                placeholder: 'Tap to set time out',
                onTap: () => _pickTimeOut(isDark, accentColor),
                hasError: _error != null && _timeOut == null,
                isDark: isDark,
                accentColor: accentColor,
                textDark: textDark,
                textMid: textMid,
                fieldBg: fieldBg,
                fieldBorder: fieldBorder,
              ),
              const SizedBox(height: 20),
            ],

            // ── Adjust Time-In picker ─────────────────────────────────
            if (_selectedResolution == 'adjust_timein') ...[
              _Label('Corrected Time In', textMid),
              _TimePicker(
                time: _adjustedTimeIn,
                placeholder: 'Tap to set corrected time in',
                onTap: () => _pickAdjustedTimeIn(isDark, accentColor),
                hasError: _error != null && _adjustedTimeIn == null,
                isDark: isDark,
                accentColor: accentColor,
                textDark: textDark,
                textMid: textMid,
                fieldBg: fieldBg,
                fieldBorder: fieldBorder,
              ),
              const SizedBox(height: 20),
            ],

            // ── Inline error ──────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF450A0A).withValues(alpha: 0.6)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.red.withValues(alpha: 0.4) : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 14,
                        color: isDark ? Colors.red.shade300 : Colors.red.shade500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                          )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Divider ───────────────────────────────────────────────
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 20),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textMid,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: fieldBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancel',
                        style: TextStyle(color: textMid, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _submitting ? null : _resolve,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Resolve & Save',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
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

// ── Excused color bundle ───────────────────────────────────────────────────

class _ExcusedColors {
  final Color bg, border, fg;
  final IconData icon;
  final String text;
  const _ExcusedColors({
    required this.bg, required this.border, required this.fg,
    required this.icon, required this.text,
  });
}

// ── Resolution tile ────────────────────────────────────────────────────────

class _ResolutionTile extends StatelessWidget {
  final _ResolutionOption option;
  final bool selected;
  final bool isDark;
  final Color accentColor, textDark, textMid, fieldBg, fieldBorder;
  final VoidCallback onTap;

  const _ResolutionTile({
    required this.option, required this.selected, required this.isDark,
    required this.accentColor, required this.textDark, required this.textMid,
    required this.fieldBg, required this.fieldBorder, required this.onTap,
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
          color: selected ? accentColor.withValues(alpha: isDark ? 0.15 : 0.07) : fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accentColor : fieldBorder, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(option.icon, size: 18, color: selected ? accentColor : textMid),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: selected ? accentColor : textDark)),
                  Text(option.hint, style: TextStyle(fontSize: 11, color: textMid)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, size: 18, color: accentColor),
          ],
        ),
      ),
    );
  }
}

// ── Time picker tile — matches _DatePickerTile layout exactly ─────────────
// Uses a GestureDetector + Container (no InkWell) so fieldBg is always
// visible and the border/text/icon colors all respect isDark.

class _TimePicker extends StatelessWidget {
  final TimeOfDay? time;
  final String placeholder;
  final VoidCallback onTap;
  final bool hasError;
  final bool isDark;
  final Color accentColor, textDark, textMid, fieldBg, fieldBorder;

  const _TimePicker({
    required this.time,
    required this.placeholder,
    required this.onTap,
    this.hasError = false,
    required this.isDark,
    required this.accentColor,
    required this.textDark,
    required this.textMid,
    required this.fieldBg,
    required this.fieldBorder,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor  = isDark ? Colors.red.shade300 : Colors.red.shade600;
    final borderColor = hasError ? errorColor : fieldBorder;
    final iconColor   = hasError
        ? errorColor
        : isDark
            ? Colors.white38
            : accentColor.withValues(alpha: 0.6);
    final valueColor  = time != null ? textDark : (hasError ? errorColor : textMid);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          // ← same fieldBg as _DatePickerTile: dark = 0xFF18181E, light = 0xFFF4F5F8
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            // thicker border when there's an error, same as date picker selected state
            width: hasError ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Clock icon — mirrors the calendar icon position in _DatePickerTile
            Icon(Icons.access_time_rounded, size: 16, color: iconColor),
            const SizedBox(width: 10),
            // Vertical divider — matches _DatePickerTile separator
            const VerticalDivider(width: 1, thickness: 1, color: kBorder),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                time != null ? time!.format(context) : placeholder,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
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
  final Color color;
  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: color, letterSpacing: 0.6,
          ),
        ),
      );
}