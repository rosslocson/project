// lib/widgets/user_profile/profile_skills_tab.dart

import 'package:flutter/material.dart';
import 'profile_components.dart';
import 'profile_utils.dart';

class ProfileSkillsTab extends StatelessWidget {
  final Map<String, dynamic>? user;

  const ProfileSkillsTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final techSkills = getProfileVal(user, 'technical_skills');
    final softSkills = getProfileVal(user, 'soft_skills');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileSectionTitle(title: 'About Me', icon: Icons.person_rounded),
          const SizedBox(height: 12),
          CleanInfoCard(label: 'Bio', value: getProfileVal(user, 'bio'), isMultiline: true),
          const SizedBox(height: 24),
          const ProfileSectionTitle(title: 'Expertise', icon: Icons.psychology_rounded),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SkillPanelClean(
                  label: 'Technical Skills',
                  raw: techSkills,
                  accentColor: Colors.blue.shade600,
                  bgColor: Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkillPanelClean(
                  label: 'Soft Skills',
                  raw: softSkills,
                  accentColor: Colors.blue.shade600,
                  bgColor: Colors.blue.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ProfileSectionTitle(title: 'Links & Socials', icon: Icons.link_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CleanInfoCard(label: 'LinkedIn URL', value: getProfileVal(user, 'linked_in'), icon: Icons.open_in_new_rounded)),
              const SizedBox(width: 12),
              Expanded(child: CleanInfoCard(label: 'GitHub URL', value: getProfileVal(user, 'git_hub'), icon: Icons.code_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}