import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_sidebar.dart';

class UserLayout extends StatefulWidget {
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
  State<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends State<UserLayout> with SingleTickerProviderStateMixin {
  final bool _isSidebarOpen = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final route = widget.currentRoute ?? GoRouterState.of(context).matchedLocation ?? '/home';
    final user = auth.user;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen
              ? UserSidebar(currentRoute: route)
              : const SizedBox(),
          ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
