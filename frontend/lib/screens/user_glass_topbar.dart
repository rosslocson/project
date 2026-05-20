import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../providers/sidebar_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

// InternSpace Shared Palette (Matched with Admin)
//const _kCosmicBlue = Color(0xFF00022E);
const _kAccentIndigo = Color(0xFF7367F0);
const _kLightAvatarEnd = Color(0xFFA78BFA);

// Pure white for lightmode as requested
const _kLightTopbarBg = Color(0xFFFFFFFF);

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

  final String? pageTitle;
  final bool showWelcome;

  const GlassTopBar({
    super.key,
    this.isSidebarOpen,
    this.onToggleSidebar,
    this.user,
    this.pageTitle,
    this.showWelcome = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // User specific logic
    final sidebar = context.watch<SidebarProvider>();
    final bool sidebarClosed = !sidebar.isUserSidebarOpen;

    final auth = context.watch<AuthProvider>();
    final bool isInitialized = auth.isAuthInitialized;
    final userMap = auth.user;

    final String firstName = (userMap?['first_name']?.toString() ?? '').trim();
    final String lastName = (userMap?['last_name']?.toString() ?? '').trim();

    final String fullName = lastName.isEmpty ? (firstName.isEmpty ? 'User' : firstName) : '$firstName $lastName';
    final String initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    final String rawAvatarUrl = (userMap?['avatar_url']?.toString() ?? '');
    final String finalAvatarUrl = rawAvatarUrl.isEmpty
        ? ''
        : rawAvatarUrl.startsWith('http')
            ? rawAvatarUrl
            : '${ApiService.baseUrl.replaceAll('/api', '')}$rawAvatarUrl';

    Widget buildSkeleton(double width, double height, {bool isCircle = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(4),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: isDark ? Colors.transparent : _kLightTopbarBg,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (sidebarClosed) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => sidebar.setUserSidebarOpen(true),
                  icon: const HamburgerIcon(),
                  tooltip: 'Open Sidebar',
                  splashColor: theme.sidebarHoverBackground,
                  highlightColor: Colors.transparent,
                ),
                const SizedBox(width: 20),
              ],
              
              // FIX: Wrapping the text column in Expanded ensures it doesn't push the right side off screen.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pageTitle ?? 'Home',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: theme.topbarText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (showWelcome)
                      if (!isInitialized)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: buildSkeleton(120, 14),
                        )
                      else
                        Text(
                          'Welcome, ${firstName.isEmpty ? '...' : firstName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.topbarMutedText,
                          ),
                        ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),

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
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 12),
                        Text('View Profile', style: TextStyle(fontWeight: FontWeight.w500)),
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
                        Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isInitialized)
                        buildSkeleton(80, 16)
                      else
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.topbarText.withValues(alpha: 0.9),
                          ),
                        ),
                      const SizedBox(width: 14),
                      if (!isInitialized)
                        buildSkeleton(40, 40, isCircle: true)
                      else
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark
                              ? const Color(0xFFCDD2FB).withValues(alpha: 0.1)
                              : _kAccentIndigo.withValues(alpha: 0.1),
                          backgroundImage: finalAvatarUrl.isNotEmpty ? NetworkImage(finalAvatarUrl) : null,
                          child: finalAvatarUrl.isEmpty
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? const [Color(0xFF7474D4), Color(0xFF10134A)]
                                          : const [_kAccentIndigo, _kLightAvatarEnd],
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
            ],
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent]
                  : [Colors.transparent, _kAccentIndigo.withValues(alpha: 0.15), Colors.transparent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }
}

// ... _ThemeToggleMenuItem remains unchanged
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
                darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(darkMode ? 'Dark Mode' : 'Light Mode',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: darkMode,
                  activeThumbColor: _kAccentIndigo,
                  onChanged: (_) => _toggleTheme(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}