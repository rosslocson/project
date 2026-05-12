import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/logout_confirmation_dialog.dart';

// InternSpace Palette
const _kCosmicBlue = Color(0xFF00022E);
const _kAccentIndigo = Color(0xFF7367F0);

// Revised Highly Pigmented Colors for Light Mode
const _kLightBlueHighlyPigmented = Color(0xFF99C7FF); // Richer, more saturated blue
const _kLightBlueGlassMid = Color(0xFFC0DAFF);      // Vibrant mid-transition
const _kLightGlassBorder = Color(0xFFB8C9F1);       // Slightly deeper border to match pigment
const _kLightAvatarEnd = Color(0xFFA78BFA);

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
  final bool isAdmin;

  const GlassTopBar({
    super.key,
    this.isSidebarOpen,
    this.onToggleSidebar,
    this.user,
    this.isAdmin = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String firstName = user?['first_name'] ?? 'User';
    final String lastName = user?['last_name'] ?? '';
    final String fullName = lastName.isEmpty ? firstName : '$firstName $lastName';
    final String initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    String rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    String finalAvatarUrl = '';
    if (rawAvatarUrl.isNotEmpty) {
      finalAvatarUrl = rawAvatarUrl.startsWith('http') 
          ? rawAvatarUrl 
          : 'http://127.0.0.1:8080$rawAvatarUrl';
    }

    final bool sidebarClosed = isSidebarOpen == false;

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
                  _kLightBlueHighlyPigmented,            // Deep Pigment Top
                  _kLightBlueGlassMid.withOpacity(0.9),  // Strong transition
                  Colors.white.withOpacity(0.5),         // Rapid fade
                  Colors.white,                          // Pure White Bottom Line
                ],
                stops: const [0.0, 0.55, 0.94, 1.0],     // Pushed color further down
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (sidebarClosed) ...[
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.sidebarHoverBackground.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? theme.border : _kLightGlassBorder,
                ),
                boxShadow: isDark 
                  ? null 
                  : [
                      BoxShadow(
                        color: _kCosmicBlue.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
              ),
              child: IconButton(
                padding: const EdgeInsets.all(12),
                onPressed: onToggleSidebar,
                icon: const HamburgerIcon(),
                tooltip: 'Open Sidebar',
                splashColor: theme.sidebarHoverBackground,
                highlightColor: Colors.transparent,
              ),
            ),
            const SizedBox(width: 24),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAdmin ? 'Admin Dashboard' : 'Home',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: theme.topbarText,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Welcome, $firstName',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.topbarMutedText,
                ),
              ),
            ],
          ),
          const Spacer(),
          PopupMenuButton<String>(
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
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.topbarText.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? theme.border : _kLightGlassBorder,
                        width: 1,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 19,
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
                child: Text(darkMode ? 'Dark Mode' : 'Light Mode', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
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