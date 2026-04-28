import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../services/api_service.dart';

// ── Brand colors ──────────────────────────────────────────────────────────────
const kBlue = Color(0xFF1E40AF);
const kBlueDark = Color(0xFF1E2A44);
const kBlueLight = Color(0xFF3B82F6);

class InternProfile {
  final int id;
  final String name;
  final String internNumber;
  final String program;
  final String school;
  final String specialization;
  final String email;
  final List<String> technicalSkills;
  final List<String> softSkills;
  final String? avatarUrl;

  const InternProfile({
    required this.id,
    required this.name,
    required this.internNumber,
    required this.program,
    required this.school,
    required this.specialization,
    required this.email,
    required this.technicalSkills,
    required this.softSkills,
    this.avatarUrl,
  });

  /// Derived — no longer stored, always computed from name
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Deterministic color from id so each intern always gets the same color
  Color get avatarColor {
    const colors = [
      Color(0xFF7B1A2E),
      Color(0xFF4A1040),
      Color(0xFF1A1050),
      Color(0xFF2A3A1A),
      Color(0xFF3A2A10),
      Color(0xFF0A3A3A),
    ];
    return colors[id % colors.length];
  }

  factory InternProfile.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] ?? '').toString().trim();
    final lastName = (json['last_name'] ?? '').toString().trim();
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    // Helper to safely parse a JSON array of strings
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      // Some APIs return a comma-separated string instead of an array
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((s) => s.trim()).toList();
      }
      return [];
    }

    return InternProfile(
      id: json['id'] as int,
      name: fullName.isNotEmpty ? fullName : 'Unnamed Intern',
      internNumber: json['intern_number'] as String? ?? 'N/A',
      program: (json['program'] ?? '').toString().trim().isNotEmpty
          ? json['program']
          : 'N/A',
      school: (json['school'] ?? '').toString().trim().isNotEmpty
          ? json['school']
          : 'N/A', // ← was hardcoded ''
      specialization:
          (json['specialization'] ?? '').toString().trim().isNotEmpty
              ? json['specialization']
              : 'N/A',
      email: json['email'] ?? '',
      technicalSkills:
          parseStringList(json['technical_skills']), // ← was hardcoded []
      softSkills: parseStringList(json['soft_skills']), // ← was hardcoded []
      avatarUrl: json['avatar_url'],
    );
  }
}

// ── Avatar widget: real photo or initials fallback ────────────────────────────

class InternAvatar extends StatelessWidget {
  final InternProfile intern;
  final double size;
  final double borderRadius;
  final double fontSize;

  const InternAvatar({
    super.key,
    required this.intern,
    this.size = 140,
    this.borderRadius = 32,
    this.fontSize = 54,
  });

  /// Resolves a raw avatar path into a full URL, matching the logic in
  /// UserAvatar so both widgets behave identically.
  String? get _resolvedAvatarUrl {
    final raw = intern.avatarUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    // Already absolute — use as-is
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    // Strip /api suffix from baseUrl to reach the server root
    // e.g. "http://localhost:8080/api" → "http://localhost:8080"
    final serverRoot = ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '');

    // Handle both "uploads/abc.jpg" and "/uploads/abc.jpg"
    final cleanRaw = raw.startsWith('/') ? raw.substring(1) : raw;
    final resolved = '$serverRoot/$cleanRaw';

    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedAvatarUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, error, __) {
                debugPrint('❌ InternAvatar load failed for $url — $error');
                return _InitialsFallback(
                  initials: intern.initials,
                  color: intern.avatarColor,
                  fontSize: fontSize,
                );
              },
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFF7B1A2E),
                    strokeWidth: 2,
                  ),
                );
              },
            )
          : _InitialsFallback(
              initials: intern.initials,
              color: intern.avatarColor,
              fontSize: fontSize,
            ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  final String initials;
  final Color color;
  final double fontSize;

  const _InitialsFallback({
    required this.initials,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
// ── Detail Page ───────────────────────────────────────────────────────────────

class InternDetailPage extends StatefulWidget {
  final InternProfile intern;
  const InternDetailPage({super.key, required this.intern});

  @override
  State<InternDetailPage> createState() => _InternDetailPageState();
}

class _InternDetailPageState extends State<InternDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  final List<DetailStar> _stars = [];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    final rng = math.Random();
    for (int i = 0; i < 160; i++) {
      _stars.add(DetailStar(
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
          // Starfield background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/space_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, __) => CustomPaint(
                  painter: StarfieldPainter(
                    animValue: _bgController.value,
                    stars: _stars,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // ── Equal padding on all four sides ──────────────────────────
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: double.infinity,
                      // ── Wider max width ───────────────────────────────────
                      constraints: const BoxConstraints(maxWidth: 1100),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, top: 16),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new,
                                    color: Colors.white70),
                                onPressed: () => Navigator.of(context).pop(),
                                splashRadius: 24,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                // Avatar with Hero
                                Hero(
                                  tag: 'intern-${intern.id}',
                                  child: InternAvatar(
                                    intern: intern,
                                    size: 160,
                                    borderRadius: 40,
                                    fontSize: 64,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  intern.name,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  intern.internNumber != 'N/A'
                                      ? 'Intern #${intern.internNumber}'
                                      : '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _InfoRow(
                                  icon: Icons.school,
                                  label: 'Program',
                                  value: intern.program.isNotEmpty
                                      ? intern.program
                                      : 'N/A',
                                ),
                                _InfoRow(
                                  icon: Icons.work,
                                  label: 'Specialization',
                                  value: intern.specialization,
                                ),
                                _InfoRow(
                                  icon: Icons.location_city,
                                  label: 'School',
                                  value: intern.school.isNotEmpty
                                      ? intern.school
                                      : 'N/A',
                                ),
                                _InfoRow(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: intern.email.isNotEmpty
                                      ? intern.email
                                      : 'N/A',
                                ),
                                if (intern.technicalSkills.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Technical Skills',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: intern.technicalSkills
                                          .map((s) => _SkillChip(s))
                                          .toList(),
                                    ),
                                  ),
                                ],
                                if (intern.softSkills.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Soft Skills',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: intern.softSkills
                                          .map((s) => _SkillChip(s))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: Colors.white.withValues(alpha: 0.8), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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

class _SkillChip extends StatelessWidget {
  final String skill;
  const _SkillChip(this.skill);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Starfield ─────────────────────────────────────────────────────────────────

class DetailStar {
  final double x, y, size, opacity, speed, phase;
  const DetailStar({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.phase,
  });
}

class StarfieldPainter extends CustomPainter {
  final double animValue;
  final List<DetailStar> stars;
  StarfieldPainter({required this.animValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final twinkle =
          (math.sin((animValue * 2 * math.pi * 1.5) + star.phase) + 1) / 2;
      final alpha = (star.opacity * (0.3 + 0.7 * twinkle)).clamp(0.0, 1.0);
      paint.color = Colors.white.withValues(alpha: alpha);
      final dx = (star.x * size.width + animValue * size.width * star.speed) %
          size.width;
      final dy = star.y * size.height;
      if (star.size > 1.5) {
        canvas.drawCircle(
          Offset(dx, dy),
          star.size * 2,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      canvas.drawCircle(Offset(dx, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter old) => old.animValue != animValue;
}