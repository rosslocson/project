import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart' as go;
import 'package:provider/provider.dart';

// Providers & Services
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

// Widgets
import '../widgets/admin_sidebar.dart';
import '../widgets/stat_card.dart';
import '../widgets/star_background.dart' as stars;
import 'admin_glass_topbar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  bool _isSidebarOpen = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _activityLogs = [];
  bool _loading = true;
  late AnimationController _bgAnimController;
  late final List<stars.Star> _stars;

  // Carousel State
  late PageController _pageController;
  late Timer _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _stars = stars.generateStars(count: 120);
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 600),
    )..repeat();
    _loadAll();

    // Initialize Carousel
    _pageController = PageController(
      viewportFraction: 0.35, 
      initialPage: _currentPage,
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

  // --- Carousel Logic ---
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % kInterns.length;
      _pageController.animateToPage(
        next,
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
  // ----------------------

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getDashboardStats(),
        ApiService.getActivityLogs(),
      ]);
      
      if (!mounted) return;
      
      final statsRes = results[0];
      final logsRes = results[1];
      
      setState(() {
        if (statsRes['ok'] == true) _stats = statsRes['data'] ?? statsRes;
        _activityLogs = (logsRes['logs'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('_loadAll error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cleanDetail(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw
        .replaceAll(RegExp(r'\s*\(id=\d+\)'), '')
        .replaceAll(RegExp(r'\s*\(active=\w+\)'), '')
        .replaceAll(RegExp(r':\s*[\w.+-]+@[\w.-]+\.\w+'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  // --- Updated Helper for Solid Light Cards ---
  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5), // Solid warm off-white to match stat cards
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGlowingCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.12),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAnimatedGalaxyBackground() {
    return stars.GalaxyBackground(
      animation: _bgAnimController,
      stars: _stars,
    );
  }

  // --- Intern Carousel Widget ---
  Widget _buildInternCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet Our Interns',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: kInterns.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final intern = kInterns[index];
              final isCenter = index == _currentPage;
              return AnimatedScale(
                scale: isCenter ? 1.0 : 0.85,
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ArrowButton(icon: Icons.chevron_left, onTap: _prev),
            const SizedBox(width: 20),
            Row(
              children: List.generate(kInterns.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF6C63FF)
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
      ],
    );
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    bool isSidebarOpen = _isSidebarOpen;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isSidebarOpen ? 250 : 0,
            child: isSidebarOpen
                ? AdminSidebar(
                    currentRoute: go.GoRouterState.of(context).uri.toString(),
                    onClose: () => setState(() => _isSidebarOpen = false),
                  )
                : const SizedBox(),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _buildAnimatedGalaxyBackground()),
                Positioned.fill(
                  child: Column(
                    children: [
                      GlassTopBar(
                        key: const Key('admin_topbar'),
                        isSidebarOpen: isSidebarOpen,
                        onToggleSidebar: () => setState(() => _isSidebarOpen = !isSidebarOpen),
                        user: user,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              
                              _buildInternCarousel(),
                              const SizedBox(height: 32),
                              
                              Text(
                                'Dashboard Stats',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              _buildStatsGrid(),
                              
                              const SizedBox(height: 48),
                              
                              _buildRecentActivity(),
                              
                              const SizedBox(height: 48),
                              
                              _buildRecentUsersSection(),
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

  Widget _buildStatsGrid() {
    if (_loading || _stats == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(64.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 1.6,
      children: [
        StatCard(
          title: 'Total Users',
          value: '${_stats!['total_users'] ?? 0}',
          icon: Icons.people,
          color: const Color(0xFF6C63FF),
          subtitle: '+12% from last month',
        ),
        StatCard(
          title: 'Active Users',
          value: '${_stats!['active_users'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
          subtitle: '+8% this week',
        ),
        StatCard(
          title: 'Admins',
          value: '${_stats!['admins'] ?? 0}',
          icon: Icons.admin_panel_settings,
          color: Colors.orange,
          subtitle: 'Team leads',
        ),
        StatCard(
          title: 'Interns',
          value: '${_stats!['interns'] ?? kInterns.length}',
          icon: Icons.school,
          color: Colors.purple,
          subtitle: 'New batch',
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz, color: Colors.white70),
              label: const Text('View All', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildActivityFeed(true),
      ],
    );
  }

  Widget _buildRecentUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Users',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 20),
        _buildRecentUsers(),
      ],
    );
  }

  Widget _buildRecentUsers() {
    final users = (_stats?['recent_users'] as List?) ?? [];
    if (users.isEmpty) {
      return _buildSectionCard(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No users yet', style: TextStyle(color: Colors.black87)),
          ),
        ),
      );
    }
    return _buildSectionCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Colors.black12), // Dark divider for light background
        itemBuilder: (context, i) {
          final u = users[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
              child: Text(
                '${u['first_name']?[0] ?? ''}${u['last_name']?[0] ?? ''}',
                style: const TextStyle(
                    color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${u['first_name']} ${u['last_name']}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87), // Dark text for readability
            ),
            subtitle: Text(u['email'] ?? '',
                style: const TextStyle(color: Colors.black54)), // Dark text for readability
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: u['role'] == 'admin'
                    ? const Color.fromARGB(255, 255, 235, 238)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                u['role'] ?? 'user',
                style: TextStyle(
                  color: u['role'] == 'admin'
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityFeed(bool isAdmin) {
    if (_activityLogs.isEmpty) {
      return _buildSectionCard(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No activity yet', style: TextStyle(color: Colors.black87)),
          ),
        ),
      );
    }
    return _buildSectionCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activityLogs.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Colors.black12), // Dark divider for light background
        itemBuilder: (context, i) {
          final log = _activityLogs[i];
          final action = log['action'] as String?;
          final rawDetail = log['details'] as String? ?? action ?? '';
          final displayText = _cleanDetail(rawDetail);
          final logUser = log['user'] as Map<String, dynamic>?;
          final userName = (isAdmin && logUser != null)
              ? '${logUser['first_name'] ?? ''} ${logUser['last_name'] ?? ''}'.trim()
              : '';
              
          return ListTile(
            dense: true,
            leading: _actionIcon(action),
            title: Text(
              displayText,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87), // Dark text for readability
            ),
            subtitle: userName.isNotEmpty
                ? Text(userName,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)) // Dark text for readability
                : null,
            trailing: Text(
              _formatDate(log['created_at'] as String?),
              style: const TextStyle(color: Colors.black54, fontSize: 12), // Dark text for readability
            ),
          );
        },
      ),
    );
  }

  Widget _actionIcon(String? action) {
    IconData icon;
    Color color;
    switch (action) {
      case 'LOGIN':
        icon = Icons.login;
        color = Colors.green;
        break;
      case 'REGISTER':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case 'UPDATE_PROFILE':
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case 'CHANGE_PASSWORD':
        icon = Icons.lock;
        color = Colors.purple;
        break;
      case 'LOGIN_FAILED':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case 'ACCOUNT_LOCKED':
        icon = Icons.lock_clock;
        color = Colors.red;
        break;
      case 'PASSWORD_RESET_REQUEST':
        icon = Icons.mail_outline;
        color = Colors.blue;
        break;
      case 'PASSWORD_RESET':
        icon = Icons.lock_reset;
        color = Colors.teal;
        break;
      case 'CREATE_USER':
        icon = Icons.person_add_alt;
        color = Colors.teal;
        break;
      case 'DELETE_USER':
        icon = Icons.delete_outline;
        color = Colors.red;
        break;
      case 'UPDATE_USER':
        icon = Icons.manage_accounts;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, size: 16, color: color),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

// ── Data Models & Detail Widgets ─────────────────────────────────────────────

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

// Carousel Tile
class _InternCardFront extends StatelessWidget {
  final InternProfile intern;
  const _InternCardFront({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                intern.initials,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: intern.avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            intern.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Intern ${intern.internNumber}',
            style: TextStyle(
              fontSize: 12,
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
  final List<CardStar> _stars = [];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    final rng = math.Random();
    for (int i = 0; i < 160; i++) {
      _stars.add(CardStar(
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
                  painter: CardStarfieldPainter(
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
                      constraints: const BoxConstraints(maxWidth: 800),
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
                            padding: const EdgeInsets.symmetric(horizontal: 40), 
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
                            padding: const EdgeInsets.symmetric(horizontal: 40),
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
                                      color: const Color(0xFF4CA1AF), 
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
                                      color: const Color(0xFFD4748A), 
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

class CardStar {
  final double x, y, size, opacity, speed, phase;
  const CardStar({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.phase,
  });
}

class CardStarfieldPainter extends CustomPainter {
  final double animValue;
  final List<CardStar> stars;
  CardStarfieldPainter({required this.animValue, required this.stars});

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
  bool shouldRepaint(covariant CardStarfieldPainter old) =>
      old.animValue != animValue;
}