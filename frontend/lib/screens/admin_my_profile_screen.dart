import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_sidebar.dart';

const _kCrimson = Color(0xFF7B0D1E);

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
              color: Colors.white.withOpacity(0.8),
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

// ── Star Data Class for Galaxy Theme ─────────────────────────────────────────
class Star {
  final double x;
  final double y;
  final double size;
  final double baseOpacity;
  final double speed;
  final double twinklePhase;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseOpacity,
    required this.speed,
    required this.twinklePhase,
  });
}

class AdminMyProfileScreen extends StatefulWidget {
  const AdminMyProfileScreen({super.key});

  @override
  State<AdminMyProfileScreen> createState() => _AdminMyProfileScreenState();
}

class _AdminMyProfileScreenState extends State<AdminMyProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  final List<Star> _stars = [];
  bool _isSidebarOpen = true;

  @override
  void initState() {
    super.initState();
    _generateStars();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 150),
    )..repeat();
  }

  void _generateStars() {
    final random = math.Random();
    for (int i = 0; i < 200; i++) {
      _stars.add(Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2.0 + 0.5,
        baseOpacity: random.nextDouble() * 0.7 + 0.3,
        speed: random.nextDouble() * 0.05 + 0.01,
        twinklePhase: random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  // ── Animated Background ────────────────────────────────────────────────────
  Widget _buildAnimatedGalaxyBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.2),
          radius: 1.5,
          colors: [
            Color(0xFF3A0812),
            Color(0xFF140306),
            Color(0xFF050505),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          return CustomPaint(
            painter: StarfieldPainter(
              animationValue: _bgAnimController.value,
              stars: _stars,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?['role'] == 'admin';

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
        finalAvatarUrl = 'http://127.0.0.1:8080$rawAvatarUrl';
      } else {
        finalAvatarUrl = rawAvatarUrl;
      }
    }

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen ? AdminSidebar(
              currentRoute: '/admin/profile',
              onClose: () => setState(() => _isSidebarOpen = false),
            ) : null,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _buildAnimatedGalaxyBackground()),
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
                            Row(
                              children: [
                                if (!_isSidebarOpen) ...[
                                  Container(
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      padding: const EdgeInsets.all(12),
                                      onPressed: () => setState(() => _isSidebarOpen = true),
                                      icon: const HamburgerIcon(),
                                      tooltip: 'Open Sidebar',
                                      splashColor: Colors.white.withOpacity(0.1),
                                      highlightColor: Colors.transparent,
                                    ),
                                  ),
                                ],
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
                                  onPressed: () {
                                    context.go('/admin/account-settings');
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit Account',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _kCrimson,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Card(
                              elevation: 0,
                              color: Colors.white.withOpacity(0.95),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor:
                                          _kCrimson.withOpacity(0.1),
                                      backgroundImage: finalAvatarUrl.isNotEmpty
                                          ? NetworkImage(finalAvatarUrl)
                                          : null,
                                      child: finalAvatarUrl.isEmpty
                                          ? Text(
                                              initials,
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: _kCrimson,
                                                letterSpacing: 0.5,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            first.isEmpty && last.isEmpty
                                              ? 'Name Not Set'
                                              : '$first $last',
                                            style: const TextStyle(
                                                fontSize: 22,
                                                letterSpacing: 0.5,
                                                fontWeight: FontWeight.w800),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user?['email'] ?? '',
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              _Badge(
                                                label: (user?['role'] ?? 'user')
                                                    .toUpperCase(),
                                                color: isAdmin
                                                    ? Colors.red.shade700
                                                    : _kCrimson,
                                                bg: isAdmin
                                                    ? Colors.red.shade50
                                                    : _kCrimson.withOpacity(
                                                        0.08),
                                              ),
                                              _Badge(
                                                label: (user?['is_active'] == true)
                                                    ? 'ACTIVE'
                                                    : 'INACTIVE',
                                                color: (user?['is_active'] == true)
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
                            Expanded(
                              child: Card(
                                elevation: 0,
                                color: Colors.white.withOpacity(0.95),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Internship Information',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: _kCrimson),
                                        ),
                                        const SizedBox(height: 24),
                                        _infoRow(context, [
                                          _Field('Name', first.isEmpty && last.isEmpty ? '—' : '$first $last'),
                                          _Field('Intern Number', user?['intern_number'] ?? '—'),
                                        ]),
                                        const SizedBox(height: 20),
                                        _infoRow(context, [
                                          _Field('Program', user?['program'] ?? '—'),
                                          _Field('School', user?['school'] ?? '—'),
                                        ]),
                                        const SizedBox(height: 20),
                                        _infoRow(context, [
                                          _Field('Specialization', user?['specialization'] ?? '—'),
                                          _Field('Email', user?['email'] ?? '—'),
                                        ]),
                                        const SizedBox(height: 24),
                                        const Divider(),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Skills & Proficiencies',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: _kCrimson),
                                        ),
                                        const SizedBox(height: 20),
                                        _infoRow(context, [
                                          _Field('Technical Skills', user?['technical_skills'] ?? '—'),
                                        ]),
                                        const SizedBox(height: 20),
                                        _infoRow(context, [
                                          _Field('Soft Skills', user?['soft_skills'] ?? '—'),
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
            ),
          ),
        ],
      ),
    );
  }

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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(16)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: color)),
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
          Text(field.label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(field.value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      );
}

// ── Custom Painter for Starfield ─────────────────────────────────────────────
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  StarfieldPainter({required this.animationValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var star in stars) {
      double twinkle = (math.sin((animationValue * 2 * math.pi * 1.5) + star.twinklePhase) + 1.0) / 2.0;
      double currentOpacity = star.baseOpacity * (0.3 + (0.7 * twinkle));
     
      paint.color = Colors.white.withOpacity(currentOpacity.clamp(0.0, 1.0));

      double dx = (star.x * size.width + (animationValue * size.width * star.speed)) % size.width;
      double dy = star.y * size.height;

      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(currentOpacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawCircle(Offset(dx, dy), star.size * 2, glowPaint);
      }

      canvas.drawCircle(Offset(dx, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
