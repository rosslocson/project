// lib/widgets/users/user_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'user_utils.dart';

class UserTile extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isArchivedView;
  final bool isCurrentUser;
  final Future<bool> Function() onToggle;
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
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = isActive(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user['role'] == 'admin';

    final rawAvatarUrl = widget.user['avatar_url'] as String? ?? '';
    final finalAvatarUrl = rawAvatarUrl.isNotEmpty
        ? (rawAvatarUrl.startsWith('http')
            ? rawAvatarUrl
            : 'http://127.0.0.1:8080$rawAvatarUrl')
        : '';

    final String fName = widget.user['first_name'] ?? '';
    final String lName = widget.user['last_name'] ?? '';
    final initials =
        '${fName.isNotEmpty ? fName[0] : ''}${lName.isNotEmpty ? lName[0] : ''}'
            .toUpperCase();

    final opacity = widget.isArchivedView ? 0.5 : 1.0;

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
            if (widget.isCurrentUser)
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
                color: widget.isArchivedView
                    ? Colors.grey.shade700
                    : (_isActive ? Colors.black87 : Colors.grey),
                decoration: (!_isActive && !widget.isArchivedView)
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            if (widget.isCurrentUser) ...[
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
            Text(widget.user['email'] ?? '',
                style: TextStyle(
                    fontSize: 11,
                    color: widget.isArchivedView
                        ? Colors.grey.shade500
                        : (_isActive ? Colors.black54 : Colors.grey.shade400))),
            if ((widget.user['department'] as String? ?? '').isNotEmpty)
              Text(
                '${widget.user['department']} · ${widget.user['position'] ?? ''}',
                style: TextStyle(
                    fontSize: 10,
                    color: widget.isArchivedView
                        ? Colors.grey.shade400
                        : (_isActive ? Colors.black38 : Colors.grey.shade400)),
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
            if (widget.isArchivedView)
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
                  color:
                      _isActive ? Colors.green.shade50 : Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isActive
                        ? Colors.green.shade800
                        : Colors.yellow.shade900,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            if (!widget.isArchivedView)
              Tooltip(
                message: _isActive ? 'Deactivate user' : 'Activate user',
                child: SizedBox(
                  width: 51,
                  height: 31,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CupertinoSwitch(
                      value: _isActive,
                      activeTrackColor: const Color(0xFF00022E),
                      inactiveTrackColor: Colors.grey.shade300,
                      onChanged: (_) async {
                        setState(() => _isActive = !_isActive);
                        final success = await widget.onToggle();
                        if (!success && mounted) {
                          setState(() => _isActive = !_isActive);
                        }
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (widget.isArchivedView)
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
                    onPressed: widget.onRestore,
                  ),
                ),
              )
            else
              Tooltip(
                message: widget.isCurrentUser
                    ? 'Cannot archive yourself'
                    : 'Archive user',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.isCurrentUser
                        ? Colors.transparent
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.isCurrentUser
                          ? Colors.transparent
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.archive_outlined,
                        color: widget.isCurrentUser
                            ? Colors.grey.shade300
                            : Colors.blueGrey.shade400),
                    onPressed: widget.isCurrentUser ? null : widget.onArchive,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
