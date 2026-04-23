import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../widgets/attendance_clock_card.dart';
import '../widgets/attendance_history_list.dart';
import '../widgets/ojt_progress_card.dart';
import '../widgets/user_sidebar.dart';        // your existing sidebar

// ── Hamburger icon  ─────────────────────
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
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

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

  bool _isSidebarOpen = true;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    super.dispose();
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
      _showSnack('Time In recorded! 🕐', isSuccess: true);
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
      _showSnack('Time Out recorded! Good work today 🎉', isSuccess: true);
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
    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Fallback dark color
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen
                ? UserSidebar(
                    currentRoute: '/attendance',
                    onClose: () => setState(() => _isSidebarOpen = false),
                  )
                : null,
          ),

          // ── Main content ───────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Background Image Layer
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/space_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                
                // Foreground Content Layer
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Page header ──────────────────────────────────
                        Row(
                          children: [
                            if (!_isSidebarOpen) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(12),
                                  onPressed: () =>
                                      setState(() => _isSidebarOpen = true),
                                  icon: const _HamburgerIcon(),
                                  tooltip: 'Open Sidebar',
                                ),
                              ),
                            ],
                            Text(
                              'My Attendance',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const Spacer(),
                            // Refresh button
                            IconButton(
                              onPressed: _loadAll,
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Colors.white70),
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Clock card ───────────────────────────────────
                        AttendanceClockCard(
                          summary: _summary,
                          isLoading: _actionLoading || _summaryLoading,
                          onTimeIn: _handleTimeIn,
                          onTimeOut: _handleTimeOut,
                        ),

                        const SizedBox(height: 20),

                        // ── OJT progress ─────────────────────────────────
                        if (_summaryLoading)
                          const Center(child: CircularProgressIndicator(color: Colors.white))
                        else if (_summary != null)
                          OjtProgressCard(summary: _summary!),

                        const SizedBox(height: 20),

                        // ── History ───────────────────────────────────────
                        AttendanceHistoryList(
                          records: _history,
                          isLoading: _historyLoading,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}