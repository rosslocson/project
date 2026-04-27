import 'package:flutter/material.dart';
import '../stat_card.dart';

class DashboardStatsGrid extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const DashboardStatsGrid({super.key, required this.stats});

  Widget _buildGlowingCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.4,
          children: [
            _buildGlowingCard(
              child: StatCard(
                title: 'Total Users',
                value: '${stats?['total_users'] ?? 0}',
                icon: Icons.people,
                color: const Color(0xFF0A1425),
                subtitle: 'Registered accounts',
              ),
            ),
            _buildGlowingCard(
              child: StatCard(
                title: 'Active Users',
                value: '${stats?['active_users'] ?? 0}',
                icon: Icons.check_circle,
                color: const Color(0xFF0A1425),
                subtitle: 'Currently active',
              ),
            ),
            _buildGlowingCard(
              child: StatCard(
                title: 'Admins',
                value: '${stats?['admin_users'] ?? 0}',
                icon: Icons.admin_panel_settings,
                color: const Color(0xFF0A1425),
                subtitle: 'Administrator accounts',
              ),
            ),
            _buildGlowingCard(
              child: StatCard(
                title: 'Inactive',
                value: '${stats?['new_users'] ?? 0}',
                icon: Icons.person_off,
                color: const Color(0xFF0A1425),
                subtitle: 'Inactive accounts',
              ),
            ),
          ],
        );
      },
    );
  }
}