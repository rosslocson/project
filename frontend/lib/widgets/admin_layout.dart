import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/admin_sidebar.dart';

// HamburgerIcon widget
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

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String? currentRoute;
  final String title;

  const AdminLayout({
    super.key,
    required this.child,
    this.currentRoute,
    this.title = 'Admin Dashboard',
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sidebar = context.watch<SidebarProvider>();
    final route = currentRoute ?? GoRouterState.of(context).matchedLocation ?? '/dashboard';
    final user = auth.user;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: sidebar.isAdminSidebarOpen ? 250 : 0,
                child: sidebar.isAdminSidebarOpen
                    ? AdminSidebar(
                        currentRoute: route,
                        onClose: () => sidebar.setAdminSidebarOpen(false),
                      )
                    : const SizedBox(),
              ),
              Expanded(
                child: child,
              ),
            ],
          ),
          // Hamburger menu button when sidebar is closed
          if (!sidebar.isAdminSidebarOpen)
            Positioned(
              top: 24,
              left: 24,
              child: Container(
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
                  onPressed: () => sidebar.setAdminSidebarOpen(true),
                  icon: const HamburgerIcon(),
                  tooltip: 'Open Sidebar',
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
