import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/app_background.dart';
import '../widgets/app_theme.dart';
import 'admin_glass_topbar.dart' as admin_topbar;

import '../widgets/admin_user_management_widgets/filter_pill_group.dart';
import '../widgets/admin_user_management_widgets/user_list_section.dart';
import '../widgets/admin_user_management_widgets/user_utils.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  final _searchCtrl = TextEditingController();

  bool _isSidebarOpen = true;
  String _filterStatus = 'All';

  // Cache per tab
  final Map<String, List<dynamic>> _cache = {};

  Map<String, int> _counts = {
    'all': 0,
    'active': 0,
    'inactive': 0,
    'archived': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUsers(status: 'all');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String? status, bool silent = false}) async {
    if (!mounted) return;

    final cacheKey = status ?? 'all';
    if (_cache.containsKey(cacheKey)) {
      setState(() => _users = _cache[cacheKey]!);
    } else if (!silent) {
      setState(() => _loading = true);
    }

    try {
      final res = await ApiService.getUsers(status: status);
      if (!mounted) return;

      final fetched = res['ok'] == true ? (res['users'] ?? []) : [];
      _cache[cacheKey] = fetched;

      setState(() {
        _users = fetched;

        if (res['counts'] != null) {
          _counts = {
            'all': res['counts']['all'] ?? 0,
            'active': res['counts']['active'] ?? 0,
            'inactive': res['counts']['inactive'] ?? 0,
            'archived': res['counts']['archived'] ?? 0,
          };
        }

        _users.sort((a, b) {
          int statusOrder(dynamic u) {
            if (u['is_archived'] == true) return 2;
            if (u['is_active'] == true) return 0;
            return 1;
          }

          return statusOrder(a).compareTo(statusOrder(b));
        });

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _silentReload() async {
    _cache.clear();
    try {
      final res = await ApiService.getUsers(status: 'all');
      if (!mounted) return;

      setState(() {
        final allUsers = res['ok'] == true ? (res['users'] ?? []) : [];

        if (res['counts'] != null) {
          _counts = {
            'all': res['counts']['all'] ?? 0,
            'active': res['counts']['active'] ?? 0,
            'inactive': res['counts']['inactive'] ?? 0,
            'archived': res['counts']['archived'] ?? 0,
          };
        }

        if (_filterStatus == 'Active') {
          _users = allUsers
              .where((u) => u['is_active'] == true && u['is_archived'] != true)
              .toList();
        } else if (_filterStatus == 'Inactive') {
          _users = allUsers
              .where(
                  (u) => u['is_active'] == false && u['is_archived'] == false)
              .toList();
        } else if (_filterStatus == 'Archived') {
          _users = allUsers.where((u) => u['is_archived'] == true).toList();
        } else {
          _users = allUsers;
        }

        _users.sort((a, b) {
          int statusOrder(dynamic u) {
            if (u['is_archived'] == true) return 2;
            if (u['is_active'] == true) return 0;
            return 1;
          }

          return statusOrder(a).compareTo(statusOrder(b));
        });
      });
    } catch (_) {
      // fail silently
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int _getCurrentUserId() {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) return 0;
    return toInt(authUser['id']);
  }

  Future<bool> _toggleActive(Map<String, dynamic> user) async {
    final id = toInt(user['id']);
    final current = isActive(user);
    final next = !current;

    setState(() => user['is_active'] = next);

    final res = await ApiService.updateUser(id, {'is_active': next});
    if (!mounted) return false;

    if (res['ok'] != true) {
      setState(() => user['is_active'] = current);
      _showError('Failed: ${res['error'] ?? 'Unknown error'}');
      return false;
    }

    _silentReload();
    return true;
  }

  Future<void> _archiveUser(Map<String, dynamic> user) async {
    final id = toInt(user['id']);
    final name = '${user['first_name']} ${user['last_name']}'.trim();

    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;
    final primaryColor =
        isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.archive_outlined, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Archive User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: theme.surfaceText, fontSize: 14),
                children: [
                  const TextSpan(text: 'Are you sure you want to archive '),
                  TextSpan(
                    text: name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.surfaceText,
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user will be hidden from active lists and unable to log in, but their data will be preserved.',
              style: TextStyle(color: theme.mutedText, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: theme.surfaceText)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.archive_outlined, size: 16),
            label: const Text('Archive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      user['is_archived'] = true;
      user['is_active'] = false;
    });

    final res = await ApiService.updateUser(
      id,
      {'is_archived': true, 'is_active': false},
    );
    if (!mounted) return;

    if (res['ok'] == true) {
      _showSuccess('$name has been archived.');
      _silentReload();
    } else {
      setState(() {
        user['is_archived'] = false;
        user['is_active'] = isActive(user);
      });
      _showError('Archive failed: ${res['error'] ?? 'Unknown error'}');
    }
  }

  Future<void> _restoreUser(Map<String, dynamic> user) async {
    final id = toInt(user['id']);
    final name = '${user['first_name']} ${user['last_name']}'.trim();

    setState(() {
      user['is_archived'] = false;
      user['is_active'] = true;
    });

    final res = await ApiService.updateUser(
      id,
      {'is_archived': false, 'is_active': true},
    );
    if (!mounted) return;

    if (res['ok'] == true) {
      _showSuccess('$name has been restored.');
      _silentReload();
    }
  }

  void _onTabChanged(String status) {
    setState(() {
      _filterStatus = status;
      _searchCtrl.clear();
    });

    String? apiStatus;
    if (status == 'Active') {
      apiStatus = 'active';
    } else if (status == 'Inactive') {
      apiStatus = 'inactive';
    } else if (status == 'Archived') {
      apiStatus = 'archived';
    } else {
      apiStatus = 'all';
    }

    _loadUsers(status: apiStatus, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;
    final currentUserId = _getCurrentUserId();

    final tabs = [
      {'id': 'All', 'label': 'All', 'count': _counts['all'] ?? 0},
      {'id': 'Active', 'label': 'Active', 'count': _counts['active'] ?? 0},
      {
        'id': 'Inactive',
        'label': 'Inactive',
        'count': _counts['inactive'] ?? 0
      },
      {
        'id': 'Archived',
        'label': 'Archived',
        'count': _counts['archived'] ?? 0
      },
    ];

    final query = _searchCtrl.text.trim().toLowerCase();

    final searchedUsers = _users.where((u) {
      if (query.isEmpty) return true;
      final firstName = (u['first_name'] ?? '').toString().toLowerCase();
      final lastName = (u['last_name'] ?? '').toString().toLowerCase();
      final fullName = '$firstName $lastName'.trim();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return fullName.contains(query) || email.contains(query);
    }).toList();

    final admins = searchedUsers.where((u) => u['role'] == 'admin').toList();
    final internUsers =
        searchedUsers.where((u) => u['role'] != 'admin').toList();

    int sortSelfToTop(dynamic a, dynamic b) {
      if (toInt(a['id']) == currentUserId) return -1;
      if (toInt(b['id']) == currentUserId) return 1;
      return 0;
    }

    admins.sort(sortSelfToTop);
    internUsers.sort(sortSelfToTop);

    return Scaffold(
      backgroundColor: theme.appBackground,
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen
                ? AdminSidebar(
                    currentRoute: GoRouterState.of(context).matchedLocation,
                    onClose: () => setState(() => _isSidebarOpen = false),
                  )
                : null,
          ),
          Expanded(
            child: AppBackground(
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
                      title: 'User Management',
                      showWelcome: false,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 100, right: 100, bottom: 28),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Bar
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? theme.surface
                                    : theme.sidebarBackground,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                style: TextStyle(
                                    color: theme.surfaceText, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search by name or email...',
                                  hintStyle: TextStyle(
                                      color: theme.mutedText, fontSize: 13),
                                  prefixIcon: Icon(Icons.search,
                                      color: theme.mutedText),
                                  suffixIcon: _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear,
                                              color: theme.mutedText),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? theme.surface
                                      : theme.sidebarBackground,
                                ),
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilterPillGroup(
                              tabs: tabs,
                              filterStatus: _filterStatus,
                              onTabChanged: _onTabChanged,
                            ),
                            const SizedBox(height: 24),
                            if (_loading)
                              Padding(
                                padding: const EdgeInsets.all(48),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: theme.topbarText,
                                  ),
                                ),
                              )
                            else if (admins.isEmpty && internUsers.isEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.surface
                                      : theme.sidebarBackground,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(48),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 56,
                                        color: theme.listMutedText,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No users found in this category.',
                                        style:
                                            TextStyle(color: theme.mutedText),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              if (admins.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: UserListSection(
                                    title: 'Administrators',
                                    users: admins,
                                    currentUserId: currentUserId,
                                    onToggleActive: _toggleActive,
                                    onArchive: _archiveUser,
                                    onRestore: _restoreUser,
                                  ),
                                ),
                              if (admins.isNotEmpty && internUsers.isNotEmpty)
                                const SizedBox(height: 24),
                              if (internUsers.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: UserListSection(
                                    title: 'Interns',
                                    users: internUsers,
                                    currentUserId: currentUserId,
                                    onToggleActive: _toggleActive,
                                    onArchive: _archiveUser,
                                    onRestore: _restoreUser,
                                  ),
                                ),
                            ],
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
}
