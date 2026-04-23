import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for sleek iOS-style switches
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
            width: 22, height: 2.5,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 14, height: 2.5,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 22, height: 2.5,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
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
  Timer? _debounce;
  
  // Default filter is now 'All'
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // Gets the current logged in user ID dynamically
  int _getCurrentUserId() {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) return 0;
    return _toInt(authUser is Map ? authUser['id'] : (authUser as dynamic).id);
  }

  // Returns number of active, unarchived admins
  int get _activeAdminCount {
    return _users.where((u) => 
      u['role'] == 'admin' && 
      (u['is_active'] == true) && 
      (u['is_archived'] != true)
    ).length;
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final id = _toInt(user['id']);
    final isAdmin = user['role'] == 'admin';
    final current = user['is_active'] as bool? ?? false;
    final next = !current;

    // Rule: Cannot deactivate the last active admin
    if (isAdmin && current == true && _activeAdminCount <= 1) {
      _showError('Action denied: At least one active admin must remain.');
      return;
    }

    setState(() => user['is_active'] = next);
    final res = await ApiService.updateUser(id, {'is_active': next});
    if (res['ok'] != true && mounted) {
      setState(() => user['is_active'] = current);
      _showError('Failed: ${res['error'] ?? 'Unknown error'}');
    }
  }

  Future<void> _archiveUser(Map<String, dynamic> user) async {
    final id = _toInt(user['id']);
    final currentUserId = _getCurrentUserId();
    final isAdmin = user['role'] == 'admin';
    final isActive = user['is_active'] as bool? ?? false;
    final name = '${user['first_name']} ${user['last_name']}';

    // Rule: Cannot archive self
    if (id == currentUserId) {
      _showError('You cannot archive your own account.');
      return;
    }

    // Rule: Cannot archive the last active admin
    if (isAdmin && isActive && _activeAdminCount <= 1) {
      _showError('Action denied: At least one active admin must remain.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A5E9A).withOpacity(0.1), 
              borderRadius: BorderRadius.circular(8)
            ),
            child: const Icon(Icons.archive_outlined, color: Color(0xFF4A5E9A), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Archive User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('This user will be hidden from active lists and unable to log in, but their data will be preserved.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.black87))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.archive_outlined, size: 16),
            label: const Text('Archive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5E9A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Call update API setting is_archived to true
    final res = await ApiService.updateUser(id, {'is_archived': true, 'is_active': false}); 
    if (!mounted) return;

    if (res['ok'] == true) {
      _showSuccess('$name has been archived.');
      await _loadUsers(search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text);
    } else {
      _showError('Archive failed: ${res['error'] ?? 'Unknown error'}');
    }
  }

  Future<void> _restoreUser(Map<String, dynamic> user) async {
    final id = _toInt(user['id']);
    final name = '${user['first_name']} ${user['last_name']}';

    // Call update API setting is_archived to false
    final res = await ApiService.updateUser(id, {'is_archived': false});
    if (!mounted) return;

    if (res['ok'] == true) {
      _showSuccess('$name has been restored.');
      await _loadUsers(search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text);
    } else {
      _showError('Restore failed: ${res['error'] ?? 'Unknown error'}');
    }
  }

  Widget _buildUserSection(String title, List<dynamic> sectionUsers) {
    if (sectionUsers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sectionUsers.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20),
              itemBuilder: (context, i) {
                final u = sectionUsers[i];
                return _UserTile(
                  key: ValueKey(_toInt(u['id'])),
                  user: u,
                  // Use the actual user state for styling, rather than the global filter state
                  isArchivedView: u['is_archived'] == true, 
                  isCurrentUser: _toInt(u['id']) == _getCurrentUserId(),
                  onToggle: () => _toggleActive(u),
                  onArchive: () => _archiveUser(u),
                  onRestore: () => _restoreUser(u),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _getCurrentUserId();

    // Calculate dynamic counts
    final int allCount = _users.length;
    final int activeCount = _users.where((u) => u['is_active'] == true && u['is_archived'] != true).length;
    final int inactiveCount = _users.where((u) => u['is_active'] != true && u['is_archived'] != true).length;
    final int archivedCount = _users.where((u) => u['is_archived'] == true).length;

    final tabs = [
      {'id': 'All', 'label': 'All', 'count': allCount},
      {'id': 'Active', 'label': 'Active', 'count': activeCount},
      {'id': 'Inactive', 'label': 'Inactive', 'count': inactiveCount},
      {'id': 'Archived', 'label': 'Archived', 'count': archivedCount},
    ];

    // 1. Filter out users based on selected status (All, Active, Inactive, Archived)
    final filteredUsers = _users.where((u) {
      final isArchived = u['is_archived'] == true;
      final isActive = u['is_active'] == true;

      if (_filterStatus == 'Archived') return isArchived;
      if (_filterStatus == 'Active') return !isArchived && isActive;
      if (_filterStatus == 'Inactive') return !isArchived && !isActive;
      return true; // For 'All', allow everything
    }).toList();

    // 2. Separate into Admins & Interns
    final admins = filteredUsers.where((u) => u['role'] == 'admin').toList();
    final internUsers = filteredUsers.where((u) => u['role'] != 'admin').toList();

    // 3. Rule: Logged-in User is always at the top of their respective list
    int sortSelfToTop(dynamic a, dynamic b) {
      if (_toInt(a['id']) == currentUserId) return -1;
      if (_toInt(b['id']) == currentUserId) return 1;
      return 0; // retain original order for others
    }
    admins.sort(sortSelfToTop);
    internUsers.sort(sortSelfToTop);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
      ),
      child: AdminLayout(
        title: 'User Management',
        currentRoute: GoRouterState.of(context).matchedLocation ?? '/users',
        child: Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A14),
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
                Text(
                  'User Management',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white,
                      ),
                ),
                const SizedBox(height: 24),

                // ── Search ───────────────────────────
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.grey),
                      onPressed: () {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _loadUsers(search: _searchCtrl.text);
                      },
                    ),
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
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
                    ),
                    filled: true, fillColor: Colors.white,
                  ),
                  onChanged: (v) {
                    setState(() {});
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      _loadUsers(search: v);
                    });
                  },
                  onSubmitted: (v) => _loadUsers(search: v),
                ),
                const SizedBox(height: 24),

                // ── Filter Pill Group (All / Active / Inactive / Archived) ──────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08), // Soft glass background
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: tabs.map((tab) {
                      final id = tab['id'] as String;
                      final label = tab['label'] as String;
                      final count = tab['count'] as int;
                      final isSelected = _filterStatus == id;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _filterStatus = id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4A5E9A) : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4A5E9A).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$label ($count)',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tables ───────────────────────────
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  )
                else if (admins.isEmpty && internUsers.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No users found in this category.',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (admins.isNotEmpty) _buildUserSection('Administrators', admins),
                  if (internUsers.isNotEmpty) _buildUserSection('Interns', internUsers),
                ],
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
  final bool isArchivedView;
  final bool isCurrentUser;
  final VoidCallback onToggle;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  const _UserTile({
    super.key,
    required this.user,
    required this.isArchivedView,
    required this.isCurrentUser,
    required this.onToggle,
    required this.onArchive,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? false;
    final isAdmin = user['role'] == 'admin';

    final rawAvatarUrl = user['avatar_url'] as String? ?? '';
    final finalAvatarUrl = rawAvatarUrl.isNotEmpty
        ? (rawAvatarUrl.startsWith('http') ? rawAvatarUrl : 'http://127.0.0.1:8080$rawAvatarUrl')
        : '';

    final String fName = user['first_name'] ?? '';
    final String lName = user['last_name'] ?? '';
    final initials = '${fName.isNotEmpty ? fName[0] : ''}${lName.isNotEmpty ? lName[0] : ''}'.toUpperCase();

    // Grey out tile completely if archived
    final opacity = isArchivedView ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isAdmin ? Colors.indigo.shade50 : Colors.blue.shade50,
              backgroundImage: finalAvatarUrl.isNotEmpty ? NetworkImage(finalAvatarUrl) : null,
              child: finalAvatarUrl.isEmpty
                  ? Text(
                      initials.isEmpty ? 'U' : initials,
                      style: TextStyle(
                        color: isAdmin ? Colors.indigo.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (isCurrentUser)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
          ],
        ),
        title: Row(
          children: [
            Text(
              '${user['first_name']} ${user['last_name']}',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isArchivedView ? Colors.grey.shade700 : (isActive ? Colors.black87 : Colors.grey),
                decoration: (!isActive && !isArchivedView) ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                child: Text('You', style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? '',
                style: TextStyle(fontSize: 11, color: isArchivedView ? Colors.grey.shade500 : (isActive ? Colors.black54 : Colors.grey.shade400))),
            if ((user['department'] as String? ?? '').isNotEmpty)
              Text(
                '${user['department']} · ${user['position'] ?? ''}',
                style: TextStyle(fontSize: 10, color: isArchivedView ? Colors.grey.shade400 : (isActive ? Colors.black38 : Colors.grey.shade400)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.indigo.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? 'Admin' : 'Intern',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: isAdmin ? Colors.indigo.shade700 : Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 6),

            if (isArchivedView)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: Text('Archived', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF4A5E9A).withOpacity(0.1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF4A5E9A) : Colors.grey.shade600,
                  ),
                ),
              ),
            
            const SizedBox(width: 12),

            // Sleek Cupertino Toggle switch
            if (!isArchivedView)
              Tooltip(
                message: isActive ? 'Deactivate user' : 'Activate user',
                child: Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: isActive,
                    activeColor: const Color(0xFF4A5E9A),
                    trackColor: Colors.grey.shade300,
                    onChanged: (_) => onToggle(),
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Styled Action Buttons
            if (isArchivedView)
              Tooltip(
                message: 'Restore user',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A5E9A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.unarchive_rounded, color: Color(0xFF4A5E9A)),
                    onPressed: onRestore,
                  ),
                ),
              )
            else
              Tooltip(
                message: isCurrentUser ? 'Cannot archive yourself' : 'Archive user',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.transparent : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrentUser ? Colors.transparent : Colors.grey.shade200,
                      width: 1,
                    )
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.archive_outlined, 
                      color: isCurrentUser ? Colors.grey.shade300 : Colors.blueGrey.shade400
                    ),
                    onPressed: isCurrentUser ? null : onArchive,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}