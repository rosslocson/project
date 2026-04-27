import 'package:flutter/material.dart';

import 'pagination_footer.dart';

class RecentActivityCard extends StatelessWidget {
  final List<dynamic> activityLogs;
  final int activityPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const RecentActivityCard({
    super.key,
    required this.activityLogs,
    required this.activityPage,
    required this.totalPages,
    required this.onPageChanged,
  });

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

  Widget _actionIcon(String? action) {
    IconData icon;
    Color color;
    switch (action) {
      case 'LOGIN': icon = Icons.login; color = Colors.green; break;
      case 'REGISTER': icon = Icons.person_add; color = Colors.blue; break;
      case 'UPDATE_PROFILE': icon = Icons.edit; color = Colors.orange; break;
      case 'CHANGE_PASSWORD': icon = Icons.lock; color = Colors.purple; break;
      case 'LOGIN_FAILED': icon = Icons.warning_amber_rounded; color = Colors.red; break;
      case 'ACCOUNT_LOCKED': icon = Icons.lock_clock; color = Colors.red; break;
      case 'PASSWORD_RESET_REQUEST': icon = Icons.mail_outline; color = Colors.blue; break;
      case 'PASSWORD_RESET': icon = Icons.lock_reset; color = Colors.teal; break;
      case 'CREATE_USER': icon = Icons.person_add_alt; color = Colors.teal; break;
      case 'DELETE_USER': icon = Icons.delete_outline; color = Colors.red; break;
      case 'UPDATE_USER': icon = Icons.manage_accounts; color = Colors.indigo; break;
      default: icon = Icons.info_outline; color = Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  'System mission log',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
            Text(
              'Page $activityPage of $totalPages',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildActivityTimeline(key: ValueKey<int>(activityPage)),
                ),
              ),
              PaginationFooter(
                currentPage: activityPage,
                totalPages: totalPages,
                onPrev: () => onPageChanged(activityPage - 1),
                onNext: () => onPageChanged(activityPage + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTimeline({required Key key}) {
    if (activityLogs.isEmpty) {
      return Center(key: key, child: const Text('No activity this week', style: TextStyle(color: Colors.black87)));
    }

    return ListView.builder(
      key: key,
      padding: const EdgeInsets.only(top: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activityLogs.length,
      itemBuilder: (context, i) {
        final log = activityLogs[i];
        final action = log['action'] as String?;
        final displayText = log['details'] as String? ?? action ?? '';
        final logUser = log['user'] as Map<String, dynamic>?;
        final userName = logUser != null ? '${logUser['first_name'] ?? ''} ${logUser['last_name'] ?? ''}'.trim() : 'System';
        final isLastItem = i == activityLogs.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 60,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isLastItem)
                      Positioned(
                        top: 36, bottom: -16,
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
                  padding: const EdgeInsets.only(top: 16, bottom: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayText,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                          Text(
                            _formatDate(log['created_at'] as String?),
                            style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(userName, style: const TextStyle(fontSize: 11, color: Colors.black54)),
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
}