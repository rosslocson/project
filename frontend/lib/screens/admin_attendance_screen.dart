// lib/screens/admin_attendance_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month - 1]} ${_pad(dt.day)}, ${dt.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Period enum
// ─────────────────────────────────────────────────────────────────────────────

enum AttendancePeriod { custom, today, week, month, year, allDates }

extension AttendancePeriodExt on AttendancePeriod {
  String get label => switch (this) {
        AttendancePeriod.custom => 'Custom',
        AttendancePeriod.today => 'Today',
        AttendancePeriod.week => 'This Week',
        AttendancePeriod.month => 'This Month',
        AttendancePeriod.year => 'This Year',
        AttendancePeriod.allDates => 'All Dates',
      };

  String? get apiPeriod => switch (this) {
        AttendancePeriod.today => 'today',
        AttendancePeriod.week => 'week',
        AttendancePeriod.month => 'month',
        AttendancePeriod.year => 'year',
        _ => null,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Status options
// ─────────────────────────────────────────────────────────────────────────────

const _kStatuses = [
  'All',
  'Present',
  'Late',
  'On Shift',
  'Missed Clock Out',
  'Absent',
];

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class AdminAttendanceRecord {
  final int id;
  final int userId;
  final String internName;
  final String avatarUrl;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final double? hoursRendered;
  final String status;

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
    final rawAvatar = j['avatar_url'] as String? ?? '';
    String avatarUrl = rawAvatar;

    if (rawAvatar.isNotEmpty &&
        !rawAvatar.startsWith('http://') &&
        !rawAvatar.startsWith('https://')) {
      // Uploads are served at the SERVER ROOT (e.g. /uploads/foo.jpg),
      // NOT under /api. Strip the trailing /api segment from baseUrl so we
      // don't produce a broken path like /api/uploads/foo.jpg (→ 404).
      final staticBase = ApiService.baseUrl
          .replaceAll(RegExp(r'/api/?$'), '') // remove trailing /api or /api/
          .replaceAll(RegExp(r'/$'), ''); // remove any remaining trailing /

      final cleanPath = rawAvatar.startsWith('/') ? rawAvatar : '/$rawAvatar';
      avatarUrl = '$staticBase$cleanPath';
    }

    return AdminAttendanceRecord(
      id: j['id'] as int? ?? 0,
      userId: j['user_id'] as int? ?? 0,
      internName: j['intern_name'] as String? ?? 'Unknown',
      avatarUrl: avatarUrl,
      date: j['date'] as String? ?? '',
      timeIn: j['time_in'] as String?,
      timeOut: j['time_out'] as String?,
      hoursRendered: (j['hours_rendered'] as num?)?.toDouble(),
      status: j['status'] as String? ?? 'Absent',
    );
  }

  String get formattedHours {
    if (hoursRendered == null) return '--';
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
  static Future<Map<String, dynamic>> fetchAttendance({
    String? date,
    String? period,
    bool allDates = false,
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
    int? userId,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (allDates)
          'all_dates': 'true'
        else if (period != null)
          'period': period
        else if (date != null)
          'date': date,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'All')   'status': status,
        if (userId != null)                       'user_id': '$userId',
      };
      final uri = Uri.parse('${ApiService.baseUrl}/admin/attendance')
          .replace(queryParameters: params);
      final res = await http.get(uri, headers: await ApiService.authHeaders());
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ok'] == true) {
        final records = (body['records'] as List? ?? [])
            .map((e) =>
                AdminAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'ok': true,
          'records': records,
          'total': body['total'] as int? ?? 0,
        };
      }
      return {'ok': false, 'error': body['error'] ?? 'Unknown error'};
    } catch (e) {
      return {'ok': false, 'error': 'Connection error: $e'};
    }
  }

  static String exportUrl({
    String? date,
    String? period,
    bool allDates = false,
    String? search,
    String? status,
  }) {
    final params = <String, String>{
      if (allDates)
        'all_dates': 'true'
      else if (period != null)
        'period': period
      else if (date != null)
        'date': date,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != 'All') 'status': status,
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

  // ── filter state ──────────────────────────────────────────────────────────
  AttendancePeriod _period = AttendancePeriod.today;
  DateTime _customDate = DateTime.now();
  String _selectedStatus = 'All';

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // ── pagination ────────────────────────────────────────────────────────────
  int _page = 1;
  final int _limit = 20;
  int _total = 0;

  List<AdminAttendanceRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load());
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
      _page = page;
    });

    final isAllDates = _period == AttendancePeriod.allDates;
    final isCustom = _period == AttendancePeriod.custom;

    final result = await AdminAttendanceService.fetchAttendance(
      allDates: isAllDates,
      period: (!isAllDates && !isCustom) ? _period.apiPeriod : null,
      date: isCustom ? _toApiDate(_customDate) : null,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      status: _selectedStatus == 'All' ? null : _selectedStatus,
      page: page,
      limit: _limit,
    );
    if (!mounted) return;
    if (result['ok'] == true) {
      setState(() {
        _records = result['records'] as List<AdminAttendanceRecord>;
        _total = result['total'] as int;
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['error'] as String?;
        _loading = false;
      });
    }
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            onPrimary: Colors.white,
            surface: Color(0xFF1A1F3A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customDate = picked;
        _period = AttendancePeriod.custom;
      });
      _load();
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
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
                        image: AssetImage('assets/images/space_background.jpg'),
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
                          padding: const EdgeInsets.only(
                              left: 100, right: 100, bottom: 28),
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
                                  _buildFilterRow(),
                                  const Divider(
                                      height:    1,
                                      thickness: 1,
                                      color:     Color(0xFFEEEEEE)),
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
    ); // Fixed: Added missing semicolon
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
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          if (!_isSidebarOpen)
            Positioned(
              left: 20,
              top: 28,
              child: Container(
                decoration: BoxDecoration(
                  color:        Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15)),
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

  // ── toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Row(
        children: [
          // Search
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search intern by name…',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: Colors.black38),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.black38),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _searchCtrl.clear();
                            _load();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF4F4F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status dropdown
          _StatusDropdown(
            value: _selectedStatus,
            onChanged: (v) {
              setState(() => _selectedStatus = v ?? 'All');
              _load();
            },
          ),
          const SizedBox(width: 12),

          // Refresh
          IconButton(
            onPressed: () => _load(page: _page),
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),

          // Export CSV
          _ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Export CSV',
            accent: const Color(0xFF22C55E),
            onTap: () {
              final isAllDates = _period == AttendancePeriod.allDates;
              final isCustom = _period == AttendancePeriod.custom;
              final url = AdminAttendanceService.exportUrl(
                allDates: isAllDates,
                period: (!isAllDates && !isCustom) ? _period.apiPeriod : null,
                date: isCustom ? _toApiDate(_customDate) : null,
                search: _searchCtrl.text.trim().isEmpty
                    ? null
                    : _searchCtrl.text.trim(),
                status: _selectedStatus == 'All' ? null : _selectedStatus,
              );
              // TODO: replace with launchUrl(Uri.parse(url)) once
              // url_launcher is added to pubspec.yaml
              _snack(url);
            },
          ),
        ],
      ),
    );
  }

  // ── filter row ────────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    const periods = [
      AttendancePeriod.today,
      AttendancePeriod.week,
      AttendancePeriod.month,
      AttendancePeriod.year,
      AttendancePeriod.allDates,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(
        children: [
          ...periods.map((p) {
            final selected = _period == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PeriodChip(
                label: p.label,
                selected: selected,
                onTap: () {
                  setState(() => _period = p);
                  _load();
                },
              ),
            );
          }),

          // Custom date picker chip
          _PeriodChip(
            label: _period == AttendancePeriod.custom
                ? _toDisplayDate(_customDate)
                : 'Custom Date',
            selected: _period == AttendancePeriod.custom,
            icon: Icons.calendar_today_rounded,
            onTap: _pickCustomDate,
          ),

          const Spacer(),

          if (_searchCtrl.text.isNotEmpty || _selectedStatus != 'All')
            _ActiveFiltersBadge(
              count: (_searchCtrl.text.isNotEmpty ? 1 : 0) +
                  (_selectedStatus != 'All' ? 1 : 0),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _selectedStatus = 'All');
                _load();
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
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
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
            icon: Icons.chevron_left_rounded,
            enabled: _page > 1,
            onTap: () => _load(page: _page - 1),
          ),
          const SizedBox(width: 8),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            enabled: _page < totalPages,
            onTap: () => _load(page: _page + 1),
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

  static const _headers = [
    'Intern',
    'Date',
    'Time In',
    'Time Out',
    'Hours Worked',
    'Status',
  ];

  static const _colWidths = <int, TableColumnWidth>{
    0: FixedColumnWidth(200),
    1: FixedColumnWidth(130),
    2: FixedColumnWidth(110),
    3: FixedColumnWidth(110),
    4: FixedColumnWidth(120),
    5: FixedColumnWidth(160),
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
        color: Color(0xFFF8F9FB),
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 2)),
      ),
      children: _headers
          .map((h) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                child: Text(
                  h,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1A1F3A),
                    letterSpacing: 0.2,
                  ),
                ),
              ))
          .toList(),
    );
  }

  TableRow _buildRow(AdminAttendanceRecord r) {
    return TableRow(
      children: [
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
                    fontSize: 13,
                    color: Color(0xFF1A1F3A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _cell(r.formattedDate),
        _cell(r.timeIn ?? '--'),
        _cell(r.timeOut ?? '--'),
        _cell(r.formattedHours),
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
// _InternAvatar
//
// Fetches the avatar image manually with auth headers (so protected upload
// routes work). The URL is already fully resolved in fromJson, so this widget
// just fires a GET with the bearer token and renders the bytes.
// Falls back gracefully to initials on any error or empty URL.
// ─────────────────────────────────────────────────────────────────────────────

class _InternAvatar extends StatefulWidget {
  final String url;
  final String name;
  const _InternAvatar({required this.url, required this.name});

  @override
  State<_InternAvatar> createState() => _InternAvatarState();
}

class _InternAvatarState extends State<_InternAvatar> {
  Uint8List? _imageBytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  @override
  void didUpdateWidget(_InternAvatar old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() {
        _loading = true;
        _failed = false;
        _imageBytes = null;
      });
      _fetchImage();
    }
  }

  Future<void> _fetchImage() async {
    if (widget.url.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
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
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
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
      backgroundColor: const Color(0xFF6C63FF),
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white54,
              ),
            )
          : _imageBytes != null
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
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period chip
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0A0A14);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent : const Color(0xFFF4F4F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13, color: selected ? Colors.white : Colors.black54),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A1F3A)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: Colors.black45),
          items: _kStatuses.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(s, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active filters badge
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveFiltersBadge extends StatelessWidget {
  final int count;
  final VoidCallback onClear;

  const _ActiveFiltersBadge({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF), width: 1.2),
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

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

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
        text = const Color(0xFF16A34A);
        bg = const Color(0xFFF0FDF4);
      case 'Late':
        border = const Color(0xFFF59E0B);
        text = const Color(0xFFB45309);
        bg = const Color(0xFFFFFBEB);
      case 'On Shift':
        border = const Color(0xFF6C63FF);
        text = const Color(0xFF4F46E5);
        bg = const Color(0xFFEEF2FF);
      case 'Missed Clock Out':
        border = const Color(0xFFEA580C);
        text = const Color(0xFFC2410C);
        bg = const Color(0xFFFFF7ED);
      case 'Absent':
      default:
        border = const Color(0xFFEF4444);
        text = const Color(0xFFDC2626);
        bg = const Color(0xFFFEF2F2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Center(
        child: Text(
          status,
          textAlign: TextAlign.center,
          style:
              TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 11),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar button
// ─────────────────────────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    color: accent, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page button
// ─────────────────────────────────────────────────────────────────────────────

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xFF6C63FF) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hamburger icon
// ─────────────────────────────────────────────────────────────────────────────

class _HamburgerIcon extends StatelessWidget {
  const _HamburgerIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bar(22),
          _bar(14, opacity: 0.8),
          _bar(22),
        ],
      ),
    );
  }

  Widget _bar(double w, {double opacity = 1.0}) => Container(
        width: w,
        height: 2.5,
        decoration: BoxDecoration(
          color:        Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
