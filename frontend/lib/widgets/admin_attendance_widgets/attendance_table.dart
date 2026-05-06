// lib/widgets/admin_attendance_widgets/attendance_table.dart
// Table widget that renders attendance records, including the status badge
// and intern avatar with auth-gated image fetching.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../models/attendance_constants.dart';
import '../../models/attendance_record.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Attendance table
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceTable extends StatelessWidget {
  final List<AdminAttendanceRecord> records;

  const AttendanceTable({super.key, required this.records});

  static const _headers = [
    'Intern', 'Date', 'Time In', 'Time Out', 'Hours Worked', 'Status',
  ];

  static const _colWidths = <int, TableColumnWidth>{
    0: FixedColumnWidth(28),
    1: FlexColumnWidth(3),
    2: FlexColumnWidth(2),
    3: FlexColumnWidth(1.5),
    4: FlexColumnWidth(1.5),
    5: FlexColumnWidth(1.5),
    6: FlexColumnWidth(2),
    7: FixedColumnWidth(28),
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
        ...records.asMap().entries.map((e) => _buildRow(e.value, e.key)),
      ],
    );
  }

  TableRow _buildHeader() {
    return TableRow(
      decoration: const BoxDecoration(
        color: kCardBg,
        border: Border(bottom: BorderSide(color: kBorder, width: 1.5)),
      ),
      children: [
        const SizedBox.shrink(),
        ..._headers.map((h) {
          final isCentered = h == 'Date' || h == 'Status';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
            child: Text(
              h.toUpperCase(),
              textAlign: isCentered ? TextAlign.center : TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: kTextMid,
                letterSpacing: 0.6,
              ),
            ),
          );
        }),
        const SizedBox.shrink(),
      ],
    );
  }

  TableRow _buildRow(AdminAttendanceRecord r, int index) {
    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven ? kSurface : const Color(0xFFFAFAFC),
      ),
      children: [
        const SizedBox.shrink(),

        // Intern name + avatar
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

        // Time In with punctuality dot
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

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          child: Center(child: StatusBadge(status: r.status)),
        ),

        const SizedBox.shrink(),
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
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 140),
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
        style: TextStyle(
            color: text, fontWeight: FontWeight.w600, fontSize: 12),
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