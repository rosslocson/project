import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/user_layout.dart';
import '../widgets/app_background.dart';

class UserAboutScreen extends StatelessWidget {
  const UserAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UserLayout(
      currentRoute: '/about',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final sidebar = context.watch<SidebarProvider>();

    return AppBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar ───────────────────────────────────────────
          SizedBox(
            height: 72,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Padding(
                      padding:
                          const EdgeInsets.only(left: 100, right: 100, top: 28),
                      child: Text(
                        'About & Contact',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                      ),
                    ),
                    if (!sidebar.isUserSidebarOpen)
                      Positioned(
                        left: 20,
                        top: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: IconButton(
                            padding: const EdgeInsets.all(12),
                            onPressed: () => sidebar.setUserSidebarOpen(true),
                            icon: const _HamburgerIcon(),
                            tooltip: 'Open Sidebar',
                            splashColor: Colors.white.withValues(alpha: 0.1),
                            highlightColor: Colors.transparent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // ── Main content container ────────────────────────────
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 100, right: 100, bottom: 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── About Us Card ─────────────────────────
                            _SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0B0F2F),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(
                                            1), // was 4, now 1
                                        child: Image.asset(
                                          'assets/images/logo_file.png',
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.public,
                                                color: Color(0xFF3B4FE4),
                                                size: 24);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      const Text(
                                        'InternSpace',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'What is InternSpace?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'InternSpace is an internship management platform designed to streamline the On-the-Job Training (OJT) experience for students and administrators. It provides tools for tracking attendance, managing intern profiles, and monitoring OJT progress — all in one place.',
                                    textAlign: TextAlign.justify, // ← add this
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF555555),
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Our Mission',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'We aim to bridge the gap between academic learning and professional work experience by providing a seamless, modern platform that keeps interns, supervisors, and institutions connected throughout the OJT journey.',
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF555555),
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Key Features',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const _FeatureItem(
                                    icon: Icons.access_time_rounded,
                                    label: 'Attendance Tracking',
                                    description:
                                        'Clock in/out with real-time OJT hour monitoring.',
                                  ),
                                  const _FeatureItem(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Intern Profiles',
                                    description:
                                        'Manage academic info, skills, and department details.',
                                  ),
                                  const _FeatureItem(
                                    icon: Icons.bar_chart_rounded,
                                    label: 'OJT Progress Dashboard',
                                    description:
                                        'Visualize completed hours and milestones at a glance.',
                                  ),
                                  const _FeatureItem(
                                    icon: Icons.admin_panel_settings_outlined,
                                    label: 'Admin Management',
                                    description:
                                        'Full administrative control over interns and departments.',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Contact Us Card ───────────────────────
                            const _SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Get in Touch',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Have questions, concerns, or feedback? We\'d love to hear from you.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF777777),
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  _ContactItem(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: 'internspace123@gmail.com',
                                  ),
                                  SizedBox(height: 16),
                                  _ContactItem(
                                    icon: Icons.phone_outlined,
                                    label: 'Phone',
                                    value: '0930-123-4567',
                                  ),
                                  SizedBox(height: 16),
                                  _ContactItem(
                                    icon: Icons.location_on_outlined,
                                    label: 'Address',
                                    value:
                                        'San Pablo City, Laguna, Philippines',
                                  ),
                                  SizedBox(height: 16),
                                  _ContactItem(
                                    icon: Icons.schedule_outlined,
                                    label: 'Support Hours',
                                    value:
                                        'Monday – Friday, 8:00 AM – 5:00 PM (PHT)',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
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

// ─── Hamburger Icon ───────────────────────────────────────────────────────────

class _HamburgerIcon extends StatelessWidget {
  const _HamburgerIcon();

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

// ─── Reusable Section Card ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Feature Item ────────────────────────────────────────────────────────────

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF3B4FE4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF3B4FE4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                    height: 1.4,
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

// ─── Contact Item ────────────────────────────────────────────────────────────

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B4FE4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF3B4FE4)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF999999),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
