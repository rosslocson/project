import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/admin_sidebar.dart';
import 'admin_glass_topbar.dart' as admin_topbar;
import '../widgets/app_theme.dart';
import '../widgets/app_background.dart';

// ── Imported Extracted Widgets ──
import '../widgets/admin_departments_widgets/department_list_content.dart';
import '../widgets/admin_departments_widgets/edit_department_dialog.dart';
import '../widgets/admin_departments_widgets/delete_department_dialog.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with TickerProviderStateMixin {
  bool _isSidebarOpen = true;
  List<dynamic> _departments = [];
  bool _loadingDept = true;

  static const double _kMobileBreak  = 600;
  static const double _kTabletBreak  = 1024;
  static const double _kSidebarWidth = 250;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.of(context).size.width;
    if (width < _kMobileBreak && _isSidebarOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isSidebarOpen = false);
      });
    }
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDept = true);
    final res = await ApiService.getDepartments();
    if (mounted) {
      setState(() {
        _departments = res['items'] ?? [];
        _loadingDept = false;
      });
    }
  }

  Future<void> _addDepartment(String name) async {
    final res = await ApiService.createDepartment(name.trim());
    if (res['ok'] == true) {
      await _loadDepartments();
    } else if (mounted) {
      _showError(res['error'] ?? 'Failed to add department');
    }
  }

  Future<void> _editItem({required int id, required String currentName}) async {
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => EditDepartmentDialog(currentName: currentName),
    );
    if (saved == null || saved == currentName) return;
    final res = await ApiService.updateDepartment(id, saved);
    if (res['ok'] == true) {
      await _loadDepartments();
      if (mounted) _showSuccess('"$saved" updated.');
    } else if (mounted) {
      _showError(res['error'] ?? 'Update failed');
    }
  }

  Future<void> _deleteItem({required int id, required String name}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteDepartmentDialog(name: name),
    );
    if (confirmed != true) return;
    final res = await ApiService.deleteDepartment(id);
    if (res['ok'] == true) {
      await _loadDepartments();
      if (mounted) _showSuccess('"$name" deleted.');
    } else if (mounted) {
      _showError(res['error'] ?? 'Delete failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 1),
    ));
  }

  EdgeInsets _cardPadding(double width) {
    if (width < _kMobileBreak)  return const EdgeInsets.symmetric(horizontal: 12);
    if (width < _kTabletBreak)  return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 100);
  }

  bool _useDrawer(double width) => width < _kTabletBreak;

  @override
  Widget build(BuildContext context) {
    final isDark    = context.isDarkInternTheme;
    final theme     = context.internTheme;
    final width     = MediaQuery.of(context).size.width;
    final useDrawer = _useDrawer(width);

    return Scaffold(
      resizeToAvoidBottomInset: false,

      drawer: useDrawer
          ? Drawer(
              width: _kSidebarWidth,
              child: AdminSidebar(
                currentRoute: '/config',
                onClose: () => Navigator.of(context).pop(),
              ),
            )
          : null,

      // ─────────────────────────────────────────────────────────────────
      // FIX: wrap in Builder so scaffoldContext is a child of Scaffold.
      // Without this, Scaffold.of(context) throws because `context` here
      // is the parent of the Scaffold, not inside it.
      // ─────────────────────────────────────────────────────────────────
      body: Builder(
        builder: (scaffoldContext) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Desktop: permanent push sidebar ───────────────────────
              if (!useDrawer)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _isSidebarOpen ? _kSidebarWidth : 0,
                  // ClipRect + OverflowBox: sidebar content stays at full
                  // width internally but is clipped to the animated width,
                  // preventing paint overflow during the collapse animation.
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      maxWidth: _kSidebarWidth,
                      child: SizedBox(
                        width: _kSidebarWidth,
                        child: AdminSidebar(
                          currentRoute: '/config',
                          onClose: () =>
                              setState(() => _isSidebarOpen = false),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Main content area ─────────────────────────────────────
              Expanded(
                child: AppBackground(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top bar ────────────────────────────────────────
                      SizedBox(
                        height: 72,
                        child: admin_topbar.GlassTopBar(
                          isSidebarOpen: _isSidebarOpen,
                          onToggleSidebar: () {
                            if (useDrawer) {
                              // FIX: scaffoldContext (from Builder) is
                              // below the Scaffold, so Scaffold.of() works.
                              Scaffold.of(scaffoldContext).openDrawer();
                            } else {
                              setState(
                                  () => _isSidebarOpen = !_isSidebarOpen);
                            }
                          },
                          user: context.read<AuthProvider>().user,
                          isAdmin: true,
                          title: 'Departments',
                          showWelcome: false,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ── Department card ────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding:
                              _cardPadding(width).copyWith(bottom: 28),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.surface
                                  : theme.sidebarBackground,
                              borderRadius: BorderRadius.circular(
                                  width < _kMobileBreak ? 12 : 24),
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
                              borderRadius: BorderRadius.circular(
                                  width < _kMobileBreak ? 12 : 24),
                              child: DepartmentListContent(
                                loading: _loadingDept,
                                items: _departments,
                                searchHint: 'Search departments...',
                                onAdd: _addDepartment,
                                onEdit: (id, name) =>
                                    _editItem(id: id, currentName: name),
                                onDelete: (id, name) =>
                                    _deleteItem(id: id, name: name),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}