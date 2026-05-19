import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../intern_cards.dart';
import '../../widgets/app_background.dart';

// ── ROSALYN LOCSON PROFILE PAGE — SPACE THEME (Two-Column) ───────────────────
//
// Layout: two-column glass card over animated space background.
//   Left panel  — Avatar, Name, Intern #, Bio (no label), Connect with Me
//   Right panel — Academic Profile + Deployment Data + Technical Skills + Soft Skills

// ─────────────────────────────────────────────────────────────────────────────
// SPACE BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, size, opacity, twinkleSeed;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.twinkleSeed,
  });
}

class _SpacePainter extends CustomPainter {
  final List<_Star> stars;
  final double time;
  _SpacePainter({required this.stars, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    _nebulae(canvas, size);
    _drawStars(canvas, size);
  }

  void _nebulae(Canvas canvas, Size size) {
    final clouds = [
      (cx: 0.55, cy: 0.68, rx: 0.38, ry: 0.26, c: const Color(0xFF2D0B5A), o: 0.38),
      (cx: 0.38, cy: 0.74, rx: 0.26, ry: 0.20, c: const Color(0xFF0B1A4A), o: 0.42),
      (cx: 0.62, cy: 0.58, rx: 0.22, ry: 0.16, c: const Color(0xFF3B0A6A), o: 0.26),
      (cx: 0.20, cy: 0.50, rx: 0.22, ry: 0.18, c: const Color(0xFF08103A), o: 0.50),
      (cx: 0.80, cy: 0.35, rx: 0.28, ry: 0.22, c: const Color(0xFF1A0840), o: 0.30),
      (cx: 0.10, cy: 0.30, rx: 0.18, ry: 0.22, c: const Color(0xFF1E0A40), o: 0.28),
      (cx: 0.90, cy: 0.70, rx: 0.18, ry: 0.22, c: const Color(0xFF0A1830), o: 0.32),
    ];
    for (final n in clouds) {
      final rect = Rect.fromCenter(
        center: Offset(n.cx * size.width, n.cy * size.height),
        width: n.rx * size.width * 2,
        height: n.ry * size.height * 2,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [n.c.withOpacity(n.o), Colors.transparent],
          ).createShader(rect)
          ..blendMode = BlendMode.screen,
      );
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    for (final s in stars) {
      final twinkle =
          0.65 + 0.35 * math.sin(time * 1.1 + s.twinkleSeed * math.pi * 2);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()
          ..color = Colors.white.withOpacity(s.opacity * twinkle)
          ..maskFilter = s.size > 1.4
              ? MaskFilter.blur(BlurStyle.normal, s.size * 0.5)
              : null,
      );
    }
  }

  @override
  bool shouldRepaint(_SpacePainter old) => old.time != time;
}

class SpaceBackground extends StatefulWidget {
  final Widget child;
  const SpaceBackground({super.key, required this.child});

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _stars = List.generate(340, (_) {
      final sz = rng.nextDouble();
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: sz < 0.70
            ? 0.3 + rng.nextDouble() * 0.5
            : sz < 0.92
                ? 0.9 + rng.nextDouble() * 0.8
                : 1.8 + rng.nextDouble() * 1.0,
        opacity: 0.25 + rng.nextDouble() * 0.70,
        twinkleSeed: rng.nextDouble(),
      );
    });
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000008),
                Color(0xFF04061A),
                Color(0xFF080320),
                Color(0xFF050218),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
        ),
        CustomPaint(
          painter: _SpacePainter(stars: _stars, time: _ctrl.value * 60),
          child: const SizedBox.expand(),
        ),
        widget.child,
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kPurple      = Color(0xFF7C3AED);
const _kPurpleGlow  = Color(0xFF6D28D9);
const _kPurpleLight = Color(0xFFDDD6FE);
const _kInkDeep     = Color(0xFF07091C);
const _kBorderMid   = Color(0xFF2E2750);
const _kAccent      = Color(0xFF9370DB);

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────

