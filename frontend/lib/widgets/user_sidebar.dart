import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'logout_confirmation_dialog.dart';

class UserSidebar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onClose;

  const UserSidebar({super.key, required this.currentRoute, this.onClose});

  // Blue theme colors
  static const Color _bgColor = Color(0xFF0B0F2F);
  static const Color _activeItemBg = Color(0xFF6366F1);
  static const Color _sectionLabelColor = Color(0xFFA78BFA);
  static const Color _textLight = Colors.white;
  static const Color _textDark = Color(0xFF050816);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: _bgColor,
      ),
      child: Column(
        children: [
          // Logo / brand & Close Button
          Padding(
            // Adjusted left padding to 20 to align with the 'MENU' label
            padding:
                const EdgeInsets.only(left: 20, top: 48, right: 20, bottom: 32),
            child: Row(
              children: [
                // ──────────────────────────────────────────────────────────────
                // Added Transform.scale to zoom the logo without moving text
                Transform.scale(
                  scale: 1.3, // Adjust this value to zoom more or less
                  child: Image.asset(
                    'assets/images/logo_file.png',
                    height: 40,
                    width: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.public,
                          color: _textLight, size: 24);
                    },
                  ),
                ),
                // ──────────────────────────────────────────────────────────────
                const SizedBox(
                    width: 12), // Increased gap between logo and text

                const Expanded(
                  child: Text(
                    'InternSpace',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                _CloseButton(onClose: onClose),
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
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  route: '/edit-profile',
                  current: currentRoute,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Account Settings',
                  route: '/account-settings',
                  current: currentRoute,
                ),
                // ── OJT / Attendance section ──────────────────────────────
                const _SectionLabel('OJT'),
                _NavItem(
                  icon: Icons.access_time_rounded,
                  label: 'Attendance',
                  route: '/attendance',
                  current: currentRoute,
                ),
                // ── Info section ──────────────────────────────────────────
                const _SectionLabel('INFO'),
                _NavItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About & Contact',
                  route: '/about',
                  current: currentRoute,
                ),
              ],
            ),
          ),

          // Sign out
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              const _SignOutButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.current == widget.route;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: active ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? UserSidebar._activeItemBg
              : _isHovering
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          hoverColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(
            widget.icon,
            size: 20,
            color: active ? UserSidebar._textDark : UserSidebar._textLight,
          ),
          title: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? UserSidebar._textDark : UserSidebar._textLight,
            ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: active ? null : () => context.go(widget.route),
        ),
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

class _SignOutButton extends StatefulWidget {
  const _SignOutButton();

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _isHovering
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          hoverColor: Colors.transparent,
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: true,
              builder: (context) => const LogoutConfirmationDialog(),
            );
            if (confirmed == true) {
              context.read<AuthProvider>().logout();
              context.go('/login');
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Icon(Icons.logout_rounded,
                    color: UserSidebar._textLight, size: 22),
                SizedBox(width: 16),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: UserSidebar._textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

class _CloseButton extends StatefulWidget {
  final VoidCallback? onClose;
  const _CloseButton({this.onClose});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovering
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            hoverColor: Colors.transparent,
            onTap: widget.onClose,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.close_rounded,
                color: UserSidebar._textLight,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
