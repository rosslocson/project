import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  const Sidebar({super.key, required this.currentRoute});

  // Exact colors extracted from the design
  static const Color _bgColor = Color(0xFF460A14);
  static const Color _logoBoxColor = Color(0xFF651323);
  static const Color _userBoxBg = Color(0xFFF9F4EC);
  static const Color _userAvatarBg = Color(0xFFE0CDB9);
  static const Color _activeItemBg = Color(0xFFC8A8A8);
  static const Color _sectionLabelColor = Color(0xFFC1ADAE);
  static const Color _textLight = Colors.white;
  static const Color _textDark = Color(0xFF460A14);

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final user    = auth.user;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: _bgColor,
      ),
      child: Column(
        children: [
          // ── Logo / brand & Close Button ─────────────────────────────
          Padding(
            // Increased top and bottom padding for more breathing room
            padding: const EdgeInsets.only(left: 20, top: 48, right: 20, bottom: 32),
            child: Row(
              children: [
                // Larger Logo Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _logoBoxColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_alt, color: _textLight, size: 24),
                ),
                const SizedBox(width: 16), // Increased horizontal spacing
                
                // Larger Application Name
                const Expanded(
                  child: Text(
                    'UserApp',
                    style: TextStyle(
                      color: _textLight,
                      fontSize: 22, // Increased font size
                      fontWeight: FontWeight.w800, // Made bolder
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                // Larger Close 'X' Button
                Material(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.read<SidebarProvider>().toggle(),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0), // Increased tap target padding
                      child: Icon(
                        Icons.close_rounded, 
                        color: _textLight, 
                        size: 24, // Increased icon size to match logo
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── User chip ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // Slightly taller
            decoration: BoxDecoration(
              color: _userBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _userAvatarBg,
                  child: Text(
                    user?['first_name'] != null && user!['first_name'].toString().isNotEmpty 
                        ? user['first_name'].toString()[0].toUpperCase() 
                        : '',
                    style: const TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (user?['role'] as String? ?? 'USER').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: _textDark, size: 18),
              ],
            ),
          ),

          // Increased spacing between User Chip and Menu
          const SizedBox(height: 24),

          // ── Nav items ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _SectionLabel('MENU'),
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  route: '/home',
                  current: currentRoute,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'My Profile',
                  route: '/profile',
                  current: currentRoute,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Account Settings',
                  route: '/account-settings', // Account Settings route
                  current: currentRoute,
                ),
                
                // Admin specific section
                if (isAdmin) ...[
                  const SizedBox(height: 16), // Extra spacing for the new section
                  const _SectionLabel('ADMINISTRATION'),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              InkWell(
                onTap: () {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                },
                child: const Padding(
                  // Slightly increased vertical padding for the Sign Out button
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: _textLight, size: 22),
                      SizedBox(width: 16),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      // Increased vertical margin to spread out the list items
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Sidebar._activeItemBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon,
          size: 20,
          color: active ? Sidebar._textDark : Sidebar._textLight,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Sidebar._textDark : Sidebar._textLight,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: active ? null : () => context.go(route),
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
        // Increased top and bottom padding to separate sections visually
        padding: const EdgeInsets.only(left: 20, top: 16, bottom: 12),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Sidebar._sectionLabelColor,
            letterSpacing: 1.0,
          ),
        ),
      );
}