import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';
import '../services/api_service.dart';

class HamburgerIcon extends StatelessWidget {
  const HamburgerIcon({super.key});

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 14,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
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
    final sidebar = context.watch<SidebarProvider>();
    final sidebarOpen = isSidebarOpen ?? sidebar.isUserSidebarOpen;
    final toggleSidebar = onToggleSidebar ?? () => sidebar.toggleUserSidebar();

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
      padding: const EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF050505).withOpacity(0.95),
            const Color(0xFF050505).withOpacity(0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Row(
        children: [
          if (!sidebarOpen) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: IconButton(
                padding: const EdgeInsets.all(12),
                onPressed: toggleSidebar,
                icon: const HamburgerIcon(),
                tooltip: 'Open Sidebar',
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.transparent,
              ),
            ),
            const SizedBox(width: 24),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Home',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Welcome, $firstName',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'profile') {
                context.go('/profile');
              } else if (choice == 'logout') {
                context.read<AuthProvider>().logout();
                context.go('/login');
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
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Sign out', style: TextStyle(color: Colors.red)),
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
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFD4748A).withOpacity(0.1),
                    backgroundImage: finalAvatarUrl.isNotEmpty
                        ? NetworkImage(finalAvatarUrl)
                        : null,
                    child: finalAvatarUrl.isEmpty
                        ? Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD4748A),
                                    Color(0xFF4A1040)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4748A)
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]),
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
