import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_layout.dart';
import '../services/api_service.dart';

const _kBlue = Color(0xFF00022E);

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _loading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    // Always fetch fresh data from the server on every screen load.
    // Never rely solely on the AuthProvider in-memory cache — it may be
    // empty or stale after a sign-out / sign-in cycle.
    _fetchProfile();
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

      // Accept the response only when it carries a real user id.
      if (res['id'] != null) {
        await context
            .read<AuthProvider>()
            .updateUserData(Map<String, dynamic>.from(res));
        if (mounted) setState(() => _loading = false);
      } else if (res['ok'] == true && res['data'] != null) {
        // Handle backends that wrap the user in { ok: true, data: {...} }
        await context.read<AuthProvider>().updateUserData(
            Map<String, dynamic>.from(res['data'] as Map<String, dynamic>));
        if (mounted) setState(() => _loading = false);
      } else {
        // Server returned something unexpected — surface the error.
        if (mounted) {
          setState(() {
            _loading = false;
            _fetchError =
                'Could not load your profile from the server. '
                'Showing cached data.';
          });
        }
      }
    } catch (e) {
      debugPrint('MyProfileScreen _fetchProfile error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _fetchError =
              'Network error. Check your connection and tap Retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserLayout(
      currentRoute: '/profile',
      child: _buildProfileContent(context),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    // After _fetchProfile() finishes it calls updateUserData(), which
    // triggers a notifyListeners() in AuthProvider, so watch() will rebuild
    // with fresh data automatically.
    final user = context.watch<AuthProvider>().user;

    final first = user?['first_name'] as String? ?? '';
    final last = user?['last_name'] as String? ?? '';
    String initials = '';
    if (first.isNotEmpty) initials += first[0];
    if (last.isNotEmpty) initials += last[0];

    // Avatar URL helper logic
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

    return Stack(
      children: [
        // ── Background ──────────────────────────────────────────────────────
        Positioned.fill(
          child: Image.asset(
            'assets/images/space_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.black),
          ),
        ),

        // ── Content ─────────────────────────────────────────────────────────
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ───────────────────────────────────────────────
                    Row(
                      children: [
                        Text(
                          'My Profile',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/edit-profile'),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _kBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Fetch-error / retry banner ────────────────────────────
                    if (_fetchError != null) _retryBanner(_fetchError!),
                    if (_fetchError != null) const SizedBox(height: 12),

                    // ── Avatar + name card ────────────────────────────────────
                    Card(
                      elevation: 0,
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Show a small spinner inside the avatar while loading
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: _kBlue.withOpacity(0.1),
                              backgroundImage: (!_loading &&
                                      finalAvatarUrl.isNotEmpty)
                                  ? NetworkImage(finalAvatarUrl)
                                  : null,
                              child: _loading
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: _kBlue),
                                    )
                                  : (finalAvatarUrl.isEmpty
                                      ? Text(
                                          initials.isEmpty ? '?' : initials,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: _kBlue,
                                            letterSpacing: 0.5,
                                          ),
                                        )
                                      : null),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _loading
                                        ? '…'
                                        : (first.isEmpty && last.isEmpty
                                            ? 'Name Not Set'
                                            : '$first $last'),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _loading ? '' : (user?['email'] ?? ''),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (!_loading)
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        _Badge(
                                          label: 'USER',
                                          color: _kBlue,
                                          bg: _kBlue.withOpacity(0.08),
                                        ),
                                        _Badge(
                                          label: (user?['is_active'] == true)
                                              ? 'ACTIVE'
                                              : 'INACTIVE',
                                          color:
                                              (user?['is_active'] == true)
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                          bg: (user?['is_active'] == true)
                                              ? Colors.green.shade50
                                              : Colors.orange.shade50,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Main info card ────────────────────────────────────────
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: Colors.white.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(color: _kBlue))
                            : SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 32),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Internship Information',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _kBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _infoRow(context, [
                                        _Field(
                                            'Name',
                                            first.isEmpty && last.isEmpty
                                                ? '—'
                                                : '$first $last'),
                                        _Field('Intern Number',
                                            _val(user, 'intern_number')),
                                      ]),
                                      const SizedBox(height: 20),
                                      _infoRow(context, [
                                        _Field('Department',
                                            _val(user, 'department')),
                                        _Field('Position',
                                            _val(user, 'position')),
                                      ]),
                                      const SizedBox(height: 20),
                                      _infoRow(context, [
                                        _Field(
                                            'Program', _val(user, 'program')),
                                        _Field('School', _val(user, 'school')),
                                      ]),
                                      const SizedBox(height: 20),
                                      _infoRow(context, [
                                        _Field('Specialization',
                                            _val(user, 'specialization')),
                                        _Field('Year Level',
                                            _val(user, 'year_level')),
                                      ]),
                                      const SizedBox(height: 20),
                                      _infoRow(context, [
                                        _Field('Internship Start',
                                            _val(user, 'start_date')),
                                        _Field('Internship End',
                                            _val(user, 'end_date')),
                                      ]),
                                      const SizedBox(height: 20),
                                      _infoRow(context, [
                                        _Field(
                                            'Email', _val(user, 'email')),
                                      ]),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Skills & Profile',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _kBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _infoRow(context, [
                                        _Field('Bio', _val(user, 'bio')),
                                      ]),
                                      const SizedBox(height: 20),
                                      _infoRow(context, [
                                        _Field('Technical Skills',
                                            _val(user, 'technical_skills')),
                                      ]),
                                      const SizedBox(height: 20),
                                      _infoRow(context, [
                                        _Field('Soft Skills',
                                            _val(user, 'soft_skills')),
                                      ]),
                                      const SizedBox(height: 20),
                                      _infoRow(context, [
                                        _Field('LinkedIn',
                                            _val(user, 'linked_in')),
                                        _Field(
                                            'GitHub', _val(user, 'git_hub')),
                                      ]),
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
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Safe field reader — returns '—' instead of null/empty string.
  String _val(Map<String, dynamic>? user, String key) {
    final v = user?[key];
    if (v == null) return '—';
    final s = v.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  Widget _retryBanner(String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
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
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
      );

  Widget _infoRow(BuildContext context, List<_Field> fields) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 400) {
        final rowChildren = <Widget>[];
        for (int i = 0; i < fields.length; i++) {
          rowChildren.add(Expanded(child: _FieldTile(fields[i])));
          if (i < fields.length - 1) {
            rowChildren.add(const SizedBox(width: 24));
          }
        }
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FieldTile(f),
                ))
            .toList(),
      );
    });
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: color,
          ),
        ),
      );
}

class _Field {
  final String label;
  final String value;
  const _Field(this.label, this.value);
}

class _FieldTile extends StatelessWidget {
  final _Field field;
  const _FieldTile(this.field);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            field.value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      );
}