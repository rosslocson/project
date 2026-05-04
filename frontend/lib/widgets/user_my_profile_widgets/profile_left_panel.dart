// lib/widgets/user_profile/profile_left_panel.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'profile_components.dart';
import 'profile_utils.dart';

class ProfileLeftPanel extends StatelessWidget {
  final Map<String, dynamic>? user;
  final String first;
  final String last;
  final String initials;
  final String finalAvatarUrl;
  final Color cardDarkBlue;
  final Color cardDarkerBlue;

  const ProfileLeftPanel({
    super.key,
    required this.user,
    required this.first,
    required this.last,
    required this.initials,
    required this.finalAvatarUrl,
    required this.cardDarkBlue,
    required this.cardDarkerBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardDarkBlue, cardDarkerBlue],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 36, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 68,
                          backgroundColor: Colors.white.withOpacity(0.10),
                          child: ClipOval(
                            child: finalAvatarUrl.isNotEmpty
                                ? Image.network(
                                    finalAvatarUrl,
                                    width: 136,
                                    height: 136,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _AvatarInitials(initials: initials),
                                  )
                                : _AvatarInitials(initials: initials),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/edit-profile'),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Icon(Icons.edit_rounded, color: cardDarkBlue, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      first.isEmpty && last.isEmpty ? 'Name Not Set' : '$first $last',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5, height: 1.2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      user?['email'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: const Text('INTERN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.lightBlueAccent)),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Divider(color: Colors.white.withOpacity(0.10), height: 1),
                  ),
                  const SizedBox(height: 24),
                  QuickInfoTile(icon: Icons.business_rounded, label: 'Department', value: getProfileVal(user, 'department')),
                  const SizedBox(height: 16),
                  QuickInfoTile(icon: Icons.work_outline_rounded, label: 'Position', value: getProfileVal(user, 'position')),
                  const SizedBox(height: 16),
                  QuickInfoTile(icon: Icons.school_rounded, label: 'School', value: getProfileVal(user, 'school')),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/edit-profile'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: cardDarkBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String initials;

  const _AvatarInitials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
