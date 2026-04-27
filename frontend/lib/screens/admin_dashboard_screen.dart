import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Providers & Services
import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';
import '../services/api_service.dart';

// Layout & Shared
import '../widgets/admin_layout.dart';
import 'admin_glass_topbar.dart';
import 'intern_widgets.dart';

// Dashboard Widgets (Your new separated files)
import '../widgets/admin_dashboard_widgets/intern_carousel_section.dart';
import '../widgets/admin_dashboard_widgets/dashboard_stats_grid.dart';
import '../widgets/admin_dashboard_widgets/recent_users_card.dart';
import '../widgets/admin_dashboard_widgets/recent_activity_card.dart';
import '../widgets/admin_dashboard_widgets/bouncing_arrow.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _activityLogs = [];
  bool _loading = true;

  List<InternProfile> _interns = [];
  bool _loadingInterns = true;
  String? _internsError;

  int _usersPage = 1;
  int _activityPage = 1;
  int _totalUsersPages = 1;
  int _totalActivityPages = 1;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _cardsKey = GlobalKey();
  bool _showScrollIndicator = false;

  List<dynamic> _allFilteredActivities = [];

  // Filter activity logs to current week (Monday to Sunday)
  List<dynamic> _filterActivitiesToCurrentWeek(List<dynamic> activities) {
    final now = DateTime.now();
    // Find the most recent Monday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    // Set to start of Monday
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    // Set to end of Sunday
    final weekEnd = weekStart.add(const Duration(days: 7, hours: 23, minutes: 59, seconds: 59));

    return activities.where((activity) {
      final createdAt = activity['created_at'];
      if (createdAt == null) return false;
      
      try {
        final activityDate = DateTime.parse(createdAt as String).toLocal();
        return activityDate.isAfter(weekStart) && activityDate.isBefore(weekEnd);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void _updateActivityPage(int newPage) {
    setState(() {
      _activityPage = newPage;
      // Recalculate activity logs for the new page
      const int activitiesPerPage = 5;
      final startIndex = (_activityPage - 1) * activitiesPerPage;
      final endIndex = startIndex + activitiesPerPage;
      _activityLogs = _allFilteredActivities.sublist(
        startIndex,
        endIndex > _allFilteredActivities.length ? _allFilteredActivities.length : endIndex,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
    _fetchInterns();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollable());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollable() {
    if (_scrollController.hasClients) {
      setState(() {
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
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollable());
    } else {
      setState(() {
        _internsError = res['error'] ?? 'Failed to load interns';
        _loadingInterns = false;
      });
    }
  }

  Future<void> _loadAll({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getDashboardStats(page: page, limit: 5),
        ApiService.getAllActivityLogs(),
      ]);

      if (!mounted) return;

      setState(() {
        if (results[0]['ok'] == true) {
          _stats = results[0];
          _usersPage = (results[0]['current_page'] ?? 0) + 1;
          _totalUsersPages = results[0]['total_pages'] ?? 1;
        }
        if (results[1]['ok'] == true) {
          final allActivities = (results[1]['logs'] as List?) ?? [];
          _allFilteredActivities = _filterActivitiesToCurrentWeek(allActivities);
          
          // Frontend pagination for activities
          const int activitiesPerPage = 5;
          _totalActivityPages = (_allFilteredActivities.length / activitiesPerPage).ceil();
          if (_totalActivityPages == 0) _totalActivityPages = 1;
          
          // Ensure activityPage is within bounds
          if (_activityPage > _totalActivityPages) _activityPage = _totalActivityPages;
          if (_activityPage < 1) _activityPage = 1;
          
          // Get current page activities
          final startIndex = (_activityPage - 1) * activitiesPerPage;
          final endIndex = startIndex + activitiesPerPage;
          _activityLogs = _allFilteredActivities.sublist(
            startIndex,
            endIndex > _allFilteredActivities.length ? _allFilteredActivities.length : endIndex,
          );
        }
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollable());
    } catch (e) {
      debugPrint('_loadAll error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sidebar = context.watch<SidebarProvider>();
    final auth = context.watch<AuthProvider>();

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
                isSidebarOpen: sidebar.isAdminSidebarOpen,
                onToggleSidebar: sidebar.toggleAdminSidebar,
                user: auth.user,
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
                          // 1. Extracted Intern Carousel
                          InternCarouselSection(
                            interns: _interns,
                            loading: _loadingInterns,
                            error: _internsError,
                            onRetry: _fetchInterns,
                          ),
                          const SizedBox(height: 32),
                          if (_loading)
                            const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          else ...[
                            // 2. Extracted Stats Grid
                            DashboardStatsGrid(stats: _stats),
                            const SizedBox(height: 100), 
                            
                            Container(
                              key: _cardsKey,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 3. Extracted Recent Users
                                  Expanded(
                                    child: RecentUsersCard(
                                      stats: _stats,
                                      usersPage: _usersPage,
                                      totalPages: _totalUsersPages,
                                      onPageChanged: (newPage) => _loadAll(page: newPage),
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  // 4. Extracted Recent Activity
                                  Expanded(
                                    child: RecentActivityCard(
                                      activityLogs: _activityLogs,
                                      activityPage: _activityPage,
                                      totalPages: _totalActivityPages,
                                      onPageChanged: _updateActivityPage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ],
                      ),
                    ),
                    // 5. Extracted Bouncing Arrow
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
                            child: BouncingArrow(onTap: _scrollToCards),
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
}