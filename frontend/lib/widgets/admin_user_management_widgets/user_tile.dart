import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../app_theme.dart';
import 'user_utils.dart';

class UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isArchivedView;
  final bool isCurrentUser;
  final VoidCallback onToggle;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  const UserTile({
    super.key,
    required this.user,
    required this.isArchivedView,
    required this.isCurrentUser,
    required this.onToggle,
    required this.onArchive,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;
    final primaryColor = isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);
    
    final isActiveUser = isActive(user);
    final isAdmin = user['role'] == 'admin';

    final rawAvatarUrl = user['avatar_url'] as String? ?? '';
    final finalAvatarUrl = rawAvatarUrl.isNotEmpty
        ? (rawAvatarUrl.startsWith('http')
            ? rawAvatarUrl
            : 'http://127.0.0.1:8080$rawAvatarUrl')
        : '';

    final String fName = user['first_name'] ?? '';
    final String lName = user['last_name'] ?? '';
    final initials =
        '${fName.isNotEmpty ? fName[0] : ''}${lName.isNotEmpty ? lName[0] : ''}'
            .toUpperCase();

    final opacity = isArchivedView ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isAdmin ? primaryColor.withValues(alpha: 0.15) : primaryColor.withValues(alpha: 0.05),
              backgroundImage: finalAvatarUrl.isNotEmpty
                  ? NetworkImage(finalAvatarUrl)
                  : null,
              child: finalAvatarUrl.isEmpty
                  ? Text(
                      initials.isEmpty ? 'U' : initials,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (isCurrentUser)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.listBackground, width: 2),
                  ),
                ),
              )
          ],
        ),
        title: Row(
          children: [
            Text(
              '$fName $lName',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isArchivedView
                    ? theme.listMutedText
                    : (isActiveUser ? theme.listText : theme.listMutedText),
                decoration: (!isActiveUser && !isArchivedView)
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: theme.formFill,
                    borderRadius: BorderRadius.circular(4)),
                child: Text('You',
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.listMutedText,
                        fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? '',
                style: TextStyle(
                    fontSize: 11,
                    color: isArchivedView
                        ? theme.listMutedText.withValues(alpha: 0.6)
                        : (isActiveUser
                            ? theme.listMutedText
                            : theme.listMutedText.withValues(alpha: 0.8)))),
            if ((user['department'] as String? ?? '').isNotEmpty)
              Text(
                '${user['department']} · ${user['position'] ?? ''}',
                style: TextStyle(
                    fontSize: 10,
                    color: isArchivedView
                        ? theme.listMutedText.withValues(alpha: 0.6)
                        : (isActiveUser
                            ? theme.listMutedText.withValues(alpha: 0.8)
                            : theme.listMutedText.withValues(alpha: 0.8))),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAdmin ? primaryColor.withValues(alpha: 0.15) : primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? 'Admin' : 'Intern',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isAdmin ? primaryColor : primaryColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (isArchivedView)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Archived',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActiveUser
                      ? Colors.green.withValues(alpha: isDark ? 0.2 : 0.1)
                      : Colors.yellow.withValues(alpha: isDark ? 0.2 : 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActiveUser ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActiveUser
                        ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                        : (isDark ? Colors.yellow.shade400 : Colors.yellow.shade900),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            if (!isArchivedView)
              Tooltip(
                message: isCurrentUser
                    ? 'Cannot deactivate yourself'
                    : (isActiveUser ? 'Deactivate user' : 'Activate user'),
                child: Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: isActiveUser,
                    activeTrackColor: isCurrentUser
                        ? theme.listMutedText.withValues(alpha: 0.5)
                        : primaryColor,
                    // Revised: Added explicit trackColor for off state visibility
                    inactiveTrackColor: isDark 
                        ? Colors.white.withValues(alpha: 0.2) // Lighter in Dark Mode
                        : Colors.grey.shade400,              // Darker in Light Mode
                    onChanged: isCurrentUser ? null : (_) => onToggle(),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (isArchivedView)
              Tooltip(
                message: 'Restore user',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.unarchive_rounded, color: primaryColor),
                    onPressed: onRestore,
                  ),
                ),
              )
            else
              Tooltip(
                message:
                    isCurrentUser ? 'Cannot archive yourself' : 'Archive user',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? Colors.transparent
                        : (isDark ? theme.formFill : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrentUser
                          ? Colors.transparent
                          : theme.border,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.archive_outlined,
                        color: isCurrentUser
                            ? theme.listMutedText.withValues(alpha: 0.3)
                            : theme.listMutedText),
                    onPressed: isCurrentUser ? null : onArchive,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}