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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCosmicBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCosmicBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: kCosmicBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: kCosmicBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 20, color: kCosmicBlue),
          ),
        ],
      ),
    );
  }
}