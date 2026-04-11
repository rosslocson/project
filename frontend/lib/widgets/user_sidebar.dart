import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserSidebar extends StatelessWidget {
  final String currentRoute;
  const UserSidebar({super.key, required this.currentRoute});

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
    final user = auth.user;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: _bgColor,
      ),
      child: Column(
        children: [
          // Logo / brand & Close Button
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
                
IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: _textLight, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  splashRadius: 24,
                ),
              ],
            ),
          ),

          // Nav items (user only)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _SectionLabel('MENU'),
                _NavItem(
                  icon: Icons.home_rounded, // Home icon
                  label: 'Home',            // Changed to Home
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
                  route: '/account-settings',
                  current: currentRoute,
                ),
              ],
            ),
          ),

          // Sign out
          Column(
            children: [
              Divider(color: Colors.white.withOpacity(0.15), height: 1),
              InkWell(
                onTap: () {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                },
                child: const Padding(
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
        color: active ? UserSidebar._activeItemBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon,
          size: 20,
          color: active ? UserSidebar._textDark : UserSidebar._textLight,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? UserSidebar._textDark : UserSidebar._textLight,
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
        padding: const EdgeInsets.only(left: 20, top: 16, bottom: 12),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: UserSidebar._sectionLabelColor,
            letterSpacing: 1.0,
          ),
        ),
      );
}