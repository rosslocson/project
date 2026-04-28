import 'package:flutter/material.dart';

// Adjust this import path based on where InternProfile and InternAvatar are located
import '../../screens/intern_widgets.dart';

class UserInternCard extends StatelessWidget {
  final InternProfile intern;
  
  const UserInternCard({super.key, required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Hero(
        tag: 'intern-${intern.internNumber}',
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shows real avatar photo if avatarUrl is set, else initials
              InternAvatar(intern: intern),
              const SizedBox(height: 24),
              Text(
                intern.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                intern.internNumber != 'N/A'
                    ? 'Intern #${intern.internNumber}'
                    : '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}