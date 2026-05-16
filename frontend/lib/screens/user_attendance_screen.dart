import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_model.dart';
import '../providers/sidebar_provider.dart';
import '../providers/auth_provider.dart';
import 'user_glass_topbar.dart';
import '../services/attendance_service.dart';
import '../widgets/attendance_clock_card.dart';
import '../widgets/attendance_history_list.dart';
import '../widgets/ojt_progress_card.dart';
import '../widgets/user_layout.dart';
import '../widgets/app_background.dart';
import '../widgets/app_theme.dart';

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
    if (mounted) {
      setState(() {
        _summary = s;
        _summaryLoading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final h = await AttendanceService.getHistory();
    if (mounted) {
      setState(() {
        _history = h;
        _historyLoading = false;
      });
    }
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
      backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
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
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar ───────────────────────────────────────────
          SizedBox(
            height: 72,
            child: GlassTopBar(
              pageTitle: 'My Attendance',
              showWelcome: false,
              user: context.watch<AuthProvider>().user,
              isSidebarOpen: sidebar.isUserSidebarOpen,
              onToggleSidebar: () =>
                  sidebar.setUserSidebarOpen(!sidebar.isUserSidebarOpen),
            ),
          ),
          const SizedBox(height: 15),

          // ── Main content container ────────────────────────────
          Expanded(
            child: Padding(
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
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Card header ───────────────────────────
                      _buildCardHeader(theme, isDark),

                      // ── Scrollable body ───────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Clock card ──────────────────
                              AttendanceClockCard(
                                summary: _summary,
                                isLoading: _actionLoading || _summaryLoading,
                                onTimeIn: _handleTimeIn,
                                onTimeOut: _handleTimeOut,
                                isOjtComplete: _summary?.isComplete ?? false,
                              ),

                              const SizedBox(height: 20),

                              // ── OJT progress ────────────────
                              if (_summaryLoading)
                                Center(
                                  child: CircularProgressIndicator(
                                    color: isDark
                                        ? const Color(0xFF7367F0)
                                        : const Color(0xFF00022E),
                                  ),
                                )
                              else if (_summary != null)
                                OjtProgressCard(summary: _summary!),

                              const SizedBox(height: 20),

                              // ── History ──────────────────────
                              AttendanceHistoryList(
                                records: _history,
                                isLoading: _historyLoading,
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(InternSpaceThemeColors theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: BoxDecoration(
        color: isDark
            ? theme.surface.withValues(alpha: 0.8)
            : theme.metricCardBackground,
        border: Border(
          bottom: BorderSide(color: theme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Attendance',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.surfaceText,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _summaryLoading
                      ? 'Loading…'
                      : '${_history.length} record${_history.length != 1 ? 's' : ''} total',
                  style: TextStyle(fontSize: 12, color: theme.mutedText),
                ),
              ],
            ),
          ),
          // Refresh button
          _GlassIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            isDark: isDark,
            onTap: _loadAll,
          ),
        ],
      ),
    );
  }
}

/// Small glass-style icon button matching the admin screen aesthetic.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
      ),
    );
  }
}
