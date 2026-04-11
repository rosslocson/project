import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/admin_sidebar.dart';

class AdminLayout extends StatefulWidget {
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
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> with SingleTickerProviderStateMixin {
  bool _isSidebarOpen = true;
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
    final route = widget.currentRoute ?? GoRouterState.of(context).matchedLocation ?? '/dashboard';
    final user = auth.user;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen
                ? AdminSidebar(
                    currentRoute: route,
                    onClose: () => setState(() => _isSidebarOpen = false),
                  )
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
