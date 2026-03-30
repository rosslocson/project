import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';

const kCrimson = Color(0xFF7B0D1E);

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getUsers(search: search);
      if (mounted) {
        setState(() {
          _users = res['ok'] == true ? (res['users'] ?? []) : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Toggle active/inactive ─────────────────────────────────────────────────
  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final id       = user['id'] as int;
    final current  = user['is_active'] as bool? ?? false;
    final newValue = !current;

    // Optimistic UI update
    setState(() => user['is_active'] = newValue);

    final res = await ApiService.updateUser(id, {'is_active': newValue});
    if (res['ok'] != true && mounted) {
      // Revert on failure
      setState(() => user['is_active'] = current);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update: ${res['error'] ?? 'Unknown error'}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ── Delete with confirmation ───────────────────────────────────────────────
  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id   = user['id'] as int;
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
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Delete User', style: TextStyle(fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Deleting user...'),
        ]),
        duration: Duration(seconds: 10),
      ),
    );

    final res = await ApiService.deleteUser(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (res['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$name has been deleted.'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      await _loadUsers(search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Delete failed: ${res['error'] ?? 'Unknown error'}'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Manage departments/positions sheet ─────────────────────────────────────
  void _showConfigManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfigManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/users'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(children: [
                    Expanded(
                      child: Text(
                        'User Management',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Manage departments/positions
                    OutlinedButton.icon(
                      onPressed: _showConfigManager,
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('Departments & Positions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kCrimson,
                        side: const BorderSide(color: kCrimson),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await context.push('/users/add');
                        _loadUsers();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCrimson,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadUsers();
                                setState(() {});
                              })
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => setState(() {}),
                    onSubmitted: (v) => _loadUsers(search: v),
                  ),
                  const SizedBox(height: 16),

                  // User list
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _users.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline,
                                          size: 56,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text('No users found',
                                          style: TextStyle(
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _users.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, indent: 20),
                                  itemBuilder: (context, i) =>
                                      _UserTile(
                                        user: _users[i],
                                        onToggle: () =>
                                            _toggleActive(_users[i]),
                                        onDelete: () =>
                                            _deleteUser(_users[i]),
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

// ── User list tile ────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _UserTile({
    required this.user,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? false;
    final isAdmin  = user['role'] == 'admin';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: kCrimson.withValues(alpha: 0.1),
        child: Text(
          '${user['first_name']?[0] ?? ''}${user['last_name']?[0] ?? ''}',
          style: const TextStyle(
              color: kCrimson, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        '${user['first_name']} ${user['last_name']}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.black87 : Colors.grey,
          decoration: isActive ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user['email'] ?? '',
              style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.black54 : Colors.grey)),
          if ((user['department'] as String? ?? '').isNotEmpty)
            Text(
              '${user['department']} · ${user['position'] ?? ''}',
              style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.black38 : Colors.grey),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAdmin ? 'Admin' : 'User',
              style: TextStyle(
                fontSize: 11,
                color: isAdmin
                    ? Colors.red.shade700
                    : Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Active/inactive badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Toggle switch
          Tooltip(
            message: isActive ? 'Deactivate user' : 'Activate user',
            child: Switch(
              value: isActive,
              activeThumbColor: Colors.green.shade600,
              inactiveThumbColor: Colors.orange.shade400,
              onChanged: (_) => onToggle(),
            ),
          ),

          // Delete button
          Tooltip(
            message: 'Delete user',
            child: IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade400),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Config manager bottom sheet ───────────────────────────────────────────────
class _ConfigManagerSheet extends StatefulWidget {
  const _ConfigManagerSheet();
  @override
  State<_ConfigManagerSheet> createState() => _ConfigManagerSheetState();
}

class _ConfigManagerSheetState extends State<_ConfigManagerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _departments = [];
  List<dynamic> _positions   = [];
  bool _loading = true;
  final _deptCtrl = TextEditingController();
  final _posCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _deptCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final d = await ApiService.getConfig(type: 'department');
    final p = await ApiService.getConfig(type: 'position');
    if (mounted) {
      setState(() {
        _departments = d['items'] ?? [];
        _positions   = p['items'] ?? [];
        _loading     = false;
      });
    }
  }

  Future<void> _add(String name, String type) async {
    if (name.trim().isEmpty) return;
    final res = await ApiService.createConfig(name.trim(), type);
    if (res['ok'] == true) {
      await _loadAll();
      if (type == 'department') _deptCtrl.clear();
      else _posCtrl.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Failed'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _delete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirm Delete'),
        content: Text('Remove "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ApiService.deleteConfig(id);
      await _loadAll();
    }
  }

  Widget _buildList(List<dynamic> items, TextEditingController ctrl, String type) {
    return Column(
      children: [
        // Add new row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'Add new $type...',
                  filled: true,
                  fillColor: const Color(0xFFEEF2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (v) => _add(v, type),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () =>
                  _add(type == 'department' ? _deptCtrl.text : _posCtrl.text, type),
              style: ElevatedButton.styleFrom(
                backgroundColor: kCrimson,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Icon(Icons.add),
            ),
          ]),
        ),
        const Divider(height: 1),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              Icon(Icons.inbox_outlined,
                  size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('No ${type}s added yet',
                  style: TextStyle(color: Colors.grey.shade500)),
            ]),
          )
        else
          ...items.map((item) => ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: kCrimson.withValues(alpha: 0.08),
                  child: Text(
                    (item['name'] as String)[0].toUpperCase(),
                    style: const TextStyle(
                        color: kCrimson, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(item['name'] ?? '',
                    style: const TextStyle(fontSize: 14)),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                  onPressed: () => _delete(item['id'] as int, item['name']),
                ),
              )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Icon(Icons.settings_outlined, color: kCrimson),
              SizedBox(width: 10),
              Text('Manage Departments & Positions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            labelColor: kCrimson,
            indicatorColor: kCrimson,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Departments'),
              Tab(text: 'Positions'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                SingleChildScrollView(
                    child: _buildList(_departments, _deptCtrl, 'department')),
                SingleChildScrollView(
                    child: _buildList(_positions, _posCtrl, 'position')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}