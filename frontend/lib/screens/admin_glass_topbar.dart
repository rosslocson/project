import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

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
    final String firstName = user?['first_name'] ?? 'User';
    final String lastName = user?['last_name'] ?? '';
    final String fullName =
        lastName.isEmpty ? firstName : '$firstName $lastName';
    final String initials =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    String rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    String finalAvatarUrl = '';
    if (rawAvatarUrl.isNotEmpty) {
      if (!rawAvatarUrl.startsWith('http')) {
        finalAvatarUrl = 'http://127.0.0.1:8080$rawAvatarUrl';
      } else {
        finalAvatarUrl = rawAvatarUrl;
      }
    }

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdmin ? 'Admin Dashboard' : 'Home',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Welcome, $firstName'!,
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
                if (isAdmin) {
                  context.push('/admin/account-settings');
                } else {
                  context.go('/profile');
                }
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
                    backgroundColor: const Color.fromARGB(255, 205, 210, 251)
                        .withOpacity(0.1),
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
                                    Color.fromARGB(255, 116, 116, 212),
                                    Color.fromARGB(255, 16, 19, 74)
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
                                    color:
                                        const Color.fromARGB(255, 122, 116, 212)
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
