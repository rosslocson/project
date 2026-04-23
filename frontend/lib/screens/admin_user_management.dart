import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';
import '../services/api_service.dart';
import '../widgets/admin_layout.dart';

// ── Custom Hamburger Icon ────────────────────────────────────────────────────
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
              color: Colors.white.withOpacity(0.8),
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

int _toInt(dynamic v) {
  if (v == null) return 0;
  return (v as num).toInt();
}

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
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final id = _toInt(user['id']);
    final current = user['is_active'] as bool? ?? false;
    final next = !current;
    setState(() => user['is_active'] = next);
    final res = await ApiService.updateUser(id, {'is_active': next});
    if (res['ok'] != true && mounted) {
      setState(() => user['is_active'] = current);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${res['error'] ?? 'Unknown error'}'),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id = _toInt(user['id']);
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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.delete_forever,
                color: Colors.blue.shade700, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Delete User',
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
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                      text: name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('This action cannot be undone.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
    if (id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error: could not read user ID. Try refreshing.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        SizedBox(width: 12),
        Text('Deleting user...'),
      ]),
      duration: Duration(seconds: 10),
    ));

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
      await _loadUsers(
          search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Delete failed: ${res['error'] ?? 'Unknown error'}'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unused variables kept in case they are used in adjacent scope/components
    final sidebar = context.watch<SidebarProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isSidebarOpen = sidebar.isAdminSidebarOpen;

    // OVERRIDE: Wrap AdminLayout in a Theme to force the background dark
    // This prevents white bars if AdminLayout uses a Scaffold or SafeArea internally
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A14), // Dark space color
      ),
      child: AdminLayout(
        title: 'User Management',
        currentRoute: GoRouterState.of(context).matchedLocation ?? '/users',
        // OVERRIDE: Swapped Stack for a robust Container that forces double.infinity
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A14), // Fallback color under the image
            image: DecorationImage(
              image: AssetImage('assets/images/space_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'User Management',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Search ───────────────────────────
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadUsers();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() {}),
                  onSubmitted: (v) => _loadUsers(search: v),
                ),
                const SizedBox(height: 8),

                // ── User list card ───────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _users.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
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
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _users.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 20),
                                itemBuilder: (context, i) {
                                  final u = _users[i];
                                  return _UserTile(
                                    key: ValueKey(_toInt(u['id'])),
                                    user: u,
                                    onToggle: () => _toggleActive(u),
                                    onDelete: () => _deleteUser(u),
                                  );
                                },
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

// ── User Tile ─────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _UserTile({
    super.key,
    required this.user,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? false;
    final isAdmin = user['role'] == 'admin';

    final rawAvatarUrl = user['avatar_url'] as String? ?? '';
    final finalAvatarUrl = rawAvatarUrl.isNotEmpty
        ? (rawAvatarUrl.startsWith('http')
            ? rawAvatarUrl
            : 'http://127.0.0.1:8080$rawAvatarUrl')
        : '';

    // Safely extract names and check if they are empty before grabbing index 0
    final String fName = user['first_name'] ?? '';
    final String lName = user['last_name'] ?? '';
    final initials =
        '${fName.isNotEmpty ? fName[0] : ''}${lName.isNotEmpty ? lName[0] : ''}'
            .toUpperCase();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
        backgroundImage:
            finalAvatarUrl.isNotEmpty ? NetworkImage(finalAvatarUrl) : null,
        child: finalAvatarUrl.isEmpty
            ? Text(
                initials.isEmpty ? 'U' : initials,
                style: TextStyle(
                  color: isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      // ── smaller user name ──
      title: Text(
        '${user['first_name']} ${user['last_name']}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.black87 : Colors.grey,
          decoration: isActive ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── smaller email ──
          Text(user['email'] ?? '',
              style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.black54 : Colors.grey)),
          if ((user['department'] as String? ?? '').isNotEmpty)
            // ── smaller department · position ──
            Text(
              '${user['department']} · ${user['position'] ?? ''}',
              style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.black38 : Colors.grey),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAdmin ? 'Admin' : 'User',
              style: TextStyle(
                fontSize: 11,
                color: isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                color:
                    isActive ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: isActive ? 'Deactivate user' : 'Activate user',
            child: Switch(
              value: isActive,
              activeThumbColor: Colors.green.shade600,
              inactiveThumbColor: Colors.orange.shade400,
              onChanged: (_) => onToggle(),
            ),
          ),
          Tooltip(
            message: 'Delete user',
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}