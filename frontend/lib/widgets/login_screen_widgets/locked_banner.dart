import 'package:flutter/material.dart';
import '../app_theme.dart'; // Adjust path if needed

class LockedBanner extends StatelessWidget {
  final int lockSecsLeft;
  final VoidCallback onForgotPassword;

  const LockedBanner({super.key, required this.lockSecsLeft, required this.onForgotPassword});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCrimsonDeep.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCrimsonDeep.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lock, color: kCrimsonDeep, size: 18),
            SizedBox(width: 8),
            Text('Account temporarily locked', style: TextStyle(color: kCrimsonDeep, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.timer_outlined, color: kCrimsonDeep, size: 16),
            const SizedBox(width: 8),
            Text('Try again in $lockSecsLeft second${lockSecsLeft != 1 ? 's' : ''}', style: const TextStyle(color: kCrimsonDeep, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: lockSecsLeft / 60,
              backgroundColor: kCrimsonDeep.withValues(alpha: 0.15),
              color: kCrimsonDeep,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onForgotPassword,
            child: const Text('Forgot your password? Reset it now →', style: TextStyle(color: kCrimsonDeep, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}