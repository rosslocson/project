// lib/screens/admin_attendance_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import '../models/attendance_constants.dart';
import '../models/attendance_record.dart' show AdminAttendanceRecord;
import '../services/admin_attendance_service.dart';
import '../services/date_helpers.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_attendance_widgets/attendance_filters.dart';
import '../widgets/admin_attendance_widgets/attendance_table.dart';
import '../widgets/admin_attendance_widgets/attendance_ui_components.dart';
import '../widgets/admin_attendance_widgets/custom_date_picker_dialog.dart';
import '../widgets/admin_attendance_widgets/pending_bell.dart'; // Added Import!
import '../widgets/app_theme.dart';
import '../widgets/app_background.dart';
import 'export_attendance.dart';
import 'admin_glass_topbar.dart' as admin_topbar;

// Re-export HamburgerIcon so other attendance files can reuse it from one place.
export '../widgets/admin_attendance_widgets/attendance_table.dart'
    show HamburgerIcon;

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
  DateTime _customDate = DateTime.now();
  DateTime _customRangeStart = DateTime.now();
  DateTime _customRangeEnd = DateTime.now();
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

  // ── Pending reports bell key ──────────────────────────────────────────────
  final GlobalKey<PendingBellState> _bellKey = GlobalKey<PendingBellState>();

  // ── Scroll controller ─────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _load();
    });
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
      _records = [];
      _page = page;
    });

    final isAllDates = _period == AttendancePeriod.allDates;
    final isCustom = _period == AttendancePeriod.custom;

    final result = await AdminAttendanceService.fetchAttendance(
      allDates: isAllDates,
      period: (!isAllDates && !isCustom) ? _period.apiPeriod : null,
      dateFrom:
          (isCustom && _isRangeMode) ? toApiDate(_customRangeStart) : null,
      dateTo: (isCustom && _isRangeMode) ? toApiDate(_customRangeEnd) : null,
      date: (isCustom && !_isRangeMode) ? toApiDate(_customDate) : null,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      status: _selectedStatus == 'All' ? null : _selectedStatus,
      page: page,
      limit: _limit,
    );

    if (!mounted) return;

    if (result['ok'] == true) {
      final all = result['records'] as List<AdminAttendanceRecord>;

      // Filter out any records dated after today (same fix as user-side _rebuild())
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final filtered = all.where((r) {
        final recordDate = DateTime.parse(r.date); // r.date is "YYYY-MM-DD"
        return !recordDate.isAfter(todayDate);
      }).toList();

      final absents = all.where((r) => r.status == 'Absent').toList();
      final present = all.where((r) => r.status != 'Absent').toList();
      final total = result['total'] as int;

      debugPrint('[AttendanceLoad] ✅ Success — total from server: $total');
      debugPrint('[AttendanceLoad] Records in this page: ${all.length}');
      debugPrint('[AttendanceLoad] → Present/clocked-in: ${present.length}');
      debugPrint(
          '[AttendanceLoad] → Absent (isAbsent==true): ${absents.length}');
      if (absents.isNotEmpty) {
        debugPrint('[AttendanceLoad] First absent record:');
        debugPrint('    id=${absents.first.id}');
        debugPrint('    date=${absents.first.date}');
        debugPrint('    timeIn=${absents.first.timeIn}');
        debugPrint('    timeOut=${absents.first.timeOut}');
        debugPrint('    status=${absents.first.status}');
      } else {
        debugPrint(
            '[AttendanceLoad] ⚠️  NO absent records in this page — backend is not returning them');
      }
      debugPrint('═══════════════════════════════════════');

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

  /// Called after any report is resolved (from table row OR bell panel).
  void _onReportResolved() {
    _load(page: _page);
    _bellKey.currentState?.reload();
  }

  Future<void> _pickCustomDate() async {
    await showDialog(
      context: context,
      builder: (_) => CustomDatePickerDialog(
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

  String get _activeDateRangeLabel {
    final now = DateTime.now();
    return switch (_period) {
      AttendancePeriod.allDates => 'All Dates',
      AttendancePeriod.custom => _isRangeMode
          ? formatDateRange(_customRangeStart, _customRangeEnd)
          : toDisplayDate(_customDate),
      _ => () {
          final (start, end) = periodRange(_period, now);
          return formatDateRange(start, end);
        }(),
    };
  }

  int get _pendingReportCount => _records.where((r) => r.hasOpenReport).length;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            child: AppBackground(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  Expanded(
                    // ── Scrollbar wraps the SingleChildScrollView, effectively putting it at the absolute edge ──
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility:
                          false, // Changed to false so it disappears when not scrolling
                      thickness: 8,
                      radius: const Radius.circular(8),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            _buildCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 72,
      child: admin_topbar.GlassTopBar(
        isSidebarOpen: _isSidebarOpen,
        onToggleSidebar: () => setState(() => _isSidebarOpen = true),
        user: context.read<AuthProvider>().user,
        isAdmin: true,
        title: 'Attendance',
        showWelcome: false,
      ),
    );
  }

  Widget _buildCard() {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;

    return Padding(
      // The horizontal padding keeps the card away from the screen edge, but the Scrollbar remains at the edge!
      padding: const EdgeInsets.only(left: 100, right: 100, bottom: 28),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.surface : theme.sidebarBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 24,
                    spreadRadius: 2,
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
              if (!_loading && _pendingReportCount > 0) _buildPendingBanner(),
              if (!_loading && _pendingReportCount > 0)
                const SizedBox(height: 12),
              Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.border.withValues(alpha: 0.15)),
              _buildBody(),
              if (_total > _limit) _buildPagination(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card header — contains title, record count, bell, and export button ───

  Widget _buildCardHeader() {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;

    final primaryColor =
        isDark ? const Color(0xFF6C63FF) : const Color(0xFF00022E);

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom:
              BorderSide(color: theme.border.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor,
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
                Text(
                  'Attendance Records',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.surfaceText,
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
                      style: TextStyle(fontSize: 12, color: theme.mutedText),
                    ),
                    if (!_loading && _period != AttendancePeriod.allDates) ...[
                      Container(
                        width: 1,
                        height: 11,
                        color: theme.border.withValues(alpha: 0.15),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_today_rounded,
                          size: 11, color: theme.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        _activeDateRangeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PendingBell(
            key: _bellKey,
            onResolved: _onReportResolved,
          ),
          const SizedBox(width: 10),
          ExportButton(
            onTap: () async {
              final isAllDates = _period == AttendancePeriod.allDates;
              final isCustom = _period == AttendancePeriod.custom;
              await AttendanceExporter.export(
                context,
                options: AttendanceExportOptions(
                  allDates: isAllDates,
                  period: (!isAllDates && !isCustom) ? _period.apiPeriod : null,
                  date: (isCustom && !_isRangeMode)
                      ? toApiDate(_customDate)
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

  // ── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AttendanceSearchField(
                  controller: _searchCtrl,
                  onClear: () {
                    _searchCtrl.clear();
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AttendanceStatusDropdown(
                        value: _selectedStatus,
                        onChanged: (v) {
                          setState(() => _selectedStatus = v ?? 'All');
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconActionButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Refresh',
                      onTap: () => _load(page: _page),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
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
            ],
          );
        },
      ),
    );
  }

  // ── Period chips ──────────────────────────────────────────────────────────

  Widget _buildPeriodRow() {
    const fixedPeriods = [
      AttendancePeriod.today,
      AttendancePeriod.week,
      AttendancePeriod.month,
      //AttendancePeriod.year,
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

  // ── Pending-reports banner (inline, above table) ──────────────────────────

  Widget _buildPendingBanner() {
    final count = _pendingReportCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pending_actions_rounded,
                color: Color(0xFF92400E), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count attendance ${count == 1 ? 'report requires' : 'reports require'} your review',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap the 🔔 bell or the review icon (📋) on flagged rows.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() => _selectedStatus = 'All');
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFB45309),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list_rounded,
                      size: 13, color: Color(0xFFFEF3C7)),
                  SizedBox(width: 5),
                  Text(
                    'Show Flagged',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFEF3C7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body (loading / empty / table) ────────────────────────────────────────

  Widget _buildBody() {
    final theme = context.internTheme;

    if (_loading && _records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
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
              ),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.metricCardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.event_busy_rounded,
                    size: 40, color: theme.mutedText),
              ),
              const SizedBox(height: 14),
              Text(
                'No attendance records found',
                style: TextStyle(
                  color: theme.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try adjusting your filters or date range',
                style: TextStyle(color: theme.mutedText, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Enforce a minimum width so the "ADMIN NOTE" column is never squeezed tightly
        final tableWidth =
            constraints.maxWidth > 1200 ? constraints.maxWidth : 1200.0;

        // No vertical SingleChildScrollView here. Scrolling is natively handled by the parent wrapper!
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: AttendanceTable(
                records: _records,
                isAdmin: true,
                onRefresh: _onReportResolved,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  Widget _buildPagination() {
    final theme = context.internTheme;
    final totalPages = (_total / _limit).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.border.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page $_page of $totalPages',
            style: TextStyle(
              color: theme.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '· $_total records total',
            style: TextStyle(color: theme.mutedText, fontSize: 12),
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
