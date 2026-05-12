import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'intern_widgets.dart';
import '../widgets/app_background.dart';

// ── Rosalyn Locson Special Profile Page ──────────────────────────────────────
//
// All fields are read from the InternProfile object (fetched from DB).
// Fields used:
//   intern.name          → first_name + last_name
//   intern.position      → position
//   intern.internNumber  → intern_number
//   intern.email         → email  (mailto: link)
//   intern.githubUrl     → github (url link)
//   intern.linkedInUrl   → linkedin (url link)
//   intern.bio           → about me
//   intern.program       → education title
//   intern.specialization→ education subtitle
//   intern.technicalSkills → technical skills list
//   intern.softSkills      → soft skills list

class RosalynProfilePage extends StatelessWidget {
  final InternProfile intern;

  const RosalynProfilePage({super.key, required this.intern});

  static const String _fallbackUrl =
      'https://yourcompanysite.com'; // ← set your default site

  Future<void> _launch(String? url) async {
    final target = (url == null || url.isEmpty) ? _fallbackUrl : url;
    final uri = Uri.parse(target);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: AppBackground(
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64 : 16,
                    vertical: 32,
                  ),
                  child: GestureDetector(
                    onTap: () {}, // prevent closing when tapping inside card
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF0F172A).withValues(alpha: 0.85),
                                const Color(0xFF1E1B4B).withValues(alpha: 0.75),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: isDesktop
                              ? _DesktopLayout(
                                  intern: intern,
                                  onEmail: () => _launchEmail(intern.email),
                                  onGitHub: () => _launch(intern.githubUrl),
                                  onLinkedIn: () => _launch(intern.linkedInUrl),
                                )
                              : _MobileLayout(
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
          ),
        ),
      ),
    );
  }
}

// ── DESKTOP: side-by-side panels ─────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final InternProfile intern;
  final VoidCallback onEmail;
  final VoidCallback onGitHub;
  final VoidCallback onLinkedIn;

  const _DesktopLayout({
    required this.intern,
    required this.onEmail,
    required this.onGitHub,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT PANEL — white background
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(36),
                bottomLeft: Radius.circular(36),
              ),
              border: Border(
                right: BorderSide(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.20),
                ),
              ),
            ),
            child: _LeftPanel(
              intern: intern,
              onEmail: onEmail,
              onGitHub: onGitHub,
              onLinkedIn: onLinkedIn,
            ),
          ),
          // RIGHT PANEL
          Expanded(child: _RightPanel(intern: intern)),
        ],
      ),
    );
  }
}

// ── MOBILE: stacked panels ────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final InternProfile intern;
  final VoidCallback onEmail;
  final VoidCallback onGitHub;
  final VoidCallback onLinkedIn;

  const _MobileLayout({
    required this.intern,
    required this.onEmail,
    required this.onGitHub,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TOP PANEL — white background
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(36),
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.20),
              ),
            ),
          ),
          child: _LeftPanel(
            intern: intern,
            isMobile: true,
            onEmail: onEmail,
            onGitHub: onGitHub,
            onLinkedIn: onLinkedIn,
          ),
        ),
        _RightPanel(intern: intern),
      ],
    );
  }
}

