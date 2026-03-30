import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  const Sidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          // Logo area
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_alt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text('UserApp',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primary)),
              ],
            ),
          ),

          // User info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primary.withValues(alpha: 0.15),
                  child: Text(
                    '${user?['first_name']?[0] ?? ''}${user?['last_name']?[0] ?? ''}',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        (user?['role'] ?? 'user').toUpperCase(),
                        style: TextStyle(fontSize: 10, color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MENU', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 8),

          // Nav items
          _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard', current: currentRoute),
          _NavItem(icon: Icons.person_outline, label: 'My Profile', route: '/profile', current: currentRoute),
          if (auth.isAdmin) ...[
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('ADMIN', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 8),
            _NavItem(icon: Icons.people_outline, label: 'Users', route: '/users', current: currentRoute),
          ],

          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String current;

  const _NavItem({required this.icon, required this.label, required this.route, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive = current == route;
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? colors.primary : Colors.grey.shade600, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? colors.primary : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => context.go(route),
        dense: true,
      ),
    );
  }
}