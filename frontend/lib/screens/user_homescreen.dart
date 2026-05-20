import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/user_layout.dart';
import 'user_glass_topbar.dart';
import 'intern_cards.dart';
import '../widgets/app_background.dart';

// ── Imported Extracted Widgets ──
import '../widgets/user_homescreen_widgets/user_intern_carousel.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _isSidebarOpen = true;

  // Intern data
  List<InternProfile> _interns = [];
  bool _loadingInterns = true;
  String? _internsError;

  @override
  void initState() {
    super.initState();
    _fetchInterns();
  }

  Future<void> _fetchInterns() async {
    setState(() {
      _loadingInterns = true;
      _internsError = null;
    });

    final res = await ApiService.getInterns();

    if (!mounted) return;

    if (res['ok'] == true) {
      final raw = res['users'] ?? res['interns'] ?? res['data'] ?? [];
      final List<InternProfile> loaded = (raw as List)
          .map((j) => InternProfile.fromJson(j as Map<String, dynamic>))
          .toList();

      setState(() {
        _interns = loaded;
        _loadingInterns = false;
      });
    } else {
      setState(() {
        _internsError = res['error'] ?? 'Failed to load interns';
        _loadingInterns = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ── FIXED REDIRECT LOGIC ──
    if (auth.isAuthInitialized && !auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final user = auth.user;

    return UserLayout(
      currentRoute: '/home',
      child: AppBackground(
        child: Column(
          children: [
            GlassTopBar(
              key: const Key('user_topbar'),
              isSidebarOpen: _isSidebarOpen,
              onToggleSidebar: () =>
                  setState(() => _isSidebarOpen = !_isSidebarOpen),
              user: user,
            ),
            Expanded(
              // LayoutBuilder handles responsiveness for different screen sizes
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Dynamically calculate padding based on screen width
                  // This prevents the "View All" or carousel from hitting the screen edge
                  final double horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 16.0;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 32, bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Extracted Carousel Component
                          // Constraining this width within the column ensures 
                          // the "View All" inside it respects the available space.
                          SizedBox(
                            width: constraints.maxWidth,
                            child: UserInternCarousel(
                              interns: _interns,
                              loading: _loadingInterns,
                              error: _internsError,
                              onRetry: _fetchInterns,
                            ),
                          ),

                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}