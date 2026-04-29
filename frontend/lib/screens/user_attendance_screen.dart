import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_model.dart';
import '../providers/sidebar_provider.dart';
import '../services/attendance_service.dart';
import '../widgets/attendance_clock_card.dart';
import '../widgets/attendance_history_list.dart';
import '../widgets/ojt_progress_card.dart';
import '../widgets/user_layout.dart';
import '../theme.dart';

class HamburgerIcon extends StatelessWidget {
  const HamburgerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 14,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  AttendanceSummary? _summary;
  List<AttendanceRecord> _history = [];

  bool _summaryLoading = true;
  bool _historyLoading = true;
  bool _actionLoading = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── Data loading ───────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([_loadSummary(), _loadHistory()]);
  }

  Future<void> _loadSummary() async {
    setState(() => _summaryLoading = true);
    final s = await AttendanceService.getSummary();
    if (mounted) setState(() { _summary = s; _summaryLoading = false; });
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final h = await AttendanceService.getHistory();
    if (mounted) setState(() { _history = h; _historyLoading = false; });
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _handleTimeIn() async {
    setState(() => _actionLoading = true);
    final res = await AttendanceService.timeIn();
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['ok'] == true) {
      _showSnack('Time In recorded!', isSuccess: true);
      await _loadAll();
    } else {
      _showSnack(res['error'] ?? 'Failed to record Time In');
    }
  }

  Future<void> _handleTimeOut() async {
    setState(() => _actionLoading = true);
    final res = await AttendanceService.timeOut();
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['ok'] == true) {
      _showSnack('Time Out recorded! Good work today', isSuccess: true);
      await _loadAll();
    } else {
      _showSnack(res['error'] ?? 'Failed to record Time Out');
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isSuccess ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return UserLayout(
      currentRoute: '/attendance',
      child: _buildAttendanceContent(context),
    );
  }

  Widget _buildAttendanceContent(BuildContext context) {
    final sidebar = context.watch<SidebarProvider>();

    return Stack(
      children: [
        // ── Background ────────────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: AppTheme.spaceBackground,
          ),
        ),

        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top bar ───────────────────────────────────────────
              SizedBox(
                height: 72,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 100, right: 100, top: 28),
                      child: Text(
                        'My Attendance',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    if (!sidebar.isUserSidebarOpen)
                      Positioned(
                        left: 20,
                        top: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: IconButton(
                            padding: const EdgeInsets.all(12),
                            onPressed: () => sidebar.setUserSidebarOpen(true),
                            icon: const HamburgerIcon(),
                            tooltip: 'Open Sidebar',
                            splashColor: Colors.white.withValues(alpha: 0.1),
                            highlightColor: Colors.transparent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // ── Main content container ────────────────────────────
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 100, right: 100, bottom: 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Refresh button ────────────────────────
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: _loadAll,
                                icon: const Icon(Icons.refresh_rounded,
                                    color: Colors.black54),
                                tooltip: 'Refresh',
                              ),
                            ),

                            // ── Clock card ────────────────────────────
                            AttendanceClockCard(
                              summary: _summary,
                              isLoading: _actionLoading || _summaryLoading,
                              onTimeIn: _handleTimeIn,
                              onTimeOut: _handleTimeOut,
                            ),

                            const SizedBox(height: 20),

                            // ── OJT progress ──────────────────────────
                            if (_summaryLoading)
                              const Center(
                                  child: CircularProgressIndicator())
                            else if (_summary != null)
                              OjtProgressCard(summary: _summary!),

                            const SizedBox(height: 20),

                            // ── History ───────────────────────────────
                            AttendanceHistoryList(
                              records: _history,
                              isLoading: _historyLoading,
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
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
}