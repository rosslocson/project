import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ErrorBanner extends StatelessWidget {
  final AuthProvider auth;
  final int attemptsLeft;
  final VoidCallback onForgotPassword;

  const ErrorBanner({super.key, required this.auth, required this.attemptsLeft, required this.onForgotPassword});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(auth.error ?? '', style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            GestureDetector(
              onTap: () => context.read<AuthProvider>().clearError(),
              child: Icon(Icons.close, size: 20, color: Colors.orange.shade400),
            ),
          ]),
          if (attemptsLeft > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text('Attempts left: ', style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
              ...List.generate(
                3,
                (i) => Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < attemptsLeft ? Colors.orange.shade500 : Colors.orange.shade100,
                  ),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onForgotPassword,
            child: Text('Forgot password? Reset it →', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}