import 'package:flutter/material.dart';

class EditProfileStatusBanner extends StatelessWidget {
  final String msg;
  final bool success;
  final VoidCallback onClose;

  const EditProfileStatusBanner({
    super.key,
    required this.msg,
    required this.success,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: success ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: success ? Colors.green.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: success ? Colors.green.shade600 : Colors.red.shade600,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: success ? Colors.green.shade800 : Colors.red.shade800, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}