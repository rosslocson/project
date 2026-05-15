// lib/widgets/users/user_list_section.dart

import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'user_tile.dart';
import 'user_utils.dart';

class UserListSection extends StatelessWidget {
  final String title;
  final List<dynamic> users;
  final int currentUserId;
  final Future<bool> Function(Map<String, dynamic>) onToggleActive;
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
    final theme = context.internTheme;
    final sectionBackground = context.isDarkInternTheme
        ? theme.listBackground.withValues(alpha: 0.98)
        : theme.sidebarBackground;
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.topbarText.withValues(alpha: 0.85)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: sectionBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color:
                    theme.border.withValues(alpha: 0.15)), // ← reduce opacity
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              // ← add this
              color: sectionBackground, // ← matches your container
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 20, color: theme.border),
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
        ),
      ],
    );
  }
}
