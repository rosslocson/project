import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_sidebar.dart';
import 'user_glass_topbar.dart';
import '../widgets/star_background.dart' as sb;
import 'intern_widgets.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with SingleTickerProviderStateMixin {
  bool _isSidebarOpen = true;

  // Background animation
  late AnimationController _bgAnimController;
  late List<sb.Star> stars;

  // Page controllers
  late PageController _pageController;
  late Timer _autoScrollTimer;
  int _currentPage = 0;
  
  static const double _viewportFraction = 0.55;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with the slower 600s duration from admin
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 600),
    )..repeat();

    // Use shared star generator
    stars = sb.generateStars(count: 120);

    // Start page large for infinite scroll
    _currentPage = kInterns.length * 1000;
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: _currentPage,
    );
    
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _prev() {
    _autoScrollTimer.cancel();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _startAutoScroll();
  }

  void _next() {
    _autoScrollTimer.cancel();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _startAutoScroll();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _pageController.dispose();
    _autoScrollTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: Row(
        children: [
          // Standard User Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen ? const UserSidebar(currentRoute: '/home') : const SizedBox(),
          ),

          Expanded(
            child: Stack(
              children: [
                // 1. Admin's Radial Gradient Background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.3, -0.3),
                        radius: 1.4,
                        colors: [Color(0xFF3A0810), Color(0xFF130205), Color(0xFF050505)],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // 2. Animated Galaxy Background
                Positioned.fill(
                  child: sb.GalaxyBackground(
                    animation: _bgAnimController, 
                    stars: stars,
                  ),
                ),
                
                // 3. Admin's Topbar and Content Format
                Positioned.fill(
                  child: Column(
                    children: [
                      GlassTopBar(
                        key: const Key('user_topbar'),
                        isSidebarOpen: _isSidebarOpen,
                        onToggleSidebar: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                        user: user,
                      ),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32), // Standardized padding like admin dashboard
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              Center(
                                child: Column(
                                  children: const [
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

                              // Intern Carousel
                              SizedBox(
                                height: 320,
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (i) => setState(() => _currentPage = i),
                                  itemBuilder: (context, index) {
                                    final intern = kInterns[index % kInterns.length];
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

                              // Arrow controls + dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                                    onPressed: _prev,
                                  ),
                                  const SizedBox(width: 20),
                                  Row(
                                    children: List.generate(kInterns.length, (i) {
                                      final active = i == (_currentPage % kInterns.length);
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 3),
                                        width: active ? 20 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: active ? const Color(0xFFD4748A) : Colors.white24,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 20),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                                    onPressed: _next,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _InternCard extends StatelessWidget {
  final InternProfile intern;
  const _InternCard({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B1524), Color(0xFF4A0E18)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A0E18).withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text(
                intern.initials,
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B1524),
                ),
              ),
            ),
          ),
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
    );
  }
}