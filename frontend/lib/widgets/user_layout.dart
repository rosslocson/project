import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/user_sidebar.dart';

class UserLayout extends StatelessWidget {
  final Widget child;
  final String? currentRoute;
  final String title;

  const UserLayout({
    super.key,
    required this.child,
    this.currentRoute,
    this.title = 'Home',
  });

  @override
  Widget build(BuildContext context) {
    final sidebar = context.watch<SidebarProvider>();
    final route = currentRoute ?? GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: sidebar.isUserSidebarOpen ? 250 : 0,
            child: sidebar.isUserSidebarOpen
                ? UserSidebar(
                    currentRoute: route,
                    onClose: () => sidebar.setUserSidebarOpen(false),
                  )
                : const SizedBox(),
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}