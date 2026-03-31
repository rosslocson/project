import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_theme.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  const Sidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final user    = auth.user;

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Logo / brand ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kCrimson,
                  kCrimson.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'UserApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ]),
          ),

          // ── User chip ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCrimson.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: kCrimson.withValues(alpha: 0.1)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kCrimson.withValues(alpha: 0.15),
                child: Text(
                  '${(user?['first_name'] as String? ?? ' ')[0]}'
                  '${(user?['last_name']  as String? ?? ' ')[0]}',
                  style: const TextStyle(
                      color: kCrimson,
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
                      '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      (user?['role'] as String? ?? 'user')
                          .toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          color: kCrimson,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 4),

          // ── Nav items ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
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
                if (isAdmin) ...[
                  const _SectionLabel('Administration'),
                  _NavItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'User Management',
                    route: '/users',
                    current: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.business_outlined,
                    label: 'Departments',
                    route: '/config',
                    current: currentRoute,
                  ),
                ],
              ],
            ),
          ),

          // ── Sign out ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: () {
                context.read<AuthProvider>().logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout_outlined,
                  color: Color(0xFF6B7280), size: 18),
              label: const Text('Sign Out',
                  style: TextStyle(
                      color: Color(0xFF6B7280), fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

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
    final active = current == route;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? kCrimson.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: active ? kCrimson : const Color(0xFF6B7280),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? kCrimson : const Color(0xFF374151),
          ),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        onTap: active ? null : () => context.go(route),
        // Active indicator bar
        trailing: active
            ? Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: kCrimson,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade400,
            letterSpacing: 1.0,
          ),
        ),
      );
}