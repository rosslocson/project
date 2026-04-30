import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/api_service.dart';
import 'intern_widgets.dart';

// ── Intern #28 Special Profile Page ──────────────────────────────────────────
//
// HOW TO LINK THIS PAGE:
//
// Find the widget where you display the intern's name (e.g. a card, list tile,
// or the InternDetailPage name Text). Wrap it in a GestureDetector like this:
//
//   GestureDetector(
//     onTap: () {
//       if (intern.id == 28) {
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (_) => Intern28ProfilePage(intern: intern),
//           ),
//         );
//       }
//     },
//     child: Text(intern.name, ...),  // ← your existing name widget
//   ),
//
// Or if you want EVERY intern name to be tappable but only #28 goes here:
//
//   GestureDetector(
//     onTap: () {
//       if (intern.id == 28) {
//         Navigator.of(context).push(
//           MaterialPageRoute(builder: (_) => Intern28ProfilePage(intern: intern)),
//         );
//       } else {
//         Navigator.of(context).push(
//           MaterialPageRoute(builder: (_) => InternDetailPage(intern: intern)),
//         );
//       }
//     },
//     child: Text(intern.name, ...),
//   ),

class Intern28ProfilePage extends StatelessWidget {
  final InternProfile intern;

  const Intern28ProfilePage({super.key, required this.intern});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Image.asset(
              'assets/images/space_background.png',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withValues(alpha: 0.65)),

            // Content
            SafeArea(
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
                              ? _DesktopLayout(intern: intern)
                              : _MobileLayout(intern: intern),
                        ),
                      ),
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

// ── DESKTOP: side-by-side panels ─────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final InternProfile intern;
  const _DesktopLayout({required this.intern});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT DARK PANEL
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                ),
              ),
            ),
            child: _LeftPanel(intern: intern),
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
  const _MobileLayout({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              ),
            ),
          ),
          child: _LeftPanel(intern: intern, isMobile: true),
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
  const _LeftPanel({required this.intern, this.isMobile = false});

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

          // Name
          Text(
            intern.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 4),

          // Pronouns (static for #28, or pull from intern if you add a field)
          Text(
            '(He/him)',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),

          const SizedBox(height: 2),

          // Role / position
          Text(
            intern.position ?? intern.program,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),

          const SizedBox(height: 20),

          // Intern badge
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
                  'INTERN #${intern.internNumber}',
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
          Text(
            'CONNECT WITH ME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),

          const SizedBox(height: 14),

          // Social icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIcon(
                icon: Icons.email_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _SocialIcon(
                icon: Icons.camera_alt_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _SocialIcon(
                // Twitter/X — using alternate_email as closest Material icon
                icon: Icons.alternate_email,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _SocialIcon(
                icon: Icons.share_outlined,
                onTap: () {},
              ),
              if (intern.linkedInUrl != null) ...[
                const SizedBox(width: 12),
                _SocialIcon(
                  icon: Icons.business_center_outlined,
                  onTap: () {},
                ),
              ],
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.white.withValues(alpha: 0.55),
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
          // About Me
          const Text(
            'ABOUT ME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'More Than Just An Intern',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            intern.bio ??
                'I make an impact, not just contributions. Experienced in building, '
                    'designing, and shipping real software used by people. Passionate about '
                    'clean code, great UX, and collaborative teamwork.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.7,
            ),
          ),

          _Divider(),

          // Education
          _SectionLabel('EDUCATION'),
          const SizedBox(height: 14),
          _TimelineEntry(
            year: intern.startDate?.substring(0, 4) ?? '2024',
            title: intern.program,
            subtitle: intern.school,
            note: intern.specialization,
          ),

          _Divider(),

          // Experience / Deployment
          _SectionLabel('EXPERIENCE'),
          const SizedBox(height: 14),
          if (intern.position != null)
            _TimelineEntry(
              year: intern.startDate?.substring(0, 4) ?? '2025',
              title: intern.position!,
              subtitle: intern.department ?? 'Department N/A',
              note: intern.endDate != null
                  ? 'Until ${intern.endDate}'
                  : null,
            ),

          // Skills chips if any
          if (intern.technicalSkills.isNotEmpty) ...[
            _Divider(),
            _SectionLabel('TECHNICAL SKILLS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: intern.technicalSkills
                  .map((s) => _SkillPill(label: s, isTech: true))
                  .toList(),
            ),
          ],

          if (intern.softSkills.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionLabel('SOFT SKILLS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: intern.softSkills
                  .map((s) => _SkillPill(label: s, isTech: false))
                  .toList(),
            ),
          ],

          const SizedBox(height: 32),

          // Resume button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF8B5CF6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: open resume URL or download
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'RESUME',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Colors.white,
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
  final String year;
  final String title;
  final String subtitle;
  final String? note;

  const _TimelineEntry({
    required this.year,
    required this.title,
    required this.subtitle,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          year,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8B5CF6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
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
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.4,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillPill extends StatelessWidget {
  final String label;
  final bool isTech;
  const _SkillPill({required this.label, required this.isTech});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isTech
            ? const Color(0xFF1E2A44).withValues(alpha: 0.6)
            : const Color(0xFF334155).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTech
              ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isTech ? const Color(0xFF3B82F6) : Colors.white,
        ),
      ),
    );
  }
}