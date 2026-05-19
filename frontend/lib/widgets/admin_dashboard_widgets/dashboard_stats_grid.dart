import 'package:flutter/material.dart';
import '../stat_card.dart';

class DashboardStatsGrid extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const DashboardStatsGrid({super.key, required this.stats});

  Widget _buildGlowingCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 800 ? 4 : 2;
        final ratio = constraints.maxWidth > 800 ? 1.4 : 1.6;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 1.4,
          children: [
            _buildGlowingCard(
              child: StatCard(
                title: 'Total Interns',
                value: '${stats?['total_interns'] ?? 0}',
                icon: Icons.school,
                color: const Color(0xFF0A1425),
                subtitle: 'Registered interns',
              ),
            ),
            _buildGlowingCard(
              child: StatCard(
                title: 'Present',
                value: '${stats?['present_count'] ?? 0}',
                icon: Icons.check_circle,
                color: const Color(0xFF0A1425),
                subtitle: 'Present today',
              ),
            ),
            _buildGlowingCard(
              child: StatCard(
                title: 'Absent',
                value: '${stats?['absent_count'] ?? 0}',
                icon: Icons.cancel,
                color: const Color(0xFF0A1425),
                subtitle: 'Absent today',
              ),
            ),
            _buildGlowingCard(
              child: StatCard(
                title: 'Late',
                value: '${stats?['late_count'] ?? 0}',
                icon: Icons.watch_later,
                color: const Color(0xFF0A1425),
                subtitle: 'Late arrivals today',
              ),
            ),
          ],
        );
      },
    );
  }
}
