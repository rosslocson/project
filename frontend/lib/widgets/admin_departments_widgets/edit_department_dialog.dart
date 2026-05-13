import 'package:flutter/material.dart';
import '../app_theme.dart'; // ADD

class EditDepartmentDialog extends StatefulWidget {
  final String currentName;
  const EditDepartmentDialog({super.key, required this.currentName});

  @override
  State<EditDepartmentDialog> createState() => _EditDepartmentDialogState();
}

class _EditDepartmentDialogState extends State<EditDepartmentDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkInternTheme;
    final activeColor = isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);
    final inputFill = isDark ? const Color(0xFF1A1A3A) : const Color(0xFFEEF2F5);
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white.withValues(alpha: 0.6) : null;
    final theme = context.internTheme;

    return AlertDialog(
      backgroundColor: theme.dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(children: [
        Icon(Icons.edit_outlined, color: activeColor, size: 20),
        const SizedBox(width: 8),
        Text('Edit Department', style: TextStyle(color: theme.surfaceText)),
      ]),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        style: TextStyle(color: inputTextColor, fontSize: 13),
        decoration: InputDecoration(
          labelText: 'Name',
          labelStyle: TextStyle(color: labelColor),
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: activeColor.withValues(alpha: 0.5))),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: theme.surfaceText)),
        ),
        ElevatedButton(
          onPressed: () {
            final v = _ctrl.text.trim();
            if (v.isNotEmpty) Navigator.pop(context, v);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}