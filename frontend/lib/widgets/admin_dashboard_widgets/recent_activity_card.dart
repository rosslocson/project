import 'package:flutter/material.dart';

import 'pagination_footer.dart';

class RecentActivityCard extends StatelessWidget {
  final List<dynamic> activityLogs;
  final int activityPage;
  final int totalPages; // Note: We will dynamically override this locally based on the weekly filter
  final Function(int) onPageChanged;

  const RecentActivityCard({
    super.key,
    required this.activityLogs,
    required this.activityPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  // --- REMOVED: Local filtering since backend now provides weekly logs ---

  // --- NEW: Clean up the raw "(active=true, archived=false)" string bug ---
  String _cleanDetails(String details) {
    String cleaned = details.replaceAll(RegExp(r'\s*\(active=true,\s*archived=false\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*\(active=false,\s*archived=false\)'), ' (Account Deactivated)');
    cleaned = cleaned.replaceAll(RegExp(r'\s*\(active=false,\s*archived=true\)'), ' (Account Archived)');
    return cleaned.trim();
  }

  // --- NEW: Format admin action strings into human-readable sentences ---
  String formatAdminAction(String rawDetails) {
    if (rawDetails.isEmpty) return 'Unknown action';
    
    // Regex to match: "Admin updated user [email] (active=X, archived=Y)"
    final RegExp adminUpdatePattern = RegExp(
      r'^Admin updated user ([^\s]+) \(active=(true|false),\s*archived=(true|false)\)$'
    );

    final match = adminUpdatePattern.firstMatch(rawDetails);
    if (match != null) {
      final email = match.group(1)!;
      final active = match.group(2)!;
      final archived = match.group(3)!;

      if (active == 'false' && archived == 'false') {
        return 'Admin deactivated user $email';
      } else if (active == 'false' && archived == 'true') {
        return 'Admin archived user $email';
      } else if (active == 'true' && archived == 'false') {
        return 'Admin activated user $email';
      }
    }

    // If no match, return original string (it should already be human-readable from backend)
    return rawDetails;
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

  Widget _actionIcon(String? action) {
    IconData icon;
    Color color;
    switch (action) {
      // User Actions
      case 'LOGIN': icon = Icons.login; color = Colors.green; break;
      case 'REGISTER': icon = Icons.person_add; color = Colors.blue; break;
      case 'UPDATE_PROFILE': icon = Icons.edit; color = Colors.orange; break;
      case 'CHANGE_PASSWORD': icon = Icons.lock; color = Colors.purple; break;
      case 'AVATAR_UPLOAD': icon = Icons.image; color = Colors.cyan; break;
      case 'LOGIN_FAILED': icon = Icons.warning_amber_rounded; color = Colors.red; break;
      case 'ACCOUNT_LOCKED': icon = Icons.lock_clock; color = Colors.red; break;
      case 'PASSWORD_RESET_REQUEST': icon = Icons.mail_outline; color = Colors.blue; break;
      case 'PASSWORD_RESET': icon = Icons.lock_reset; color = Colors.teal; break;
      
      // User Management (Admin)
      case 'CREATE_USER': icon = Icons.person_add_alt; color = Colors.teal; break;
      case 'UPDATE_USER': icon = Icons.manage_accounts; color = Colors.indigo; break;
      case 'DELETE_USER': icon = Icons.delete_outline; color = Colors.red; break;
      
      // Department Management (Admin)
      case 'CREATE_DEPARTMENT': icon = Icons.business; color = Colors.deepOrange; break;
      case 'UPDATE_DEPARTMENT': icon = Icons.domain; color = Colors.deepOrange; break;
      case 'DELETE_DEPARTMENT': icon = Icons.business_center; color = Colors.red; break;
      
      // Position Management (Admin)
      case 'CREATE_POSITION': icon = Icons.person_outline; color = Colors.amber; break;
      case 'UPDATE_POSITION': icon = Icons.badge; color = Colors.amber; break;
      case 'DELETE_POSITION': icon = Icons.badge_outlined; color = Colors.red; break;
      
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
    // --- Pagination Calculation ---
    final filteredLogs = activityLogs; // Backend already filtered for current week
    debugPrint('🔍 RECENT_ACTIVITY_CARD: Received ${filteredLogs.length} logs for display on this page');
    debugPrint('🔍 RECENT_ACTIVITY_CARD: Total pages from parent: $totalPages, Current page: $activityPage');
    
    if (filteredLogs.isNotEmpty) {
      debugPrint('🔍 RECENT_ACTIVITY_CARD: First log - action=${filteredLogs[0]['action']}, user=${filteredLogs[0]['user']}');
    }
    
    // Use the totalPages passed from parent, don't recalculate it!
    // The parent has already calculated total pages based on ALL activities
    int actualTotalPages = totalPages;
    if (actualTotalPages < 1) actualTotalPages = 1;
    
    // Prevent out-of-bounds page if the list dynamically shrinks
    int safeCurrentPage = activityPage > actualTotalPages ? actualTotalPages : activityPage;
    if (safeCurrentPage < 1) safeCurrentPage = 1;

    // The logs passed in are already paginated by the parent, just display them
    final paginatedLogs = filteredLogs;

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
                  'System mission log (Past 7 Days)',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
            Text(
              'Page $safeCurrentPage of $actualTotalPages',
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
                  child: _buildActivityTimeline(
                    key: ValueKey<int>(safeCurrentPage),
                    logs: paginatedLogs, // Pass only the current page's logs
                  ),
                ),
              ),
              PaginationFooter(
                currentPage: safeCurrentPage,
                totalPages: actualTotalPages,
                // Ensure we don't paginate out of bounds
                onPrev: safeCurrentPage > 1 
                    ? () => onPageChanged(safeCurrentPage - 1) 
                    : () {}, 
                onNext: safeCurrentPage < actualTotalPages 
                    ? () => onPageChanged(safeCurrentPage + 1) 
                    : () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTimeline({required Key key, required List<dynamic> logs}) {
    if (logs.isEmpty) {
      return Center(
        key: key, 
        child: const Text('No activity this week', style: TextStyle(color: Colors.black87))
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
        
        // Clean the display text to remove the bugged string
        String rawDetails = log['details'] as String? ?? action ?? '';
        final displayText = formatAdminAction(rawDetails);
        
        final logUser = log['user'] as Map<String, dynamic>?;
        final userName = logUser != null 
            ? '${logUser['first_name'] ?? ''} ${logUser['last_name'] ?? ''}'.trim() 
            : 'System';
        final isLastItem = i == logs.length - 1;

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