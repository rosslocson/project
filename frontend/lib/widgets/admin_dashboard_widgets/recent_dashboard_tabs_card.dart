import 'package:flutter/material.dart';

import 'pagination_footer.dart';

enum RecentDashboardTab { users, activity }

class RecentDashboardTabsCard extends StatefulWidget {
  final Map<String, dynamic>? stats;
  final List<dynamic> activityLogs;
  final int usersPage;
  final int activityPage;
  final int totalUsersPages;
  final int totalActivityPages;
  final Function(int) onUsersPageChanged;
  final Function(int) onActivityPageChanged;

  const RecentDashboardTabsCard({
    super.key,
    required this.stats,
    required this.activityLogs,
    required this.usersPage,
    required this.activityPage,
    required this.totalUsersPages,
    required this.totalActivityPages,
    required this.onUsersPageChanged,
    required this.onActivityPageChanged,
  });

  @override
  State<RecentDashboardTabsCard> createState() =>
      _RecentDashboardTabsCardState();
}

class _RecentDashboardTabsCardState extends State<RecentDashboardTabsCard> {
  RecentDashboardTab _activeTab = RecentDashboardTab.users;

  int get _currentPage => _activeTab == RecentDashboardTab.users
      ? widget.usersPage
      : widget.activityPage;

  int get _totalPages {
    final total = _activeTab == RecentDashboardTab.users
        ? widget.totalUsersPages
        : widget.totalActivityPages;
    return total < 1 ? 1 : total;
  }

  String get _subtitle => _activeTab == RecentDashboardTab.users
      ? 'Platform members'
      : 'System mission log (Past 7 Days)';

