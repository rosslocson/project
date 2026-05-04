import 'package:flutter/material.dart';

class StatusMessageBanner extends StatelessWidget {
  final String msg;
  final bool success;

  const StatusMessageBanner({super.key, required this.msg, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: success ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error_outline,
              color: success ? Colors.green : Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    fontSize: 13,
                    color: success ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}