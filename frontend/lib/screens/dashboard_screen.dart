import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _activityLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // Loads stats and activity logs in parallel.
  // getActivityLogs() is already filtered on the backend:
  //   - regular users  → only their own logs
  //   - admins         → all logs
  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getDashboardStats(),
        ApiService.getActivityLogs(),
      ]);

      if (!mounted) return;

      final statsRes = results[0];
      final logsRes  = results[1];

      setState(() {
        if (statsRes['ok'] == true) {
          _stats = statsRes;
        }
        _activityLogs = (logsRes['logs'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('_loadAll error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/dashboard'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Welcome back, ${user?['first_name'] ?? 'User'}! 👋',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loadAll,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    // ── Stat cards — visible to ALL users ────────────
                    LayoutBuilder(builder: (context, constraints) {
                      final cols = constraints.maxWidth > 800 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            title: 'Total Users',
                            value: '${_stats?['total_users'] ?? 0}',
                            icon: Icons.people,
                            color: const Color(0xFF6C63FF),
                            subtitle: 'Registered accounts',
                          ),
                          StatCard(
                            title: 'Active Users',
                            value: '${_stats?['active_users'] ?? 0}',
                            icon: Icons.check_circle,
                            color: const Color(0xFF4CAF50),
                            subtitle: 'Currently active',
                          ),
                          StatCard(
                            title: 'Admins',
                            value: '${_stats?['admin_users'] ?? 0}',
                            icon: Icons.admin_panel_settings,
                            color: const Color(0xFFFF6B6B),
                            subtitle: 'Administrator accounts',
                          ),
                          StatCard(
                            title: 'Inactive',
                            value: '${_stats?['new_users'] ?? 0}',
                            icon: Icons.person_off,
                            color: const Color(0xFFFFA726),
                            subtitle: 'Inactive accounts',
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 32),

                    // ── Recent users — visible to ALL users ──────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Users',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (auth.isAdmin)
                          TextButton.icon(
                            onPressed: () => context.go('/users'),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: _buildRecentUsers(),
                    ),
                    const SizedBox(height: 24),

                    // ── Recent Activity — filtered per role ──────────
                    // Regular users → their own logs only (backend filters)
                    // Admins        → all users' logs (backend returns all)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.isAdmin
                                  ? 'Recent Activity'
                                  : 'My Recent Activity',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (!auth.isAdmin)
                              Text(
                                'Your account activity only',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: _buildActivityFeed(auth.isAdmin),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent users ───────────────────────────────────────────────────────────
  Widget _buildRecentUsers() {
    final users = (_stats?['recent_users'] as List?) ?? [];
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No users yet')),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final u = users[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                const Color(0xFF6C63FF).withValues(alpha: 0.1),
            child: Text(
              '${u['first_name']?[0] ?? ''}${u['last_name']?[0] ?? ''}',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            '${u['first_name']} ${u['last_name']}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(u['email'] ?? ''),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: u['role'] == 'admin'
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              u['role'] ?? 'user',
              style: TextStyle(
                color: u['role'] == 'admin'
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Activity feed ──────────────────────────────────────────────────────────
  Widget _buildActivityFeed(bool isAdmin) {
    if (_activityLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No activity yet')),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activityLogs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final log = _activityLogs[i];

        // Admins see whose action it was; regular users don't need this
        final logUser = log['user'] as Map<String, dynamic>?;
        final userName = (isAdmin && logUser != null)
            ? '${logUser['first_name'] ?? ''} ${logUser['last_name'] ?? ''}'
                .trim()
            : '';

        return ListTile(
          dense: true,
          leading: _actionIcon(log['action'] as String?),
          title: Text(
            log['details'] ?? log['action'] ?? '',
            style: const TextStyle(fontSize: 13),
          ),
          // Only show the user name subtitle for admins
          subtitle: userName.isNotEmpty
              ? Text(
                  userName,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                )
              : null,
          trailing: Text(
            _formatDate(log['created_at'] as String?),
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        );
      },
    );
  }

  // ── Action icon ────────────────────────────────────────────────────────────
  Widget _actionIcon(String? action) {
    IconData icon;
    Color color;
    switch (action) {
      case 'LOGIN':
        icon = Icons.login;
        color = Colors.green;
        break;
      case 'REGISTER':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case 'UPDATE_PROFILE':
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case 'CHANGE_PASSWORD':
        icon = Icons.lock;
        color = Colors.purple;
        break;
      case 'LOGIN_FAILED':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case 'ACCOUNT_LOCKED':
        icon = Icons.lock_clock;
        color = Colors.red;
        break;
      case 'PASSWORD_RESET_REQUEST':
        icon = Icons.mail_outline;
        color = Colors.blue;
        break;
      case 'PASSWORD_RESET':
        icon = Icons.lock_reset;
        color = Colors.teal;
        break;
      case 'CREATE_USER':
        icon = Icons.person_add_alt;
        color = Colors.teal;
        break;
      case 'DELETE_USER':
        icon = Icons.delete_outline;
        color = Colors.red;
        break;
      case 'UPDATE_USER':
        icon = Icons.manage_accounts;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, size: 14, color: color),
    );
  }

  // ── Date formatter ─────────────────────────────────────────────────────────
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}