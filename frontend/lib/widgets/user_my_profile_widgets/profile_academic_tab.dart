// lib/widgets/user_profile/profile_academic_tab.dart

import 'package:flutter/material.dart';
import 'profile_components.dart';
import 'profile_utils.dart';

class ProfileAcademicTab extends StatelessWidget {
  final Map<String, dynamic>? user;
  final int? requiredHours;

  const ProfileAcademicTab({super.key, required this.user, required this.requiredHours});

  @override
  Widget build(BuildContext context) {
    final computedEndDate = user?['estimated_end_date']?.toString().trim() ?? '';
    final displayedEndDate = getProfileVal(user, 'end_date');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileSectionTitle(title: 'Timeline & Hours', icon: Icons.schedule_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CleanInfoCard(label: 'Internship Start', value: getProfileVal(user, 'start_date'), icon: Icons.event_rounded)),
              const SizedBox(width: 12),
              Expanded(child: CleanInfoCard(label: 'Internship End', value: displayedEndDate, icon: Icons.event_available_rounded)),
              const SizedBox(width: 12),
              Expanded(child: CleanInfoCard(label: 'Required OJT Hours', value: requiredHours != null ? '$requiredHours hrs' : '—', icon: Icons.hourglass_empty_rounded)),
            ],
          ),
          if (computedEndDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estimated completion by $computedEndDate (based on $requiredHours hrs @ 8 hrs/day, Mon–Fri)',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const ProfileSectionTitle(title: 'Placement Details', icon: Icons.work_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CleanInfoCard(label: 'Department', value: getProfileVal(user, 'department'))),
              const SizedBox(width: 12),
              Expanded(child: CleanInfoCard(label: 'Position', value: getProfileVal(user, 'position'))),
              const SizedBox(width: 12),
              Expanded(child: CleanInfoCard(label: 'Intern Number', value: getProfileVal(user, 'intern_number'), icon: Icons.badge_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          const ProfileSectionTitle(title: 'Academic Background', icon: Icons.school_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 2, child: CleanInfoCard(label: 'School / University', value: getProfileVal(user, 'school'), icon: Icons.account_balance_rounded)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: CleanInfoCard(label: 'Year Level', value: getProfileVal(user, 'year_level'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CleanInfoCard(label: 'Program / Course', value: getProfileVal(user, 'program'))),
              const SizedBox(width: 12),
              Expanded(child: CleanInfoCard(label: 'Specialization', value: getProfileVal(user, 'specialization'))),
            ],
          ),
        ],
      ),
    );
  }
}