  void _handlePageChange(int page) {
    if (_activeTab == RecentDashboardTab.users) {
      widget.onUsersPageChanged(page);
    } else {
      widget.onActivityPageChanged(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeCurrentPage = _currentPage.clamp(1, _totalPages);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeTab == RecentDashboardTab.users
                      ? 'Recent Users'
                      : 'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  _subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            Text(
              'Page $safeCurrentPage of $_totalPages',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _SegmentedToggle(
                    activeTab: _activeTab,
                    onChanged: (tab) => setState(() => _activeTab = tab),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation);

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: _activeTab == RecentDashboardTab.users
                      ? _buildUsersList(
                          key: ValueKey<String>('users-$safeCurrentPage'),
                        )
                      : _buildActivityTimeline(
                          key: ValueKey<String>('activity-$safeCurrentPage'),
                          logs: widget.activityLogs,
                        ),
                ),
              ),
              PaginationFooter(
                currentPage: safeCurrentPage,
                totalPages: _totalPages,
                onPrev: () => _handlePageChange(safeCurrentPage - 1),
                onNext: () => _handlePageChange(safeCurrentPage + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList({required Key key}) {
    final users = (widget.stats?['recent_users'] as List?) ?? [];
    if (users.isEmpty) {
      return Center(
        key: key,
        child: const Text(
          'No users yet',
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    return ListView.separated(
      key: key,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: Colors.black12,
        indent: 70,
      ),
      itemBuilder: (context, i) {
        final u = users[i];
        if (u == null || u is! Map<String, dynamic>) {
          return const SizedBox.shrink();
        }

        final fName = u['first_name']?.toString() ?? '';
        final lName = u['last_name']?.toString() ?? '';
        final name = u['name']?.toString() ?? '';
        final email = u['email']?.toString() ?? '';
        final displayName = [fName, lName].where((s) => s.isNotEmpty).join(' ');
        final titleText = displayName.isNotEmpty
            ? displayName
            : (name.isNotEmpty ? name : (email.isNotEmpty ? email : 'Unknown'));

        String initials = 'U';
        try {
          if (fName.isNotEmpty || lName.isNotEmpty) {
            final firstInitial =
                fName.isNotEmpty ? fName.trim()[0].toUpperCase() : '';
            final lastInitial =
                lName.isNotEmpty ? lName.trim()[0].toUpperCase() : '';
            initials = '$firstInitial$lastInitial'.trim();
            if (initials.isEmpty) initials = 'U';
          } else if (name.isNotEmpty) {
            final trimmedName = name.trim();
            if (trimmedName.isNotEmpty) {
              final parts = trimmedName.split(RegExp(r'\s+'));
              initials = parts.length > 1
                  ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                  : parts[0][0].toUpperCase();
            }
          } else if (email.isNotEmpty) {
            final trimmedEmail = email.trim();
            if (trimmedEmail.isNotEmpty) {
              initials = trimmedEmail[0].toUpperCase();
            }
          }
        } catch (_) {
          initials = 'U';
        }

        final avatarUrl = u['avatar']?.toString() ??
            u['avatar_url']?.toString() ??
            u['image']?.toString();
        final hasImage = avatarUrl != null && avatarUrl.trim().isNotEmpty;
        final fullAvatarUrl = hasImage
            ? (avatarUrl.startsWith('http')
                ? avatarUrl
                : (avatarUrl.startsWith('/uploads/')
                    ? 'http://localhost:8080$avatarUrl'
                    : 'http://localhost:8080/uploads/$avatarUrl'))
            : '';

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            child: hasImage && fullAvatarUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      fullAvatarUrl,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _InitialsLabel(initials: initials);
                      },
                    ),
                  )
                : _InitialsLabel(initials: initials),
          ),
          title: Text(
            titleText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          trailing: _buildRoleBadge(u['role']?.toString()),
        );
      },
    );
  }

  Widget _buildRoleBadge(String? role) {
    final roleStr = role?.trim().toLowerCase() ?? '';
    final isAdmin = roleStr == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFDBE9F4) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.green.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        roleStr.isNotEmpty ? roleStr : 'user',
        style: TextStyle(
          color: isAdmin ? Colors.red.shade700 : Colors.green.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActivityTimeline({
    required Key key,
    required List<dynamic> logs,
  }) {
    if (logs.isEmpty) {
      return Center(
        key: key,
        child: const Text(
          'No activity this week',
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    return ListView.builder(
      key: key,
      padding: const EdgeInsets.only(top: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, i) {
        final log = logs[i];
        final action = log['action'] as String?;
        final rawDetails = log['details'] as String? ?? action ?? '';
        final displayText = _formatAdminAction(rawDetails);
        final logUser = log['user'] as Map<String, dynamic>?;
        final userName = logUser != null
            ? '${logUser['first_name'] ?? ''} ${logUser['last_name'] ?? ''}'
                .trim()
            : 'System';
        final isLastItem = i == logs.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 64,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isLastItem)
                      Positioned(
                        top: 36,
                        bottom: -16,
                        child: Container(width: 2, color: Colors.black12),
                      ),
                    Positioned(
                      top: 12,
                      child: _actionIcon(action),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 16, bottom: 20, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatDate(log['created_at'] as String?),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName.isEmpty ? 'System' : userName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  String _formatAdminAction(String rawDetails) {
    if (rawDetails.isEmpty) return 'Unknown action';

    final clockIn = RegExp(r'^CLOCK_IN:(.+)$').firstMatch(rawDetails);
    if (clockIn != null) return 'Clocked in at ${clockIn.group(1)!.trim()}';

    final clockOut = RegExp(r'^CLOCK_OUT:(.+)$').firstMatch(rawDetails);
    if (clockOut != null) return 'Clocked out at ${clockOut.group(1)!.trim()}';

    final adminUpdatePattern = RegExp(
      r'^Admin updated user ([^\s]+) \(active=(true|false),\s*archived=(true|false)\)$',
    );
    final match = adminUpdatePattern.firstMatch(rawDetails);
    if (match != null) {
      final email = match.group(1)!;
      final active = match.group(2)!;
      final archived = match.group(3)!;
      if (active == 'false' && archived == 'false') {
        return 'Admin deactivated user $email';
      }
      if (active == 'false' && archived == 'true') {
        return 'Admin archived user $email';
      }
      if (active == 'true' && archived == 'false') {
        return 'Admin activated user $email';
      }
    }

    return _cleanDetails(rawDetails);
  }

  String _cleanDetails(String details) {
    String cleaned = details.replaceAll(
      RegExp(r'\s*\(active=true,\s*archived=false\)'),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\s*\(active=false,\s*archived=false\)'),
      ' (Account Deactivated)',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\s*\(active=false,\s*archived=true\)'),
      ' (Account Archived)',
    );
    return cleaned.trim();
  }

  Widget _actionIcon(String? action) {
    IconData icon;
    Color color;

    switch (action) {
      case 'CLOCK_IN':
        icon = Icons.login_rounded;
        color = Colors.green;
        break;
      case 'CLOCK_OUT':
        icon = Icons.logout_rounded;
        color = Colors.deepOrange;
        break;
      case 'LOGIN':
        icon = Icons.login;
        color = Colors.green;
        break;
      case 'REGISTER':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case 'UPDATE_PROFILE':
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case 'CHANGE_PASSWORD':
        icon = Icons.lock;
        color = Colors.purple;
        break;
      case 'AVATAR_UPLOAD':
        icon = Icons.image;
        color = Colors.cyan;
        break;
      case 'LOGIN_FAILED':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case 'ACCOUNT_LOCKED':
        icon = Icons.lock_clock;
        color = Colors.red;
        break;
      case 'PASSWORD_RESET_REQUEST':
        icon = Icons.mail_outline;
        color = Colors.blue;
        break;
      case 'PASSWORD_RESET':
        icon = Icons.lock_reset;
        color = Colors.teal;
        break;
      case 'CREATE_USER':
        icon = Icons.person_add_alt;
        color = Colors.teal;
        break;
      case 'UPDATE_USER':
        icon = Icons.manage_accounts;
        color = Colors.indigo;
        break;
      case 'DELETE_USER':
        icon = Icons.delete_outline;
        color = Colors.red;
        break;
      case 'CREATE_DEPARTMENT':
        icon = Icons.business;
        color = Colors.deepOrange;
        break;
      case 'UPDATE_DEPARTMENT':
        icon = Icons.domain;
        color = Colors.deepOrange;
        break;
      case 'DELETE_DEPARTMENT':
        icon = Icons.business_center;
        color = Colors.red;
        break;
      case 'CREATE_POSITION':
        icon = Icons.person_outline;
        color = Colors.amber;
        break;
      case 'UPDATE_POSITION':
        icon = Icons.badge;
        color = Colors.amber;
        break;
      case 'DELETE_POSITION':
        icon = Icons.badge_outlined;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final RecentDashboardTab activeTab;
  final ValueChanged<RecentDashboardTab> onChanged;

  const _SegmentedToggle({
    required this.activeTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentButton(
            label: 'Recent Users',
            selected: activeTab == RecentDashboardTab.users,
            onTap: () => onChanged(RecentDashboardTab.users),
          ),
          _SegmentButton(
            label: 'Recent Activity',
            selected: activeTab == RecentDashboardTab.activity,
            onTap: () => onChanged(RecentDashboardTab.activity),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF7673C8) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF7673C8).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialsLabel extends StatelessWidget {
  final String initials;

  const _InitialsLabel({required this.initials});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF6C63FF),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
