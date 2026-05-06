import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../widgets/admin_sidebar.dart';
import 'export_attendance.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Date helpers
// ─────────────────────────────────────────────────────────────────────────────

String _pad(int n) => n.toString().padLeft(2, '0');

String _formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${_pad(dt.month)}/${_pad(dt.day)}/${dt.year}';
  } catch (_) {
    return iso;
  }
}

String _toApiDate(DateTime dt) =>
    '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';

String _toDisplayDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${_pad(dt.day)}, ${dt.year}';
}

/// Short display: "May 06"
String _toShortDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${_pad(dt.day)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Date range helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the (start, end) DateTime pair for a given period relative to [now].
(DateTime, DateTime) _periodRange(AttendancePeriod period, DateTime now) {
  switch (period) {
    case AttendancePeriod.today:
      return (now, now);
    case AttendancePeriod.week:
      // Monday → Sunday (or today if mid-week)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return (monday, sunday.isAfter(now) ? now : sunday);
    case AttendancePeriod.month:
      final start = DateTime(now.year, now.month, 1);
      return (start, now);
    case AttendancePeriod.year:
      final start = DateTime(now.year, 1, 1);
      return (start, now);
    default:
      return (now, now);
  }
}

/// Formats a period range into a human-readable label.
/// • Same day  → "May 06, 2025"
/// • Same year → "Apr 30 – May 06"
/// • Diff year → "Dec 30, 2024 – Jan 05, 2025"
String _formatDateRange(DateTime start, DateTime end) {
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return _toDisplayDate(start);
  }
  if (start.year == end.year) {
    return '${_toShortDate(start)} – ${_toShortDate(end)}, ${end.year}';
  }
  return '${_toDisplayDate(start)} – ${_toDisplayDate(end)}';
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
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF0A0A14);
const _kAccent = Color(0xFF6C63FF);
const _kCardBg = Color(0xFFFAFAFC);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFEEEFF4);
const _kTextDark = Color(0xFF1A1F3A);
const _kTextMid = Color(0xFF64748B);
const _kTextLight = Color(0xFF94A3B8);
const _kBlue = Color(0xFF00022E);
const _kButtonDark = Color(0xFF0D0D2B);

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
      final staticBase = ApiService.baseUrl
          .replaceAll(RegExp(r'/api/?$'), '')
          .replaceAll(RegExp(r'/$'), '');
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

  static int? _toMinutes(String? time) {
    if (time == null) return null;
    try {
      final iso = DateTime.tryParse(time);
      if (iso != null) {
        final local = iso.toLocal();
        return local.hour * 60 + local.minute;
      }
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return null;
    }
  }

  bool get isOnTime {
    final minutes = _toMinutes(timeIn);
    if (minutes == null) return false;
    return minutes <= 8 * 60;
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
    String? dateFrom,
    String? dateTo,
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
        else if (dateFrom != null && dateTo != null) ...<String, String>{
          'date_from': dateFrom,
          'date_to': dateTo,
        } else if (date != null)
          'date': date,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'All') 'status': status,
        if (userId != null) 'user_id': '$userId',
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
          'total': body['total'] as int? ?? 0
        };
      }
      return {'ok': false, 'error': body['error'] ?? 'Unknown error'};
    } catch (e) {
      return {'ok': false, 'error': 'Connection error: $e'};
    }
  }

  static String exportUrl({
    String? date,
    String? dateFrom,
    String? dateTo,
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
      else if (dateFrom != null && dateTo != null) ...<String, String>{
        'date_from': dateFrom,
        'date_to': dateTo,
      } else if (date != null)
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

  AttendancePeriod _period = AttendancePeriod.today;

  // Single-date custom
  DateTime _customDate = DateTime.now();

  // Date-range custom
  DateTime _customRangeStart = DateTime.now();
  DateTime _customRangeEnd = DateTime.now();
  bool _isRangeMode = false; // false = single day, true = range

  String _selectedStatus = 'All';

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  int _page = 1;
  final int _limit = 20;
  int _total = 0;

  List<AdminAttendanceRecord> _records = [];
  bool _loading = true;
  bool _isFirstLoad = true;
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
      _isFirstLoad = _records.isEmpty;
    });

    final isAllDates = _period == AttendancePeriod.allDates;
    final isCustom = _period == AttendancePeriod.custom;

    final result = await AdminAttendanceService.fetchAttendance(
      allDates: isAllDates,
      period: (!isAllDates && !isCustom) ? _period.apiPeriod : null,
      // Custom range vs single day
      dateFrom: (isCustom && _isRangeMode)
          ? _toApiDate(_customRangeStart)
          : null,
      dateTo: (isCustom && _isRangeMode)
          ? _toApiDate(_customRangeEnd)
          : null,
      date: (isCustom && !_isRangeMode) ? _toApiDate(_customDate) : null,
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
        _isFirstLoad = false;
      });
    } else {
      setState(() {
        _error = result['error'] as String?;
        _loading = false;
        _isFirstLoad = false;
      });
    }
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickCustomDate() async {
    // Show a small modal with two options: single date or date range
    await showDialog(
      context: context,
      builder: (ctx) => _CustomDatePickerDialog(
        initialSingleDate: _customDate,
        initialRangeStart: _customRangeStart,
        initialRangeEnd: _customRangeEnd,
        initialIsRange: _isRangeMode,
        onConfirm: ({
          required bool isRange,
          DateTime? singleDate,
          DateTime? rangeStart,
          DateTime? rangeEnd,
        }) {
          setState(() {
            _isRangeMode = isRange;
            _period = AttendancePeriod.custom;
            if (isRange) {
              _customRangeStart = rangeStart!;
              _customRangeEnd = rangeEnd!;
            } else {
              _customDate = singleDate!;
            }
          });
          _load();
        },
      ),
    );
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

  // ── Active date range label ───────────────────────────────────────────────

  String get _activeDateRangeLabel {
    final now = DateTime.now();
    switch (_period) {
      case AttendancePeriod.allDates:
        return 'All Dates';
      case AttendancePeriod.custom:
        if (_isRangeMode) {
          return _formatDateRange(_customRangeStart, _customRangeEnd);
        }
        return _toDisplayDate(_customDate);
      default:
        final (start, end) = _periodRange(_period, now);
        return _formatDateRange(start, end);
    }
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
                        fit: BoxFit.cover,
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
                              color: _kSurface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: _kBlue.withValues(alpha: 0.08),
                                  blurRadius: 32,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCardHeader(),
                                  _buildToolbar(),
                                  _buildPeriodRow(),
                                  const Divider(
                                      height: 1, thickness: 1, color: _kBorder),
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

  // ── top bar ───────────────────────────────────────────────────────────────

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
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(12),
                  onPressed: () => setState(() => _isSidebarOpen = true),
                  icon: const _HamburgerIcon(),
                  tooltip: 'Open Sidebar',
                  splashColor: Colors.white.withValues(alpha: 0.1),
                  highlightColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── card header ───────────────────────────────────────────────────────────

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kButtonDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fact_check_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Records',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                // ── Date range label ──────────────────────────────────────
                Row(
                  children: [
                    Text(
                      _loading
                          ? 'Loading…'
                          : '$_total ${_total == 1 ? 'record' : 'records'} found',
                      style: const TextStyle(fontSize: 12, color: _kTextMid),
                    ),
                    if (!_loading && _period != AttendancePeriod.allDates) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 11,
                        color: _kBorder,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: _kTextLight),
                      const SizedBox(width: 4),
                      Text(
                        _activeDateRangeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextMid,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _ExportButton(
            onTap: () async {
              final isAllDates = _period == AttendancePeriod.allDates;
              final isCustom = _period == AttendancePeriod.custom;
              await AttendanceExporter.export(
                context,
                options: AttendanceExportOptions(
                  allDates: isAllDates,
                  period: (!isAllDates && !isCustom) ? _period.apiPeriod : null,
                  date: (isCustom && !_isRangeMode)
                      ? _toApiDate(_customDate)
                      : null,
                  search: _searchCtrl.text.trim().isEmpty
                      ? null
                      : _searchCtrl.text.trim(),
                  status: _selectedStatus == 'All' ? null : _selectedStatus,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
      child: Row(
        children: [
          Expanded(
            child: _SearchField(
              controller: _searchCtrl,
              onClear: () {
                _searchCtrl.clear();
                _load();
              },
            ),
          ),
          const SizedBox(width: 12),
          _StatusDropdown(
            value: _selectedStatus,
            onChanged: (v) {
              setState(() => _selectedStatus = v ?? 'All');
              _load();
            },
          ),
          const SizedBox(width: 10),
          _IconActionButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: () => _load(page: _page),
          ),
          if (_searchCtrl.text.isNotEmpty || _selectedStatus != 'All') ...[
            const SizedBox(width: 10),
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
        ],
      ),
    );
  }

  // ── period row ────────────────────────────────────────────────────────────

  Widget _buildPeriodRow() {
    const periods = [
      AttendancePeriod.today,
      AttendancePeriod.week,
      AttendancePeriod.month,
      AttendancePeriod.year,
      AttendancePeriod.allDates,
    ];

    // Build the Custom chip label
    String customLabel;
    if (_period == AttendancePeriod.custom) {
      if (_isRangeMode) {
        customLabel = _formatDateRange(_customRangeStart, _customRangeEnd);
      } else {
        customLabel = _toDisplayDate(_customDate);
      }
    } else {
      customLabel = 'Custom Date';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
      child: Row(
        children: [
          ...periods.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PeriodChip(
                  label: p.label,
                  selected: _period == p,
                  onTap: () {
                    setState(() => _period = p);
                    _load();
                  },
                ),
              )),
          _PeriodChip(
            label: customLabel,
            selected: _period == AttendancePeriod.custom,
            icon: Icons.calendar_today_rounded,
            onTap: _pickCustomDate,
          ),
        ],
      ),
    );
  }

  // ── body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.error_outline_rounded,
                  color: Colors.red.shade400, size: 36),
            ),
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _load(page: _page),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: _kAccent),
            ),
          ],
        ),
      );
    }
    if (_records.isEmpty && !_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.event_busy_rounded,
                  size: 40, color: _kTextLight),
            ),
            const SizedBox(height: 14),
            const Text(
              'No attendance records found',
              style: TextStyle(
                color: _kTextMid,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your filters or date range',
              style: TextStyle(color: _kTextLight, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: _AttendanceTable(records: _records),
    );
  }

  // ── pagination ────────────────────────────────────────────────────────────

  Widget _buildPagination() {
    final totalPages = (_total / _limit).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page $_page of $totalPages',
            style: const TextStyle(
                color: _kTextMid, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            '· $_total records total',
            style: const TextStyle(color: _kTextLight, fontSize: 12),
          ),
          const SizedBox(width: 16),
          _PageButton(
            icon: Icons.chevron_left_rounded,
            enabled: _page > 1,
            onTap: () => _load(page: _page - 1),
          ),
          const SizedBox(width: 6),
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
// Custom Date Picker Dialog (single date OR date range)
// ─────────────────────────────────────────────────────────────────────────────

typedef _DatePickerConfirm = void Function({
  required bool isRange,
  DateTime? singleDate,
  DateTime? rangeStart,
  DateTime? rangeEnd,
});

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialSingleDate;
  final DateTime initialRangeStart;
  final DateTime initialRangeEnd;
  final bool initialIsRange;
  final _DatePickerConfirm onConfirm;

  const _CustomDatePickerDialog({
    required this.initialSingleDate,
    required this.initialRangeStart,
    required this.initialRangeEnd,
    required this.initialIsRange,
    required this.onConfirm,
  });

  @override
  State<_CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late bool _isRange;
  late DateTime _singleDate;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _isRange = widget.initialIsRange;
    _singleDate = widget.initialSingleDate;
    _rangeStart = widget.initialRangeStart;
    _rangeEnd = widget.initialRangeEnd;
  }

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _singleDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _singleDate = picked);
  }

  Future<void> _pickRangeStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked;
        // If start is after end, clamp end to start
        if (_rangeEnd.isBefore(_rangeStart)) {
          _rangeEnd = _rangeStart;
        }
      });
    }
  }

  Future<void> _pickRangeEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEnd.isBefore(_rangeStart) ? _rangeStart : _rangeEnd,
      firstDate: _rangeStart, // can't pick end before start
      lastDate: DateTime.now(),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() => _rangeEnd = picked);
    }
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kAccent,
            onPrimary: Colors.white,
            surface: Color(0xFF1A1F3A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kButtonDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.date_range_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Custom Date Filter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: _kTextLight),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Toggle: Single / Range ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _ModeTab(
                      label: 'Single Date',
                      icon: Icons.today_rounded,
                      selected: !_isRange,
                      onTap: () => setState(() => _isRange = false),
                    ),
                    _ModeTab(
                      label: 'Date Range',
                      icon: Icons.date_range_rounded,
                      selected: _isRange,
                      onTap: () => setState(() => _isRange = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Date display / picker trigger ─────────────────────────
              if (!_isRange) ...[
                _DatePickerTile(
                  label: 'Select Date',
                  value: _toDisplayDate(_singleDate),
                  onTap: _pickSingleDate,
                ),
              ] else ...[
                _DatePickerTile(
                  label: 'From',
                  value: _toDisplayDate(_rangeStart),
                  onTap: _pickRangeStart,
                ),
                const SizedBox(height: 10),
                _DatePickerTile(
                  label: 'To',
                  value: _toDisplayDate(_rangeEnd),
                  onTap: _pickRangeEnd,
                ),
                const SizedBox(height: 6),
                // Range summary pill
                if (_isRange)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _kAccent.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDateRange(_rangeStart, _rangeEnd),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 24),

              // ── Actions ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _kTextMid,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _kBorder),
                        ),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onConfirm(
                          isRange: _isRange,
                          singleDate: _isRange ? null : _singleDate,
                          rangeStart: _isRange ? _rangeStart : null,
                          rangeEnd: _isRange ? _rangeEnd : null,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kButtonDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dialog sub-widgets ────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _kButtonDark : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : _kTextMid),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _kTextMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kTextLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            const VerticalDivider(width: 1, thickness: 1, color: _kBorder),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextDark,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded,
                size: 16, color: _kTextLight),
          ],
        ),
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
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1.5)),
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
                color: _kTextMid,
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
        color: index.isEven ? _kSurface : const Color(0xFFFAFAFC),
      ),
      children: [
        const SizedBox.shrink(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
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
                    color: _kTextDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _cell(r.formattedDate, centered: true),
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
                  style: TextStyle(fontSize: 13, color: _kTextMid)),
        ),
        _cell(r.timeOut ?? '--'),
        _cell(r.formattedHours),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          child: Center(child: _StatusBadge(status: r.status)),
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
          style: const TextStyle(fontSize: 13, color: _kTextMid),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchField({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: _kTextDark),
        decoration: InputDecoration(
          hintText: 'Search intern by name…',
          hintStyle: const TextStyle(fontSize: 13, color: _kTextLight),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 18, color: _kTextLight),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: _kTextLight),
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
            borderSide: const BorderSide(color: _kAccent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon action button
// ─────────────────────────────────────────────────────────────────────────────

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.refresh_rounded, color: _kTextMid, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export button
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ExportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kButtonDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Export PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _kButtonDark : const Color(0xFFF4F5F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kButtonDark : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? Colors.white : _kTextMid),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kTextMid,
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
          style: const TextStyle(fontSize: 13, color: _kTextDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: _kTextMid),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent, width: 1.2),
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
        border = _kAccent;
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
        style:
            TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 12),
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
      color: enabled ? _kButtonDark : const Color(0xFFF4F5F8),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.white : _kTextLight,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intern avatar
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
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}