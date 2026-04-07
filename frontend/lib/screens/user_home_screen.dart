import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'; // Added for ImageFilter (Glassmorphism effect)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/sidebar.dart';

// ── Custom Hamburger Icon (Redesigned) ──────────────────────────────────────
class HamburgerIcon extends StatelessWidget {
  const HamburgerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 14,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class InternProfile {
  final String name;
  final int internNumber;
  final String program;
  final String school;
  final String specialization;
  final String email;
  final List<String> technicalSkills;
  final List<String> softSkills;
  final Color avatarColor;
  final String initials;

  const InternProfile({
    required this.name,
    required this.internNumber,
    required this.program,
    required this.school,
    required this.specialization,
    required this.email,
    required this.technicalSkills,
    required this.softSkills,
    required this.avatarColor,
    required this.initials,
  });
}

// ── Sample data ───────────────────────────────────────────────────────────────
const List<InternProfile> kInterns = [
  InternProfile(
    name: 'Jamie Reyes',
    internNumber: 1,
    program: 'Bachelor of Science in Computer Science',
    school: 'University of Santo Tomas',
    specialization: 'Web Development',
    email: 'jamie.reyes@email.com',
    technicalSkills: ['Flutter', 'Dart', 'Firebase', 'Git'],
    softSkills: ['Teamwork', 'Communication', 'Adaptable'],
    avatarColor: Color(0xFF7B1A2E),
    initials: 'JR',
  ),
  InternProfile(
    name: 'Lorraine De Castro',
    internNumber: 2,
    program: 'Bachelor of Science in Information Technology',
    school: 'De La Salle University',
    specialization: 'UI/UX Design',
    email: 'lorraine@gmail.com',
    technicalSkills: ['Figma', 'HTML/CSS', 'React', 'Prototyping'],
    softSkills: ['Creativity', 'Detail-oriented', 'Time management'],
    avatarColor: Color(0xFF4A1040),
    initials: 'LD',
  ),
  InternProfile(
    name: 'Airra De Castro',
    internNumber: 3,
    program: 'Bachelor of Science in Software Engineering',
    school: 'Ateneo de Manila University',
    specialization: 'Backend Systems',
    email: 'airra@gmail.com',
    technicalSkills: ['Python', 'Django', 'PostgreSQL', 'Docker'],
    softSkills: ['Problem-solving', 'Leadership', 'Critical thinking'],
    avatarColor: Color(0xFF1A1050),
    initials: 'AD',
  ),
  InternProfile(
    name: 'Alex Santos',
    internNumber: 12,
    program: 'Bachelor of Science in Information System',
    school: 'CARD',
    specialization: 'N/A',
    email: 'alex@gmail.com',
    technicalSkills: ['HTML', 'Python', 'C++'],
    softSkills: ['Attention to detail', 'Adaptability', 'Problem-solving', 'Teamwork'],
    avatarColor: Color(0xFF2A3A1A),
    initials: 'AS',
  ),
  InternProfile(
    name: 'Joy Mendoza',
    internNumber: 8,
    program: 'Bachelor of Science in Computer Engineering',
    school: 'Mapúa University',
    specialization: 'Embedded Systems',
    email: 'joy.mendoza@email.com',
    technicalSkills: ['C', 'Arduino', 'MATLAB', 'PCB Design'],
    softSkills: ['Analytical thinking', 'Persistence', 'Collaboration'],
    avatarColor: Color(0xFF3A2A10),
    initials: 'JM',
  ),
  InternProfile(
    name: 'Raven Cruz',
    internNumber: 5,
    program: 'Bachelor of Science in Data Science',
    school: 'University of the Philippines',
    specialization: 'Machine Learning',
    email: 'raven.cruz@email.com',
    technicalSkills: ['Python', 'TensorFlow', 'SQL', 'Tableau'],
    softSkills: ['Curiosity', 'Research', 'Presentation'],
    avatarColor: Color(0xFF0A3A3A),
    initials: 'RC',
  ),
];

// ── Star model ────────────────────────────────────────────────────────────────
class Star {
  final double x, y, size, opacity, speed, phase;
  const Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.phase,
  });
}

