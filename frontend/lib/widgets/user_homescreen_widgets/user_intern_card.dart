import 'dart:ui';
import 'package:flutter/material.dart';
import '../intern_carousel_palette.dart';
import '../../screens/intern_cards.dart';
import '../../screens/intern_cards/intern_ross_profile_page.dart';
import '../../screens/intern_cards/intern_alex_profile_page.dart';
import '../../screens/intern_cards/intern_airra_profile_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserInternCard
// ─────────────────────────────────────────────────────────────────────────────

class UserInternCard extends StatelessWidget {
  final InternProfile intern;

  const UserInternCard({super.key, required this.intern});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (intern.name == 'Rosalyn Locson') {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => RosalynProfilePage(intern: intern)),
          );
        } else if (intern.name == 'Alex Llanza') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AlexProfilePage(intern: intern)),
          );
        } else if (intern.name == 'Airra Lorraine De Castro') {
          // 👈 add this block
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AirraProfilePage(intern: intern)),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InternDetailPage(intern: intern)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Hero(
          tag: 'intern-hero-${intern.id}',
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

// ─────────────────────────────────────────────────────────────────────────────
// GlassArrowButton
// ─────────────────────────────────────────────────────────────────────────────

class GlassArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GlassArrowButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  State<GlassArrowButton> createState() => _GlassArrowButtonState();
}

class _GlassArrowButtonState extends State<GlassArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  InternCarouselPalette.arrowBorder(context, hovered: _hovered),
              width: 1.2,
            ),
          ),
          // ClipOval is required for BackdropFilter to be clipped to the circle
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: InternCarouselPalette.arrowBlurSigma(context),
                sigmaY: InternCarouselPalette.arrowBlurSigma(context),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: InternCarouselPalette.arrowBackground(
                    context,
                    hovered: _hovered,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: InternCarouselPalette.arrowIcon(context,
                      hovered: _hovered),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CarouselDotIndicator
// ─────────────────────────────────────────────────────────────────────────────

class CarouselDotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const CarouselDotIndicator({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? InternCarouselPalette.dotActiveFill(context)
                : InternCarouselPalette.dotInactiveFill(context),
            border: Border.all(
              color: isActive
                  ? InternCarouselPalette.dotActiveBorder(context)
                  : InternCarouselPalette.dotInactiveBorder(context),
              width: 0.8,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CarouselControls  (arrows + dots in one row, drop-in widget)
// ─────────────────────────────────────────────────────────────────────────────

class CarouselControls extends StatelessWidget {
  final int count;
  final int current;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const CarouselControls({
    super.key,
    required this.count,
    required this.current,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPrev,
        ),
        const SizedBox(width: 16),
        CarouselDotIndicator(count: count, current: current),
        const SizedBox(width: 16),
        GlassArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}
