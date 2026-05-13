import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/app_theme.dart';
import '../widgets/user_layout.dart';
import 'user_glass_topbar.dart';

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
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar ───────────────────────────────────────────
          SizedBox(
            height: 72,
            child: GlassTopBar(
              pageTitle: 'About & Contact',
              showWelcome: false,
              user: context.watch<AuthProvider>().user,
              isSidebarOpen: sidebar.isUserSidebarOpen,
              onToggleSidebar: () =>
                  sidebar.setUserSidebarOpen(!sidebar.isUserSidebarOpen),
            ),
          ),
          const SizedBox(height: 15),

          // ── Main content container ────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 100, right: 100, bottom: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? theme.surface : theme.sidebarBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.border,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : theme.shadowColor,
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Card header ───────────────────────────
                      _buildCardHeader(theme, isDark),

                      // ── Scrollable body ───────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── About Card ───────────────────
                              _SectionCard(
                                isDark: isDark,
                                theme: theme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : const Color(0xFF0B0F2F),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: isDark
                                                ? Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                            alpha: 0.12),
                                                    width: 1)
                                                : null,
                                          ),
                                          padding: const EdgeInsets.all(1),
                                          child: Image.asset(
                                            'assets/images/logo_file.png',
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(Icons.public,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF3B4FE4),
                                                  size: 24);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          'InternSpace',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: theme.surfaceText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(
                                        text: 'What is InternSpace?',
                                        theme: theme),
                                    const SizedBox(height: 8),
                                    _BodyText(
                                      text:
                                          'InternSpace is an internship management platform designed to streamline the On-the-Job Training (OJT) experience for students and administrators. It provides tools for tracking attendance, managing intern profiles, and monitoring OJT progress — all in one place.',
                                      theme: theme,
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(
                                        text: 'Our Mission', theme: theme),
                                    const SizedBox(height: 8),
                                    _BodyText(
                                      text:
                                          'We aim to bridge the gap between academic learning and professional work experience by providing a seamless, modern platform that keeps interns, supervisors, and institutions connected throughout the OJT journey.',
                                      theme: theme,
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(
                                        text: 'Key Features', theme: theme),
                                    const SizedBox(height: 12),
                                    _FeatureItem(
                                      icon: Icons.access_time_rounded,
                                      label: 'Attendance Tracking',
                                      description:
                                          'Clock in/out with real-time OJT hour monitoring.',
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                    _FeatureItem(
                                      icon: Icons.person_outline_rounded,
                                      label: 'Intern Profiles',
                                      description:
                                          'Manage academic info, skills, and department details.',
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                    _FeatureItem(
                                      icon: Icons.bar_chart_rounded,
                                      label: 'OJT Progress Dashboard',
                                      description:
                                          'Visualize completed hours and milestones at a glance.',
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                    _FeatureItem(
                                      icon: Icons.admin_panel_settings_outlined,
                                      label: 'Admin Management',
                                      description:
                                          'Full administrative control over interns and departments.',
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Contact Card ─────────────────
                              _SectionCard(
                                isDark: isDark,
                                theme: theme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionTitle(
                                        text: 'Get in Touch', theme: theme),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Have questions, concerns, or feedback? We\'d love to hear from you.',
                                      style: TextStyle(
                                          fontSize: 13, color: theme.mutedText),
                                    ),
                                    const SizedBox(height: 24),
                                    _ContactItem(
                                      icon: Icons.email_outlined,
                                      label: 'Email',
                                      value: 'internspace123@gmail.com',
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                    const SizedBox(height: 16),
                                    _ContactItem(
                                      icon: Icons.phone_outlined,
                                      label: 'Phone',
                                      value: '0930-123-4567',
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                    const SizedBox(height: 16),
                                    _ContactItem(
                                      icon: Icons.location_on_outlined,
                                      label: 'Address',
                                      value:
                                          'San Pablo City, Laguna, Philippines',
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                    const SizedBox(height: 16),
                                    _ContactItem(
                                      icon: Icons.schedule_outlined,
                                      label: 'Support Hours',
                                      value:
                                          'Monday – Friday, 8:00 AM – 5:00 PM (PHT)',
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
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
    );
  }

  Widget _buildCardHeader(InternSpaceThemeColors theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: BoxDecoration(
        color: isDark
            ? theme.surface.withValues(alpha: 0.8)
            : theme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: theme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFF00022E),
              borderRadius: BorderRadius.circular(12),
              border: isDark
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.12), width: 1)
                  : null,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: isDark ? Colors.white70 : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About & Contact',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.surfaceText,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'InternSpace platform information',
                style: TextStyle(fontSize: 12, color: theme.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final InternSpaceThemeColors theme;

  const _SectionCard({
    required this.child,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : theme.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Section Title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final InternSpaceThemeColors theme;

  const _SectionTitle({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: theme.surfaceText,
      ),
    );
  }
}

// ─── Body Text ───────────────────────────────────────────────────────────────

class _BodyText extends StatelessWidget {
  final String text;
  final InternSpaceThemeColors theme;

  const _BodyText({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: TextStyle(
        fontSize: 14,
        color: theme.mutedText,
        height: 1.6,
      ),
    );
  }
}

// ─── Feature Item ────────────────────────────────────────────────────────────

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isDark;
  final InternSpaceThemeColors theme;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? const Color(0xFF7367F0) : const Color(0xFF3B4FE4);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark
                  ? accentColor.withValues(alpha: 0.15)
                  : accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: isDark
                  ? Border.all(
                      color: accentColor.withValues(alpha: 0.3), width: 1)
                  : null,
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.surfaceText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.mutedText,
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
  final bool isDark;
  final InternSpaceThemeColors theme;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? const Color(0xFF7367F0) : const Color(0xFF3B4FE4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? accentColor.withValues(alpha: 0.15)
                : accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: isDark
                ? Border.all(
                    color: accentColor.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Icon(icon, size: 18, color: accentColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.mutedText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.surfaceText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
