// lib/screens/user_my_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/user_sidebar.dart';
import '../widgets/app_background.dart';
import '../widgets/app_theme.dart';
import 'user_glass_topbar.dart';
import '../providers/sidebar_provider.dart';

// ── Imported Extracted Widgets ──
import '../widgets/user_my_profile_widgets/profile_left_panel.dart';
import '../widgets/user_my_profile_widgets/profile_academic_tab.dart';
import '../widgets/user_my_profile_widgets/profile_skills_tab.dart';
import '../widgets/user_my_profile_widgets/profile_components.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _fetchError;
  // Sidebar open state is controlled by SidebarProvider to match GlassTopBar hamburger behavior.
  // (This page previously used local state which could diverge.)
  // ignore: unused_field
  final bool _isSidebarOpen = true;
  late TabController _tabs;

  int? _requiredHours;

  // Custom Dark Blue Theme for the Left Card
  final Color _cardDarkBlue = const Color(0xFF0B132B);
  final Color _cardDarkerBlue = const Color(0xFF060A17);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetchProfile();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _fetchError = null;
    });

    try {
      await context.read<AuthProvider>().refreshProfile();
      if (!mounted) return;

      final user = context.read<AuthProvider>().user;
      final raw = user?['required_ojt_hours'];
      final hours = raw is int ? raw : int.tryParse(raw?.toString() ?? '');

      setState(() {
        _loading = false;
        _requiredHours = hours;
      });
    } catch (e) {
      if (!mounted) return;
      final raw = context.read<AuthProvider>().user?['required_ojt_hours'];
      setState(() {
        _loading = false;
        _fetchError = 'Network error. Check your connection and tap Retry.';
        _requiredHours = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final user = context.watch<AuthProvider>().user;

    final first = user?['first_name'] as String? ?? '';
    final last = user?['last_name'] as String? ?? '';
    String initials = '';
    if (first.isNotEmpty) initials += first[0];
    if (last.isNotEmpty) initials += last[0];

    final rawAvatarUrl = user?['avatar_url']?.toString().trim() ?? '';
    final finalAvatarUrl = rawAvatarUrl.isEmpty
        ? ''
        : rawAvatarUrl.startsWith('http://') ||
                rawAvatarUrl.startsWith('https://')
            ? rawAvatarUrl
            : '${ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}/${rawAvatarUrl.replaceFirst(RegExp(r'^/+'), '')}';

    return Scaffold(
      backgroundColor: theme.appBackground,
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: context.watch<SidebarProvider>().isUserSidebarOpen ? 250 : 0,
            child: context.watch<SidebarProvider>().isUserSidebarOpen
                ? UserSidebar(
                    currentRoute: '/profile',
                    onClose: () => context
                        .read<SidebarProvider>()
                        .setUserSidebarOpen(false),
                  )
                : null,
          ),
          Expanded(
            child: AppBackground(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 72,
                    child: GlassTopBar(
                      pageTitle: 'My Profile',
                      showWelcome: false,
                      user: user,
                      isSidebarOpen:
                          context.watch<SidebarProvider>().isUserSidebarOpen,
                      onToggleSidebar: () => context
                          .read<SidebarProvider>()
                          .setUserSidebarOpen(!context
                              .read<SidebarProvider>()
                              .isUserSidebarOpen),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 96, right: 96, bottom: 28),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.isDarkInternTheme
                              ? theme.surface
                              : theme.sidebarBackground,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: context.isDarkInternTheme
                              ? []
                              : [
                                  BoxShadow(
                                    color: theme.shadowColor,
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _loading
                              ? Center(
                                  child: CircularProgressIndicator(
                                      color: theme.surfaceText))
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ProfileLeftPanel(
                                      user: user,
                                      first: first,
                                      last: last,
                                      initials: initials,
                                      finalAvatarUrl: finalAvatarUrl,
                                      cardDarkBlue: _cardDarkBlue,
                                      cardDarkerBlue: _cardDarkerBlue,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (_fetchError != null)
                                            ProfileRetryBanner(
                                              msg: _fetchError!,
                                              onRetry: _fetchProfile,
                                            ),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                  bottom: BorderSide(
                                                      color: theme.border)),
                                            ),
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: TabBar(
                                              controller: _tabs,
                                              labelColor: theme.surfaceText,
                                              unselectedLabelColor:
                                                  theme.mutedText,
                                              indicatorColor:
                                                  context.isDarkInternTheme
                                                      ? const Color(0xFF7367F0)
                                                      : const Color(0xFF00022E),
                                              indicatorWeight: 3,
                                              dividerColor: Colors.transparent,
                                              labelStyle: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14),
                                              unselectedLabelStyle:
                                                  const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14),
                                              tabs: const [
                                                Tab(
                                                    iconMargin: EdgeInsets.only(
                                                        bottom: 6),
                                                    icon: Icon(
                                                        Icons.school_outlined,
                                                        size: 20),
                                                    text: 'Academic Info'),
                                                Tab(
                                                    iconMargin: EdgeInsets.only(
                                                        bottom: 6),
                                                    icon: Icon(
                                                        Icons.stars_outlined,
                                                        size: 20),
                                                    text: 'Skills & Profile'),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              color: context.isDarkInternTheme
                                                  ? theme.surface
                                                  : theme.sidebarBackground,
                                              child: TabBarView(
                                                controller: _tabs,
                                                children: [
                                                  ProfileAcademicTab(
                                                      user: user,
                                                      requiredHours:
                                                          _requiredHours),
                                                  ProfileSkillsTab(user: user),
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
}
