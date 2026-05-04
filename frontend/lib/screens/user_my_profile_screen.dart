import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_sidebar.dart';
import '../widgets/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';

// ── Custom Hamburger Icon ────────────────────────────────────────────────────
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

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _fetchError;
  bool _isSidebarOpen = true;
  late TabController _tabs;

  // ── Stored after profile fetch so it's available for the read-only view ──
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

      debugPrint('✅ MyProfile required_hours: $hours (raw: $raw)');

      setState(() {
        _loading = false;
        _requiredHours = hours;
      });
    } catch (e) {
      debugPrint('MyProfileScreen _fetchProfile error: $e');
      if (!mounted) return;

      final raw = context.read<AuthProvider>().user?['required_ojt_hours'];
      setState(() {
        _loading = false;
        _fetchError = 'Network error. Check your connection and tap Retry.';
        _requiredHours = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
      });
    }
  }

  String _val(Map<String, dynamic>? user, String key) {
    final v = user?[key];
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  String? _computeEstimatedEndDate(String startDateStr, int requiredHours) {
    DateTime start;
    try {
      start = DateTime.parse(startDateStr);
    } catch (_) {
      return null;
    }

    final int daysNeeded = (requiredHours / 8).ceil();
    DateTime current = start;
    int daysWorked = 0;

    while (daysWorked < daysNeeded) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        daysWorked++;
      }
      if (daysWorked < daysNeeded) {
        current = current.add(const Duration(days: 1));
      }
    }

    return '${current.year}-'
        '${current.month.toString().padLeft(2, '0')}-'
        '${current.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final first = user?['first_name'] as String? ?? '';
    final last = user?['last_name'] as String? ?? '';
    String initials = '';
    if (first.isNotEmpty) initials += first[0];
    if (last.isNotEmpty) initials += last[0];

    String rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    String finalAvatarUrl = '';
    if (rawAvatarUrl.isNotEmpty) {
      if (!rawAvatarUrl.startsWith('http')) {
        final staticBase = ApiService.baseUrl
            .replaceAll(RegExp(r'/api/?$'), '')
            .replaceAll(RegExp(r'/$'), '');
        final cleanPath =
            rawAvatarUrl.startsWith('/') ? rawAvatarUrl : '/$rawAvatarUrl';
        finalAvatarUrl = '$staticBase$cleanPath';
      } else {
        finalAvatarUrl = rawAvatarUrl;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen
                ? UserSidebar(
                    currentRoute: '/profile',
                    onClose: () => setState(() => _isSidebarOpen = false),
                  )
                : null,
          ),

          // ── Main content ─────────────────────────────────────────
          Expanded(
            child: AppBackground(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top bar ───────────────────────────────────
                  SizedBox(
                    height: 72,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 100, right: 100, top: 28),
                          child: Row(
                            children: [
                              Text(
                                'My Profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                        if (!_isSidebarOpen)
                          Positioned(
                            left: 20,
                            top: 28,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: IconButton(
                                padding: const EdgeInsets.all(12),
                                onPressed: () =>
                                    setState(() => _isSidebarOpen = true),
                                icon: const HamburgerIcon(),
                                tooltip: 'Open Sidebar',
                                splashColor:
                                    Colors.white.withValues(alpha: 0.1),
                                highlightColor: Colors.transparent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ── Main container ────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 100, right: 100, bottom: 28),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 40,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _loading
                              ? Center(
                                  child: CircularProgressIndicator(
                                      color: _cardDarkBlue),
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // ── LEFT PANEL ──
                                    _buildLeftPanel(
                                      user,
                                      first,
                                      last,
                                      initials,
                                      finalAvatarUrl,
                                    ),

                                    // ── RIGHT PANEL ──
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (_fetchError != null)
                                            _retryBanner(_fetchError!),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                    color:
                                                        Colors.grey.shade200),
                                              ),
                                            ),
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: TabBar(
                                              controller: _tabs,
                                              labelColor: _cardDarkBlue,
                                              unselectedLabelColor:
                                                  Colors.grey.shade500,
                                              indicatorColor: _cardDarkBlue,
                                              indicatorWeight: 3,
                                              dividerColor: Colors.transparent,
                                              labelStyle: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              unselectedLabelStyle:
                                                  const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                              tabs: const [
                                                Tab(
                                                  iconMargin: EdgeInsets.only(
                                                      bottom: 6),
                                                  icon: Icon(
                                                      Icons.school_outlined,
                                                      size: 20),
                                                  text: 'Academic Info',
                                                ),
                                                Tab(
                                                  iconMargin: EdgeInsets.only(
                                                      bottom: 6),
                                                  icon: Icon(
                                                      Icons.stars_outlined,
                                                      size: 20),
                                                  text: 'Skills & Profile',
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              color: Colors.white,
                                              child: TabBarView(
                                                controller: _tabs,
                                                children: [
                                                  _buildAcademicTab(user),
                                                  _buildSkillsTab(user),
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

  // ── LEFT PANEL ────────────────────────────────────────────────────────────

  Widget _buildLeftPanel(
    Map<String, dynamic>? user,
    String first,
    String last,
    String initials,
    String finalAvatarUrl,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardDarkBlue, _cardDarkerBlue],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 36, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 68,
                          backgroundColor: Colors.white.withOpacity(0.10),
                          backgroundImage: finalAvatarUrl.isNotEmpty
                              ? NetworkImage(finalAvatarUrl)
                              : null,
                          child: finalAvatarUrl.isEmpty
                              ? Text(
                                  initials.isEmpty ? '?' : initials,
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/edit-profile'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.edit_rounded,
                              color: _cardDarkBlue, size: 18),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Name ──────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      first.isEmpty && last.isEmpty
                          ? 'Name Not Set'
                          : '$first $last',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Email ─────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      user?['email'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Badge ─────────────────────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'INTERN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Divider(
                        color: Colors.white.withOpacity(0.10), height: 1),
                  ),

                  const SizedBox(height: 24),

                  // ── Quick-info tiles ──────────────────────────────────────
                  _QuickInfoTile(
                    icon: Icons.business_rounded,
                    label: 'Department',
                    value: _val(user, 'department'),
                  ),
                  const SizedBox(height: 16),
                  _QuickInfoTile(
                    icon: Icons.work_outline_rounded,
                    label: 'Position',
                    value: _val(user, 'position'),
                  ),
                  const SizedBox(height: 16),
                  _QuickInfoTile(
                    icon: Icons.school_rounded,
                    label: 'School',
                    value: _val(user, 'school'),
                  ),
                ],
              ),
            ),
          ),

          // ── Edit profile button ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/edit-profile'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _cardDarkBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Academic tab ──────────────────────────────────────────────────────────

  Widget _buildAcademicTab(Map<String, dynamic>? user) {
    final requiredHours = _requiredHours;

    String? computedEndDate;
    if (requiredHours != null && requiredHours > 0) {
      final startStr = user?['start_date']?.toString().trim() ?? '';
      if (startStr.isNotEmpty) {
        computedEndDate = _computeEstimatedEndDate(startStr, requiredHours);
      }
    }

    final displayedEndDate = _val(user, 'end_date');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
              title: 'Timeline & Hours', icon: Icons.schedule_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CleanInfoCard(
                  label: 'Internship Start',
                  value: _val(user, 'start_date'),
                  icon: Icons.event_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CleanInfoCard(
                  label: 'Internship End',
                  value: displayedEndDate,
                  icon: Icons.event_available_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CleanInfoCard(
                  label: 'Required OJT Hours',
                  value: requiredHours != null ? '$requiredHours hrs' : '—',
                  icon: Icons.hourglass_empty_rounded,
                ),
              ),
            ],
          ),
          if (computedEndDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estimated completion by $computedEndDate (based on $requiredHours hrs @ 8 hrs/day, Mon–Fri)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          _SectionTitle(title: 'Placement Details', icon: Icons.work_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CleanInfoCard(
                  label: 'Department',
                  value: _val(user, 'department'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CleanInfoCard(
                  label: 'Position',
                  value: _val(user, 'position'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CleanInfoCard(
                  label: 'Intern Number',
                  value: _val(user, 'intern_number'),
                  icon: Icons.badge_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SectionTitle(
              title: 'Academic Background', icon: Icons.school_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _CleanInfoCard(
                  label: 'School / University',
                  value: _val(user, 'school'),
                  icon: Icons.account_balance_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _CleanInfoCard(
                  label: 'Year Level',
                  value: _val(user, 'year_level'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CleanInfoCard(
                  label: 'Program / Course',
                  value: _val(user, 'program'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CleanInfoCard(
                  label: 'Specialization',
                  value: _val(user, 'specialization'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Skills tab ───────────────────────────────────────────────────────────

  Widget _buildSkillsTab(Map<String, dynamic>? user) {
    final techSkills = _val(user, 'technical_skills');
    final softSkills = _val(user, 'soft_skills');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'About Me', icon: Icons.person_rounded),
          const SizedBox(height: 12),
          _CleanInfoCard(
            label: 'Bio',
            value: _val(user, 'bio'),
            isMultiline: true,
          ),

          const SizedBox(height: 24),

          _SectionTitle(title: 'Expertise', icon: Icons.psychology_rounded),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SkillPanelClean(
                  label: 'Technical Skills',
                  raw: techSkills,
                  accentColor: Colors.blue.shade600,
                  bgColor: Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SkillPanelClean(
                  label: 'Soft Skills',
                  raw: softSkills,
                  accentColor: Colors.blue.shade600, // Changed to Blue
                  bgColor: Colors.blue.shade50,      // Changed to Blue
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SectionTitle(title: 'Links & Socials', icon: Icons.link_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CleanInfoCard(
                  label: 'LinkedIn URL',
                  value: _val(user, 'linked_in'),
                  icon: Icons.open_in_new_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CleanInfoCard(
                  label: 'GitHub URL',
                  value: _val(user, 'git_hub'),
                  icon: Icons.code_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _retryBanner(String msg) => Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.wifi_off_rounded, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style:
                      TextStyle(color: Colors.orange.shade900, fontSize: 12))),
          TextButton(
            onPressed: _fetchProfile,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
      );
}

// ── Shared UI Components ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _CleanInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isMultiline;

  const _CleanInfoCard({
    required this.label,
    required this.value,
    this.icon,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Very soft slate
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: isMultiline ? null : 1,
            overflow:
                isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              color: isEmpty ? Colors.grey.shade400 : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w400, // Reduced from w600
              height: isMultiline ? 1.5 : 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillPanelClean extends StatelessWidget {
  final String label;
  final String raw;
  final Color accentColor;
  final Color bgColor;

  const _SkillPanelClean({
    required this.label,
    required this.raw,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _CleanSkillChips(
              raw: raw, accentColor: accentColor, bgColor: bgColor),
        ],
      ),
    );
  }
}

class _CleanSkillChips extends StatelessWidget {
  final String raw;
  final Color accentColor;
  final Color bgColor;

  const _CleanSkillChips({
    required this.raw,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    if (raw == '—' || raw.trim().isEmpty) {
      return Text('—',
          style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.w400));
    }

    final skills =
        raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map((s) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _QuickInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blueAccent.shade100, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.60),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}