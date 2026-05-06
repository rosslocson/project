import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../providers/sidebar_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

const _lightTopbarStart = Color(0xFFF1F6FF);
const _lightTopbarEnd = Color(0xFFDCE8FF);
const _lightTopbarPanel = Color(0xFFF5F9FF);
const _lightTopbarBorder = Color(0xFFD0DCF7);
const _lightAvatarStart = Color(0xFF6366F1);
const _lightAvatarEnd = Color(0xFFA78BFA);

class HamburgerIcon extends StatelessWidget {
  const HamburgerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final color = theme.topbarText;

    return SizedBox(
      width: 22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 14,
            height: 2.5,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 22,
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

  const GlassTopBar({
    super.key,
    this.isSidebarOpen,
    this.onToggleSidebar,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebar = context.watch<SidebarProvider>();
    final bool sidebarClosed = !sidebar.isUserSidebarOpen;

    final String firstName = user?['first_name'] ?? 'User';
    final String lastName = user?['last_name'] ?? '';
    final String fullName =
        lastName.isEmpty ? firstName : '$firstName $lastName';
    final String initials =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    String rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    final String finalAvatarUrl = rawAvatarUrl.isEmpty
        ? ''
        : rawAvatarUrl.startsWith('http')
            ? rawAvatarUrl
            : '${ApiService.baseUrl.replaceAll('/api', '')}$rawAvatarUrl';

    return Container(
      padding: const EdgeInsets.only(
        left: 32,
        right: 32,
        top: 24,
        bottom: 32,
      ),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.topbarScrim.withValues(alpha: 0.95),
                  theme.topbarScrim.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _lightTopbarStart.withValues(alpha: 0.98),
                  _lightTopbarEnd.withValues(alpha: 0.8),
                  _lightAvatarStart.withValues(alpha: 0.18),
                  _lightTopbarEnd.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.32, 0.62, 1.0],
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Hamburger — only when sidebar is closed ───────────────────
          if (sidebarClosed) ...[
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.sidebarHoverBackground.withValues(alpha: 0.8)
                    : _lightTopbarPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? theme.border : _lightTopbarBorder,
                ),
              ),
              child: IconButton(
                padding: const EdgeInsets.all(12),
                onPressed: () => sidebar.setUserSidebarOpen(true),
                icon: const HamburgerIcon(),
                tooltip: 'Open Sidebar',
                splashColor: theme.sidebarHoverBackground,
                highlightColor: Colors.transparent,
              ),
            ),
            const SizedBox(width: 24),
          ],
          // ── Title ─────────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Home',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.topbarText,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Welcome, $firstName',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.topbarMutedText,
                ),
              ),
            ],
          ),
          const Spacer(),
          // ── User menu ─────────────────────────────────────────────────
          PopupMenuButton<String>(
            onSelected: (String choice) async {
              if (choice == 'profile') {
                context.go('/profile');
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
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 12),
                    Text('View Profile'),
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
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Log Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.topbarText.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: (isDark
                            ? const Color(0xFF6366F1)
                            : _lightAvatarStart)
                        .withValues(alpha: isDark ? 0.18 : 0.14),
                    backgroundImage: finalAvatarUrl.isNotEmpty
                        ? NetworkImage(finalAvatarUrl)
                        : null,
                    child: finalAvatarUrl.isEmpty
                        ? Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? const [
                                        Color(0xFF6366F1),
                                        Color(0xFF4A1040),
                                      ]
                                    : const [
                                        _lightAvatarStart,
                                        _lightAvatarEnd,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: theme.topbarText.withValues(alpha: 0.35),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                          ? const Color(0xFF6366F1)
                                          : _lightAvatarStart)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 18,
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
        ],
      ),
    );
  }
}

class _ThemeToggleMenuItem extends StatelessWidget {
  const _ThemeToggleMenuItem();

  Future<void> _toggleTheme(BuildContext context) async {
    await context.read<ThemeProvider>().toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final darkMode = themeProvider.isDarkMode;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _toggleTheme(context),
          child: Row(
            children: [
              Icon(
                darkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(darkMode ? 'Dark Mode' : 'Light Mode'),
              ),
              Switch(
                value: darkMode,
                activeColor: const Color(0xFF6B4EFF),
                onChanged: (_) => _toggleTheme(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

