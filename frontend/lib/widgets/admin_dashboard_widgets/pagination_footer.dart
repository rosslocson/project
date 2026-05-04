import 'package:flutter/material.dart';

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
    // Calculate visible page range for sliding window effect
    int startPage = 1;
    int endPage = totalPages;
    
    if (totalPages > 5) {
      // Center the current page in the window when possible
      startPage = currentPage - 2;
      endPage = currentPage + 2;
      
      // Adjust if at the beginning
      if (startPage < 1) {
        startPage = 1;
        endPage = 5;
      }
      
      // Adjust if at the end
      if (endPage > totalPages) {
        endPage = totalPages;
        startPage = totalPages - 4;
        if (startPage < 1) startPage = 1;
      }
    }
    
    int visiblePages = endPage - startPage + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: currentPage > 1 ? onPrev : null,
            icon: const Icon(Icons.arrow_back_ios, size: 12),
            label: const Text('Prev'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7673C8),
              disabledForegroundColor: Colors.black26,
            ),
          ),
          Row(
            children: List.generate(visiblePages, (index) {
              final pageNumber = startPage + index;
              final isActive = pageNumber == currentPage;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF7673C8) : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          TextButton(
            onPressed: currentPage < totalPages ? onNext : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7673C8),
              disabledForegroundColor: Colors.black26,
            ),
            child: const Row(
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