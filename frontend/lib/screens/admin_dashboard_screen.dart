import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Providers & Services
import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';
import '../services/api_service.dart';

// Widgets
import '../widgets/admin_layout.dart';
import '../widgets/stat_card.dart';
import 'admin_glass_topbar.dart';

// Reuse the shared InternProfile model and widgets from intern_widgets.dart
import 'intern_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  List<dynamic> _activityLogs = [];
  bool _loading = true;
  bool _showAllActivity = false;
  bool _showAllUsers = false;

  // Dynamic intern list
  List<InternProfile> _interns = [];
  bool _loadingInterns = true;
  String? _internsError;

  // Carousel
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.35, initialPage: 0);
    _loadAll();
    _fetchInterns();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // ── Intern fetching ──────────────────────────────────────────────

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
        _currentPage = loaded.isNotEmpty ? loaded.length * 1000 : 0;
      });

      if (_interns.isNotEmpty) {
        _pageController.dispose();
        _pageController = PageController(
          viewportFraction: 0.35,
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

  // ── Carousel logic ───────────────────────────────────────────────

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

  void _openDetail(InternProfile intern) {
    _autoScrollTimer?.cancel();
    Navigator.of(context)
        .push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => InternDetailPage(intern: intern),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ))
        .then((_) {
      if (mounted) _startAutoScroll();
    });
  }

  // ── Data loading ─────────────────────────────────────────────────

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
        if (statsRes['ok'] == true) _stats = statsRes;
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

  // ── Intern carousel section ──────────────────────────────────────

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
        _buildCarouselBody(),
        const SizedBox(height: 16),
        if (!_loadingInterns && _interns.isNotEmpty) _buildDotNavigation(),
      ],
    );
  }

  Widget _buildCarouselBody() {
    if (_loadingInterns) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

    if (_internsError != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 40),
              const SizedBox(height: 8),
              Text(_internsError!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
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

    if (_interns.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No interns found.',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (context, index) {
          final intern = _interns[index % _interns.length];
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
    );
  }

  Widget _buildDotNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ArrowButton(icon: Icons.chevron_left, onTap: _prev),
        const SizedBox(width: 20),
        Row(
          children: List.generate(_interns.length, (i) {
            final active = i == (_currentPage % _interns.length);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color.fromARGB(255, 118, 115, 200)
                    : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(width: 20),
        _ArrowButton(icon: Icons.chevron_right, onTap: _next),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sidebar = context.watch<SidebarProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isSidebarOpen = sidebar.isAdminSidebarOpen;

    return AdminLayout(
      title: 'Admin Dashboard',
      currentRoute: GoRouterState.of(context).matchedLocation,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/space_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
              GlassTopBar(
                isSidebarOpen: isSidebarOpen,
                onToggleSidebar: sidebar.toggleAdminSidebar,
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
                      if (_loading)
                        const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white),
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth > 800 ? 4 : 2;
                            return GridView.count(
                              crossAxisCount: cols,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 1.4,
                              children: [
                                _buildGlowingCard(
                                  child: StatCard(
                                    title: 'Total Users',
                                    value: '${_stats?['total_users'] ?? 0}',
                                    icon: Icons.people,
                                    color: const Color(0xFF0A1425),
                                    subtitle: 'Registered accounts',
                                  ),
                                ),
                                _buildGlowingCard(
                                  child: StatCard(
                                    title: 'Active Users',
                                    value: '${_stats?['active_users'] ?? 0}',
                                    icon: Icons.check_circle,
                                    color: const Color(0xFF0A1425),
                                    subtitle: 'Currently active',
                                  ),
                                ),
                                _buildGlowingCard(
                                  child: StatCard(
                                    title: 'Admins',
                                    value: '${_stats?['admin_users'] ?? 0}',
                                    icon: Icons.admin_panel_settings,
                                    color: const Color(0xFF0A1425),
                                    subtitle: 'Administrator accounts',
                                  ),
                                ),
                                _buildGlowingCard(
                                  child: StatCard(
                                    title: 'Inactive',
                                    value: '${_stats?['new_users'] ?? 0}',
                                    icon: Icons.person_off,
                                    color: const Color(0xFF0A1425),
                                    subtitle: 'Inactive accounts',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        // ── Recent Users ───────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Users',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: () => setState(
                                  () => _showAllUsers = !_showAllUsers),
                              icon: Icon(
                                _showAllUsers
                                    ? Icons.expand_less
                                    : Icons.arrow_forward,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                _showAllUsers ? 'Show Less' : 'View All',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildRecentUsers(),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Recent Activity ────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Activity',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                Text(
                                  'All recent system activity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            if (_activityLogs.length > 5)
                              TextButton.icon(
                                onPressed: () => setState(() =>
                                    _showAllActivity = !_showAllActivity),
                                icon: Icon(
                                  _showAllActivity
                                      ? Icons.expand_less
                                      : Icons.arrow_forward,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _showAllActivity ? 'Show Less' : 'View All',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildActivityFeed(true),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUsers() {
    final allUsers = (_stats?['recent_users'] as List?) ?? [];
    if (allUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child:
              Text('No users yet', style: TextStyle(color: Colors.black87)),
        ),
      );
    }
    const int previewCount = 5;
    final users =
        _showAllUsers ? allUsers : allUsers.take(previewCount).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, i) {
        final u = users[i];
        final fName = u['first_name']?.toString() ?? '';
        final lName = u['last_name']?.toString() ?? '';
        final initials =
            '${fName.isNotEmpty ? fName[0] : ''}${lName.isNotEmpty ? lName[0] : ''}'
                .toUpperCase();
        final avatarUrl = u['avatar_url']?.toString();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
            backgroundImage:
                (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    initials.isEmpty ? 'U' : initials,
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(
            '$fName $lName'.trim(),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          subtitle: Text(u['email'] ?? '',
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: u['role'] == 'admin'
                  ? const Color(0xFFDBE9F4)
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
    );
  }

  Widget _buildActivityFeed(bool isAdmin) {
    if (_activityLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No activity yet',
              style: TextStyle(color: Colors.black87)),
        ),
      );
    }

    const int previewCount = 5;
    final logsToShow = _showAllActivity
        ? _activityLogs
        : _activityLogs.take(previewCount).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logsToShow.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, i) {
        final log = logsToShow[i];
        final action = log['action'] as String?;
        final rawDetail = log['details'] as String? ?? action ?? '';
        final displayText = _cleanDetail(rawDetail);
        final logUser = log['user'] as Map<String, dynamic>?;
        final userName = (isAdmin && logUser != null)
            ? '${logUser['first_name'] ?? ''} ${logUser['last_name'] ?? ''}'
                .trim()
            : '';

        return ListTile(
          leading: _actionIcon(action),
          title: Text(
            displayText,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          subtitle: userName.isNotEmpty
              ? Text(userName,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black54))
              : null,
          trailing: Text(
            _formatDate(log['created_at'] as String?),
            style:
                const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        );
      },
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

// ── Carousel card (admin style) ───────────────────────────────────

class _InternCardFront extends StatelessWidget {
  final InternProfile intern;
  const _InternCardFront({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2540), Color(0xFF4A5E9A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2540).withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Real avatar photo or initials fallback
          InternAvatar(
            intern: intern,
            size: 70,
            borderRadius: 18,
            fontSize: 28,
          ),
          const SizedBox(height: 12),
          Text(
            intern.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Intern #${intern.internNumber}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arrow button ──────────────────────────────────────────────────

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
          border:
              Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
        ),
        child:
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
      ),
    );
  }
}