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
const _kAccent = Color(0xFF6C63FF);

// PDF colour palette
final _pdfDark = PdfColor.fromHex('0D0D2B');
final _pdfAccent = PdfColor.fromHex('6C63FF');
final _pdfHeaderBg = PdfColor.fromHex('F4F5F8');
final _pdfBorder = PdfColor.fromHex('EEEEF4');
final _pdfTextMid = PdfColor.fromHex('64748B');
final _pdfTextLight = PdfColor.fromHex('94A3B8');

// Status badge colours — (background, text)
final _statusColors = <String, (PdfColor, PdfColor)>{
  'Present': (PdfColor.fromHex('F0FDF4'), PdfColor.fromHex('16A34A')),
  'Late': (PdfColor.fromHex('FFFBEB'), PdfColor.fromHex('B45309')),
  'On Shift': (PdfColor.fromHex('EEF2FF'), PdfColor.fromHex('4F46E5')),
  'Missed Clock Out': (PdfColor.fromHex('FFF7ED'), PdfColor.fromHex('C2410C')),
  'Absent': (PdfColor.fromHex('FEF2F2'), PdfColor.fromHex('DC2626')),
};

// ─────────────────────────────────────────────────────────────────────────────
// How many data rows to render per page-chunk.
// 20 is conservative for landscape A4 at font-size 9 + standard padding.
// Raise to 25 if pages look too sparse; lower if rows still get clipped.
// ─────────────────────────────────────────────────────────────────────────────
const _kRowsPerPage = 1000;