// ── Starfield painter ─────────────────────────────────────────────────────────
class StarfieldPainter extends CustomPainter {
  final double animValue;
  final List<Star> stars;
  StarfieldPainter({required this.animValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final twinkle =
          (math.sin((animValue * 2 * math.pi * 1.5) + star.phase) + 1) / 2;
      final alpha = (star.opacity * (0.3 + 0.7 * twinkle)).clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(alpha);
      final dx = (star.x * size.width +
              animValue * size.width * star.speed) %
          size.width;
      final dy = star.y * size.height;
      if (star.size > 1.5) {
        canvas.drawCircle(
          Offset(dx, dy),
          star.size * 2,
          Paint()
            ..color = Colors.white.withOpacity(alpha * 0.25)
            ..maskFilter =
                const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      canvas.drawCircle(Offset(dx, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter old) =>
      old.animValue != animValue;
}

// ── Dashboard Screen ──────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // Background animation
  late AnimationController _bgAnimController;
  final List<Star> _stars = [];

  // Carousel controllers
  late PageController _pageController;
  late Timer _autoScrollTimer;
  
  // Start the page at a very large multiple of the total intern count
  // so the user can immediately swipe backward if they want to.
  int _currentPage = kInterns.length * 1000;
  static const double _viewportFraction = 0.55;

  @override
  void initState() {
    super.initState();
    
    // Initialize Galaxy Background
    _generateStars();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120), 
    )..repeat();

    // Initialize Carousel
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: _currentPage,
    );
    _startAutoScroll();
  }

  void _generateStars() {
    final rng = math.Random();
    for (int i = 0; i < 160; i++) {
      _stars.add(Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 1.8 + 0.4,
        opacity: rng.nextDouble() * 0.6 + 0.2,
        speed: rng.nextDouble() * 0.03 + 0.005,
        phase: rng.nextDouble() * 2 * math.pi,
      ));
    }
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

  void _openDetail(InternProfile intern) {
    _autoScrollTimer.cancel();
    Navigator.of(context)
        .push(PageRouteBuilder(
          pageBuilder: (_, anim, __) => InternDetailPage(intern: intern),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ))
        .then((_) {
          if (mounted) _startAutoScroll();
        });
  }

  Widget _buildAnimatedGalaxyBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 1.4,
          colors: [Color(0xFF3A0810), Color(0xFF130205), Color(0xFF050505)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (_, __) => CustomPaint(
          painter: StarfieldPainter(
              animValue: _bgAnimController.value, stars: _stars),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sidebarProvider = context.watch<SidebarProvider>();
    final user = auth.user;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: sidebarProvider.isOpen ? 250 : 0,
            child: sidebarProvider.isOpen ? const Sidebar(currentRoute: '/home') : null,
          ),
          Expanded(
            child: Stack(
              children: [
                // Galaxy Background
                Positioned.fill(child: _buildAnimatedGalaxyBackground()),
                
                // Dashboard Content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ───────────────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (!sidebarProvider.isOpen) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(12),
                                  onPressed: () => context.read<SidebarProvider>().toggle(),
                                  icon: const HamburgerIcon(),
                                  tooltip: 'Open Sidebar',
                                  splashColor: Colors.white.withValues(alpha: 0.1),
                                  highlightColor: Colors.transparent,
                                ),
                              ),
                              const SizedBox(width: 24),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${user?['first_name'] ?? 'User'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),

                        // ── Intern Carousel Titles ───────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Meet Our Interns',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.92),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap a card to view full profile',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Intern Carousel ──────────────────────────────────
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            // Notice: itemCount is removed to allow infinite scrolling
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemBuilder: (context, index) {
                              // Use modulo to cycle through the actual list length
                              final realIndex = index % kInterns.length;
                              final intern = kInterns[realIndex];
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
                                    child: _InternCardFront(intern: intern),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Arrow controls + dots ────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ArrowButton(icon: Icons.chevron_left, onTap: _prev),
                            const SizedBox(width: 20),
                            Row(
                              children: List.generate(kInterns.length, (i) {
                                // Match the actual position with modulo
                                final active = i == (_currentPage % kInterns.length);
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: active ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? const Color(0xFFD4748A)
                                        : Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(width: 20),
                            _ArrowButton(icon: Icons.chevron_right, onTap: _next),
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
    );
  }
}

// ── Front card (carousel tile) ────────────────────────────────────────────────
class _InternCardFront extends StatelessWidget {
  final InternProfile intern;
  const _InternCardFront({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                intern.initials,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: intern.avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            intern.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Intern ${intern.internNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arrow button ──────────────────────────────────────────────────────────────
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
      ),
    );
  }
}

// ── Redesigned Detail Page (Glassmorphism & Chips) ────────────────────────────
class InternDetailPage extends StatefulWidget {
  final InternProfile intern;
  const InternDetailPage({super.key, required this.intern});
  @override
  State<InternDetailPage> createState() => _InternDetailPageState();
}

class _InternDetailPageState extends State<InternDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  final List<Star> _stars = [];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    final rng = math.Random();
    for (int i = 0; i < 160; i++) {
      _stars.add(Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 1.8 + 0.4,
        opacity: rng.nextDouble() * 0.6 + 0.2,
        speed: rng.nextDouble() * 0.03 + 0.005,
        phase: rng.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intern = widget.intern;
    return Scaffold(
      body: Stack(
        children: [
          // Galaxy background
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
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, __) => CustomPaint(
                  painter: StarfieldPainter(
                      animValue: _bgController.value, stars: _stars),
                ),
              ),
            ),
          ),
          
          // Card content with Glassmorphism
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 580),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24).withOpacity(0.5), // Deep sleek transparent background
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          // ── Top Bar (Back Button) ──
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, top: 16),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                                onPressed: () => Navigator.of(context).pop(),
                                splashRadius: 24,
                              ),
                            ),
                          ),

                          // ── Header Profile ──
                          Column(
                            children: [
                              // Glowing Avatar
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: intern.avatarColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: intern.avatarColor.withOpacity(0.6),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    )
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    intern.initials,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                intern.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Intern ${intern.internNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Divider ──
                          Divider(color: Colors.white.withOpacity(0.1), thickness: 1, indent: 32, endIndent: 32),
                          const SizedBox(height: 16),

                          // ── Info Grid / Rows ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                _IconInfoRow(icon: Icons.school_outlined, text: intern.school),
                                const SizedBox(height: 12),
                                _IconInfoRow(icon: Icons.menu_book_outlined, text: intern.program),
                                const SizedBox(height: 12),
                                _IconInfoRow(icon: Icons.star_border_outlined, text: intern.specialization),
                                const SizedBox(height: 12),
                                _IconInfoRow(icon: Icons.email_outlined, text: intern.email),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          Divider(color: Colors.white.withOpacity(0.1), thickness: 1, indent: 32, endIndent: 32),
                          const SizedBox(height: 20),

                          // ── Skills Sections ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Technical Skills',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: intern.technicalSkills.map((skill) {
                                    return _SkillChip(
                                      label: skill,
                                      color: const Color(0xFF4CA1AF), // Sleek teal accent
                                    );
                                  }).toList(),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                const Text(
                                  'Soft Skills',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: intern.softSkills.map((skill) {
                                    return _SkillChip(
                                      label: skill,
                                      color: const Color(0xFFD4748A), // Match landing page dot accent
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modern Icon Info Row ──────────────────────────────────────────────────────
class _IconInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Custom Skill Chip ─────────────────────────────────────────────────────────
class _SkillChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SkillChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}