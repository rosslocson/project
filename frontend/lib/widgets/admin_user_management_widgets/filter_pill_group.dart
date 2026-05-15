// lib/widgets/users/filter_pill_group.dart

import 'package:flutter/material.dart';
import '../app_theme.dart';

class FilterPillGroup extends StatelessWidget {
  final List<Map<String, dynamic>> tabs;
  final String filterStatus;
  final Function(String) onTabChanged;

  const FilterPillGroup({
    super.key,
    required this.tabs,
    required this.filterStatus,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;

    // Dynamic Active Color based on your palette:
    // Dark Mode: Accent Purple (#7367F0) | Light Mode: Cosmic Blue (#00022E)
    final activeColor =
        isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);

    // Track Background (The long pill container)
    final trackColor = isDark
        ? const Color(0xFF00022E).withValues(alpha: 0.6) // Deep cosmic pocket
        : const Color(0xFF6B7280)
            .withValues(alpha: 0.1); // Soft wash of Secondary Text

    // Border Color
    final trackBorderColor = isDark
        ? theme.border.withValues(alpha: 0.15)
        : const Color(0xFF6B7280).withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: trackBorderColor, width: 1),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: tabs.map((tab) {
          final id = tab['id'] as String;
          final label = tab['label'] as String;
          final count = tab['count'] as int;
          final isSelected = filterStatus == id;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : isDark
                          ? const Color(0xFF00001A).withValues(alpha: 0.0)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.0),
                            blurRadius: 0,
                            offset: Offset.zero,
                          )
                        ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$label ($count)',
                  style: TextStyle(
                    // Text color: White when selected
                    // When unselected: White opacity for Dark | Secondary Gray for Light
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF6B7280)),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
