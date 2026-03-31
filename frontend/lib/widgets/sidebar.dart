import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

const _kCrimson = Color(0xFF7B0D1E);

class Sidebar extends StatelessWidget {
  final String currentRoute;
  const Sidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final first = user?['first_name'] as String? ?? '';
    final last  = user?['last_name']  as String? ?? '';
    String initials = '';
    if (first.isNotEmpty) initials += first[0];
    if (last.isNotEmpty)  initials += last[0];

    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          // ── Logo ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _kCrimson,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('UserApp',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kCrimson)),
            ]),
          ),

          // ── User card (clickable → My Profile) ───────────────────────
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kCrimson.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentRoute == '/profile'
                      ? _kCrimson.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _kCrimson.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                        color: _kCrimson,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$first $last',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        (user?['role'] ?? 'user').toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10, color: _kCrimson),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: _kCrimson),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ── MENU section ───────────────────────────────────────────────
          _sectionLabel('MENU'),
          const SizedBox(height: 6),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: '/dashboard',
            current: currentRoute,
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'My Profile',
            route: '/profile',
            current: currentRoute,
          ),
          _NavItem(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            route: '/profile/edit',
            current: currentRoute,
          ),

          // ── ADMIN section ──────────────────────────────────────────────
          if (auth.isAdmin) ...[
            const SizedBox(height: 16),
            _sectionLabel('ADMIN'),
            const SizedBox(height: 6),
            _NavItem(
              icon: Icons.people_outline,
              label: 'User Management',
              route: '/users',
              current: currentRoute,
            ),
            _NavItem(
              icon: Icons.person_add_outlined,
              label: 'Add User',
              route: '/users/add',
              current: currentRoute,
            ),
            _NavItem(
              icon: Icons.business_outlined,
              label: 'Departments',
              route: '/config',
              current: currentRoute,
            ),
          ],

          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 20),
            title: const Text('Sign Out',
                style: TextStyle(color: Colors.red, fontSize: 14)),
            dense: true,
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

// ── Section label helper ──────────────────────────────────────────────────────
Widget _sectionLabel(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: Colors.grey,
                fontWeight: FontWeight.w600)),
      ),
    );

// ── Nav item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   route;
  final String   current;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? _kCrimson.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? _kCrimson : Colors.grey.shade500,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? _kCrimson : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => context.go(route),
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
      ),
    );
  }
}