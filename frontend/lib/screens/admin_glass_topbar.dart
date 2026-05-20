import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/app_theme.dart';

// InternSpace Palette
const _kAccentIndigo = Color(0xFF7367F0);
const _kLightAvatarEnd = Color(0xFFA78BFA);

class HamburgerIcon extends StatelessWidget {
  const HamburgerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final color = theme.topbarText;

    return SizedBox(
      width: 24,
      height: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 24,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 15,
            height: 2.5,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 24,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassTopBar extends StatelessWidget {
  final bool? isSidebarOpen;
  final VoidCallback? onToggleSidebar;
  final Map<String, dynamic>? user;
  final bool isAdmin;
  final String? title;
  final bool showWelcome;

  const GlassTopBar({
    super.key,
    this.isSidebarOpen,
    this.onToggleSidebar,
    this.user,
    this.isAdmin = true,
    this.title,
    this.showWelcome = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String firstName = user?['first_name'] ?? 'User';
    final String lastName = user?['last_name'] ?? '';
    final String fullName =
        lastName.isEmpty ? firstName : '$firstName $lastName';
    final String initials =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    String rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    String finalAvatarUrl = '';
    if (rawAvatarUrl.isNotEmpty) {
      finalAvatarUrl = rawAvatarUrl.startsWith('http')
          ? rawAvatarUrl
          : 'http://127.0.0.1:8080$rawAvatarUrl';
    }

    final bool sidebarClosed = isSidebarOpen == false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 14,
          ),
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Sidebar Toggle Button
              if (sidebarClosed) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onToggleSidebar,
                  icon: const HamburgerIcon(),
                  tooltip: 'Open Sidebar',
                  splashColor: theme.sidebarHoverBackground,
                  highlightColor: Colors.transparent,
                ),
                const SizedBox(width: 28),
              ],

              // 2. Title Section (Takes up exactly half of the bar maximum space)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title ?? (isAdmin ? 'Admin Dashboard' : 'Home'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF00022E),
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    if (user != null && showWelcome)
                      Text(
                        'Welcome, $firstName',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : const Color(0xFF00022E).withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16), // Protective layout buffer gap

              // 3. User Profile Actions (Expanded container pins alignment securely to the far right)
              if (user != null)
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight, // Locks layout to the outer right screen edge
                    child: PopupMenuButton<String>(
                      onSelected: (String choice) async {
                        if (choice == 'profile') {
                          if (isAdmin) {
                            context.push('/admin/account-settings');
                          } else {
                            context.go('/profile');
                          }
                        } else if (choice == 'logout') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => const LogoutConfirmationDialog(),
                          );
                          if (confirmed == true) {
                            context.read<AuthProvider>().logout();
                            context.go('/login');
                          }
                        }
                      },
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 20),
                              SizedBox(width: 12),
                              Text('View Profile',
                                  style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          enabled: false,
                          child: _ThemeToggleMenuItem(),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20, color: Colors.redAccent),
                              SizedBox(width: 12),
                              Text('Log Out',
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // shrink-wraps contents naturally on desktop
                          children: [
                            Flexible(
                              child: Text(
                                fullName,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : const Color(0xFF00022E),
                                ),
                                overflow: TextOverflow.ellipsis, // Safely truncates only if the screen gets super tight
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 14),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark
                                  ? const Color(0xFFCDD2FB).withValues(alpha: 0.1)
                                  : _kAccentIndigo.withValues(alpha: 0.1),
                              backgroundImage: finalAvatarUrl.isNotEmpty
                                  ? NetworkImage(finalAvatarUrl)
                                  : null,
                              child: finalAvatarUrl.isEmpty
                                  ? Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? const [
                                                  Color(0xFF7474D4),
                                                  Color(0xFF10134A)
                                                ]
                                              : const [
                                                  _kAccentIndigo,
                                                  _kLightAvatarEnd
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent
                    ]
                  : [
                      Colors.transparent,
                      _kAccentIndigo.withValues(alpha: 0.15),
                      Colors.transparent
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeToggleMenuItem extends StatelessWidget {
  const _ThemeToggleMenuItem();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final darkMode = themeProvider.isDarkMode;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => themeProvider.toggleTheme(),
          child: Row(
            children: [
              Icon(
                darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  darkMode ? 'Dark Mode' : 'Light Mode',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: darkMode,
                  activeThumbColor: _kAccentIndigo,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}