import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onClose;
  const AdminSidebar({super.key, required this.currentRoute, this.onClose});

  // Exact colors extracted from the design
  static const Color _bgColor = Color(0xFF460A14);
  static const Color _logoBoxColor = Color(0xFF651323);
  static const Color _activeItemBg = Color(0xFFC8A8A8);
  static const Color _sectionLabelColor = Color(0xFFC1ADAE);
  static const Color _textLight = Colors.white;
  static const Color _textDark = Color(0xFF460A14);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
final isAdmin = auth.isAdmin;

    final user = auth.user;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: _bgColor,
      ),
      child: Column(
        children: [
          // Logo / brand
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 48, right: 20, bottom: 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _logoBoxColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_alt, color: _textLight, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'UserApp',
                    style: TextStyle(
                      color: _textLight,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClose,
                    child: Material(
                      color: Colors.white.withOpacity(0.1),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.close_rounded, 
                          color: _textLight, 
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),



          // Nav items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _SectionLabel('MENU'),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  route: '/dashboard',
                  current: currentRoute,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'My Profile',
                  route: '/admin/profile',
                  current: currentRoute,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Account Settings',
                  route: '/admin/account-settings',
                  current: currentRoute,
                ),
                // Admin specific section
                if (isAdmin) ...[
                  const SizedBox(height: 16),
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

          // Sign out
          Column(
            children: [
              Divider(color: Colors.white.withOpacity(0.15), height: 1),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<AuthProvider>().logout();
                    context.go('/login');
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              ),
            ],
          ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AdminSidebar._activeItemBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon,
          size: 20,
          color: active ? AdminSidebar._textDark : AdminSidebar._textLight,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AdminSidebar._textDark : AdminSidebar._textLight,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: active ? null : () => context.go(route),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 20, top: 12, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AdminSidebar._sectionLabelColor,
            letterSpacing: 1.0,
          ),
        ),
      );
}

