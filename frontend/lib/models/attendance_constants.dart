// lib/models/attendance_constants.dart
// Enums, status options, and design tokens shared across admin attendance files.

import 'package:flutter/material.dart';

// ── Period enum ───────────────────────────────────────────────────────────────

enum AttendancePeriod { custom, today, week, month, year, allDates }

extension AttendancePeriodExt on AttendancePeriod {
  String get label => switch (this) {
        AttendancePeriod.custom   => 'Custom',
        AttendancePeriod.today    => 'Today',
        AttendancePeriod.week     => 'This Week',
        AttendancePeriod.month    => 'This Month',
        AttendancePeriod.year     => 'This Year',
        AttendancePeriod.allDates => 'All Dates',
      };

  String? get apiPeriod => switch (this) {
        AttendancePeriod.today  => 'today',
        AttendancePeriod.week   => 'week',
        AttendancePeriod.month  => 'month',
        AttendancePeriod.year   => 'year',
        _                       => null,
      };
}

// ── Status options ────────────────────────────────────────────────────────────

const kAttendanceStatuses = [
  'All',
  'Present',
  'Late',
  'On Shift',
  'Missed Clock Out',
  'Absent',
];

// ── Design tokens ─────────────────────────────────────────────────────────────

const kPrimary    = Color(0xFF0A0A14);
const kAccent     = Color(0xFF6C63FF);
const kCardBg     = Color(0xFFFAFAFC);
const kSurface    = Color(0xFFFFFFFF);
const kBorder     = Color(0xFFEEEFF4);
const kTextDark   = Color(0xFF1A1F3A);
const kTextMid    = Color(0xFF64748B);
const kTextLight  = Color(0xFF94A3B8);
const kBlue       = Color(0xFF00022E);
const kButtonDark = Color(0xFF0D0D2B);