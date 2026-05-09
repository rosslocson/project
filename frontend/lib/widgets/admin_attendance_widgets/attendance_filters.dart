// lib/widgets/admin_attendance_widgets/attendance_filters.dart
// Filter bar widgets: search field, status dropdown, period chips,
// active filters badge.

import 'package:flutter/material.dart';

import '../../models/attendance_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const AttendanceSearchField({
    super.key,
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: kTextDark),
        decoration: InputDecoration(
          hintText: 'Search intern by name…',
          hintStyle: const TextStyle(fontSize: 13, color: kTextLight),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 18, color: kTextLight),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: kTextLight),
                  padding: EdgeInsets.zero,
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF4F5F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status dropdown
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceStatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const AttendanceStatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: kTextDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: kTextMid),
          items: kAttendanceStatuses
              .map((s) => DropdownMenuItem<String>(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period chip
// ─────────────────────────────────────────────────────────────────────────────

class PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const PeriodChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kButtonDark : const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kButtonDark : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13,
                  color: selected ? Colors.white : kTextMid),
              const SizedBox(width: 5),
            ],
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active filters badge
// ─────────────────────────────────────────────────────────────────────────────

class ActiveFiltersBadge extends StatelessWidget {
  final int count;
  final VoidCallback onClear;

  const ActiveFiltersBadge({
    super.key,
    required this.count,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccent, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count filter${count > 1 ? 's' : ''} active',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFF4F46E5)),
          ),
        ],
      ),
    );
  }
}