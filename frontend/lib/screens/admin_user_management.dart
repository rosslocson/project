import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/admin_sidebar.dart';

// ── Imported Extracted Widgets ──
import '../widgets/admin_user_management_widgets/user_utils.dart';
import '../widgets/admin_user_management_widgets/users_hamburger_icon.dart';
import '../widgets/admin_user_management_widgets/filter_pill_group.dart';
import '../widgets/admin_user_management_widgets/user_list_section.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isSidebarOpen = true;

  String _filterStatus = 'All';
  Map<String, int> _counts = {
    'all': 0,
    'active': 0,
    'inactive': 0,
    'archived': 0
  };

  @override
  void initState() {
    super.initState();
    _loadUsers(status: 'all');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers({String? search, String? status}) async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getUsers(search: search, status: status);
      if (mounted) {
        setState(() {
          _users = res['ok'] == true ? (res['users'] ?? []) : [];
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
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _silentReload() async {
    try {
      final res = await ApiService.getUsers(
          search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
          status: 'all');
      if (mounted) {
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
          // Filter displayed users based on current tab
          if (_filterStatus == 'Active') {
            _users = allUsers
                .where(
                    (u) => u['is_active'] == true && u['is_archived'] != true)
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
      }
    } catch (e) {
      // fail silently
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 1),
    ));
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
    } else {
      _silentReload();
      return true;
    }
  }

  Future<void> _archiveUser(Map<String, dynamic> user) async {
    final id = toInt(user['id']);
    final name = '${user['first_name']} ${user['last_name']}';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF4A5E9A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.archive_outlined,
                color: Color(0xFF4A5E9A), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Archive User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  const TextSpan(text: 'Are you sure you want to archive '),
                  TextSpan(
                      text: name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
                'This user will be hidden from active lists and unable to log in, but their data will be preserved.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black87))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.archive_outlined, size: 16),
            label: const Text('Archive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5E9A),
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
        id, {'is_archived': true, 'is_active': false});
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
      duration:
      const Duration(seconds: 1);
    }
  }

  Future<void> _restoreUser(Map<String, dynamic> user) async {
    final id = toInt(user['id']);
    final name = '${user['first_name']} ${user['last_name']}';

    setState(() {
      user['is_archived'] = false;
      user['is_active'] = true;
    });

    final res = await ApiService.updateUser(
        id, {'is_archived': false, 'is_active': true});
    if (!mounted) return;

    if (res['ok'] == true) {
      _showSuccess('$name has been archived.');
      _silentReload();
      duration:
      const Duration(seconds: 1);
    }
  }

  void _onTabChanged(String status) {
    setState(() => _filterStatus = status);
    String? apiStatus;
    if (status == 'Active') {
      apiStatus = 'active';
    } else if (status == 'Inactive') {
      apiStatus = 'inactive';
    } else if (status == 'Archived') {
      apiStatus = 'archived';
    } else if (status == 'All') {
      apiStatus = 'all';
    }
    _loadUsers(status: apiStatus);
  }

  @override
  Widget build(BuildContext context) {
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

    final filteredUsers = _filterStatus == 'Inactive'
        ? _users.where((u) => u['is_archived'] != true).toList()
        : _users;

    final admins = filteredUsers.where((u) => u['role'] == 'admin').toList();
    final internUsers =
        filteredUsers.where((u) => u['role'] != 'admin').toList();

    int sortSelfToTop(dynamic a, dynamic b) {
      if (toInt(a['id']) == currentUserId) return -1;
      if (toInt(b['id']) == currentUserId) return 1;
      return 0;
    }

    admins.sort(sortSelfToTop);
    internUsers.sort(sortSelfToTop);

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
                    currentRoute: GoRouterState.of(context).matchedLocation,
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
                      color: Color(0xFF0A0A14),
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
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 100, right: 100, top: 28),
                              child: Text(
                                'User Management',
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
                            if (!_isSidebarOpen)
                              Positioned(
                                left: 20,
                                top: 28,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15)),
                                  ),
                                  child: IconButton(
                                    padding: const EdgeInsets.all(12),
                                    onPressed: () =>
                                        setState(() => _isSidebarOpen = true),
                                    icon: const UsersHamburgerIcon(),
                                    tooltip: 'Open Sidebar',
                                    splashColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    highlightColor: Colors.transparent,
                                  ),
                                ),
                              ),
                          ],
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
                                TextField(
                                  controller: _searchCtrl,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search by name or email...',
                                    hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13),
                                    prefixIcon: IconButton(
                                      icon: const Icon(Icons.search,
                                          color: Colors.grey),
                                      onPressed: () {
                                        if (_debounce?.isActive ?? false) {
                                          _debounce!.cancel();
                                        }
                                        _loadUsers(search: _searchCtrl.text);
                                      },
                                    ),
                                    suffixIcon: _searchCtrl.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.grey),
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              _loadUsers(status: 'all');
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: (v) {
                                    setState(() {});
                                    if (_debounce?.isActive ?? false) {
                                      _debounce!.cancel();
                                    }
                                    _debounce = Timer(
                                        const Duration(milliseconds: 300),
                                        () => _loadUsers(search: v));
                                  },
                                  onSubmitted: (v) => _loadUsers(search: v),
                                ),
                                const SizedBox(height: 24),
                                FilterPillGroup(
                                  tabs: tabs,
                                  filterStatus: _filterStatus,
                                  onTabChanged: _onTabChanged,
                                ),
                                const SizedBox(height: 24),
                                if (_loading)
                                  const Padding(
                                    padding: EdgeInsets.all(48),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white)),
                                  )
                                else if (admins.isEmpty && internUsers.isEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.all(48),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.people_outline,
                                              size: 56,
                                              color: Colors.grey.shade300),
                                          const SizedBox(height: 12),
                                          Text(
                                              'No users found in this category.',
                                              style: TextStyle(
                                                  color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                  )
                                else ...[
                                  if (admins.isNotEmpty)
                                    UserListSection(
                                      title: 'Administrators',
                                      users: admins,
                                      currentUserId: currentUserId,
                                      onToggleActive: _toggleActive,
                                      onArchive: _archiveUser,
                                      onRestore: _restoreUser,
                                    ),
                                  if (internUsers.isNotEmpty)
                                    UserListSection(
                                      title: 'Interns',
                                      users: internUsers,
                                      currentUserId: currentUserId,
                                      onToggleActive: _toggleActive,
                                      onArchive: _archiveUser,
                                      onRestore: _restoreUser,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
