// lib/widgets/admin_attendance_widgets/attendance_table.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../services/admin_attendance_service.dart';
import '../../models/attendance_constants.dart';
import '../../models/attendance_record.dart';
import '../../widgets/app_theme.dart';
import 'report_issue_dialog.dart';
import 'review_report_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Attendance table
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceTable extends StatelessWidget {
  final List<AdminAttendanceRecord> records;
  final VoidCallback? onRefresh;
  final bool isAdmin;

  const AttendanceTable({
    super.key,
    required this.records,
    this.onRefresh,
    this.isAdmin = false,
  });

  static const _headers = [
    'Intern',
    'Date',
    'Time In',
    'Time Out',
    'Hours',
    'Status',
  ];

  static const _minColWidths = [160.0, 110.0, 100.0, 100.0, 72.0, 110.0, 44.0];

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = _minColWidths.fold(0.0, (a, b) => a + b);
        final tableWidth =
            constraints.maxWidth >= minWidth ? constraints.maxWidth : minWidth;

        final Map<int, TableColumnWidth> colWidths = {
          for (int i = 0; i < _minColWidths.length; i++)
            i: FixedColumnWidth(
              _minColWidths[i] * tableWidth / minWidth,
            ),
        };

        return ScrollConfiguration(
          behavior:
              ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: tableWidth,
              child: Table(
                columnWidths: colWidths,
                border: TableBorder(
                  horizontalInside: BorderSide(color: theme.border),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _buildHeader(context),
                  ...records
                      .asMap()
                      .entries
                      .map((e) => _buildRow(context, e.value, e.key)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TableRow _buildHeader(BuildContext context) {
    final theme = context.internTheme;

    return TableRow(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: theme.border, width: 1.5)),
      ),
      children: [
        ..._headers.map((h) {
          final centered = h == 'Date' || h == 'Status';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
            child: Text(
              h.toUpperCase(),
              textAlign: centered ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: theme.mutedText,
                letterSpacing: 0.6,
              ),
            ),
          );
        }),
        const SizedBox.shrink(),
      ],
    );
  }

  TableRow _buildRow(
      BuildContext context, AdminAttendanceRecord r, int index) {
    final theme = context.internTheme;

    return TableRow(
      decoration: const BoxDecoration(color: Colors.transparent),
      children: [
        // ── Intern name + avatar ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          child: Row(
            children: [
              InternAvatar(url: r.avatarUrl, name: r.internName),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  r.internName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: theme.surfaceText,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),

        _cell(context, r.formattedDate, centered: true),

        // ── Time In with punctuality dot ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          child: r.timeIn != null
              ? Builder(builder: (context) {
                  bool isLate = false;
                  try {
                    final raw = r.timeIn!.trim().toUpperCase();
                    final isPm = raw.endsWith('PM');
                    final digits = raw
                        .replaceAll('AM', '')
                        .replaceAll('PM', '')
                        .trim();
                    final parts = digits.split(':');
                    int hour = int.parse(parts[0]);
                    final minute =
                        parts.length > 1 ? int.parse(parts[1]) : 0;
                    if (isPm && hour != 12) hour += 12;
                    if (!isPm && hour == 12) hour = 0;
                    isLate = hour > 8 || (hour == 8 && minute >= 15);
                  } catch (_) {
                    isLate = !r.isOnTime;
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLate
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          r.timeIn!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isLate
                                ? const Color(0xFFDC2626)
                                : kTextMid,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                })
              : const Text('--',
                  style: TextStyle(fontSize: 13, color: kTextMid)),
        ),

        _cell(context, r.timeOut ?? '--'),
        _cell(context, r.formattedHours),

        // ── Status badge ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          child: Center(child: StatusBadge(status: r.status)),
        ),

        // ── Action cell ──────────────────────────────────────────────────
        _ActionCell(record: r, isAdmin: isAdmin, onRefresh: onRefresh),
      ],
    );
  }

  Widget _cell(BuildContext context, String text, {bool centered = false}) {
    final theme = context.internTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: TextStyle(fontSize: 13, color: theme.mutedText),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Reason cell
// ─────────────────────────────────────────────────────────────────────────────

class ReportReasonCell extends StatelessWidget {
  final AdminAttendanceRecord record;
  final bool isAdmin;

  const ReportReasonCell({
    super.key,
    required this.record,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final reportReason = record.reportReason;
    final hasReportReason = reportReason != null && reportReason.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      child: hasReportReason
          ? ReportReasonChip(reason: reportReason)
          : const Text(
              '--',
              style: TextStyle(fontSize: 13, color: kTextMid),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Note cell
// ─────────────────────────────────────────────────────────────────────────────

class AdminNoteCell extends StatefulWidget {
  final AdminAttendanceRecord record;
  final bool isAdmin;
  final VoidCallback? onChanged;

  const AdminNoteCell({
    super.key,
    required this.record,
    required this.isAdmin,
    this.onChanged,
  });

  @override
  State<AdminNoteCell> createState() => _AdminNoteCellState();
}

class _AdminNoteCellState extends State<AdminNoteCell> {
  bool _editing = false;
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.record.remark ?? '');
  }

  @override
  void didUpdateWidget(AdminNoteCell old) {
    super.didUpdateWidget(old);
    if (!_editing && old.record.remark != widget.record.remark) {
      _ctrl.text = widget.record.remark ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AdminAttendanceService.updateRemark(
      widget.record.id,
      _ctrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;
    final remark = widget.record.remark;
    final hasRemark = remark != null && remark.isNotEmpty;

    if (!widget.isAdmin) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        child: Text(
          hasRemark ? remark : '--',
          style: TextStyle(
            fontSize: 12,
            fontStyle: hasRemark ? FontStyle.normal : FontStyle.italic,
            color: hasRemark
                ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
                : theme.mutedText,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (_editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 2,
                style: TextStyle(fontSize: 12, color: theme.surfaceText),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(8),
                  filled: true,
                  fillColor: theme.metricCardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: theme.sidebarActiveForeground),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : GestureDetector(
                        onTap: _save,
                        child: const Icon(Icons.check_circle,
                            color: Color(0xFF22C55E), size: 22),
                      ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _editing = false),
                  child: const Icon(Icons.cancel,
                      color: Color(0xFFEF4444), size: 22),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                hasRemark ? remark : 'Add note…',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: hasRemark ? FontStyle.normal : FontStyle.italic,
                  color: hasRemark
                      ? (isDark
                          ? const Color(0xFF818CF8)
                          : const Color(0xFF4F46E5))
                      : theme.mutedText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 12, color: theme.mutedText),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report reason chip
// ─────────────────────────────────────────────────────────────────────────────

class ReportReasonChip extends StatelessWidget {
  final String reason;
  const ReportReasonChip({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.flag_rounded, size: 11, color: Color(0xFF92400E)),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF92400E),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action cell
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCell extends StatelessWidget {
  final AdminAttendanceRecord record;
  final bool isAdmin;
  final VoidCallback? onRefresh;

  const _ActionCell({
    required this.record,
    required this.isAdmin,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final r = record;

    if (isAdmin) {
      if (!r.hasOpenReport) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Tooltip(
          message: 'Review pending report',
          child: GestureDetector(
            onTap: () => ReviewReportSheet.show(
              context,
              r,
              onResolved: onRefresh,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 20, color: theme.sidebarActiveForeground),
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!r.isReportable) return const SizedBox.shrink();

    final alreadyReported = r.isReported;
    final String reportHint = switch (r.status) {
      'Absent' => 'Dispute absence',
      'Late' => 'Dispute late mark',
      'Missed Clock Out' => 'Report missed clock-out',
      _ => 'Report an issue',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Tooltip(
        message: alreadyReported ? 'Report submitted' : reportHint,
        child: GestureDetector(
          onTap: alreadyReported
              ? null
              : () => ReportIssueDialog.show(
                    context,
                    r,
                    onReported: onRefresh,
                  ),
          child: Icon(
            alreadyReported ? Icons.flag : Icons.flag_outlined,
            size: 20,
            color: alreadyReported
                ? const Color(0xFFF59E0B)
                : theme.mutedText,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge — dark-mode aware
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkInternTheme;

    final (Color border, Color text, Color bg) = switch (status) {
      'Present' => isDark
          ? (
              const Color(0xFF22C55E),
              const Color(0xFF22C55E),
              const Color(0xFF22C55E).withValues(alpha: 0.12),
            )
          : (
              const Color(0xFF22C55E),
              const Color(0xFF16A34A),
              const Color(0xFFF0FDF4),
            ),
      'Late' => isDark
          ? (
              const Color(0xFFF59E0B),
              const Color(0xFFF59E0B),
              const Color(0xFFF59E0B).withValues(alpha: 0.12),
            )
          : (
              const Color(0xFFF59E0B),
              const Color(0xFFB45309),
              const Color(0xFFFFFBEB),
            ),
      'On Shift' => isDark
          ? (
              const Color(0xFF818CF8),
              const Color(0xFF818CF8),
              const Color(0xFF818CF8).withValues(alpha: 0.12),
            )
          : (
              kAccent,
              const Color(0xFF4F46E5),
              const Color(0xFFEEF2FF),
            ),
      'Missed Clock Out' => isDark
          ? (
              const Color(0xFFFB923C),
              const Color(0xFFFB923C),
              const Color(0xFFFB923C).withValues(alpha: 0.12),
            )
          : (
              const Color(0xFFEA580C),
              const Color(0xFFC2410C),
              const Color(0xFFFFF7ED),
            ),
      _ => isDark
          ? (
              const Color(0xFFEF4444),
              const Color(0xFFEF4444),
              const Color(0xFFEF4444).withValues(alpha: 0.12),
            )
          : (
              const Color(0xFFEF4444),
              const Color(0xFFDC2626),
              const Color(0xFFFEF2F2),
            ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style:
            TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intern avatar
// ─────────────────────────────────────────────────────────────────────────────

class InternAvatar extends StatefulWidget {
  final String url;
  final String name;

  const InternAvatar({super.key, required this.url, required this.name});

  @override
  State<InternAvatar> createState() => _InternAvatarState();
}

class _InternAvatarState extends State<InternAvatar> {
  Uint8List? _imageBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  @override
  void didUpdateWidget(InternAvatar old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() {
        _loading = true;
        _imageBytes = null;
      });
      _fetchImage();
    }
  }

  Future<void> _fetchImage() async {
    if (widget.url.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(widget.url),
        headers: await ApiService.authHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        setState(() {
          _imageBytes = res.bodyBytes;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _initials {
    final trimmed = widget.name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkInternTheme;

    return CircleAvatar(
      radius: 18,
      backgroundColor:
          isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDCEEFD),
      child: _imageBytes != null
          ? ClipOval(
              child: Image.memory(
                _imageBytes!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            )
          : Text(
              _initials,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF5B9BD5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HamburgerIcon
// ─────────────────────────────────────────────────────────────────────────────

class HamburgerIcon extends StatelessWidget {
  final VoidCallback onTap;
  const HamburgerIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    return GestureDetector(
      onTap: onTap,
      child: Icon(Icons.menu_rounded, size: 22, color: theme.mutedText),
    );
  }
}