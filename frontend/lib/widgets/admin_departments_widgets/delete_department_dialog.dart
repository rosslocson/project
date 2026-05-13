import 'package:flutter/material.dart';
import '../app_theme.dart'; // ADD

class DeleteDepartmentDialog extends StatelessWidget {
  final String name;
  const DeleteDepartmentDialog({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;

    return AlertDialog(
      backgroundColor: theme.dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(children: [
        Icon(Icons.delete_forever, color: Colors.red.shade700, size: 20),
        const SizedBox(width: 8),
        Text('Confirm Delete', style: TextStyle(color: theme.surfaceText)),
      ]),
      content: RichText(
        text: TextSpan(
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
            fontSize: 14,
          ),
          children: [
            const TextSpan(text: 'Remove '),
            TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: ' from departments?'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: theme.surfaceText)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}