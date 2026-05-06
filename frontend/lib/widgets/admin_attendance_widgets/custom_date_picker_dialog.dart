// lib/widgets/admin_attendance_widgets/custom_date_picker_dialog.dart
// Modal dialog for picking a single date or a date range.

import 'package:flutter/material.dart';

import '../../models/attendance_constants.dart';
import '../../services/date_helpers.dart';

typedef DatePickerConfirmCallback = void Function({
  required bool isRange,
  DateTime? singleDate,
  DateTime? rangeStart,
  DateTime? rangeEnd,
});

class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialSingleDate;
  final DateTime initialRangeStart;
  final DateTime initialRangeEnd;
  final bool initialIsRange;
  final DatePickerConfirmCallback onConfirm;

  const CustomDatePickerDialog({
    super.key,
    required this.initialSingleDate,
    required this.initialRangeStart,
    required this.initialRangeEnd,
    required this.initialIsRange,
    required this.onConfirm,
  });

  @override
  State<CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late bool _isRange;
  late DateTime _singleDate;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _isRange    = widget.initialIsRange;
    _singleDate = widget.initialSingleDate;
    _rangeStart = widget.initialRangeStart;
    _rangeEnd   = widget.initialRangeEnd;
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _singleDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: _theme,
    );
    if (picked != null) setState(() => _singleDate = picked);
  }

  Future<void> _pickRangeStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: _theme,
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked;
        if (_rangeEnd.isBefore(_rangeStart)) _rangeEnd = _rangeStart;
      });
    }
  }

  Future<void> _pickRangeEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEnd.isBefore(_rangeStart) ? _rangeStart : _rangeEnd,
      firstDate: _rangeStart,
      lastDate: DateTime.now(),
      builder: _theme,
    );
    if (picked != null) setState(() => _rangeEnd = picked);
  }

  Widget _theme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kAccent,
            onPrimary: Colors.white,
            surface: Color(0xFF1A1F3A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildModeToggle(),
              const SizedBox(height: 20),
              _buildDatePickers(),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kButtonDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.date_range_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            'Custom Date Filter',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextDark),
          ),
          const Spacer(),
          IconButton(
            icon:
                const Icon(Icons.close_rounded, size: 18, color: kTextLight),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );

  Widget _buildModeToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _ModeTab(
              label: 'Single Date',
              icon: Icons.today_rounded,
              selected: !_isRange,
              onTap: () => setState(() => _isRange = false),
            ),
            _ModeTab(
              label: 'Date Range',
              icon: Icons.date_range_rounded,
              selected: _isRange,
              onTap: () => setState(() => _isRange = true),
            ),
          ],
        ),
      );

  Widget _buildDatePickers() {
    if (!_isRange) {
      return _DatePickerTile(
        label: 'Select Date',
        value: toDisplayDate(_singleDate),
        onTap: _pickSingleDate,
      );
    }
    return Column(
      children: [
        _DatePickerTile(
          label: 'From',
          value: toDisplayDate(_rangeStart),
          onTap: _pickRangeStart,
        ),
        const SizedBox(height: 10),
        _DatePickerTile(
          label: 'To',
          value: toDisplayDate(_rangeEnd),
          onTap: _pickRangeEnd,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: kAccent.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatDateRange(_rangeStart, _rangeEnd),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() => Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: kTextMid,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: kBorder),
                ),
              ),
              child: const Text('Cancel',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(
                  isRange:    _isRange,
                  singleDate: _isRange ? null : _singleDate,
                  rangeStart: _isRange ? _rangeStart : null,
                  rangeEnd:   _isRange ? _rangeEnd : null,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? kButtonDark : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : kTextMid),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : kTextMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kTextLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            const VerticalDivider(width: 1, thickness: 1, color: kBorder),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextDark),
              ),
            ),
            const Icon(Icons.calendar_month_rounded,
                size: 16, color: kTextLight),
          ],
        ),
      ),
    );
  }
}