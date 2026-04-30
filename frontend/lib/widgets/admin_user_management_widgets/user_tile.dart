import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
                  isAdmin ? Colors.indigo.shade50 : Colors.blue.shade50,
              backgroundImage: finalAvatarUrl.isNotEmpty
                  ? NetworkImage(finalAvatarUrl)
                  : null,
              child: finalAvatarUrl.isEmpty
                  ? Text(
                      initials.isEmpty ? 'U' : initials,
                      style: TextStyle(
                        color: isAdmin
                            ? Colors.indigo.shade700
                            : Colors.blue.shade700,
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
                    border: Border.all(color: Colors.white, width: 2),
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
                    ? Colors.grey.shade700
                    : (isActiveUser ? Colors.black87 : Colors.grey),
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
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4)),
                child: Text('You',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
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
                        ? Colors.grey.shade500
                        : (isActiveUser
                            ? Colors.black54
                            : Colors.grey.shade400))),
            if ((user['department'] as String? ?? '').isNotEmpty)
              Text(
                '${user['department']} · ${user['position'] ?? ''}',
                style: TextStyle(
                    fontSize: 10,
                    color: isArchivedView
                        ? Colors.grey.shade400
                        : (isActiveUser
                            ? Colors.black38
                            : Colors.grey.shade400)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.indigo.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? 'Admin' : 'Intern',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      isAdmin ? Colors.indigo.shade700 : Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (isArchivedView)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Archived',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActiveUser
                      ? Colors.green.shade50
                      : Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActiveUser ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActiveUser
                        ? Colors.green.shade800
                        : Colors.yellow.shade900,
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
                        ? Colors.grey.shade400
                        : const Color(0xFF00022E),
                    inactiveTrackColor: Colors.grey.shade300,
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
                    color: const Color(0xFF4A5E9A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.unarchive_rounded,
                        color: Color(0xFF4A5E9A)),
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
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrentUser
                          ? Colors.transparent
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.archive_outlined,
                        color: isCurrentUser
                            ? Colors.grey.shade300
                            : Colors.blueGrey.shade400),
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
