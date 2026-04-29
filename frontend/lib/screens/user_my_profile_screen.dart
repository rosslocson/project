import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_sidebar.dart';
import '../widgets/app_theme.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
      final res = await ApiService.getProfile();
      if (!mounted) return;

      if (res['id'] != null) {
        await context
            .read<AuthProvider>()
            .updateUserData(Map<String, dynamic>.from(res));
        if (mounted) setState(() => _loading = false);
      } else if (res['ok'] == true && res['data'] != null) {
        await context.read<AuthProvider>().updateUserData(
            Map<String, dynamic>.from(res['data'] as Map<String, dynamic>));
        if (mounted) setState(() => _loading = false);
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _fetchError =
                'Could not load your profile from the server. Showing cached data.';
          });
        }
      }
    } catch (e) {
      debugPrint('MyProfileScreen _fetchProfile error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _fetchError = 'Network error. Check your connection and tap Retry.';
        });
      }
    }
  }

  String _val(Map<String, dynamic>? user, String key) {
    final v = user?[key];
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
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
        finalAvatarUrl =
            '${Uri.parse(ApiService.baseUrl).replace(queryParameters: null).toString().replaceAll('/api', '')}$rawAvatarUrl';
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
            child: Stack(
              children: [
                // Background
                Positioned.fill(
                  child: Container(
                    decoration: AppTheme.spaceBackground,
                  ),
                ),

                Positioned.fill(
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
                                        color: Colors.white.withOpacity(0.15)),
                                  ),
                                  child: IconButton(
                                    padding: const EdgeInsets.all(12),
                                    onPressed: () =>
                                        setState(() => _isSidebarOpen = true),
                                    icon: const HamburgerIcon(),
                                    tooltip: 'Open Sidebar',
                                    splashColor: Colors.white.withOpacity(0.1),
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
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 40,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _loading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: kCrimsonDeep))
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // ── LEFT PANEL: Avatar + Identity ──
                                        _buildLeftPanel(
                                          user,
                                          first,
                                          last,
                                          initials,
                                          finalAvatarUrl,
                                        ),

                                        // ── RIGHT PANEL: Tabs + Content ───
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // Error banner
                                              if (_fetchError != null)
                                                _retryBanner(_fetchError!),

                                              // Tabs
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                        color: Colors
                                                            .grey.shade200),
                                                  ),
                                                ),
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: TabBar(
                                                  controller: _tabs,
                                                  labelColor: Colors.black,
                                                  unselectedLabelColor:
                                                      Colors.grey.shade500,
                                                  indicatorColor: kCrimsonDeep,
                                                  indicatorWeight: 3,
                                                  dividerColor:
                                                      Colors.transparent,
                                                  tabs: const [
                                                    Tab(
                                                      iconMargin:
                                                          EdgeInsets.only(
                                                              bottom: 4),
                                                      icon: Icon(
                                                          Icons.school_outlined,
                                                          size: 18),
                                                      text: 'Academic Info',
                                                    ),
                                                    Tab(
                                                      iconMargin:
                                                          EdgeInsets.only(
                                                              bottom: 4),
                                                      icon: Icon(
                                                          Icons.stars_outlined,
                                                          size: 18),
                                                      text: 'Skills & Profile',
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Tab content
                                              Expanded(
                                                child: TabBarView(
                                                  controller: _tabs,
                                                  children: [
                                                    _buildAcademicTab(user),
                                                    _buildSkillsTab(user),
                                                  ],
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
              ],
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
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kCrimsonDeep,
            const Color(0xFF00022E),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 36),

          // ── Avatar ──────────────────────────────────────────────
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.10),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 72,
                  backgroundColor: Colors.white.withOpacity(0.12),
                  backgroundImage: finalAvatarUrl.isNotEmpty
                      ? NetworkImage(finalAvatarUrl)
                      : null,
                  child: finalAvatarUrl.isEmpty
                      ? Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        )
                      : null,
                ),
              ),
              // Edit avatar button
              GestureDetector(
                onTap: () => context.go('/edit-profile'),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: kCrimsonDeep,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Name ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              first.isEmpty && last.isEmpty ? 'Name Not Set' : '$first $last',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ── Email ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              user?['email'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Text(
              'INTERN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Divider ───────────────────────────────────────────────
          Divider(
            color: Colors.white.withOpacity(0.15),
            height: 1,
            indent: 28,
            endIndent: 28,
          ),

          const SizedBox(height: 24),

          // ── Quick-info tiles ──────────────────────────────────────
          _QuickInfoTile(
            icon: Icons.business_rounded,
            label: 'Department',
            value: _val(user, 'department'),
          ),
          const SizedBox(height: 14),
          _QuickInfoTile(
            icon: Icons.work_outline_rounded,
            label: 'Position',
            value: _val(user, 'position'),
          ),
          const SizedBox(height: 14),
          _QuickInfoTile(
            icon: Icons.school_rounded,
            label: 'School',
            value: _val(user, 'school'),
          ),
          const SizedBox(height: 14),
          _QuickInfoTile(
            icon: Icons.badge_rounded,
            label: 'Intern No.',
            value: _val(user, 'intern_number'),
          ),

          const Spacer(),

          // ── Edit profile button ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/edit-profile'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kCrimsonDeep,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Academic tab ─────────────────────────────────────────────────────────

  Widget _buildAcademicTab(Map<String, dynamic>? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ReadonlyField(
                  label: 'Department',
                  value: _val(user, 'department'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ReadonlyField(
                  label: 'Position',
                  value: _val(user, 'position'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ReadonlyField(
            label: 'School / University',
            value: _val(user, 'school'),
          ),
          const SizedBox(height: 16),
          _ReadonlyField(
            label: 'Program / Course',
            value: _val(user, 'program'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReadonlyField(
                  label: 'Specialization',
                  value: _val(user, 'specialization'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ReadonlyField(
                  label: 'Year Level',
                  value: _val(user, 'year_level'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ReadonlyField(
            label: 'Intern Number',
            value: _val(user, 'intern_number'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReadonlyField(
                  label: 'Internship Start',
                  value: _val(user, 'start_date'),
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ReadonlyField(
                  label: 'Internship End',
                  value: _val(user, 'end_date'),
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ReadonlyField(
            label: 'Email',
            value: _val(user, 'email'),
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
          _ReadonlyField(
            label: 'Bio',
            value: _val(user, 'bio'),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _label('Technical Skills'),
          _SkillChips(raw: techSkills, color: kCrimsonDeep),
          const SizedBox(height: 16),
          _label('Soft Skills'),
          _SkillChips(raw: softSkills, color: const Color(0xFF00022E)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReadonlyField(
                  label: 'LinkedIn URL',
                  value: _val(user, 'linked_in'),
                  icon: Icons.link,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ReadonlyField(
                  label: 'GitHub URL',
                  value: _val(user, 'git_hub'),
                  icon: Icons.link,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      );

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

// ── Quick Info Tile (used in left panel) ──────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.50),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.90),
                  ),
                  maxLines: 2,
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

// ── Read-only field ───────────────────────────────────────────────────────────

class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  final IconData? icon;

  const _ReadonlyField({
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isEmpty ? Colors.grey.shade400 : Colors.black,
                    fontSize: 14,
                    fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: Colors.grey.shade400),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Skill chips ───────────────────────────────────────────────────────────────

class _SkillChips extends StatelessWidget {
  final String raw;
  final Color color;

  const _SkillChips({required this.raw, required this.color});

  @override
  Widget build(BuildContext context) {
    if (raw == '—' || raw.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text('—',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w400)),
      );
    }

    final skills =
        raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills
            .map((s) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
