// lib/widgets/users/filter_pill_group.dart

import 'package:flutter/material.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: tabs.map((tab) {
          final id = tab['id'] as String;
          final label = tab['label'] as String;
          final count = tab['count'] as int;
          final isSelected = filterStatus == id;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00022E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF4A5E9A).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$label ($count)',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
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