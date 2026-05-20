// lib/widgets/admin_attendance_widgets/custom_date_picker_dialog.dart
// Modal dialog for picking a single date or a date range.

import 'package:flutter/material.dart';

import '../../models/attendance_constants.dart';
import '../../services/date_helpers.dart';
import '../app_theme.dart';

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
  State<CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late bool _isRange;
  late DateTime _singleDate;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _isRange = widget.initialIsRange;
    _singleDate = widget.initialSingleDate;
    _rangeStart = widget.initialRangeStart;
    _rangeEnd = widget.initialRangeEnd;
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

  // Replace the existing _theme method entirely with this:

  // Replace the existing _theme method entirely with this:

  Widget _theme(BuildContext ctx, Widget? child) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final accentColor = isDark ? kAccent : const Color(0xFF00022E);

    if (isDark) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: accentColor,
            onPrimary: Colors.white,
            surface: const Color(0xFF0E0E12),
            onSurface: Colors.white,
            surfaceContainerHighest: const Color(0xFF18181E),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: const Color(0xFF0E0E12),
            headerBackgroundColor:
                const Color(0xFF0E0E12), // ← matches calendar body
            headerForegroundColor:
                Colors.white70, // ← softer white for header text
            dayBackgroundColor: MaterialStateColor.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? accentColor
                  : Colors.transparent,
            ),
            dayForegroundColor: MaterialStateColor.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? Colors.white
                  : Colors.white70,
            ),
            todayBorder: BorderSide(color: accentColor),
            todayForegroundColor: MaterialStateColor.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? Colors.white
                  : accentColor,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: accentColor),
          ),
        ),
        child: child!,
      );
    }

    // ── Light mode ─────────────────────────────────────────────────────────────
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: ColorScheme.light(
          primary: accentColor,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: kTextDark,
          surfaceContainerHighest: const Color(0xFFF4F5F8),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          headerBackgroundColor: accentColor,
          headerForegroundColor: Colors.white,
          dayBackgroundColor: MaterialStateColor.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? accentColor
                : Colors.transparent,
          ),
          dayForegroundColor: MaterialStateColor.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? Colors.white
                : kTextDark,
          ),
          todayBorder: BorderSide(color: accentColor),
          todayForegroundColor: MaterialStateColor.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? Colors.white
                : accentColor,
          ),
          yearBackgroundColor: MaterialStateColor.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? accentColor
                : Colors.transparent,
          ),
          yearForegroundColor: MaterialStateColor.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? Colors.white
                : kTextDark,
          ),
          rangePickerBackgroundColor: Colors.white,
          rangeSelectionBackgroundColor: accentColor.withValues(alpha: 0.12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accentColor),
        ),
      ),
      child: child!,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<InternSpaceThemeColors>() ??
        InternSpaceThemeColors.dark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF0E0E12)
        : theme.dialogBackground; // Updated from 0xFF0D0D2B

    // Accent: purple in dark mode, navy in light mode
    final accentColor = isDark ? kAccent : const Color(0xFF00022E);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.08))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.18),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, accentColor),
            const SizedBox(height: 20),
            _buildModeToggle(isDark, accentColor),
            const SizedBox(height: 20),
            _buildDatePickers(isDark, accentColor),
            const SizedBox(height: 24),
            _buildActions(isDark, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color accentColor) => Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.date_range_rounded, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'Custom Date Filter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : kTextDark,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: isDark ? Colors.white38 : kTextLight,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );

  Widget _buildModeToggle(bool isDark, Color accentColor) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF18181E)
              : const Color(0xFFF4F5F8), // Updated from 0xFF070A1F
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _ModeTab(
              label: 'Single Date',
              icon: Icons.today_rounded,
              selected: !_isRange,
              isDark: isDark,
              accentColor: accentColor,
              onTap: () => setState(() => _isRange = false),
            ),
            _ModeTab(
              label: 'Date Range',
              icon: Icons.date_range_rounded,
              selected: _isRange,
              isDark: isDark,
              accentColor: accentColor,
              onTap: () => setState(() => _isRange = true),
            ),
          ],
        ),
      );

  Widget _buildDatePickers(bool isDark, Color accentColor) {
    if (!_isRange) {
      return _DatePickerTile(
        label: 'Select Date',
        value: toDisplayDate(_singleDate),
        isDark: isDark,
        accentColor: accentColor,
        onTap: _pickSingleDate,
      );
    }
    return Column(
      children: [
        _DatePickerTile(
          label: 'From',
          value: toDisplayDate(_rangeStart),
          isDark: isDark,
          accentColor: accentColor,
          onTap: _pickRangeStart,
        ),
        const SizedBox(height: 10),
        _DatePickerTile(
          label: 'To',
          value: toDisplayDate(_rangeEnd),
          isDark: isDark,
          accentColor: accentColor,
          onTap: _pickRangeEnd,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? accentColor.withValues(alpha: 0.1)
                : accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatDateRange(_rangeStart, _rangeEnd),
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor,
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

  Widget _buildActions(bool isDark, Color accentColor) => Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white60 : kTextMid,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        isDark ? Colors.white.withValues(alpha: 0.08) : kBorder,
                  ),
                ),
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(
                  isRange: _isRange,
                  singleDate: _isRange ? null : _singleDate,
                  rangeStart: _isRange ? _rangeStart : null,
                  rangeEnd: _isRange ? _rangeEnd : null,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.accentColor,
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
            color: selected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected
                      ? Colors.white
                      : isDark
                          ? Colors.white38
                          : kTextMid),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : isDark
                          ? Colors.white38
                          : kTextMid,
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
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF18181E)
              : const Color(0xFFF4F5F8), // Updated from 0xFF070A1F
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : kBorder,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : kTextLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            const VerticalDivider(width: 1, thickness: 1, color: kBorder),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : kTextDark,
                ),
              ),
            ),
            Icon(Icons.calendar_month_rounded,
                size: 16,
                color: isDark
                    ? Colors.white38
                    : accentColor.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
