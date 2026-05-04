// export_attendance.dart
//
// Standalone PDF-export helper for the Admin Attendance screen.
//
// Packages needed (add to pubspec.yaml):
//   pdf:      ^3.11.1
//   printing: ^5.13.1
//
// ── Usage ────────────────────────────────────────────────────────────────────
//
//   onTap: () async {
//     final isAllDates = _period == AttendancePeriod.allDates;
//     final isCustom   = _period == AttendancePeriod.custom;
//     await AttendanceExporter.export(
//       context,
//       options: AttendanceExportOptions(
//         allDates: isAllDates,
//         period:   (!isAllDates && !isCustom) ? _period.apiPeriod : null,
//         date:     isCustom ? _toApiDate(_customDate) : null,
//         search:   _searchCtrl.text.trim().isEmpty
//                       ? null
//                       : _searchCtrl.text.trim(),
//         status:   _selectedStatus == 'All' ? null : _selectedStatus,
//       ),
//     );
//   },
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens (mirrors admin_attendance_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

const _kButtonDark = Color(0xFF0D0D2B);
const _kAccent     = Color(0xFF6C63FF);

// PDF colour palette
final _pdfDark      = PdfColor.fromHex('0D0D2B');
final _pdfAccent    = PdfColor.fromHex('6C63FF');
final _pdfHeaderBg  = PdfColor.fromHex('F4F5F8');
final _pdfBorder    = PdfColor.fromHex('EEEEF4');
final _pdfTextMid   = PdfColor.fromHex('64748B');
final _pdfTextLight = PdfColor.fromHex('94A3B8');

// Status badge colours — (background, text)
final _statusColors = <String, (PdfColor, PdfColor)>{
  'Present':          (PdfColor.fromHex('F0FDF4'), PdfColor.fromHex('16A34A')),
  'Late':             (PdfColor.fromHex('FFFBEB'), PdfColor.fromHex('B45309')),
  'On Shift':         (PdfColor.fromHex('EEF2FF'), PdfColor.fromHex('4F46E5')),
  'Missed Clock Out': (PdfColor.fromHex('FFF7ED'), PdfColor.fromHex('C2410C')),
  'Absent':           (PdfColor.fromHex('FEF2F2'), PdfColor.fromHex('DC2626')),
};

// ─────────────────────────────────────────────────────────────────────────────
// AttendanceExportOptions
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceExportOptions {
  final bool    allDates;
  final String? period;  // "today" | "week" | "month" | "year"
  final String? date;    // "YYYY-MM-DD"
  final String? search;
  final String? status;

  const AttendanceExportOptions({
    this.allDates = false,
    this.period,
    this.date,
    this.search,
    this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AttendanceExportResult
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceExportResult {
  final bool    success;
  final String? error;

  const AttendanceExportResult._({required this.success, this.error});
  factory AttendanceExportResult.ok()           => const AttendanceExportResult._(success: true);
  factory AttendanceExportResult.fail(String e) => AttendanceExportResult._(success: false, error: e);
}

// ─────────────────────────────────────────────────────────────────────────────
// Lightweight record model (matches backend AdminAttendanceRow)
// ─────────────────────────────────────────────────────────────────────────────

class _Record {
  final String internName;
  final String date;
  final String timeIn;
  final String timeOut;
  final String hours;
  final String status;

  const _Record({
    required this.internName,
    required this.date,
    required this.timeIn,
    required this.timeOut,
    required this.hours,
    required this.status,
  });

  factory _Record.fromJson(Map<String, dynamic> j) {
    final h = (j['hours_rendered'] as num?)?.toDouble();
    String hours = '--';
    if (h != null) {
      final hh = h.floor();
      final mm = ((h - hh) * 60).round();
      hours = '${hh}h ${mm}m';
    }
    return _Record(
      internName: j['intern_name'] as String? ?? 'Unknown',
      date:       _fmtDate(j['date'] as String? ?? ''),
      timeIn:     j['time_in']  as String? ?? '--',
      timeOut:    j['time_out'] as String? ?? '--',
      hours:      hours,
      status:     j['status']  as String? ?? 'Absent',
    );
  }

  static String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month.toString().padLeft(2, '0')}/'
             '${dt.day.toString().padLeft(2, '0')}/'
             '${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AttendanceExporter
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceExporter {
  AttendanceExporter._();

  static Future<AttendanceExportResult> export(
    BuildContext context, {
    required AttendanceExportOptions options,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final snackCtrl = messenger.showSnackBar(_progressSnack());

    try {
      // 1. Fetch all matching records (limit=1000 — no pagination for export)
      final records = await _fetchAll(options);

      snackCtrl.close();

      if (records == null) {
        _snack(context, 'Export failed: could not fetch records.', isError: true);
        return AttendanceExportResult.fail('Fetch error');
      }
      if (records.isEmpty) {
        _snack(context, 'No records found for this filter.', isError: true);
        return AttendanceExportResult.fail('No records');
      }

      // 2. Build the PDF; _buildPdf returns Uint8List directly
      final pdfBytes = await _buildPdf(records, options);

      // 3. Hand off to printing — opens native save/share/print dialog
      await Printing.layoutPdf(
        // onLayout must return Future<Uint8List>; pdfBytes is already Uint8List
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: _filename(options),
      );

      return AttendanceExportResult.ok();
    } catch (e) {
      snackCtrl.close();
      _snack(context, 'Export error: $e', isError: true);
      return AttendanceExportResult.fail('$e');
    }
  }

  // ── Fetch records ─────────────────────────────────────────────────────────

  static Future<List<_Record>?> _fetchAll(AttendanceExportOptions opts) async {
    try {
      final params = <String, String>{
        'page':  '1',
        'limit': '1000',
        if (opts.allDates)
          'all_dates': 'true'
        else if (opts.period != null)
          'period': opts.period!
        else if (opts.date != null)
          'date': opts.date!,
        if (opts.search != null && opts.search!.isNotEmpty)
          'search': opts.search!,
        if (opts.status != null && opts.status != 'All')
          'status': opts.status!,
      };

      final uri = Uri.parse('${ApiService.baseUrl}/admin/attendance')
          .replace(queryParameters: params);

      final res = await http
          .get(uri, headers: await ApiService.authHeaders())
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ok'] != true) return null;

      return (body['records'] as List? ?? [])
          .map((e) => _Record.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── PDF builder — returns Uint8List ───────────────────────────────────────

  static Future<Uint8List> _buildPdf(
    List<_Record>           records,
    AttendanceExportOptions opts,
  ) async {
    final doc = pw.Document(
      title:  'Attendance Report',
      author: 'Admin',
    );

    // Column labels and their flex widths — explicit List<double>
    const headers = ['Intern', 'Date', 'Time In', 'Time Out', 'Hours', 'Status'];
    final flex    = <double>[3.0, 2.0, 1.5, 1.5, 1.5, 2.0];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin:     const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        header:     (ctx) => _buildHeader(ctx, opts),
        footer:     (ctx) => _buildFooter(ctx),
        build:      (ctx) => [
          pw.SizedBox(height: 16),
          _buildTable(records, headers, flex),
        ],
      ),
    );

    // doc.save() returns Future<Uint8List>
    return doc.save();
  }

  // ── PDF header ────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(pw.Context ctx, AttendanceExportOptions opts) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _pdfBorder, width: 1),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Left accent bar
          pw.Container(
            width: 4,
            height: 36,
            decoration: pw.BoxDecoration(
              color: _pdfAccent,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Attendance Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfDark,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _subtitleText(opts),
                style: pw.TextStyle(fontSize: 10, color: _pdfTextMid),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Text(
            'Generated ${_todayStr()}',
            style: pw.TextStyle(fontSize: 9, color: _pdfTextLight),
          ),
        ],
      ),
    );
  }

  // ── PDF footer ────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _pdfBorder, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Attendance Monitoring System',
            style: pw.TextStyle(fontSize: 8, color: _pdfTextLight),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _pdfTextLight),
          ),
        ],
      ),
    );
  }

  // ── PDF table ─────────────────────────────────────────────────────────────

  static pw.Widget _buildTable(
    List<_Record>  records,
    List<String>   headers,
    List<double>   flex,        // explicit List<double> — fixes the type error
  ) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _pdfBorder, width: 0.5),
        bottom:           pw.BorderSide(color: _pdfBorder, width: 0.5),
      ),
      columnWidths: {
        for (int i = 0; i < headers.length; i++)
          i: pw.FlexColumnWidth(flex[i]),
      },
      children: [
        // ── Header row ──────────────────────────────────────────────────────
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _pdfHeaderBg),
          children: headers.map((h) {
            final centered = h == 'Date' || h == 'Status';
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: pw.Text(
                h.toUpperCase(),
                textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfTextMid,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }).toList(),
        ),

        // ── Data rows ───────────────────────────────────────────────────────
        ...records.asMap().entries.map((entry) {
          final i    = entry.key;
          final r    = entry.value;
          final rowBg = i.isEven ? PdfColors.white : PdfColor.fromHex('FAFAFC');

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _dataCell(r.internName, bold: true, color: _pdfDark),
              _dataCell(r.date,    centered: true),
              _dataCell(r.timeIn),
              _dataCell(r.timeOut),
              _dataCell(r.hours),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: pw.Center(child: _statusBadge(r.status)),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _dataCell(
    String    text, {
    bool      bold     = false,
    bool      centered = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: pw.Text(
          text,
          textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? _pdfTextMid,
          ),
        ),
      );

  static pw.Widget _statusBadge(String status) {
    final colors = _statusColors[status] ??
        (PdfColor.fromHex('FEF2F2'), PdfColor.fromHex('DC2626'));
    final bg        = colors.$1;
    final textColor = colors.$2;

    // pw.BorderRadius with large radii causes the "fish eye" rendering bug
    // in the pdf package. Use a small fixed radius (4pt) which is safe.
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: textColor, width: 0.8),
      ),
      child: pw.Text(
        status,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _filename(AttendanceExportOptions opts) {
    if (opts.allDates)       return 'attendance_all_dates.pdf';
    if (opts.period != null) return 'attendance_${opts.period}.pdf';
    if (opts.date   != null) return 'attendance_${opts.date}.pdf';
    return 'attendance_${_todayStr()}.pdf';
  }

  static String _subtitleText(AttendanceExportOptions opts) {
    if (opts.allDates) return 'All Dates';
    if (opts.period != null) {
      return switch (opts.period) {
        'today' => 'Today ${_todayStr()}',
        'week'  => 'This Week',
        'month' => 'This Month',
        'year'  => 'This Year',
        _       => opts.period!,
      };
    }
    if (opts.date != null) return _Record._fmtDate(opts.date!);
    return _todayStr();
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/'
           '${now.day.toString().padLeft(2, '0')}/'
           '${now.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI helpers
// ─────────────────────────────────────────────────────────────────────────────

SnackBar _progressSnack() => SnackBar(
      duration: const Duration(minutes: 5),
      backgroundColor: _kButtonDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Preparing PDF export…',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

void _snack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor:
          isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ),
  );
}