import 'package:flutter/material.dart';
// import '../providers/sidebar_provider.dart'; // Removed

class AppScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget child;
  final Color? appBarColor;
  final bool showBackButton;
  final bool showAppBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.appBarColor,
    this.showBackButton = false,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    // final sidebarProvider = context.watch<SidebarProvider>(); // Removed
    
    return Scaffold(
      // drawer: Sidebar(currentRoute: currentRoute), // removed hamburger opens drawer
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              leading: showAppBar
                  ? IconButton(
                      icon: const Icon(Icons.menu, color: Color(0xFF7B0D1E)),
                      onPressed: () {}, // Sidebar removed
                      tooltip: 'Toggle Menu',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : null,
              backgroundColor: appBarColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black26,
              actions: actions,
              automaticallyImplyLeading: showBackButton,
            )
          : null,
      body: Row(
        children: [
          // Consistent animated sidebar overlay
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 0.0, // Sidebar removed
            child: const SizedBox(),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