// ── LEFT PANEL ────────────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final InternProfile intern;
  final bool isMobile;
  final VoidCallback onEmail;
  final VoidCallback onGitHub;
  final VoidCallback onLinkedIn;

  const _LeftPanel({
    required this.intern,
    this.isMobile = false,
    required this.onEmail,
    required this.onGitHub,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glowing avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: InternAvatar(
              intern: intern,
              size: isMobile ? 120 : 148,
              borderRadius: 34,
              fontSize: 52,
            ),
          ),

          const SizedBox(height: 20),

          // Full name (from DB: first_name + last_name)
          Text(
            intern.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 6),

          // Position + Department (from DB)
          if ((intern.position != null && intern.position!.isNotEmpty) ||
              (intern.department != null && intern.department!.isNotEmpty))
            Text(
              [
                if (intern.position != null && intern.position!.isNotEmpty)
                  intern.position!,
                if (intern.department != null && intern.department!.isNotEmpty)
                  intern.department!,
              ].join(' • '),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
            ),

          const SizedBox(height: 16),

          // Intern number badge (from DB: intern_number)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  intern.internNumber != 'N/A'
                      ? '#${intern.internNumber}'
                      : 'INTERN',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Connect with me
          const Text(
            'CONNECT WITH ME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 14),

          // Social icons — email hidden if empty; GitHub & LinkedIn always shown (fallback to site)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (intern.email.isNotEmpty) ...[
                _SocialIcon(
                  icon: Icons.email_outlined,
                  onTap: onEmail,
                ),
                const SizedBox(width: 12),
              ],
              _SocialIcon(
                icon: Icons.code_rounded,
                onTap: onGitHub, // falls back to site if githubUrl is empty
              ),
              const SizedBox(width: 12),
              _SocialIcon(
                icon: Icons.business_center_outlined,
                onTap: onLinkedIn, // falls back to site if linkedInUrl is empty
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}

// ── RIGHT PANEL ───────────────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  final InternProfile intern;
  const _RightPanel({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ABOUT ME (from DB: bio) ─────────────────────────────────────
          const _SectionLabel('ABOUT ME'),
          const SizedBox(height: 12),
          Text(
            intern.bio?.isNotEmpty == true ? intern.bio! : 'No bio available.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.7,
            ),
          ),

          _Divider(),

          // ── EDUCATION (from DB: program + specialization + school) ────────
          const _SectionLabel('EDUCATION'),
          const SizedBox(height: 14),
          _TimelineEntry(
            title: intern.program.isNotEmpty ? intern.program : 'Program N/A',
            subtitle: intern.specialization?.isNotEmpty == true
                ? intern.specialization!
                : '',
            school: intern.school.isNotEmpty ? intern.school : null,
          ),

          // ── TECHNICAL SKILLS (from DB) ──────────────────────────────────
          if (intern.technicalSkills.isNotEmpty) ...[
            _Divider(),
            const _SectionLabel('TECHNICAL SKILLS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: intern.technicalSkills
                  .asMap()
                  .entries
                  .map((e) =>
                      _SkillPill(label: e.value, isTech: true, index: e.key))
                  .toList(),
            ),
          ],

          // ── SOFT SKILLS (from DB) ───────────────────────────────────────
          if (intern.softSkills.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel('SOFT SKILLS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: intern.softSkills
                  .asMap()
                  .entries
                  .map((e) =>
                      _SkillPill(label: e.value, isTech: false, index: e.key))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      height: 1,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? school;

  const _TimelineEntry(
      {required this.title, required this.subtitle, this.school});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
              height: 1.4,
            ),
          ),
        ],
        if (school != null && school!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.account_balance_outlined,
                  size: 12, color: Colors.white.withValues(alpha: 0.35)),
              const SizedBox(width: 5),
              Text(
                school!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.35),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SkillPill extends StatelessWidget {
  final String label;
  final bool isTech;
  final int index;

  const _SkillPill(
      {required this.label, required this.isTech, required this.index});

  // Tech skills: blues / teals / cyans
  static const _techColors = [
    (
      bg: Color(0xFF1E3A5F),
      border: Color(0xFF3B82F6),
      text: Color(0xFF93C5FD)
    ), // blue
    (
      bg: Color(0xFF134E4A),
      border: Color(0xFF14B8A6),
      text: Color(0xFF5EEAD4)
    ), // teal
    (
      bg: Color(0xFF1E3A5F),
      border: Color(0xFF6366F1),
      text: Color(0xFFA5B4FC)
    ), // indigo
    (
      bg: Color(0xFF0C4A6E),
      border: Color(0xFF0EA5E9),
      text: Color(0xFF7DD3FC)
    ), // sky
    (
      bg: Color(0xFF1E3A4A),
      border: Color(0xFF06B6D4),
      text: Color(0xFF67E8F9)
    ), // cyan
  ];

  // Soft skills: purples / pinks / ambers
  static const _softColors = [
    (
      bg: Color(0xFF3B1F5E),
      border: Color(0xFF8B5CF6),
      text: Color(0xFFC4B5FD)
    ), // violet
    (
      bg: Color(0xFF4A1942),
      border: Color(0xFFEC4899),
      text: Color(0xFFF9A8D4)
    ), // pink
    (
      bg: Color(0xFF451A03),
      border: Color(0xFFF97316),
      text: Color(0xFFFDBA74)
    ), // orange
    (
      bg: Color(0xFF422006),
      border: Color(0xFFEAB308),
      text: Color(0xFFFDE047)
    ), // amber
    (
      bg: Color(0xFF2D1B4E),
      border: Color(0xFFD946EF),
      text: Color(0xFFF0ABFC)
    ), // fuchsia
  ];

  @override
  Widget build(BuildContext context) {
    final palette = isTech ? _techColors : _softColors;
    final c = palette[index % palette.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.text,
        ),
      ),
    );
  }
}
