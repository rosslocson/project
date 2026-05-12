import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

import '../widgets/admin_sidebar.dart';
import 'admin_glass_topbar.dart' as admin_topbar;



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

  @override
  void initState() {
    super.initState();
    _loadDepartments();
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
                    currentRoute: '/config',
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
                      SizedBox(
                        height: 72,
                        child: admin_topbar.GlassTopBar(
                          isSidebarOpen: _isSidebarOpen,
                          onToggleSidebar: () =>
                              setState(() => _isSidebarOpen = true),
                          user: context.read<AuthProvider>().user,
                          isAdmin: true,
                          title: 'Departments',
                          showWelcome: false,
                        ),
                      ),

                      const SizedBox(height: 15),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 100, right: 100, bottom: 28),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
