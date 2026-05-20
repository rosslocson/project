import 'package:flutter/material.dart';
import '../app_theme.dart';
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
    final theme = context.internTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        color: theme.topbarText,
                      ),
                ),
                Text(
                  'Platform members',
                  style: TextStyle(
                    fontSize: 12, 
                    color: theme.topbarMutedText,
                  ),
                ),
              ],
            ),
            Text(
              'Page $usersPage of $totalPages',
              style: TextStyle(
                color: theme.topbarMutedText.withValues(alpha: 0.8), 
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 500,
          decoration: BoxDecoration(
            color: isDark
                ? theme.listBackground.withValues(alpha: 0.98)
                : theme.sidebarBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildUsersList(
                    context,
                    key: ValueKey<int>(usersPage),
                  ),
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

  Widget _buildUsersList(BuildContext context, {required Key key}) {
    final users = (stats?['recent_users'] as List?) ?? [];
    final theme = context.internTheme;
    if (users.isEmpty) {
      return Center(
        key: key, 
        child: Text('No users yet', style: TextStyle(color: theme.listText)),
      );
    }

    return ListView.separated(
      key: key,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: users.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: theme.border, indent: 70),
      itemBuilder: (context, i) {
        if (i >= users.length) return const SizedBox.shrink();
        
        final u = users[i];
        if (u == null || u is! Map<String, dynamic>) {
          return const SizedBox.shrink(); // Skip invalid user data
        }
        
        // Safely extract string values
        final fName = u['first_name']?.toString() ?? '';
        final lName = u['last_name']?.toString() ?? '';
        final name = u['name']?.toString() ?? '';
        final email = u['email']?.toString() ?? '';
        
        // Determine the best display name
        final displayName = [fName, lName].where((s) => s.isNotEmpty).join(' ');
        final titleText = displayName.isNotEmpty 
            ? displayName 
            : (name.isNotEmpty ? name : (email.isNotEmpty ? email : 'Unknown'));
        
        // Robust initials logic
        String initials = 'U';
        try {
          if (fName.isNotEmpty || lName.isNotEmpty) {
            final firstInitial = fName.isNotEmpty ? fName.trim()[0].toUpperCase() : '';
            final lastInitial = lName.isNotEmpty ? lName.trim()[0].toUpperCase() : '';
            initials = '$firstInitial$lastInitial'.trim();
            if (initials.isEmpty) initials = 'U';
          } else if (name.isNotEmpty) {
            final trimmedName = name.trim();
            if (trimmedName.isNotEmpty) {
              final parts = trimmedName.split(RegExp(r'\s+'));
              if (parts.length > 1) {
                initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
              } else {
                initials = parts[0][0].toUpperCase();
              }
            }
          } else if (email.isNotEmpty) {
            final trimmedEmail = email.trim();
            if (trimmedEmail.isNotEmpty) {
              initials = trimmedEmail[0].toUpperCase();
            }
          }
        } catch (e) {
          initials = 'U'; // Fallback in case of any string indexing errors
        }

        // Check if there is an avatar image URL in the map
        final avatarUrl = u['avatar']?.toString() ?? u['avatar_url']?.toString() ?? u['image']?.toString();
        final hasImage = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.trim().isNotEmpty;
        final fullAvatarUrl = hasImage 
            ? (avatarUrl.startsWith('http') 
                ? avatarUrl 
                : (avatarUrl.startsWith('/uploads/') 
                    ? 'http://localhost:8080$avatarUrl'
                    : 'http://localhost:8080/uploads/$avatarUrl'))
            : '';
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF), 
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFF6C63FF), 
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
          title: Text(
            titleText, 
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.listText),
          ),
          subtitle: Text(email, style: TextStyle(fontSize: 11, color: theme.listMutedText)),
          trailing: _buildRoleBadge(context, u['role']?.toString()),
        );
      },
    );
  }

  Widget _buildRoleBadge(BuildContext context, String? role) {
    final theme = context.internTheme;
    final roleStr = role?.trim().toLowerCase() ?? '';
    final isAdmin = roleStr == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? theme.adminBadgeBackground : theme.userBadgeBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
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
}
