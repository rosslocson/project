// lib/widgets/users/user_list_section.dart

import 'package:flutter/material.dart';
import 'user_tile.dart';
import 'user_utils.dart';

class UserListSection extends StatelessWidget {
  final String title;
  final List<dynamic> users;
  final int currentUserId;
  final Function(Map<String, dynamic>) onToggleActive;
  final Function(Map<String, dynamic>) onArchive;
  final Function(Map<String, dynamic>) onRestore;

  const UserListSection({
    super.key,
    required this.title,
    required this.users,
    required this.currentUserId,
    required this.onToggleActive,
    required this.onArchive,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20),
              itemBuilder: (context, i) {
                final u = users[i];
                return UserTile(
                  key: ValueKey(toInt(u['id'])),
                  user: u,
                  isArchivedView: isArchived(u),
                  isCurrentUser: toInt(u['id']) == currentUserId,
                  onToggle: () => onToggleActive(u),
                  onArchive: () => onArchive(u),
                  onRestore: () => onRestore(u),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}