// ─────────────────────────────────────────────────────────────────────────────
// How many records to pull in one HTTP request.
// Bump this if you expect > 5 000 records.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// AttendanceExportOptions
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceExportOptions {
  final bool allDates;
  final String? period; // "today" | "week" | "month" | "year"
  final String? date; // "YYYY-MM-DD"
  final String? dateFrom;
  final String? dateTo;
  final String? search;
  final String? status;

  const AttendanceExportOptions({
    this.allDates = false,
    this.period,
    this.date,
    this.dateFrom,
    this.dateTo,
    this.search,
    this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AttendanceExportResult
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceExportResult {
  final bool success;
  final String? error;

  const AttendanceExportResult._({required this.success, this.error});
  factory AttendanceExportResult.ok() =>
      const AttendanceExportResult._(success: true);
  factory AttendanceExportResult.fail(String e) =>
      AttendanceExportResult._(success: false, error: e);
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
      date: _fmtDate(j['date'] as String? ?? ''),
      timeIn: j['time_in'] as String? ?? '--',
      timeOut: j['time_out'] as String? ?? '--',
      hours: hours,
      status: j['status'] as String? ?? 'Absent',
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
      // 1. Fetch all matching records
      final records = await _fetchAll(options);
      if (!context.mounted) {
        return AttendanceExportResult.fail('Context unmounted');
      }

      snackCtrl.close();

      if (records == null) {
        _snack(context, 'Export failed: could not fetch records.',
            isError: true);
        return AttendanceExportResult.fail('Fetch error');
      }
      if (records.isEmpty) {
        _snack(context, 'No records found for this filter.', isError: true);
        return AttendanceExportResult.fail('No records');
      }

      // 2. Build the PDF
      final pdfBytes = await _buildPdf(records, options);

      if (!context.mounted) {
        return AttendanceExportResult.fail('Context unmounted');
      }

      // 3. Hand off to printing — opens native save/share/print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: _filename(options),
      );

      return AttendanceExportResult.ok();
    } catch (e) {
      if (context.mounted) {
        snackCtrl.close();
        _snack(context, 'Export error: $e', isError: true);
      }
      return AttendanceExportResult.fail('$e');
    }
  }

  // ── Fetch records ─────────────────────────────────────────────────────────

  static Future<List<_Record>?> _fetchAll(AttendanceExportOptions opts) async {
    try {
      final allRecords = <_Record>[];
      int page = 1;
      const batchSize = 100; // safe page size your backend definitely supports

      while (true) {
        final params = <String, String>{
          'page': '$page',
          'limit': '$batchSize',
          if (opts.allDates)
            'all_dates': 'true'
          else if (opts.period != null)
            'period': opts.period!
          else if (opts.dateFrom != null && opts.dateTo != null) ...{
            'date_from': opts.dateFrom!,
            'date_to': opts.dateTo!,
          } else if (opts.date != null)
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
            .timeout(const Duration(seconds: 90));

        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['ok'] != true) return null;

        final batch = (body['records'] as List? ?? [])
            .map((e) => _Record.fromJson(e as Map<String, dynamic>))
            .toList();

        allRecords.addAll(batch);

        final total = body['total'] as int? ?? allRecords.length;

        // Stop when we've collected everything or got an empty/short page
        if (allRecords.length >= total || batch.length < batchSize) break;

        page++;
      }

      return allRecords;
    } catch (_) {
      return null;
    }
  }

  // ── PDF builder ───────────────────────────────────────────────────────────
  //
  // FIX: A single pw.Table never page-breaks mid-table in the pdf package.
  // Solution: slice records into chunks of _kRowsPerPage and emit one
  // pw.Table per chunk. pw.MultiPage naturally places each chunk widget,
  // inserting page breaks between them as needed. The column header row is
  // repeated at the top of every chunk so every page is self-contained.
  //
  static Future<Uint8List> _buildPdf(
    List<_Record> records,
    AttendanceExportOptions opts,
  ) async {
    final doc = pw.Document(
      title: 'Attendance Report',
      author: 'Admin',
    );

    const headers = [
      'Intern',
      'Date',
      'Time In',
      'Time Out',
      'Hours',
      'Status'
    ];
    final flex = <double>[3.0, 2.0, 1.5, 1.5, 1.5, 2.0];

    // Slice records into page-sized chunks
    final chunks = <List<_Record>>[];
    for (int i = 0; i < records.length; i += _kRowsPerPage) {
      chunks.add(
        records.sublist(i, (i + _kRowsPerPage).clamp(0, records.length)),
      );
    }

    // Build widget list imperatively — avoid collection-for + spread inside
    // MultiPage's build callback, which can cause the pdf layout engine to
    // silently truncate widgets beyond the first page.
    final List<pw.Widget> pageWidgets = [pw.SizedBox(height: 12)];
    for (int c = 0; c < chunks.length; c++) {
      pageWidgets.add(
        _buildTableChunk(
          chunk: chunks[c],
          chunkIndex: c,
          globalOffset: c * _kRowsPerPage,
          headers: headers,
          flex: flex,
          isFirstChunk: c == 0,
        ),
      );
      if (c < chunks.length - 1) {
        pageWidgets.add(pw.SizedBox(height: 2));
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        header: (ctx) => _buildHeader(ctx, opts, records.length),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => pageWidgets,
      ),
    );

    return doc.save();
  }

  // ── PDF header ────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    pw.Context ctx,
    AttendanceExportOptions opts,
    int totalRecords,
  ) {
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
            decoration: pw.BoxDecoration(color: _pdfAccent),
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
                '${_subtitleText(opts)}  ·  $totalRecords record${totalRecords == 1 ? '' : 's'}',
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
            'Attendance Monitoring',
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

  // ── PDF table chunk ───────────────────────────────────────────────────────
  //
  // Renders one pw.Table for a subset of records. Each chunk includes its
  // own header row so columns are labelled on every page.
  //
  static pw.Widget _buildTableChunk({
    required List<_Record> chunk,
    required int chunkIndex,
    required int globalOffset, // row index of chunk[0] in full list
    required List<String> headers,
    required List<double> flex,
    required bool isFirstChunk,
  }) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _pdfBorder, width: 0.5),
        bottom: pw.BorderSide(color: _pdfBorder, width: 0.5),
        // Draw a top border only on the very first chunk to avoid a
        // double-line where the previous chunk's bottom border sits.
        top: isFirstChunk
            ? pw.BorderSide(color: _pdfBorder, width: 0.5)
            : pw.BorderSide.none,
      ),
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: pw.FlexColumnWidth(flex[i]),
      },
      children: [
        // ── Column header row (repeated on every chunk / page) ─────────────
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _pdfHeaderBg),
          children: headers.map((h) {
            final centered = h == 'Date' || h == 'Status';
            return pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
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
        ...chunk.asMap().entries.map((entry) {
          final localIdx = entry.key;
          final r = entry.value;
          // Use global offset so alternating colours are consistent across chunks
          final globalIdx = globalOffset + localIdx;
          final rowBg =
              globalIdx.isEven ? PdfColors.white : PdfColor.fromHex('FAFAFC');

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _dataCell(r.internName, bold: true, color: _pdfDark),
              _dataCell(r.date, centered: true),
              _dataCell(r.timeIn),
              _dataCell(r.timeOut),
              _dataCell(r.hours),
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: pw.Center(child: _statusBadge(r.status)),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _dataCell(
    String text, {
    bool bold = false,
    bool centered = false,
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
    final bg = colors.$1;
    final textColor = colors.$2;

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
    if (opts.allDates) return 'attendance_all_dates.pdf';
    if (opts.period != null) return 'attendance_${opts.period}.pdf';
    if (opts.dateFrom != null && opts.dateTo != null) {
      return 'attendance_${opts.dateFrom}_to_${opts.dateTo}.pdf'; // ← ADD
    }
    if (opts.date != null) return 'attendance_${opts.date}.pdf';
    return 'attendance_${_todayStr()}.pdf';
  }

  static String _subtitleText(AttendanceExportOptions opts) {
    if (opts.allDates) return 'All Dates';
    if (opts.period != null) {
      return switch (opts.period) {
        'today' => 'Today — ${_todayStr()}',
        'week' => 'This Week',
        'month' => 'This Month',
        _ => opts.period!,
      };
    }
    if (opts.dateFrom != null && opts.dateTo != null) {
      // ← ADD
      return '${_Record._fmtDate(opts.dateFrom!)} – ${_Record._fmtDate(opts.dateTo!)}'; // ← ADD
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
      content: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
            ),
          ),
          SizedBox(width: 14),
          Text(
            'Fetching all records… this may take a moment',
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
