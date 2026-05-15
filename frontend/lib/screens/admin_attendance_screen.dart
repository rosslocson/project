// lib/screens/admin_attendance_screen.dart
// Admin attendance monitoring screen.
// Layout + state only — all widgets are in admin_attendance_widgets/.

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
import '../widgets/admin_attendance_widgets/review_report_sheet.dart';
import '../widgets/admin_attendance_widgets/attendance_ui_components.dart';
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
  final GlobalKey<_PendingBellState> _bellKey = GlobalKey();

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

  int get _activeFilterCount =>
      (_searchCtrl.text.isNotEmpty ? 1 : 0) +
      (_selectedStatus != 'All' ? 1 : 0);

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
                  const SizedBox(height: 15),
                  Expanded(child: _buildCard()),
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
      padding: const EdgeInsets.only(left: 100, right: 100, bottom: 28),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.surface : theme.sidebarBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border.withValues(alpha: 0.15)),
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
              Expanded(child: _buildBody()),
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
        isDark ? const Color(0xFF1A1F5A) : const Color(0xFF00022E);

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
                      const SizedBox(width: 8),
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
          _PendingBell(
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
            ),
          ],
        ),
      );
    }

    if (_records.isEmpty) {
      return Center(
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
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: AttendanceTable(
        records: _records,
        isAdmin: true,
        onRefresh: _onReportResolved,
      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// _PendingBell — notification bell placed beside the Export button
// ─────────────────────────────────────────────────────────────────────────────

class _PendingBell extends StatefulWidget {
  final VoidCallback? onResolved;

  const _PendingBell({super.key, this.onResolved});

  @override
  State<_PendingBell> createState() => _PendingBellState();
}

class _PendingBellState extends State<_PendingBell>
    with SingleTickerProviderStateMixin {
  List<AdminAttendanceRecord> _pending = [];
  bool _loading = true;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);

    reload();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final res = await AdminAttendanceService.fetchPendingReports();
    if (!mounted) return;

    final prev = _pending.length;
    setState(() {
      _pending = res['ok'] == true
          ? (res['records'] as List<AdminAttendanceRecord>)
          : [];
      _loading = false;
    });

    if (_pending.length > prev) {
      _shakeCtrl.forward(from: 0);
    }
  }

  void _openPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PendingPanel(
        records: _pending,
        onResolved: () {
          reload();
          widget.onResolved?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final count = _pending.length;
    final hasReports = count > 0;

    return Tooltip(
      message: hasReports
          ? '$count pending ${count == 1 ? 'report' : 'reports'}'
          : 'No pending reports',
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: child,
        ),
        child: Material(
          color: hasReports ? const Color(0xFFFFFBEB) : const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: hasReports ? () => _openPanel(context) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: hasReports
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFCD34D),
                        width: 1.5,
                      ),
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    hasReports
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_outlined,
                    size: 20,
                    color: hasReports ? const Color(0xFF92400E) : Colors.white,
                  ),
                  if (hasReports)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 17, minHeight: 17),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PendingPanel — draggable bottom sheet listing all pending reports
// ─────────────────────────────────────────────────────────────────────────────

class _PendingPanel extends StatelessWidget {
  final List<AdminAttendanceRecord> records;
  final VoidCallback? onResolved;

  const _PendingPanel({required this.records, this.onResolved});

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Drag handle ─────────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE68A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pending_actions_rounded,
                        color: Color(0xFF92400E), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pending Reports (${records.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.surfaceText,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.metricCardBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.close, size: 16, color: theme.mutedText),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: theme.border),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 40, color: Color(0xFF22C55E)),
                          const SizedBox(height: 12),
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.surfaceText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No pending reports to review.',
                            style:
                                TextStyle(fontSize: 12, color: theme.mutedText),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _PendingTile(
                        record: records[i],
                        onResolved: () {
                          Navigator.pop(context);
                          onResolved?.call();
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PendingTile — single row inside the pending panel
// ─────────────────────────────────────────────────────────────────────────────

class _PendingTile extends StatelessWidget {
  final AdminAttendanceRecord record;
  final VoidCallback? onResolved;

  const _PendingTile({required this.record, this.onResolved});

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    return InkWell(
      onTap: () => ReviewReportSheet.show(
        context,
        record,
        onResolved: onResolved,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            InternAvatar(url: record.avatarUrl, name: record.internName),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.internName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: theme.surfaceText,
                          ),
                        ),
                      ),
                      StatusBadge(status: record.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.formattedDate,
                    style: TextStyle(fontSize: 12, color: theme.mutedText),
                  ),
                  if (record.reportReason != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.reportReason!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF92400E),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron + "Review" label
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 18, color: theme.sidebarActiveForeground),
                const SizedBox(height: 2),
                Text(
                  'Review',
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.sidebarActiveForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
