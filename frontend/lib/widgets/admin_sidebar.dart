import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'app_theme.dart';
import 'logout_confirmation_dialog.dart';

/// The main sidebar navigation widget for the Admin portal.
/// Displays the branding logo, navigation links tailored to the admin's role,
/// and a secure logout button.
class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onClose;
  
  const AdminSidebar({super.key, required this.currentRoute, this.onClose});

  @override
  Widget build(BuildContext context) {
    // Access authentication state to determine role-based access
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    
    // Fetch custom theme properties
    final theme = context.internTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        // Adjust background transparency based on the active theme
        color: theme.sidebarBackground.withValues(alpha: isDarkMode ? 0.4 : 0.8),
        border: Border(
          right: BorderSide(
            color: theme.border.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          // Applies a frosted glass blur effect to the background
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // HEADER: Logo & App Title
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 16, 32),
                child: Row(
                  children: [
                    // Swaps logo image based on light/dark mode
                    IndexedStack(
                      index: isDarkMode ? 0 : 1,
                      children: [
                        Image.asset(
                          'assets/images/logo_file.png', 
                          height: 44,
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

              // ==========================================
              // MAIN NAVIGATION: Scrollable Links
              // ==========================================
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const _SectionLabel('Menu'),
                    _NavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Dashboard',
                      route: '/dashboard',
                      current: currentRoute,
                    ),
                    _NavItem(
                      icon: Icons.settings_outlined,
                      label: 'Account Settings',
                      route: '/admin/account-settings',
                      current: currentRoute,
                    ),
                    
                    // Conditionally render admin-exclusive routes
                    if (isAdmin) ...[
                      const SizedBox(height: 32),
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
                      _NavItem(
                        icon: Icons.punch_clock_outlined,
                        label: 'Attendance',
                        route: '/admin/attendance',
                        current: currentRoute,
                      ),
                    ],
                  ],
                ),
              ),

              // ==========================================
              // FOOTER: Sign Out Area
              // ==========================================
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    color: theme.border.withValues(alpha: 0.15),
                    height: 1,
                    thickness: 3,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    child: _SignOutButton(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A highly interactive individual navigation item within the sidebar.
/// Includes hover states, active state highlights, and animated positioning.
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
    // Check if this specific navigation item matches the current active route
    final active = widget.current == widget.route;
    final theme = context.internTheme;
    
    return MouseRegion(
      // Change cursor dynamically based on active state
      cursor: active ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Expands clickable area to the entire row
        onTap: active ? null : () => context.go(widget.route),
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Stack(
            children: [
              // Active Background Gradient
              if (active)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.sidebarActiveBackground.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              
              // Active Left Indicator Line
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
                          color: theme.sidebarActiveBackground.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ),

              // Animated Icon & Text Container
              // Slightly nudges to the right when hovered and not active
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
                          : theme.sidebarText.withValues(alpha: _isHovered ? 0.9 : 0.5),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active 
                            ? theme.sidebarActiveForeground 
                            : theme.sidebarText.withValues(alpha: _isHovered ? 0.9 : 0.5),
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

/// Small, muted label used to categorize sections in the sidebar.
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
          color: theme.sidebarMutedText.withValues(alpha: 0.7),
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

/// A dedicated sign-out button featuring hover animations and confirmation logic.
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
        behavior: HitTestBehavior.opaque, // Expands clickable area
        onTap: () async {
          // Await the user's response from the confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (context) => const LogoutConfirmationDialog(),
          );
          
          // GUARD: Ensure the BuildContext is still valid after the async gap
          if (!context.mounted) return;

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
                      color: _isHovered ? Colors.redAccent : theme.sidebarText.withValues(alpha: 0.5), 
                      size: 20
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: _isHovered ? Colors.redAccent : theme.sidebarText.withValues(alpha: 0.5),
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

/// A close button specifically meant for collapsing the sidebar on smaller screens.
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
        behavior: HitTestBehavior.opaque, // Expands clickable area
        onTap: widget.onClose,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: _isHovered ? theme.sidebarText.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.menu_open_rounded,
            color: theme.sidebarText.withValues(alpha: _isHovered ? 1.0 : 0.5),
            size: 22,
          ),
        ),
      ),
    );
  }
}