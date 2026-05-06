// lib/screens/admin_attendance_screen.dart
// Admin attendance monitoring screen.
// Owns layout and state only — all widgets are in admin_attendance_widgets/.

import 'dart:async';
import 'package:flutter/material.dart';

import '../models/attendance_constants.dart';
import '../models/attendance_record.dart';
import '../services/admin_attendance_service.dart';
import '../services/date_helpers.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_attendance_widgets/attendance_filters.dart';
import '../widgets/admin_attendance_widgets/attendance_table.dart';
import '../widgets/admin_attendance_widgets/attendance_ui_components.dart';
import '../widgets/admin_attendance_widgets/custom_date_picker_dialog.dart';
import 'export_attendance.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  // ── Sidebar ───────────────────────────────────────────────────────────────
  bool _isSidebarOpen = true;

  // ── Period / date ─────────────────────────────────────────────────────────
  AttendancePeriod _period = AttendancePeriod.today;
  DateTime _customDate       = DateTime.now();
  DateTime _customRangeStart = DateTime.now();
  DateTime _customRangeEnd   = DateTime.now();
  bool _isRangeMode = false;

  // ── Filters ───────────────────────────────────────────────────────────────
  String _selectedStatus = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // ── Pagination ────────────────────────────────────────────────────────────
  int _page = 1;
  static const int _limit = 20;
  int _total = 0;

  // ── Data ──────────────────────────────────────────────────────────────────
  List<AdminAttendanceRecord> _records = [];
  bool _loading = true;
  String? _error;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error   = null;
      _page    = page;
    });

    final isAllDates = _period == AttendancePeriod.allDates;
    final isCustom   = _period == AttendancePeriod.custom;

    final result = await AdminAttendanceService.fetchAttendance(
      allDates: isAllDates,
      period:   (!isAllDates && !isCustom) ? _period.apiPeriod : null,
      dateFrom: (isCustom && _isRangeMode) ? toApiDate(_customRangeStart) : null,
      dateTo:   (isCustom && _isRangeMode) ? toApiDate(_customRangeEnd)   : null,
      date:     (isCustom && !_isRangeMode) ? toApiDate(_customDate)      : null,
      search:   _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      status:   _selectedStatus == 'All' ? null : _selectedStatus,
      page:     page,
      limit:    _limit,
    );

    if (!mounted) return;

    if (result['ok'] == true) {
      setState(() {
        _records = result['records'] as List<AdminAttendanceRecord>;
        _total   = result['total'] as int;
        _loading = false;
      });
    } else {
      setState(() {
        _error   = result['error'] as String?;
        _loading = false;
      });
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickCustomDate() async {
    await showDialog(
      context: context,
      builder: (_) => CustomDatePickerDialog(
        initialSingleDate: _customDate,
        initialRangeStart: _customRangeStart,
        initialRangeEnd:   _customRangeEnd,
        initialIsRange:    _isRangeMode,
        onConfirm: ({
          required bool isRange,
          DateTime? singleDate,
          DateTime? rangeStart,
          DateTime? rangeEnd,
        }) {
          setState(() {
            _isRangeMode = isRange;
            _period      = AttendancePeriod.custom;
            if (isRange) {
              _customRangeStart = rangeStart!;
              _customRangeEnd   = rangeEnd!;
            } else {
              _customDate = singleDate!;
            }
          });
          _load();
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _activeDateRangeLabel {
    final now = DateTime.now();
    return switch (_period) {
      AttendancePeriod.allDates => 'All Dates',
      AttendancePeriod.custom   => _isRangeMode
          ? formatDateRange(_customRangeStart, _customRangeEnd)
          : toDisplayDate(_customDate),
      _ => () {
          final (start, end) = periodRange(_period, now);
          return formatDateRange(start, end);
        }(),
    };
  }

  int get _activeFilterCount =>
      (_searchCtrl.text.isNotEmpty ? 1 : 0) +
      (_selectedStatus != 'All' ? 1 : 0);

  void _clearAllFilters() {
    _searchCtrl.clear();
    setState(() => _selectedStatus = 'All');
    _load();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          // Sidebar
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

          // Main area
          Expanded(
            child: Stack(
              children: [
                // Background image
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
                      _buildTopBar(),
                      const SizedBox(height: 15),
                      Expanded(child: _buildCard()),
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

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
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
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(12),
                  onPressed: () => setState(() => _isSidebarOpen = true),
                  icon: const HamburgerIcon(),
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

  // ── White card ────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 100, right: 100, bottom: 28),
      child: Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kBlue.withValues(alpha: 0.08),
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
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(child: _buildBody()),
              if (_total > _limit) _buildPagination(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card header ───────────────────────────────────────────────────────────

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: const BoxDecoration(
        color: kCardBg,
        border: Border(bottom: BorderSide(color: kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kButtonDark,
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
                    color: kTextDark,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _loading
                          ? 'Loading…'
                          : '$_total ${_total == 1 ? 'record' : 'records'} found',
                      style:
                          const TextStyle(fontSize: 12, color: kTextMid),
                    ),
                    if (!_loading &&
                        _period != AttendancePeriod.allDates) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 11,
                        color: kBorder,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: kTextLight),
                      const SizedBox(width: 4),
                      Text(
                        _activeDateRangeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kTextMid,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ExportButton(
            onTap: () async {
              final isAllDates = _period == AttendancePeriod.allDates;
              final isCustom   = _period == AttendancePeriod.custom;
              await AttendanceExporter.export(
                context,
                options: AttendanceExportOptions(
                  allDates: isAllDates,
                  period: (!isAllDates && !isCustom)
                      ? _period.apiPeriod
                      : null,
                  date: (isCustom && !_isRangeMode)
                      ? toApiDate(_customDate)
                      : null,
                  search: _searchCtrl.text.trim().isEmpty
                      ? null
                      : _searchCtrl.text.trim(),
                  status: _selectedStatus == 'All'
                      ? null
                      : _selectedStatus,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
      child: Row(
        children: [
          Expanded(
            child: AttendanceSearchField(
              controller: _searchCtrl,
              onClear: () {
                _searchCtrl.clear();
                _load();
              },
            ),
          ),
          const SizedBox(width: 12),
          AttendanceStatusDropdown(
            value: _selectedStatus,
            onChanged: (v) {
              setState(() => _selectedStatus = v ?? 'All');
              _load();
            },
          ),
          const SizedBox(width: 10),
          IconActionButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: () => _load(page: _page),
          ),
          if (_activeFilterCount > 0) ...[
            const SizedBox(width: 10),
            ActiveFiltersBadge(
              count: _activeFilterCount,
              onClear: _clearAllFilters,
            ),
          ],
        ],
      ),
    );
  }

  // ── Period chips ──────────────────────────────────────────────────────────

  Widget _buildPeriodRow() {
    const fixedPeriods = [
      AttendancePeriod.today,
      AttendancePeriod.week,
      AttendancePeriod.month,
      AttendancePeriod.year,
      AttendancePeriod.allDates,
    ];

    final customLabel = _period == AttendancePeriod.custom
        ? (_isRangeMode
            ? formatDateRange(_customRangeStart, _customRangeEnd)
            : toDisplayDate(_customDate))
        : 'Custom Date';

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
      child: Row(
        children: [
          ...fixedPeriods.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PeriodChip(
                  label: p.label,
                  selected: _period == p,
                  onTap: () {
                    setState(() => _period = p);
                    _load();
                  },
                ),
              )),
          PeriodChip(
            label: customLabel,
            selected: _period == AttendancePeriod.custom,
            icon: Icons.calendar_today_rounded,
            onTap: _pickCustomDate,
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

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
                style:
                    TextStyle(color: Colors.red.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _load(page: _page),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: kAccent),
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
                  size: 40, color: kTextLight),
            ),
            const SizedBox(height: 14),
            const Text(
              'No attendance records found',
              style: TextStyle(
                  color: kTextMid,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your filters or date range',
              style: TextStyle(color: kTextLight, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: AttendanceTable(records: _records),
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  Widget _buildPagination() {
    final totalPages = (_total / _limit).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page $_page of $totalPages',
            style: const TextStyle(
                color: kTextMid,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            '· $_total records total',
            style: const TextStyle(color: kTextLight, fontSize: 12),
          ),
          const SizedBox(width: 16),
          PageButton(
            icon: Icons.chevron_left_rounded,
            enabled: _page > 1,
            onTap: () => _load(page: _page - 1),
          ),
          const SizedBox(width: 6),
          PageButton(
            icon: Icons.chevron_right_rounded,
            enabled: _page < totalPages,
            onTap: () => _load(page: _page + 1),
          ),
        ],
      ),
    );
  }
}