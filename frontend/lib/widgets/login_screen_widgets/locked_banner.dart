import 'package:flutter/material.dart';
import '../app_theme.dart'; // Adjust path if needed

class LockedBanner extends StatelessWidget {
  final int lockSecsLeft;
  final VoidCallback onForgotPassword;

  const LockedBanner({
    super.key, 
    required this.lockSecsLeft, 
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic color logic: kCrimsonDeep for light mode, a brighter crimson for dark mode visibility
    final Color mainColor = isDark ? const Color(0xFFFF6B6B) : kCrimsonDeep;
    final Color bgColor = mainColor.withValues(alpha: isDark ? 0.12 : 0.07);
    final Color borderColor = mainColor.withValues(alpha: isDark ? 0.25 : 0.2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lock, color: mainColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Account temporarily locked', 
              style: TextStyle(
                color: mainColor, 
                fontWeight: FontWeight.bold, 
                fontSize: 13,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.timer_outlined, color: mainColor, size: 16),
            const SizedBox(width: 8),
            Text(
              'Try again in $lockSecsLeft second${lockSecsLeft != 1 ? 's' : ''}', 
              style: TextStyle(color: mainColor, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: lockSecsLeft / 60,
              backgroundColor: mainColor.withValues(alpha: 0.15),
              color: mainColor,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onForgotPassword,
            child: Text(
              'Forgot your password? Reset it now →', 
              style: TextStyle(
                color: mainColor, 
                fontSize: 12, 
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}