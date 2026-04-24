import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/user_layout.dart';
import 'user_glass_topbar.dart';
import 'intern_widgets.dart';

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

  // Carousel
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  static const double _viewportFraction = 0.55;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: _currentPage,
    );
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
        // Reset page to a large offset for infinite scroll
        _currentPage = loaded.isNotEmpty ? loaded.length * 1000 : 0;
      });

      if (_interns.isNotEmpty) {
        // Rebuild controller with correct initial page now that we know count
        _pageController.dispose();
        _pageController = PageController(
          viewportFraction: _viewportFraction,
          initialPage: _currentPage,
        );
        _startAutoScroll();
      }
    } else {
      setState(() {
        _internsError = res['error'] ?? 'Failed to load interns';
        _loadingInterns = false;
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_interns.isEmpty) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _prev() {
    _autoScrollTimer?.cancel();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _startAutoScroll();
  }

  void _next() {
    _autoScrollTimer?.cancel();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return UserLayout(
      currentRoute: '/home',
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/space_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              GlassTopBar(
                key: const Key('user_topbar'),
                isSidebarOpen: _isSidebarOpen,
                onToggleSidebar: () =>
                    setState(() => _isSidebarOpen = !_isSidebarOpen),
                user: user,
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 48, right: 48, bottom: 24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'Meet Our Interns',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tap a card to view full profile',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildCarouselSection(),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselSection() {
    // Loading state
    if (_loadingInterns) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

    // Error state
    if (_internsError != null) {
      return SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              Text(
                _internsError!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _fetchInterns,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_interns.isEmpty) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: Text(
            'No interns found.',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    // Carousel
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final intern = _interns[index % _interns.length];
              final isCenter = index == _currentPage;

              return AnimatedScale(
                scale: isCenter ? 1.0 : 0.82,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: isCenter ? 1.0 : 0.45,
                  duration: const Duration(milliseconds: 350),
                  child: GestureDetector(
                    onTap: () => _openDetail(intern),
                    child: _InternCard(intern: intern),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 32),
              onPressed: _prev,
            ),
            const SizedBox(width: 20),
            Row(
              children: List.generate(_interns.length, (i) {
                final active = i == (_currentPage % _interns.length);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF4A5E9A)
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 32),
              onPressed: _next,
            ),
          ],
        ),
      ],
    );
  }

  void _openDetail(InternProfile intern) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InternDetailPage(intern: intern),
      ),
    );
  }
}

// ── Intern Card ───────────────────────────────────────────────────────────────

class _InternCard extends StatelessWidget {
  final InternProfile intern;
  const _InternCard({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Hero(
        tag: 'intern-${intern.internNumber}',
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.4),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shows real avatar photo if avatarUrl is set, else initials
              InternAvatar(intern: intern),
              const SizedBox(height: 24),
              Text(
                intern.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Intern #${intern.internNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}