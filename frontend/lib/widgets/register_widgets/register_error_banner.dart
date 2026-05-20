import 'package:flutter/material.dart';

const kCosmicBlue = Color(0xFF00022E);

class RegisterErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onClear;

  const RegisterErrorBanner({
    super.key,
    required this.error,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50;
    final borderColor = isDark ? Colors.red.shade700 : Colors.red.shade200;
    final iconColor = isDark ? Colors.red.shade200 : Colors.red.shade700;
    final textColor = isDark ? Colors.red.shade100 : Colors.red.shade900;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 20, color: iconColor),
          ),
        ],
      ),
    );
  }
}
