// lib/screens/admin_attendance_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/sidebar_provider.dart';
import '../services/api_service.dart';
import '../widgets/admin_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Date helpers — no intl package needed
// ─────────────────────────────────────────────────────────────────────────────

String _pad(int n) => n.toString().padLeft(2, '0');

/// "2026-04-27" → "04/27/2026"
String _formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${_pad(dt.month)}/${_pad(dt.day)}/${dt.year}';
  } catch (_) {
    return iso;
  }
}

/// DateTime → "YYYY-MM-DD"  (for API calls)
String _toApiDate(DateTime dt) =>
    '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';

/// DateTime → "Apr 27, 2026"  (for toolbar label)
String _toDisplayDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${_pad(dt.day)}, ${dt.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class AdminAttendanceRecord {
  final int     id;
  final int     userId;
  final String  internName;
  final String  avatarUrl;
  final String  date;
  final String? timeIn;
  final String? timeOut;
  final double? hoursRendered;
  final String  status;

  const AdminAttendanceRecord({
    required this.id,
    required this.userId,
    required this.internName,
    required this.avatarUrl,
    required this.date,
    this.timeIn,
    this.timeOut,
    this.hoursRendered,
    required this.status,
  });

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> j) {
    return AdminAttendanceRecord(
      id:            j['id']            as int?    ?? 0,
      userId:        j['user_id']       as int?    ?? 0,
      internName:    j['intern_name']   as String? ?? 'Unknown',
      avatarUrl:     j['avatar_url']    as String? ?? '',
      date:          j['date']          as String? ?? '',
      timeIn:        j['time_in']       as String?,
      timeOut:       j['time_out']      as String?,
      hoursRendered: (j['hours_rendered'] as num?)?.toDouble(),
      status:        j['status']        as String? ?? 'Absent',
    );
  }

  String get formattedHours {
    if (hoursRendered == null) return '0h 0m';
    final h = hoursRendered!.floor();
    final m = ((hoursRendered! - h) * 60).round();
    return '${h}h ${m}m';
  }

  String get formattedDate => _formatDate(date);
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class AdminAttendanceService {
  /// GET /api/admin/attendance
  static Future<Map<String, dynamic>> fetchAttendance({
    String? date,
    bool    allDates = false,
    int     page     = 1,
    int     limit    = 20,
    int?    userId,
  }) async {
    try {
      final params = <String, String>{
        'page':  '$page',
        'limit': '$limit',
        if (allDates) 'all_dates': 'true'
        else if (date != null) 'date': date,
        if (userId != null) 'user_id': '$userId',
      };
      final uri = Uri.parse('${ApiService.baseUrl}/admin/attendance')
          .replace(queryParameters: params);
      final res  = await http.get(uri, headers: await ApiService.authHeaders());
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ok'] == true) {
        final records = (body['records'] as List? ?? [])
            .map((e) => AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'ok': true, 'records': records, 'total': body['total'] as int? ?? 0};
      }
      return {'ok': false, 'error': body['error'] ?? 'Unknown error'};
    } catch (e) {
      return {'ok': false, 'error': 'Connection error: $e'};
    }
  }

  /// Builds the CSV export URL — open with url_launcher in your app.
  static String exportUrl({String? date, bool allDates = false}) {
    final params = <String, String>{
      if (allDates) 'all_dates': 'true'
      else if (date != null) 'date': date,
    };
    return Uri.parse('${ApiService.baseUrl}/admin/attendance/export')
        .replace(queryParameters: params)
        .toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  // ── Filter ─────────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  bool     _allDates     = false;

  // ── Pagination ─────────────────────────────────────────────────────────────
  int       _page  = 1;
  final int _limit = 20;   // final → fixes prefer_final_fields lint
  int       _total = 0;

  // ── Data ───────────────────────────────────────────────────────────────────
  List<AdminAttendanceRecord> _records = [];
  bool    _loading = true;
  String? _error;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> _load({int page = 1}) async {
    setState(() { _loading = true; _error = null; _page = page; });

    final result = await AdminAttendanceService.fetchAttendance(
      date:     _allDates ? null : _toApiDate(_selectedDate),
      allDates: _allDates,
      page:     page,
      limit:    _limit,
    );

    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        _records = result['records'] as List<AdminAttendanceRecord>;
        _total   = result['total']   as int;
        _loading = false;
      });
    } else {
      setState(() { _error = result['error'] as String?; _loading = false; });
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDate,
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   Color(0xFF6C63FF),
            onPrimary: Colors.white,
            surface:   Color(0xFF1A1F3A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _selectedDate = picked; _allDates = false; });
      _load();
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/attendance',
      child:        _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final sidebar = context.watch<SidebarProvider>();
    return Stack(
      children: [
        // Space background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/space_background.png'),
                fit:   BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context, sidebar),
              const SizedBox(height: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 100, right: 100, bottom: 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color:        Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: [
                          _buildToolbar(),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                          Expanded(child: _buildBody()),
                          if (_total > _limit) _buildPagination(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, SidebarProvider sidebar) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 100, right: 100, top: 28),
            child: Text(
              'Attendance Monitoring',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize:      28,
                fontWeight:    FontWeight.w800,
                color:         Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (!sidebar.isUserSidebarOpen)
            Positioned(
              left: 20,
              top:  28,
              child: Container(
                decoration: BoxDecoration(
                  color:        Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: IconButton(
                  padding:        const EdgeInsets.all(12),
                  onPressed:      () => sidebar.setUserSidebarOpen(true),
                  icon:           const _HamburgerIcon(),
                  tooltip:        'Open Sidebar',
                  splashColor:    Colors.white.withValues(alpha: 0.1),
                  highlightColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final dateLabel = _allDates ? 'All Dates' : _toDisplayDate(_selectedDate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _ToolbarButton(
            icon:   Icons.calendar_today_rounded,
            label:  dateLabel,
            accent: const Color(0xFF6C63FF),
            onTap:  _pickDate,
          ),
          const SizedBox(width: 10),
          FilterChip(
            label:          const Text('All Dates'),
            selected:       _allDates,
            onSelected:     (v) { setState(() => _allDates = v); _load(); },
            selectedColor:  const Color(0xFF6C63FF).withValues(alpha: 0.15),
            checkmarkColor: const Color(0xFF6C63FF),
            labelStyle: TextStyle(
              color:      _allDates ? const Color(0xFF6C63FF) : Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize:   13,
            ),
            side: BorderSide(
              color: _allDates ? const Color(0xFF6C63FF) : Colors.grey.shade300,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _load(page: _page),
            icon:      const Icon(Icons.refresh_rounded, color: Colors.black54),
            tooltip:   'Refresh',
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon:   Icons.download_rounded,
            label:  'Export CSV',
            accent: const Color(0xFF22C55E),
            onTap: () {
              final url = AdminAttendanceService.exportUrl(
                date:     _allDates ? null : _toApiDate(_selectedDate),
                allDates: _allDates,
              );
              // Swap the snack for: launchUrl(Uri.parse(url))
              // once url_launcher is added to pubspec.yaml
              _snack(url);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _load(page: _page),
              icon:      const Icon(Icons.refresh_rounded),
              label:     const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'No attendance records found',
              style: TextStyle(color: Colors.black45, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: _AttendanceTable(records: _records),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / _limit).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page $_page of $totalPages  ($_total records)',
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(width: 16),
          _PageButton(
            icon:    Icons.chevron_left_rounded,
            enabled: _page > 1,
            onTap:   () => _load(page: _page - 1),
          ),
          const SizedBox(width: 8),
          _PageButton(
            icon:    Icons.chevron_right_rounded,
            enabled: _page < totalPages,
            onTap:   () => _load(page: _page + 1),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceTable extends StatelessWidget {
  final List<AdminAttendanceRecord> records;
  const _AttendanceTable({required this.records});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.8),
        5: FlexColumnWidth(1.2),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade100),
      ),
      children: [
        _buildHeader(),
        ...records.map(_buildRow),
      ],
    );
  }

  TableRow _buildHeader() {
    const headers = [
      'Intern', 'Date', 'Time In', 'Time Out', 'Total Worked Hours', 'Status',
    ];
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 2)),
      ),
      children: headers.map((h) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Text(
          h,
          style: const TextStyle(
            fontWeight:    FontWeight.w700,
            fontSize:      14,
            color:         Color(0xFF1A1F3A),
            letterSpacing: 0.2,
          ),
        ),
      )).toList(),
    );
  }

  TableRow _buildRow(AdminAttendanceRecord r) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              _InternAvatar(url: r.avatarUrl, name: r.internName),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  r.internName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   14,
                    color:      Color(0xFF1A1F3A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _cell(r.formattedDate),
        _cell(r.timeIn  ?? '--:--'),
        _cell(r.timeOut ?? '--:--'),
        _cell(r.formattedHours),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: _StatusBadge(status: r.status),
        ),
      ],
    );
  }

  Widget _cell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF444444))),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InternAvatar extends StatelessWidget {
  final String url;
  final String name;
  const _InternAvatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    if (url.isNotEmpty) {
      return CircleAvatar(
        radius:                  18,
        backgroundImage:         NetworkImage(url),
        backgroundColor:         const Color(0xFF6C63FF),
        onBackgroundImageError:  (_, __) {},
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );
    }
    return CircleAvatar(
      radius:          18,
      backgroundColor: const Color(0xFF6C63FF),
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color text;
    final Color bg;

    // Switch with Dart 3 exhaustive style — no break needed
    switch (status) {
      case 'Present':
        border = const Color(0xFF22C55E);
        text   = const Color(0xFF16A34A);
        bg     = const Color(0xFFF0FDF4);
      case 'Late':
        border = const Color(0xFFF59E0B);
        text   = const Color(0xFFB45309);
        bg     = const Color(0xFFFFFBEB);
      case 'In Progress':
        border = const Color(0xFF6C63FF);
        text   = const Color(0xFF4F46E5);
        bg     = const Color(0xFFEEF2FF);
      default:
        border = const Color(0xFFEF4444);
        text   = const Color(0xFFDC2626);
        bg     = const Color(0xFFFEF2F2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: border, width: 1.5),
      ),
      child: Text(
        status,
        style: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        accent;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData     icon;
  final bool         enabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        enabled ? const Color(0xFF6C63FF) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap:        enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size:  20,
            color: enabled ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

class _HamburgerIcon extends StatelessWidget {
  const _HamburgerIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:  MainAxisAlignment.spaceBetween,
        children: [
          _bar(22),
          _bar(14, opacity: 0.8),
          _bar(22),
        ],
      ),
    );
  }

  Widget _bar(double w, {double opacity = 1.0}) => Container(
    width:  w,
    height: 2.5,
    decoration: BoxDecoration(
      color:        Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}