import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';

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

  Future<void> _loadUsers({String? search}) async {
    setState(() => _loading = true);
    final res = await ApiService.getUsers(search: search);
    if (res['ok'] == true && mounted) {
      setState(() { _users = res['users'] ?? []; _loading = false; });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteUser(id);
      _loadUsers();
    }
  }

  Future<void> _toggleActive(int id, bool current) async {
    await ApiService.updateUser(id, {'is_active': !current});
    _loadUsers();
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
                  Row(
                    children: [
                      Expanded(
                        child: Text('User Management',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/users/add');
                          _loadUsers();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadUsers();
                              })
                          : null,
                    ),
                    onSubmitted: (v) => _loadUsers(search: v),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _users.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('No users found'),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _users.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final u = _users[i];
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                                        child: Text(
                                          '${u['first_name']?[0] ?? ''}${u['last_name']?[0] ?? ''}',
                                          style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(
                                        '${u['first_name']} ${u['last_name']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u['email'] ?? ''),
                                          if (u['department'] != null && (u['department'] as String).isNotEmpty)
                                            Text(u['department'], style: const TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Role badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: u['role'] == 'admin'
                                                  ? Colors.red.shade50
                                                  : Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              u['role'] ?? 'user',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: u['role'] == 'admin'
                                                    ? Colors.red.shade700
                                                    : Colors.blue.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Active toggle
                                          Switch(
                                            value: u['is_active'] ?? false,
                                            onChanged: (v) => _toggleActive(u['id'], u['is_active'] ?? false),
                                          ),
                                          // Delete button
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _deleteUser(
                                                u['id'], '${u['first_name']} ${u['last_name']}'),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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