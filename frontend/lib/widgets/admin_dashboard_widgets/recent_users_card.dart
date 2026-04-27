import 'package:flutter/material.dart';

import 'pagination_footer.dart';

class RecentUsersCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final int usersPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const RecentUsersCard({
    super.key,
    required this.stats,
    required this.usersPage,
    required this.totalPages,
    required this.onPageChanged,
  });

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
                  'Recent Users',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                Text(
                  'Platform members',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
            Text(
              'Page $usersPage of $totalPages',
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
                  child: _buildUsersList(key: ValueKey<int>(usersPage)),
                ),
              ),
              PaginationFooter(
                currentPage: usersPage,
                totalPages: totalPages,
                onPrev: () => onPageChanged(usersPage - 1),
                onNext: () => onPageChanged(usersPage + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList({required Key key}) {
    final users = (stats?['recent_users'] as List?) ?? [];
    if (users.isEmpty) {
      return Center(key: key, child: const Text('No users yet', style: TextStyle(color: Colors.black87)));
    }

    return ListView.separated(
      key: key,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12, indent: 70),
      itemBuilder: (context, i) {
        final u = users[i];
        final fName = u['first_name']?.toString() ?? '';
        final lName = u['last_name']?.toString() ?? '';
        final displayName = [fName, lName].where((s) => s.isNotEmpty).join(' ');
        final titleText = displayName.isNotEmpty ? displayName : (u['name']?.toString() ?? u['email']?.toString() ?? 'Unknown');
        final initials = '${fName.isNotEmpty ? fName[0] : ''}${lName.isNotEmpty ? lName[0] : ''}'.toUpperCase();
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(titleText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          subtitle: Text(u['email'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.black54)),
          trailing: _buildRoleBadge(u['role']),
        );
      },
    );
  }

  Widget _buildRoleBadge(String? role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFDBE9F4) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAdmin ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1)),
      ),
      child: Text(
        role ?? 'user',
        style: TextStyle(
          color: isAdmin ? Colors.red.shade700 : Colors.green.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}