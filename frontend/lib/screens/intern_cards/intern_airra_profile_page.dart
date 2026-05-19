import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../intern_cards.dart';
import '../../widgets/app_background.dart';

// ── AIRRA LORRAINE DE CASTRO — STARFIELD PROFILE PAGE ────────────────────────
class AirraProfilePage extends StatelessWidget {
  final InternProfile intern;
  const AirraProfilePage({super.key, required this.intern});

  static const String _fallbackUrl = 'https://yourcompanysite.com';
  static const Color _accentPrimary = Color(0xFF9333EA);
  static const Color _accentSecondary = Color(0xFF7C3AED);
  static const Color _accentMuted = Color(0xFFE9D5FF);

  Future<void> _launch(String? url) async {
    final target = (url == null || url.isEmpty) ? _fallbackUrl : url;
    final uri = Uri.parse(target);
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
        child: AppBackground(
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64 : 16,
                    vertical: 32,
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    child: _buildCard(isDesktop),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── CARD SHELL ───────────────────────────────────────────────────────────
  Widget _buildCard(bool isDesktop) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1150, minHeight: 600),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: const DecorationImage(
          image: AssetImage('images/airra_space_bg.png'),
          fit: BoxFit.cover,
        ),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: _accentSecondary.withValues(alpha: 0.18),
            blurRadius: 90,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            color: const Color(0xFF060810).withValues(alpha: 0.25),
            padding: const EdgeInsets.all(28),
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  // ── DESKTOP: avatar left | panels right ──────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 4, child: Center(child: _buildAvatarIdentity())),
        const SizedBox(width: 32),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _allPanels(),
          ),
        ),
      ],
    );
  }

  // ── MOBILE: stacked ──────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAvatarIdentity(),
        const SizedBox(height: 32),
        ..._allPanels(),
      ],
    );
  }

  List<Widget> _allPanels() => [
        _buildGlassCard(title: 'Academic Profile', child: _academicContent()),
        const SizedBox(height: 12),
        _buildGlassCard(title: 'Deployment Data', child: _deploymentContent()),
        const SizedBox(height: 12),
        _buildGlassCard(
            title: 'Competencies',
            child: _skillsContent(intern.technicalSkills)),
        const SizedBox(height: 12),
        _buildGlassCard(
            title: 'Interpersonal Skills',
            child: _skillsContent(intern.softSkills)),
      ];

  // ── AVATAR + IDENTITY ────────────────────────────────────────────────────
  Widget _buildAvatarIdentity() {
    const double avatarSize = 210;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: avatarSize + 20,
          height: avatarSize + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFF6D28D9), Color(0xFFC026D3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _accentPrimary.withValues(alpha: 0.55),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF060810),
              ),
              child: ClipOval(
                child: InternAvatar(
                  intern: intern,
                  size: avatarSize,
                  borderRadius: avatarSize / 2,
                  fontSize: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          intern.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: _accentPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _accentPrimary.withValues(alpha: 0.40)),
          ),
          child: Text(
            intern.internNumber != 'N/A'
                ? 'ID: #${intern.internNumber}'
                : 'SYSTEM APPRENTICE',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: _accentMuted,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              icon: Icons.code_rounded,
              accentColor: _accentPrimary,
              accentMuted: _accentMuted,
              tooltip: 'GitHub',
              onTap: () => _launch(intern.githubUrl),
            ),
            const SizedBox(width: 24),
            _SocialButton(
              icon: Icons.person_pin_rounded,
              accentColor: _accentPrimary,
              accentMuted: _accentMuted,
              tooltip: 'LinkedIn',
              onTap: () => _launch(intern.linkedInUrl),
            ),
          ],
        ),
      ],
    );
  }

  // ── PANEL CONTENTS ───────────────────────────────────────────────────────
  Widget _academicContent() {
    final spec = (intern.specialization?.isNotEmpty == true)
        ? intern.specialization!
        : 'N/A';
    return Column(children: [
      _DetailGridRow(
        label1: 'INSTITUTION',
        value1: intern.school.isNotEmpty ? intern.school : '',
        label2: 'PROGRAM',
        value2: intern.program.isNotEmpty ? intern.program : '',
      ),
      const SizedBox(height: 14),
      _DetailGridRow(
        label1: 'SPECIALIZATION',
        value1: spec,
        label2: 'YEAR LEVEL',
        value2: intern.yearLevel ?? '—',
      ),
    ]);
  }

  Widget _deploymentContent() {
    final position =
        (intern.position?.isNotEmpty == true && intern.position != 'tentative')
            ? intern.position!
            : '';
    return Column(children: [
      _DetailGridRow(
        label1: 'DEPARTMENT',
        value1: intern.department?.isNotEmpty == true
            ? intern.department!
            : 'Development',
        label2: 'DESIGNATION',
        value2: position,
      ),
      const SizedBox(height: 14),
      _DetailGridRow(
        label1: 'START DATE',
        value1: intern.startDate ?? 'TBA',
        label2: 'END DATE',
        value2: intern.endDate ?? 'TBA',
      ),
    ]);
  }

  Widget _skillsContent(List<String> skills) {
    if (skills.isEmpty) {
      return Text(
        'No skills configured.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: skills.map((s) => _StarBadge(label: s)).toList(),
    );
  }

  // ── GLASSMORPHISM CARD ───────────────────────────────────────────────────
  Widget _buildGlassCard({required String title, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        // ↑ Increased blur to obscure the background without going overboard
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            // ↑ Darker fill so the starfield bleeds through much less
            color: const Color(0xFF060810).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // ↑ Slightly more visible border to reinforce the glass edge
              color: Colors.white.withValues(alpha: 0.13),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(width: 32, height: 2, color: const Color(0xFF8B5CF6)),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ── SUB-COMPONENTS ────────────────────────────────────────────────────────────

class _DetailGridRow extends StatelessWidget {
  final String label1, value1, label2, value2;
  const _DetailGridRow({
    required this.label1,
    required this.value1,
    required this.label2,
    required this.value2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _DetailItem(label: label1, value: value1)),
        const SizedBox(width: 16),
        Expanded(child: _DetailItem(label: label2, value: value2)),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label, value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ── SOCIAL BUTTON — hover + tooltip ──────────────────────────────────────────
class _SocialButton extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final Color accentMuted;
  final VoidCallback onTap;
  final String tooltip;

  const _SocialButton({
    required this.icon,
    required this.accentColor,
    required this.accentMuted,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hovered
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hovered
                      ? widget.accentColor.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                widget.icon,
                size: 22,
                color: _hovered
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.75),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _hovered ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0D2E).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.45),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.tooltip,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: widget.accentMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STAR BADGE — static, no hover ────────────────────────────────────────────
class _StarBadge extends StatelessWidget {
  final String label;
  const _StarBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E1A).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF9333EA).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE9D5FF),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
