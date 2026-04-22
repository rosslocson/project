import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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

  // Page controllers
  late PageController _pageController;
  late Timer _autoScrollTimer;
  int _currentPage = 0;
  
  static const double _viewportFraction = 0.55;

  @override
  void initState() {
    super.initState();
    
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
    _pageController.dispose();
    _autoScrollTimer.cancel();
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
          // Fixed space background matching user_account_settings_screen.dart
          Positioned.fill(
            child: Image.asset(
              'assets/images/space_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content overlay
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
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
                                      color: active ? const Color(0xFF4A5E9A) : Colors.white24,
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
          colors: [Color(0xFF1A2540), Color(0xFF4A5E9A)], // Blue matching admin
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