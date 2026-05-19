import 'package:flutter/material.dart';
import '../../models/attendance_record.dart' show AdminAttendanceRecord;
import '../../services/admin_attendance_service.dart';
import '../../widgets/app_theme.dart';
import 'attendance_table.dart';
import 'review_report_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PendingBell — notification bell placed beside the Export button
// ─────────────────────────────────────────────────────────────────────────────

class PendingBell extends StatefulWidget {
  final VoidCallback? onResolved;

  const PendingBell({super.key, this.onResolved});

  @override
  State<PendingBell> createState() => PendingBellState();
}

class PendingBellState extends State<PendingBell>
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
    debugPrint(
        '🔔 Bell fetch: ok=${res['ok']}, count=${(res['records'] as List?)?.length ?? 0}');

    if (!mounted) return;

    final prev = _pending.length;

    setState(() {
      _pending = res['ok'] == true
          ? (res['records'] as List<AdminAttendanceRecord>? ?? [])
          : [];
      _loading = false;
    });

    if (_pending.length > prev) {
      _shakeCtrl.forward(from: 0);
    }
  }

  void _openPanel(BuildContext rootCtx) {
    showDialog(
      context: rootCtx,
      useRootNavigator: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => PendingPanel(
        initialRecords: _pending,
        rootContext: rootCtx,
        onRecordResolved: () {
          reload();
          widget.onResolved?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkInternTheme;

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

    // Navy in light mode, purple in dark mode — matches Export button
    final idleColor =
        isDark ? const Color(0xFF6C63FF) : const Color(0xFF00022E);

    return Tooltip(
      message: hasReports
          ? '$count pending ${count == 1 ? 'report' : 'reports'}'
          : 'No pending reports',
      child: GestureDetector(
        onTap: () => _openPanel(context),
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(_shakeAnim.value, 0),
            child: child,
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: idleColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: idleColor,
                width: 1.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  hasReports
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_outlined,
                  size: 20,
                  color: Colors.white,
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
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// PendingPanel — draggable bottom sheet listing all pending reports.
// ─────────────────────────────────────────────────────────────────────────────

class PendingPanel extends StatefulWidget {
  final List<AdminAttendanceRecord> initialRecords;
  final VoidCallback? onRecordResolved;
  final BuildContext rootContext;

  const PendingPanel({
    super.key,
    required this.initialRecords,
    required this.rootContext,
    this.onRecordResolved,
  });

  @override
  State<PendingPanel> createState() => _PendingPanelState();
}

class _PendingPanelState extends State<PendingPanel> {
  late List<AdminAttendanceRecord> _records;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _records = List<AdminAttendanceRecord>.from(widget.initialRecords);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _refreshing = true);

    final res = await AdminAttendanceService.fetchPendingReports();
    debugPrint(
        '📋 Panel refresh: ok=${res['ok']}, count=${(res['records'] as List<AdminAttendanceRecord>?)?.length ?? 0}');

    if (!mounted) return;

    setState(() {
      _records = res['ok'] == true
          ? (res['records'] as List<AdminAttendanceRecord>? ?? [])
          : [];
      _refreshing = false;
    });
  }

  void _onTileResolved() {
    _refresh();
    widget.onRecordResolved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    // Fallback constants if kSurface, kTextDark, kTextMid aren't globally defined in app_theme.dart
    final Color surfaceColor = theme.surface;
    final Color textDark = theme.surfaceText;
    final Color textMid = theme.mutedText;

    // Adjusted dynamic colors for the header action buttons
    final Color actionBtnBg =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF4F4F8);
    final Color actionBtnIconColor = isDark ? Colors.white70 : textMid;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: screenHeight * 0.78,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                      'Pending Reports (${_records.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const Spacer(),
                    if (_refreshing)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _refresh,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: actionBtnBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.refresh_rounded,
                              size: 16, color: actionBtnIconColor),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: actionBtnBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close,
                            size: 16, color: actionBtnIconColor),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: theme.border),

              // List
              Flexible(
                child: _records.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
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
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No pending reports to review.',
                              style: TextStyle(fontSize: 12, color: textMid),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => PendingTile(
                          record: _records[i],
                          rootContext: widget.rootContext,
                          onResolved: _onTileResolved,
                        ),
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
// PendingTile — single row inside the pending panel
// ─────────────────────────────────────────────────────────────────────────────

class PendingTile extends StatelessWidget {
  final AdminAttendanceRecord record;
  final VoidCallback? onResolved;
  final BuildContext rootContext;

  const PendingTile({
    super.key,
    required this.record,
    required this.rootContext,
    this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;

    return GestureDetector(
      onTap: () => ReviewReportSheet.show(
        rootContext,
        record,
        onResolved: onResolved,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF3B2F00).withOpacity(0.3)
              : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? const Color(0xFFF59E0B).withOpacity(0.5)
                : const Color(0xFFFCD34D),
          ),
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
                      IntrinsicWidth(
                        child: StatusBadge(status: record.status),
                      ),
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
                        color: isDark
                            ? const Color(0xFF78350F).withOpacity(0.4)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.reportReason!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFF92400E),
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

            // Review label + icon
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
