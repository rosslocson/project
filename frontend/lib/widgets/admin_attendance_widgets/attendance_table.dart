// lib/widgets/admin_attendance_widgets/attendance_table.dart
// Table widget that renders attendance records, including the status badge,
// intern avatar with auth-gated image fetching, report reason column,
// admin note (remark) column, and report / review actions.
//
// NOTE: PendingReportsBell has been removed from this file.
// The canonical bell now lives in admin_attendance_screen.dart (_PendingBell)
// and is placed beside the Export button in the card header.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../services/admin_attendance_service.dart';
import '../../models/attendance_constants.dart';
import '../../models/attendance_record.dart';
import 'report_issue_dialog.dart';
import 'review_report_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Attendance table
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceTable extends StatelessWidget {
  final List<AdminAttendanceRecord> records;
  final VoidCallback? onRefresh;

  /// Pass true when the viewer is an admin (enables inline remark editing
  /// and the review-report sheet instead of the report-issue dialog).
  final bool isAdmin;

  const AttendanceTable({
    super.key,
    required this.records,
    this.onRefresh,
    this.isAdmin = false,
  });

  // Headers match the 8 data columns (columns 1–8 in _colWidths).
  static const _headers = [
    'Intern',
    'Date',
    'Time In',
    'Time Out',
    'Hours',
    'Status',
    'Report Reason',
    'Admin Note',
  ];

  static const _colWidths = <int, TableColumnWidth>{
    0: FixedColumnWidth(16),  // left gutter — balanced with right
    1: FlexColumnWidth(4),    // Intern — wider
    2: FlexColumnWidth(2),    // Date
    3: FlexColumnWidth(1.4),  // Time In
    4: FlexColumnWidth(1.4),  // Time Out
    5: FlexColumnWidth(1.2),  // Hours
    6: FlexColumnWidth(3),    // Status — wide enough for "Missed Clock Out"
    7: FlexColumnWidth(1.8),  // Report Reason — narrower, wraps to next line
    8: FlexColumnWidth(1.8),  // Admin Note — narrower
    9: FixedColumnWidth(16),  // right gutter — balanced with left
  };

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: _colWidths,
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade100),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeader(),
        ...records
            .asMap()
            .entries
            .map((e) => _buildRow(context, e.value, e.key)),
      ],
    );
  }

  TableRow _buildHeader() {
    return TableRow(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: kBorder, width: 1.5)),
      ),
      children: [
        const SizedBox.shrink(),
        ..._headers.map((h) {
          final centered = h == 'Date' || h == 'Status';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
            child: Text(
              h.toUpperCase(),
              textAlign: centered ? TextAlign.center : TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: kTextMid,
                letterSpacing: 0.6,
              ),
            ),
          );
        }),
        const SizedBox.shrink(), // action column header
      ],
    );
  }

  TableRow _buildRow(
      BuildContext context, AdminAttendanceRecord r, int index) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.transparent),
      children: [
        const SizedBox.shrink(),

        // ── Intern name + avatar ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          child: Row(
            children: [
              InternAvatar(url: r.avatarUrl, name: r.internName),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  r.internName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: kTextDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        _cell(r.formattedDate, centered: true),

        // ── Time In with punctuality dot ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          child: r.timeIn != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r.isOnTime
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      r.timeIn!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: r.isOnTime
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                )
              : const Text('--',
                  style: TextStyle(fontSize: 13, color: kTextMid)),
        ),

        _cell(r.timeOut ?? '--'),
        _cell(r.formattedHours),

        // ── Status badge ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          child: Center(child: StatusBadge(status: r.status)),
        ),

        // ── Report Reason column ─────────────────────────────────────────
        _ReportReasonCell(record: r, isAdmin: isAdmin),

        // ── Admin Note (Remark) column ───────────────────────────────────
        _AdminNoteCell(record: r, isAdmin: isAdmin, onChanged: onRefresh),

        // ── Action cell ──────────────────────────────────────────────────
        _ActionCell(record: r, isAdmin: isAdmin, onRefresh: onRefresh),
      ],
    );
  }

  Widget _cell(String text, {bool centered = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        child: Text(
          text,
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: const TextStyle(fontSize: 13, color: kTextMid),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Reason cell — read-only for both intern and admin
// Shows the intern's filed report reason as an amber chip, or '--' if none.
// ─────────────────────────────────────────────────────────────────────────────

class _ReportReasonCell extends StatelessWidget {
  final AdminAttendanceRecord record;
  final bool isAdmin;

  const _ReportReasonCell({
    required this.record,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final reportReason = record.reportReason;
    final hasReportReason = reportReason != null && reportReason.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
      child: hasReportReason
          ? _ReportReasonChip(reason: reportReason)
          : const Text(
              '--',
              style: TextStyle(fontSize: 13, color: kTextMid),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Note cell — inline editable for admin, read-only for intern
// ─────────────────────────────────────────────────────────────────────────────

class _AdminNoteCell extends StatefulWidget {
  final AdminAttendanceRecord record;
  final bool isAdmin;
  final VoidCallback? onChanged;

  const _AdminNoteCell({
    required this.record,
    required this.isAdmin,
    this.onChanged,
  });

  @override
  State<_AdminNoteCell> createState() => _AdminNoteCellState();
}

class _AdminNoteCellState extends State<_AdminNoteCell> {
  bool _editing = false;
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.record.remark ?? '');
  }

  @override
  void didUpdateWidget(_AdminNoteCell old) {
    super.didUpdateWidget(old);
    // When the parent refreshes after a resolve, sync the controller with
    // the latest remark from the server — but only when not actively editing,
    // so we never clobber text the admin is mid-typing.
    if (!_editing && old.record.remark != widget.record.remark) {
      _ctrl.text = widget.record.remark ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Save remark via the dedicated PATCH endpoint ─────────────────────────
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
    final remark = widget.record.remark;
    final hasRemark = remark != null && remark.isNotEmpty;

    // ── Intern: read-only ────────────────────────────────────────────────
    if (!widget.isAdmin) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        child: Text(
          hasRemark ? remark : '--',
          style: TextStyle(
            fontSize: 12,
            fontStyle: hasRemark ? FontStyle.normal : FontStyle.italic,
            color: hasRemark ? const Color(0xFF4F46E5) : kTextMid,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // ── Admin: editing state ─────────────────────────────────────────────
    if (_editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kAccent),
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

    // ── Admin: display state — tappable to open inline edit ──────────────
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                hasRemark ? remark : 'Add note…',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: hasRemark ? FontStyle.normal : FontStyle.italic,
                  color: hasRemark ? const Color(0xFF4F46E5) : kTextMid,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 12, color: kTextMid),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report reason chip — amber pill showing the intern's filed reason
// ─────────────────────────────────────────────────────────────────────────────

class _ReportReasonChip extends StatelessWidget {
  final String reason;
  const _ReportReasonChip({required this.reason});

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
    final r = record;

    if (isAdmin) {
      // Admin: show review icon with orange dot only when report is pending
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
                const Icon(Icons.rate_review_outlined,
                    size: 20, color: kAccent),
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

    // ── Intern: flag icon on reportable statuses ─────────────────────────
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
            color: alreadyReported ? const Color(0xFFF59E0B) : kTextMid,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color border, Color text, Color bg) = switch (status) {
      'Present' => (
          const Color(0xFF22C55E),
          const Color(0xFF16A34A),
          const Color(0xFFF0FDF4),
        ),
      'Late' => (
          const Color(0xFFF59E0B),
          const Color(0xFFB45309),
          const Color(0xFFFFFBEB),
        ),
      'On Shift' => (
          kAccent,
          const Color(0xFF4F46E5),
          const Color(0xFFEEF2FF),
        ),
      'Missed Clock Out' => (
          const Color(0xFFEA580C),
          const Color(0xFFC2410C),
          const Color(0xFFFFF7ED),
        ),
      _ => (
          const Color(0xFFEF4444),
          const Color(0xFFDC2626),
          const Color(0xFFFEF2F2),
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
        style: TextStyle(
            color: text, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intern avatar (auth-gated image fetch)
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
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFDCEEFD),
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
              style: const TextStyle(
                color: Color(0xFF5B9BD5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HamburgerIcon — re-exported by admin_attendance_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

class HamburgerIcon extends StatelessWidget {
  final VoidCallback onTap;
  const HamburgerIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(Icons.menu_rounded, size: 22, color: kTextMid),
    );
  }
}