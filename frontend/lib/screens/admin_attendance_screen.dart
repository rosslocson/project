// lib/screens/admin_attendance_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../widgets/admin_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Date helpers
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

/// DateTime → "YYYY-MM-DD"
String _toApiDate(DateTime dt) =>
    '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';

/// DateTime → "Apr 27, 2026"
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
  final String  department;
  final String  school;
  final String  program;
  final String  startDate;
  final String  endDate;
  final double  requiredOjtHours;
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
    required this.department,
    required this.school,
    required this.program,
    required this.startDate,
    required this.endDate,
    required this.requiredOjtHours,
    required this.date,
    this.timeIn,
    this.timeOut,
    this.hoursRendered,
    required this.status,
  });

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> j) {
    return AdminAttendanceRecord(
      id:               j['id']                 as int?    ?? 0,
      userId:           j['user_id']            as int?    ?? 0,
      internName:       j['intern_name']        as String? ?? 'Unknown',
      avatarUrl:        j['avatar_url']         as String? ?? '',
      department:       j['department']         as String? ?? '',
      school:           j['school']             as String? ?? '',
      program:          j['program']            as String? ?? '',
      startDate:        j['start_date']         as String? ?? '',
      endDate:          j['end_date']           as String? ?? '',
      requiredOjtHours: (j['required_ojt_hours'] as num?)?.toDouble() ?? 0,
      date:             j['date']               as String? ?? '',
      timeIn:           j['time_in']            as String?,
      timeOut:          j['time_out']           as String?,
      hoursRendered:    (j['hours_rendered']    as num?)?.toDouble(),
      status:           j['status']             as String? ?? 'Absent',
    );
  }

  String get formattedHours {
    if (hoursRendered == null) return '--';
    final h = hoursRendered!.floor();
    final m = ((hoursRendered! - h) * 60).round();
    return '${h}h ${m}m';
  }

  String get formattedDate    => _formatDate(date);
  String get formattedStart   => startDate.isEmpty ? '--' : _formatDate(startDate);
  String get formattedEnd     => endDate.isEmpty   ? '--' : _formatDate(endDate);
  String get requiredHoursStr => requiredOjtHours == 0
      ? '--'
      : '${requiredOjtHours.toStringAsFixed(0)}h';
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class AdminAttendanceService {
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
  bool _isSidebarOpen = true;

  DateTime _selectedDate = DateTime.now();
  bool     _allDates     = false;

  int       _page  = 1;
  final int _limit = 20;
  int       _total = 0;

  List<AdminAttendanceRecord> _records = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve:    Curves.easeInOut,
            width:    _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen
                ? AdminSidebar(
                    currentRoute: '/admin/attendance',
                    onClose: () => setState(() => _isSidebarOpen = false),
                  )
                : null,
          ),
          Expanded(
            child: Stack(
              children: [
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
                      _buildTopBar(context),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
          if (!_isSidebarOpen)
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
                  onPressed:      () => setState(() => _isSidebarOpen = true),
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
              // Replace _snack with launchUrl(Uri.parse(url)) once
              // url_launcher is added to pubspec.yaml
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _AttendanceTable(records: _records),
      ),
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

  // Column indices
  // 0  Intern name + avatar
  // 1  Department
  // 2  School
  // 3  Program
  // 4  OJT Period (start → end)
  // 5  Required Hours
  // 6  Date
  // 7  Time In
  // 8  Time Out
  // 9  Hours Worked
  // 10 Status

  static const _headers = [
    'Intern',
    'Department',
    'School',
    'Program',
    'OJT Period',
    'Required Hrs',
    'Date',
    'Time In',
    'Time Out',
    'Hours Worked',
    'Status',
  ];

  static const _colWidths = <int, TableColumnWidth>{
    0:  FixedColumnWidth(180), // Intern
    1:  FixedColumnWidth(160), // Department
    2:  FixedColumnWidth(200), // School
    3:  FixedColumnWidth(180), // Program
    4:  FixedColumnWidth(180), // OJT Period
    5:  FixedColumnWidth(110), // Required Hrs
    6:  FixedColumnWidth(120), // Date
    7:  FixedColumnWidth(100), // Time In
    8:  FixedColumnWidth(100), // Time Out
    9:  FixedColumnWidth(110), // Hours Worked
    10: FixedColumnWidth(150), // Status
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
        ...records.map(_buildRow),
      ],
    );
  }

  TableRow _buildHeader() {
    return TableRow(
      decoration: const BoxDecoration(
        color:  Color(0xFFF8F9FB),
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 2)),
      ),
      children: _headers.map((h) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Text(
          h,
          style: const TextStyle(
            fontWeight:    FontWeight.w700,
            fontSize:      13,
            color:         Color(0xFF1A1F3A),
            letterSpacing: 0.2,
          ),
        ),
      )).toList(),
    );
  }

  TableRow _buildRow(AdminAttendanceRecord r) {
    final ojtPeriod = (r.startDate.isEmpty && r.endDate.isEmpty)
        ? '--'
        : '${r.formattedStart} → ${r.formattedEnd}';

    return TableRow(
      children: [
        // 0 — Intern
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              _InternAvatar(url: r.avatarUrl, name: r.internName),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  r.internName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                    color:      Color(0xFF1A1F3A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // 1 — Department
        _cell(r.department.isEmpty ? '--' : r.department),
        // 2 — School
        _cell(r.school.isEmpty ? '--' : r.school),
        // 3 — Program
        _cell(r.program.isEmpty ? '--' : r.program),
        // 4 — OJT Period
        _cell(ojtPeriod),
        // 5 — Required Hours
        _cell(r.requiredHoursStr),
        // 6 — Date
        _cell(r.formattedDate),
        // 7 — Time In
        _cell(r.timeIn  ?? '--'),
        // 8 — Time Out
        _cell(r.timeOut ?? '--'),
        // 9 — Hours Worked
        _cell(r.formattedHours),
        // 10 — Status
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: _StatusBadge(status: r.status),
        ),
      ],
    );
  }

  Widget _cell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
    ),
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
        radius:                 18,
        backgroundImage:        NetworkImage(url),
        backgroundColor:        const Color(0xFF6C63FF),
        onBackgroundImageError: (_, __) {},
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
      case 'Missed Clock Out':
        border = const Color(0xFFEA580C);
        text   = const Color(0xFFC2410C);
        bg     = const Color(0xFFFFF7ED);
      case 'Absent':
        border = const Color(0xFFEF4444);
        text   = const Color(0xFFDC2626);
        bg     = const Color(0xFFFEF2F2);
      default:
        border = const Color(0xFFEF4444);
        text   = const Color(0xFFDC2626);
        bg     = const Color(0xFFFEF2F2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: border, width: 1.5),
      ),
      child: Text(
        status,
        style: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 11),
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