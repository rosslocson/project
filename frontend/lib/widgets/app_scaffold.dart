import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget child;
  final Color? appBarColor;
  final bool showBackButton;
  final bool showAppBar;
  final Widget? sidebar; // pass your sidebar widget here

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.appBarColor,
    this.showBackButton = false,
    this.showAppBar = true,
    this.sidebar,
  });

  static const double _mobileBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        return Scaffold(
          // On mobile: sidebar becomes a drawer
          drawer:
              (isMobile && sidebar != null) ? Drawer(child: sidebar!) : null,

          appBar: showAppBar
              ? AppBar(
                  title: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  leading: isMobile
                      ? Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu,
                                color: Color(0xFF7B0D1E)),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                            tooltip: 'Toggle Menu',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        )
                      : showBackButton
                          ? const BackButton()
                          : null,
                  backgroundColor:
                      appBarColor ?? Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  actions: actions,
                  automaticallyImplyLeading: showBackButton,
                )
              : null,

          body: Row(
            children: [
              // On desktop: sidebar stays visible on the left
              if (!isMobile && sidebar != null)
                SizedBox(
                  width: 240,
                  child: sidebar!,
                ),
              // Main content fills remaining space
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
