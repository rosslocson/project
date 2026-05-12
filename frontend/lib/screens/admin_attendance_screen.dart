// lib/screens/admin_attendance_screen.dart
// Admin attendance monitoring screen.
// Layout + state only — all widgets are in admin_attendance_widgets/.

import 'dart:async';

import 'package:flutter/material.dart';

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
import 'export_attendance.dart';

// Re-export HamburgerIcon so other attendance files can reuse it from one place.
export '../widgets/admin_attendance_widgets/attendance_table.dart' show HamburgerIcon;


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

  // ── Pending reports bell (reload after resolve) ───────────────────────────
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
      _page = page;
    });

    final isAllDates = _period == AttendancePeriod.allDates;
    final isCustom = _period == AttendancePeriod.custom;

    final result = await AdminAttendanceService.fetchAttendance(
      allDates: isAllDates,
      period: (!isAllDates && !isCustom) ? _period.apiPeriod : null,
      dateFrom: (isCustom && _isRangeMode) ? toApiDate(_customRangeStart) : null,
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
      (_searchCtrl.text.isNotEmpty ? 1 : 0) + (_selectedStatus != 'All' ? 1 : 0);

  int get _pendingReportCount => _records.where((r) => r.hasOpenReport).length;

  void _clearAllFilters() {
    _searchCtrl.clear();
    setState(() => _selectedStatus = 'All');
    _load();
  }

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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
          Positioned(
            right: 24,
            top: 24,
            child: _PendingBell(
              key: _bellKey,
              onResolved: _onReportResolved,
            ),
          ),
        ],
      ),
    );
  }

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
              if (!_loading && _pendingReportCount > 0) _buildPendingBanner(),
              if (!_loading && _pendingReportCount > 0) const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(child: _buildBody()),
              if (_total > _limit) _buildPagination(),
            ],
          ),
        ),
      ),
    );
  }

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
                      style: const TextStyle(fontSize: 12, color: kTextMid),
                    ),
                    if (!_loading && _period != AttendancePeriod.allDates) ...[
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
              final isCustom = _period == AttendancePeriod.custom;
              await AttendanceExporter.export(
                context,
                options: AttendanceExportOptions(
                  allDates: isAllDates,
                  period: (!isAllDates && !isCustom) ? _period.apiPeriod : null,
                  date: (isCustom && !_isRangeMode) ? toApiDate(_customDate) : null,
                  search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
                  status: _selectedStatus == 'All' ? null : _selectedStatus,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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
                  'Tap the review icon (📋) on flagged rows or use the bell above.',
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
            Text(_error!, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
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
                fontWeight: FontWeight.w500,
              ),
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
      child: AttendanceTable(
        records: _records,
        isAdmin: true,
        onRefresh: _onReportResolved,
      ),
    );
  }

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
              fontWeight: FontWeight.w500,
            ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Pending-reports bell widget (private to this file)
// ─────────────────────────────────────────────────────────────────────────────

class _PendingBell extends StatefulWidget {
  final VoidCallback? onResolved;

  const _PendingBell({super.key, this.onResolved});

  @override
  State<_PendingBell> createState() => _PendingBellState();
}

class _PendingBellState extends State<_PendingBell> {
  List<AdminAttendanceRecord> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final res = await AdminAttendanceService.fetchPendingReports();

    if (!mounted) return;

    setState(() {
      _pending = res['ok'] == true
          ? (res['records'] as List<AdminAttendanceRecord>)
          : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white70,
        ),
      );
    }

    final count = _pending.length;
    return GestureDetector(
      onTap: count == 0 ? null : () => _showPanel(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            count > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_outlined,
            color: count > 0 ? Colors.amber.shade300 : Colors.white70,
            size: 26,
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPanel(BuildContext context) {
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending-reports panel (inside the bell sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _PendingPanel extends StatelessWidget {
  final List<AdminAttendanceRecord> records;
  final VoidCallback? onResolved;

  const _PendingPanel({required this.records, this.onResolved});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions,
                      color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Reports (${records.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: records.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending reports',
                        style: TextStyle(color: kTextMid, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

class _PendingTile extends StatelessWidget {
  final AdminAttendanceRecord record;
  final VoidCallback? onResolved;

  const _PendingTile({required this.record, this.onResolved});

  @override
  Widget build(BuildContext context) {
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
            InternAvatar(url: record.avatarUrl, name: record.internName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.internName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: kTextDark,
                          ),
                        ),
                      ),
                      StatusBadge(status: record.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.formattedDate,
                    style: const TextStyle(fontSize: 12, color: kTextMid),
                  ),
                  if (record.reportReason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      record.reportReason!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kTextMid),
          ],
        ),
      ),
    );
  }
}

