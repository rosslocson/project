import 'dart:async';
import 'dart:math';
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

  // Dynamic intern list
  List<InternProfile> _interns = [];
  bool _loadingInterns = true;
  String? _internsError;

  // Carousel
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  // Pagination States for Dashboard Cards
  int _usersPage = 0;
  int _activityPage = 0;
  static const int _itemsPerPage = 5;

  // Scrolling States & Keys for precise targeting
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _cardsKey = GlobalKey(); // Key to target the bottom cards
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.35, initialPage: 0);
    _loadAll();
    _fetchInterns();

    // Add scroll listener to fade out the indicator when user scrolls down
    _scrollController.addListener(_onScroll);
    // Check if the content is actually scrollable after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollable());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll Indicator & Targeting Logic ───────────────────────────

  void _checkScrollable() {
    if (_scrollController.hasClients) {
      setState(() {
        // Only show indicator if there is overflow content AND we are at the top
        _showScrollIndicator = _scrollController.position.maxScrollExtent > 0 &&
            _scrollController.offset < 50;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && _showScrollIndicator) {
      setState(() => _showScrollIndicator = false);
    } else if (_scrollController.offset <= 50 &&
        !_showScrollIndicator &&
        _scrollController.position.maxScrollExtent > 0) {
      setState(() => _showScrollIndicator = true);
    }
  }

  void _scrollToCards() {
    final context = _cardsKey.currentContext;
    if (context != null) {
      // ensureVisible calculates the exact math to bring this widget into view
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.0, // 0.0 means align to the very top edge of the scroll view
      );
    }
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
      
      // Re-check scrollability after data loads and layout shifts
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollable());
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
      
      // Re-check scrollability after data loads
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollable());
    } catch (e) {
      debugPrint('_loadAll error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cleanDetail(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw
        .replaceAll(RegExp(r'\s*\(id=\d+\)'), '')
        .replaceAll(RegExp(r'\s*\(active=\w+(?:,\s*archived=\w+)?\)'), '')
        .replaceAll(RegExp(r'\s*\(archived=\w+\)'), '')
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
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Pagination Helpers ───────────────────────────────────────────
  
  int get _totalUsers => (_stats?['recent_users'] as List?)?.length ?? 0;
  int get _totalUsersPages => max(1, (_totalUsers / _itemsPerPage).ceil());
  
  int get _totalActivity => _activityLogs.length;
  int get _totalActivityPages => max(1, (_totalActivity / _itemsPerPage).ceil());

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
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildInternCarousel(),
                          const SizedBox(height: 32),
                          if (_loading)
                            const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          else ...[
                            _buildStatsGrid(),
                            // Clean spacing that allows the scroll target to perfectly frame the cards
                            const SizedBox(height: 100), 
                            
                            // ── Side-by-Side Paginated Content Area (Targeted by Key) ──────────
                            Container(
                              key: _cardsKey,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Side: Recent Users
                                  Expanded(child: _buildPaginatedUsersCard()),
                                  const SizedBox(width: 32),
                                  // Right Side: Recent Activity Timeline
                                  Expanded(child: _buildPaginatedActivityCard()),
                                ],
                              ),
                            ),
                            // Extra padding at bottom to ensure scrolling past the cards is smooth
                            const SizedBox(height: 40),
                          ],
                        ],
                      ),
                    ),
                    
                    // ── Animated Bouncing Scroll Indicator ──────────
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _showScrollIndicator ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: !_showScrollIndicator,
                          child: Center(
                            child: _BouncingArrow(
                              onTap: _scrollToCards, // Point directly to the cards row
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
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
    );
  }

  // ── Paginated Card Component: Users ──────────────────────────────
  Widget _buildPaginatedUsersCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Users',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  'Platform members',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
            Text(
              'Page ${_usersPage + 1} of $_totalUsersPages',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildUsersList(key: ValueKey<int>(_usersPage)),
                ),
              ),
              _buildPaginationFooter(
                currentPage: _usersPage,
                totalPages: _totalUsersPages,
                onPrev: () {
                  if (_usersPage > 0) {
                    setState(() => _usersPage--);
                  }
                },
                onNext: () {
                  if (_usersPage < _totalUsersPages - 1) {
                    setState(() => _usersPage++);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList({required Key key}) {
    final allUsers = (_stats?['recent_users'] as List?) ?? [];
    if (allUsers.isEmpty) {
      return Center(key: key, child: const Text('No users yet', style: TextStyle(color: Colors.black87)));
    }

    final safeStartIndex = max(0, _usersPage * _itemsPerPage).clamp(0, allUsers.length);
    final safeEndIndex = (safeStartIndex + _itemsPerPage).clamp(0, allUsers.length);
    final users = allUsers.sublist(safeStartIndex, safeEndIndex);

    return ListView.separated(
      key: key,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12, indent: 70),
      itemBuilder: (context, i) {
        final u = users[i];
        final fName = u['first_name']?.toString() ?? '';
        final lName = u['last_name']?.toString() ?? '';
        final displayName = [fName, lName].where((s) => s.isNotEmpty).join(' ');
        final titleText = displayName.isNotEmpty ? displayName : (u['name']?.toString() ?? u['email']?.toString() ?? 'Unknown');
        final initials = '${fName.isNotEmpty ? fName[0] : ''}${lName.isNotEmpty ? lName[0] : ''}'.toUpperCase();
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(titleText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          subtitle: Text(u['email'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.black54)),
          trailing: _buildRoleBadge(u['role']),
        );
      },
    );
  }

  Widget _buildRoleBadge(String? role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFDBE9F4) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAdmin ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1)),
      ),
      child: Text(
        role ?? 'user',
        style: TextStyle(
          color: isAdmin ? Colors.red.shade700 : Colors.green.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Paginated Card Component: Activity Timeline ──────────────────
  Widget _buildPaginatedActivityCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  'System mission log',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
            Text(
              'Page ${_activityPage + 1} of $_totalActivityPages',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildActivityTimeline(key: ValueKey<int>(_activityPage)),
                ),
              ),
              _buildPaginationFooter(
                currentPage: _activityPage,
                totalPages: _totalActivityPages,
                onPrev: () {
                  if (_activityPage > 0) {
                    setState(() => _activityPage--);
                  }
                },
                onNext: () {
                  if (_activityPage < _totalActivityPages - 1) {
                    setState(() => _activityPage++);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTimeline({required Key key}) {
    if (_activityLogs.isEmpty) {
      return Center(key: key, child: const Text('No activity yet', style: TextStyle(color: Colors.black87)));
    }

    final safeStartIndex = max(0, _activityPage * _itemsPerPage).clamp(0, _activityLogs.length);
    final safeEndIndex = (safeStartIndex + _itemsPerPage).clamp(0, _activityLogs.length);
    final logsToShow = _activityLogs.sublist(safeStartIndex, safeEndIndex);

    return ListView.builder(
      key: key,
      padding: const EdgeInsets.only(top: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logsToShow.length,
      itemBuilder: (context, i) {
        final log = logsToShow[i];
        final action = log['action'] as String?;
        final rawDetail = log['details'] as String? ?? action ?? '';
        final displayText = _cleanDetail(rawDetail);
        final logUser = log['user'] as Map<String, dynamic>?;
        final userName = logUser != null ? '${logUser['first_name'] ?? ''} ${logUser['last_name'] ?? ''}'.trim() : 'System';
        final isLastItem = i == logsToShow.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 60,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isLastItem)
                      Positioned(
                        top: 36, bottom: -16,
                        child: Container(width: 2, color: Colors.black12),
                      ),
                    Positioned(
                      top: 12,
                      child: _actionIcon(action),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayText,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                          Text(
                            _formatDate(log['created_at'] as String?),
                            style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(userName, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Reusable Pagination Footer ───────────────────────────────────
  Widget _buildPaginationFooter({
    required int currentPage,
    required int totalPages,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: currentPage > 0 ? onPrev : null,
            icon: const Icon(Icons.arrow_back_ios, size: 12),
            label: const Text('Prev'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7673C8),
              disabledForegroundColor: Colors.black26,
            ),
          ),
          Row(
            children: List.generate(totalPages, (index) {
              final isActive = index == currentPage;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF7673C8) : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          TextButton(
            onPressed: currentPage < totalPages - 1 ? onNext : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7673C8),
              disabledForegroundColor: Colors.black26,
            ),
            child: const Row(
              children: [
                Text('Next'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Methods ───────────────────────────────────────────────

  Widget _actionIcon(String? action) {
    IconData icon;
    Color color;
    switch (action) {
      case 'LOGIN': icon = Icons.login; color = Colors.green; break;
      case 'REGISTER': icon = Icons.person_add; color = Colors.blue; break;
      case 'UPDATE_PROFILE': icon = Icons.edit; color = Colors.orange; break;
      case 'CHANGE_PASSWORD': icon = Icons.lock; color = Colors.purple; break;
      case 'LOGIN_FAILED': icon = Icons.warning_amber_rounded; color = Colors.red; break;
      case 'ACCOUNT_LOCKED': icon = Icons.lock_clock; color = Colors.red; break;
      case 'PASSWORD_RESET_REQUEST': icon = Icons.mail_outline; color = Colors.blue; break;
      case 'PASSWORD_RESET': icon = Icons.lock_reset; color = Colors.teal; break;
      case 'CREATE_USER': icon = Icons.person_add_alt; color = Colors.teal; break;
      case 'DELETE_USER': icon = Icons.delete_outline; color = Colors.red; break;
      case 'UPDATE_USER': icon = Icons.manage_accounts; color = Colors.indigo; break;
      default: icon = Icons.info_outline; color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 14, color: color),
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

  // ── Intern Carousel Widgets ──────────────────────────────────────

  Widget _buildInternCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet Our Interns',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildCarouselBody(),
        const SizedBox(height: 16),
        if (!_loadingInterns && _interns.isNotEmpty) _buildDotNavigation(),
      ],
    );
  }

  Widget _buildCarouselBody() {
    if (_loadingInterns) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: Colors.white54)));
    if (_internsError != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 40),
              const SizedBox(height: 8),
              Text(_internsError!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: _fetchInterns,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text('Retry', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }
    if (_interns.isEmpty) return const SizedBox(height: 180, child: Center(child: Text('No interns found.', style: TextStyle(color: Colors.white54, fontSize: 15))));

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
              child: GestureDetector(onTap: () => _openDetail(intern), child: _InternCardFront(intern: intern)),
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
                color: active ? const Color.fromARGB(255, 118, 115, 200) : Colors.white.withValues(alpha: 0.25),
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
}

class _InternCardFront extends StatelessWidget {
  final InternProfile intern;
  const _InternCardFront({required this.intern});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.4), blurRadius: 32, offset: const Offset(0, 16))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InternAvatar(intern: intern, size: 70, borderRadius: 18, fontSize: 28),
          const SizedBox(height: 12),
          Text(intern.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Intern #${intern.internNumber}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8)),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 22),
      ),
    );
  }
}

// ── Custom Bouncing Arrow Widget ───────────────────────────────────

class _BouncingArrow extends StatefulWidget {
  final VoidCallback onTap;
  
  const _BouncingArrow({required this.onTap});

  @override
  _BouncingArrowState createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<_BouncingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B).withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7673C8).withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}