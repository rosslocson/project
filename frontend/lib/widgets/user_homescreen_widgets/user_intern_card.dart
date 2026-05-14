import 'package:flutter/material.dart';
import '../intern_carousel_palette.dart';
import '../../screens/intern_cards.dart';
import '../../screens/intern_ross_profile_page.dart';

class UserInternCard extends StatelessWidget {
  final InternProfile intern;

  const UserInternCard({super.key, required this.intern});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ← MOVED HERE (wraps everything)
      onTap: () {
        if (intern.name == 'Rosalyn Locson') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RosalynProfilePage(intern: intern),
            ),
          );
        } else {
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: InternCarouselPalette.cardGradient(context),
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: InternCarouselPalette.cardShadows(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InternAvatar(intern: intern),
                const SizedBox(height: 24),
                Text(
                  // ← plain Text now, no GestureDetector
                  intern.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: InternCarouselPalette.cardForeground(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  intern.internNumber != 'N/A'
                      ? 'Intern #${intern.internNumber}'
                      : '',
                  style: TextStyle(
                    fontSize: 14,
                    color: InternCarouselPalette.cardForegroundMuted(context),
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
