import 'package:flutter/material.dart';
import '../../screens/intern_widgets.dart';
import '../../screens/intern_ross_profile_page.dart';

class UserInternCard extends StatelessWidget {
  final InternProfile intern;

  const UserInternCard({super.key, required this.intern});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ← MOVED HERE (wraps everything)
      onTap: () {
        if (intern.id == 28) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RosalynProfilePage(intern: intern),
            ),
          );
        } else {
          // ← ADD THIS
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InternDetailPage(intern: intern),
            ),
          );
        }
      },
      child: Container(
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
                InternAvatar(intern: intern),
                const SizedBox(height: 24),
                Text(
                  // ← plain Text now, no GestureDetector
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
      ),
    );
  }
}
