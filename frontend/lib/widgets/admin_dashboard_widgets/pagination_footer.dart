import 'package:flutter/material.dart';
import '../app_theme.dart';

class PaginationFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const PaginationFooter({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    int startPage = 1;
    int endPage = totalPages;

    if (totalPages > 5) {
      startPage = currentPage - 2;
      endPage = currentPage + 2;

      if (startPage < 1) {
        startPage = 1;
        endPage = 5;
      }

      if (endPage > totalPages) {
        endPage = totalPages;
        startPage = totalPages - 4;
        if (startPage < 1) startPage = 1;
      }
    }

    int visiblePages = endPage - startPage + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: currentPage > 1 ? onPrev : null,
            icon: const Icon(Icons.arrow_back_ios, size: 12),
            label: const Text('Prev'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              disabledForegroundColor: theme.mutedText.withValues(alpha: 0.5),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 300;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(visiblePages, (index) {
                    final pageNumber = startPage + index;
                    final isActive = pageNumber == currentPage;
                    return Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: isCompact ? 0.3 : 4),
                      width:
                          isActive ? (isCompact ? 2 : 20) : (isCompact ? 1 : 8),
                      height: isCompact ? 2 : 8,
                      decoration: BoxDecoration(
                        color:
                            isActive ? const Color(0xFF6366F1) : theme.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          TextButton(
            onPressed: currentPage < totalPages ? onNext : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              disabledForegroundColor: theme.mutedText.withValues(alpha: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Next'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
