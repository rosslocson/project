import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'app_theme.dart';
import 'logout_confirmation_dialog.dart';

class UserSidebar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onClose;

  const UserSidebar({super.key, required this.currentRoute, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    
    // Determine if the current theme is dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 270, // Matched with AdminSidebar for consistency
      decoration: BoxDecoration(
        color: theme.sidebarBackground.withOpacity(isDarkMode ? 0.4 : 0.8), // Glassmorphism base
        border: Border(
          right: BorderSide(
            color: theme.border.withOpacity(0.15), // Very subtle separator
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Blurs the starry background
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Close Button Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 16, 32),
                child: Row(
                  children: [
                    IndexedStack(
                      index: isDarkMode ? 0 : 1,
                      children: [
                        Image.asset(
                          'assets/images/logo_file.png', 
                          height: 44, // Increased logo size
                          width: 44,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.public, color: theme.sidebarText, size: 34),
                        ),
                        Image.asset(
                          'assets/images/logo_file_lightmode.png',
                          height: 44,
                          width: 44,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.public, color: theme.sidebarText, size: 34),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'InternSpace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.sidebarText,
                          fontSize: 18,
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
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const _SectionLabel('Menu'),
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
                    
                    const SizedBox(height: 16),
                    const _SectionLabel('OJT'),
                    _NavItem(
                      icon: Icons.access_time_rounded,
                      label: 'Attendance',
                      route: '/attendance',
                      current: currentRoute,
                    ),

                    const SizedBox(height: 16),
                    const _SectionLabel('Info'),
                    _NavItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About & Contact',
                      route: '/about',
                      current: currentRoute,
                    ),
                  ],
                ),
              ),

              // Footer / Sign Out
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _SignOutButton(),
              ),
            ],
          ),
        ),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.current == widget.route;
    final theme = context.internTheme;
    
    return MouseRegion(
      cursor: active ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: active ? null : () => context.go(widget.route),
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Stack(
            children: [
              // Active Background Gradient Fade
              if (active)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.sidebarActiveBackground.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              
              // Glowing Edge Indicator
              if (active)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: theme.sidebarActiveBackground,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.sidebarActiveBackground.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ),

              // Content with Hover Shift
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: (_isHovered && !active) ? 32.0 : 28.0, 
                top: 0,
                bottom: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 20,
                      color: active 
                          ? theme.sidebarActiveForeground 
                          : theme.sidebarText.withOpacity(_isHovered ? 0.9 : 0.5),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active 
                            ? theme.sidebarActiveForeground 
                            : theme.sidebarText.withOpacity(_isHovered ? 0.9 : 0.5),
                        letterSpacing: 0.6, 
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 16, bottom: 16),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.sidebarMutedText.withOpacity(0.7),
          letterSpacing: 2.0, 
        ),
      ),
    );
  }
}

class _SignOutButton extends StatefulWidget {
  const _SignOutButton();

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
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
        child: Container(
          height: 48,
          color: Colors.transparent,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: _isHovered ? 32.0 : 28.0,
                top: 0,
                bottom: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded, 
                      color: _isHovered ? Colors.redAccent : theme.sidebarText.withOpacity(0.5), 
                      size: 20
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: _isHovered ? Colors.redAccent : theme.sidebarText.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6, 
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onClose,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: _isHovered ? theme.sidebarText.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.menu_open_rounded, 
            color: theme.sidebarText.withOpacity(_isHovered ? 1.0 : 0.5),
            size: 22,
          ),
        ),
      ),
    );
  }
}