class RosalynProfilePage extends StatelessWidget {
  final InternProfile intern;
  const RosalynProfilePage({super.key, required this.intern});

  static const String _fallbackUrl = 'https://yourcompanysite.com';

  Future<void> _launch(String? url) async {
    final t = (url == null || url.isEmpty) ? _fallbackUrl : url;
    final uri = Uri.parse(t);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: SpaceBackground(
          child: Container(
            color: Colors.black.withValues(alpha: 0.28),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: 20,
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    child: isDesktop
                        ? _TwoColumnCard(
                            intern: intern,
                            onEmail: () => _launchEmail(intern.email),
                            onGitHub: () => _launch(intern.githubUrl),
                            onLinkedIn: () => _launch(intern.linkedInUrl),
                          )
                        : _MobileCard(
                            intern: intern,
                            onEmail: () => _launchEmail(intern.email),
                            onGitHub: () => _launch(intern.githubUrl),
                            onLinkedIn: () => _launch(intern.linkedInUrl),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TWO-COLUMN CARD (desktop)
// Left: flex 4 (narrower) — avatar, name, bio, connect
// Right: flex 6 (wider)   — academic + deployment + skills
// ─────────────────────────────────────────────────────────────────────────────

class _TwoColumnCard extends StatelessWidget {
  final InternProfile intern;
  final VoidCallback onEmail;
  final VoidCallback onGitHub;
  final VoidCallback onLinkedIn;

  const _TwoColumnCard({
    required this.intern,
    required this.onEmail,
    required this.onGitHub,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            // Wider max width, no minHeight — let content drive height
            constraints: const BoxConstraints(maxWidth: 980),
            decoration: BoxDecoration(
              color: _kInkDeep.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: _kPurple.withValues(alpha: 0.28), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 60,
                  spreadRadius: 4,
                  offset: const Offset(0, 24),
                ),
                BoxShadow(
                  color: _kPurpleGlow.withValues(alpha: 0.18),
                  blurRadius: 100,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── LEFT PANEL — narrower (flex 4) ────────────────────
                  Expanded(
                    flex: 4,
                    child: _LeftPanel(
                      intern: intern,
                      onEmail: onEmail,
                      onGitHub: onGitHub,
                      onLinkedIn: onLinkedIn,
                    ),
                  ),

                  // vertical divider
                  _VerticalDivider(),

                  // ── RIGHT PANEL — wider (flex 6) ──────────────────────
                  Expanded(
                    flex: 6,
                    child: _RightPanel(intern: intern),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MobileCard extends StatelessWidget {
  final InternProfile intern;
  final VoidCallback onEmail;
  final VoidCallback onGitHub;
  final VoidCallback onLinkedIn;

  const _MobileCard({
    required this.intern,
    required this.onEmail,
    required this.onGitHub,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            decoration: BoxDecoration(
              color: _kInkDeep.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: _kPurple.withValues(alpha: 0.25), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 60,
                  spreadRadius: 4,
                  offset: const Offset(0, 24),
                ),
                BoxShadow(
                  color: _kPurpleGlow.withValues(alpha: 0.18),
                  blurRadius: 100,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroSection(intern: intern),
                _GlowDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bio — no label, centered
                      Center(child: _AboutBlock(bio: intern.bio)),
                      _Divider(),
                      _SectionHeader(
                          icon: Icons.people_alt_outlined,
                          label: 'Connect with Me'),
                      const SizedBox(height: 12),
                      Center(
                        child: _ConnectRow(
                          intern: intern,
                          onEmail: onEmail,
                          onGitHub: onGitHub,
                          onLinkedIn: onLinkedIn,
                        ),
                      ),
                      _Divider(),
                      _SectionHeader(
                          icon: Icons.school_outlined,
                          label: 'Academic Profile'),
                      const SizedBox(height: 12),
                      _AcademicProfileBlock(intern: intern),
                      _Divider(),
                      _SectionHeader(
                          icon: Icons.location_on_outlined,
                          label: 'Deployment Data'),
                      const SizedBox(height: 12),
                      _DeploymentBlock(intern: intern),
                      if (intern.technicalSkills.isNotEmpty) ...[
                        _Divider(),
                        _SectionHeader(
                            icon: Icons.code_rounded,
                            label: 'Technical Skills'),
                        const SizedBox(height: 10),
                        _SkillChips(
                            skills: intern.technicalSkills, isTech: true),
                      ],
                      if (intern.softSkills.isNotEmpty) ...[
                        _Divider(),
                        _SectionHeader(
                            icon: Icons.psychology_outlined,
                            label: 'Soft Skills'),
                        const SizedBox(height: 10),
                        _SkillChips(
                            skills: intern.softSkills, isTech: false),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT PANEL
// — Centered: Avatar, Name, Position, ID Badge, Bio (no label), Connect
// ─────────────────────────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final InternProfile intern;
  final VoidCallback onEmail;
  final VoidCallback onGitHub;
  final VoidCallback onLinkedIn;

  const _LeftPanel({
    required this.intern,
    required this.onEmail,
    required this.onGitHub,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kPurple.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
        borderRadius:
            const BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar (slightly bigger: 126px) ───────────────────────────
          _AvatarRing(intern: intern),
          const SizedBox(height: 16),

          // ── Name ──────────────────────────────────────────────────────
          Text(
            intern.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),

          // ── Position subtitle ─────────────────────────────────────────
          if (intern.position?.isNotEmpty ?? false)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_history_outlined,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.45)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    intern.position!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.55),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // ── ID Badge ──────────────────────────────────────────────────
          if (intern.internNumber != 'N/A')
            _IdBadge(number: intern.internNumber),

          const SizedBox(height: 20),
          _GlowDivider(),
          const SizedBox(height: 20),

          // ── Bio — no label header, centered ──────────────────────────
          _AboutBlock(bio: intern.bio),

          const SizedBox(height: 20),

          // ── Connect with Me — label + centered chips ──────────────────
          _SectionHeader(
              icon: Icons.people_alt_outlined, label: 'Connect with Me'),
          const SizedBox(height: 12),
          Center(
            child: _ConnectRow(
              intern: intern,
              onEmail: onEmail,
              onGitHub: onGitHub,
              onLinkedIn: onLinkedIn,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL — Academic Profile + Deployment Data + Skills
// ─────────────────────────────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  final InternProfile intern;
  const _RightPanel({required this.intern});

  @override
  Widget build(BuildContext context) {
    final safeStart = (intern.startDate == null ||
            intern.startDate.toString().isEmpty ||
            intern.startDate.toString() == 'null')
        ? 'TBA'
        : intern.startDate.toString();
    final safeEnd = (intern.endDate == null ||
            intern.endDate.toString().isEmpty ||
            intern.endDate.toString() == 'null')
        ? 'TBA'
        : intern.endDate.toString();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _kPurple.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
        borderRadius:
            const BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top accent strip ──────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              height: 2,
              width: 48,
              decoration: BoxDecoration(
                color: _kAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── ACADEMIC PROFILE ──────────────────────────────────────────
          _SectionHeader(
              icon: Icons.school_outlined, label: 'Academic Profile'),
          const SizedBox(height: 14),
          _AcademicProfileBlock(intern: intern),

          _Divider(),

          // ── DEPLOYMENT DATA ───────────────────────────────────────────
          _SectionHeader(
              icon: Icons.location_on_outlined, label: 'Deployment Data'),
          const SizedBox(height: 14),
          _DeploymentBlock(intern: intern, safeStart: safeStart, safeEnd: safeEnd),

          // ── TECHNICAL SKILLS ──────────────────────────────────────────
          if (intern.technicalSkills.isNotEmpty) ...[
            _Divider(),
            _SectionHeader(
                icon: Icons.code_rounded, label: 'Technical Skills'),
            const SizedBox(height: 12),
            _SkillChips(skills: intern.technicalSkills, isTech: true),
          ],

          // ── SOFT SKILLS ───────────────────────────────────────────────
          if (intern.softSkills.isNotEmpty) ...[
            _Divider(),
            _SectionHeader(
                icon: Icons.psychology_outlined, label: 'Soft Skills'),
            const SizedBox(height: 12),
            _SkillChips(skills: intern.softSkills, isTech: false),
          ],

          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACADEMIC PROFILE BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _AcademicProfileBlock extends StatelessWidget {
  final InternProfile intern;
  const _AcademicProfileBlock({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailItem(
          label: 'INSTITUTION',
          value: intern.school.isNotEmpty ? intern.school : '—',
        ),
        const SizedBox(height: 12),
        _DetailItem(
          label: 'PROGRAM',
          value: intern.program.isNotEmpty ? intern.program : '—',
        ),
        const SizedBox(height: 12),
        _DetailItem(
          label: 'SPECIALIZATION',
          value: (intern.specialization?.isNotEmpty == true)
              ? intern.specialization!
              : '—',
        ),
        const SizedBox(height: 12),
        _DetailItem(
          label: 'YEAR LEVEL',
          value: intern.yearLevel ?? '—',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEPLOYMENT BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _DeploymentBlock extends StatelessWidget {
  final InternProfile intern;
  final String safeStart;
  final String safeEnd;

  const _DeploymentBlock({
    required this.intern,
    this.safeStart = 'TBA',
    this.safeEnd = 'TBA',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailItem(
          label: 'DEPARTMENT',
          value: (intern.department?.isNotEmpty == true)
              ? intern.department!
              : '—',
        ),
        const SizedBox(height: 12),
        _DetailItem(
          label: 'DESIGNATION',
          value: (intern.position?.isNotEmpty == true &&
                  intern.position != 'tentative')
              ? intern.position!
              : '—',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _DetailItem(label: 'START DATE', value: safeStart)),
            const SizedBox(width: 12),
            Expanded(child: _DetailItem(label: 'END DATE', value: safeEnd)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERTICAL DIVIDER
// ─────────────────────────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            _kPurple.withValues(alpha: 0.45),
            _kPurple.withValues(alpha: 0.45),
            Colors.transparent,
          ],
          stops: const [0.0, 0.15, 0.85, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION (mobile only)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final InternProfile intern;
  const _HeroSection({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _kPurple.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarRing(intern: intern),
          const SizedBox(height: 16),
          Text(
            intern.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          if (intern.position?.isNotEmpty ?? false)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_history_outlined,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.45)),
                const SizedBox(width: 5),
                Text(
                  intern.position!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.58),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          if (intern.department?.isNotEmpty ?? false) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.35)),
                const SizedBox(width: 5),
                Text(
                  intern.department!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (intern.internNumber != 'N/A')
            _IdBadge(number: intern.internNumber),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR RING — slightly bigger (130px)
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarRing extends StatelessWidget {
  final InternProfile intern;
  const _AvatarRing({required this.intern});

  @override
  Widget build(BuildContext context) {
    const double size = 126;
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF6D28D9), Color(0xFFC026D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.55),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0B0D1A),
          ),
          child: ClipOval(
            child: InternAvatar(
              intern: intern,
              size: size,
              borderRadius: size / 2,
              fontSize: 44,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ID BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _IdBadge extends StatelessWidget {
  final String number;
  const _IdBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: _kPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _kPurple.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge_outlined, size: 13, color: _kAccent),
          const SizedBox(width: 8),
          Text(
            '# $number',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
              color: _kPurpleLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _kPurple.withValues(alpha: 0.28),
              width: 0.8,
            ),
          ),
          child: Icon(icon, size: 14, color: _kAccent),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            color: Color(0xFFAB8FF0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kPurple.withValues(alpha: 0.40),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONNECT ROW — centered wrap
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectRow extends StatelessWidget {
  final InternProfile intern;
  final VoidCallback onEmail;
  final VoidCallback onGitHub;
  final VoidCallback onLinkedIn;

  const _ConnectRow({
    required this.intern,
    required this.onEmail,
    required this.onGitHub,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (intern.email.isNotEmpty)
          _ConnectChip(
            icon: Icons.alternate_email_rounded,
            label: 'Email',
            onTap: onEmail,
          ),
        _ConnectChip(
          icon: Icons.code_rounded,
          label: 'GitHub',
          onTap: onGitHub,
        ),
        _ConnectChip(
          icon: Icons.work_outline_rounded,
          label: 'LinkedIn',
          onTap: onLinkedIn,
        ),
      ],
    );
  }
}

class _ConnectChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ConnectChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  State<_ConnectChip> createState() => _ConnectChipState();
}

class _ConnectChipState extends State<_ConnectChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? _kPurple.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _hovered ? _kPurple.withValues(alpha: 0.70) : _kBorderMid,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: _kPurple.withValues(alpha: 0.22),
                        blurRadius: 12)
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _hovered
                    ? _kPurpleLight
                    : Colors.white.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _hovered
                      ? _kPurpleLight
                      : Colors.white.withValues(alpha: 0.62),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT BLOCK — no label, centered text
// ─────────────────────────────────────────────────────────────────────────────

class _AboutBlock extends StatelessWidget {
  final String? bio;
  const _AboutBlock({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        border: Border(
          left:
              BorderSide(color: _kPurple.withValues(alpha: 0.65), width: 2.5),
          top: BorderSide(
              color: _kBorderMid.withValues(alpha: 0.40), width: 0.5),
          right: BorderSide(
              color: _kBorderMid.withValues(alpha: 0.40), width: 0.5),
          bottom: BorderSide(
              color: _kBorderMid.withValues(alpha: 0.40), width: 0.5),
        ),
      ),
      child: Text(
        bio?.isNotEmpty == true ? bio! : 'No bio available.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          color: Colors.white.withValues(alpha: 0.78),
          height: 1.75,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKILL CHIPS
// ─────────────────────────────────────────────────────────────────────────────

class _SkillChips extends StatelessWidget {
  final List<String> skills;
  final bool isTech;
  const _SkillChips({required this.skills, required this.isTech});

  static const _techPalette = [
    (bg: Color(0xFF1B1060), border: Color(0xFF4F46E5), text: Color(0xFFA5B4FC)),
    (bg: Color(0xFF0F2B4A), border: Color(0xFF2563EB), text: Color(0xFF93C5FD)),
    (bg: Color(0xFF0D3340), border: Color(0xFF0891B2), text: Color(0xFF67E8F9)),
    (bg: Color(0xFF1A1040), border: Color(0xFF7C3AED), text: Color(0xFFDDD6FE)),
    (bg: Color(0xFF0D2D30), border: Color(0xFF0D9488), text: Color(0xFF5EEAD4)),
  ];

  static const _softPalette = [
    (bg: Color(0xFF3B0B52), border: Color(0xFF9333EA), text: Color(0xFFE9D5FF)),
    (bg: Color(0xFF4A0F2F), border: Color(0xFFDB2777), text: Color(0xFFFBCFE8)),
    (bg: Color(0xFF3C1060), border: Color(0xFF7E22CE), text: Color(0xFFD8B4FE)),
    (bg: Color(0xFF4A1A40), border: Color(0xFFC026D3), text: Color(0xFFF5D0FE)),
    (bg: Color(0xFF451A03), border: Color(0xFFF97316), text: Color(0xFFFDBA74)),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = isTech ? _techPalette : _softPalette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.asMap().entries.map((e) {
        final c = palette[e.key % palette.length];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border.withValues(alpha: 0.50)),
          ),
          child: Text(
            e.value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.text,
              letterSpacing: 0.2,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIVIDERS
// ─────────────────────────────────────────────────────────────────────────────

class _GlowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _kPurple.withValues(alpha: 0.50),
            _kPurple.withValues(alpha: 0.50),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      color: const Color(0xFF1A1A2E),
    );
  }
}