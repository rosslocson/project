import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/user_layout.dart';
import 'user_glass_topbar.dart';
import 'intern_widgets.dart';
import 'intern_directory_screen.dart';
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
    debugPrint('🔍 INTERNS KEYS: ${res.keys.toList()}');
    debugPrint('🔍 INTERNS FULL: $res');

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
    final user = auth.user;

    return UserLayout(
      currentRoute: '/home',
      child: AppBackground(
        child: Column(
          children: [
            GlassTopBar(
              key: const Key('user_topbar'),
              isSidebarOpen: _isSidebarOpen,
              onToggleSidebar: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
              user: user,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 48, right: 48, bottom: 24),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Meet Our Interns',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to the new directory page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const InternDirectoryScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF8A84FF), // Matches your accent purple/blue
                              ),
                              child: const Row(
                                children: [
                                  Text('View All'),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Extracted Carousel Component
                      UserInternCarousel(
                        interns: _interns,
                        loading: _loadingInterns,
                        error: _internsError,
                        onRetry: _fetchInterns,
                      ),
                      
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}