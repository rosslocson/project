import 'package:flutter/material.dart';

class DeleteDepartmentDialog extends StatelessWidget {
  final String name;

  const DeleteDepartmentDialog({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(children: [
        Icon(Icons.delete_forever, color: Colors.red.shade700, size: 20),
        const SizedBox(width: 8),
        const Text('Confirm Delete'),
      ]),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
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
          child: const Text('Cancel'),
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