import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../intern_carousel_palette.dart';

import '../../screens/intern_cards.dart';
import '../../screens/intern_directory_screen.dart';
import '../../screens/intern_cards/intern_ross_profile_page.dart';
import '../../screens/intern_cards/intern_alex_profile_page.dart';
import '../../screens/intern_cards/intern_airra_profile_page.dart';

class InternCarouselSection extends StatefulWidget {
  final List<InternProfile> interns;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const InternCarouselSection({
    super.key,
    required this.interns,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  State<InternCarouselSection> createState() => _InternCarouselSectionState();
}

class _InternCarouselSectionState extends State<InternCarouselSection> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  double _lastTargetFraction = 0.35;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.interns.isNotEmpty ? widget.interns.length * 1000 : 0;
    _pageController = PageController(
        viewportFraction: _lastTargetFraction, initialPage: _currentPage);
    if (!widget.loading && widget.interns.isNotEmpty) {
      _startAutoScroll();
    }
  }

  @override
  void didUpdateWidget(covariant InternCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interns != oldWidget.interns && widget.interns.isNotEmpty) {
      _currentPage = widget.interns.length * 1000;
      _rebuildPageController(_lastTargetFraction);
      _startAutoScroll();
    }
  }

  void _rebuildPageController(double targetFraction) {
    _pageController.dispose();
    _pageController = PageController(
      viewportFraction: targetFraction,
      initialPage: _currentPage,
    );
    _lastTargetFraction = targetFraction;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.interns.isEmpty) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _prev() {
    _autoScrollTimer?.cancel();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _startAutoScroll();
  }

  void _next() {
    _autoScrollTimer?.cancel();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _startAutoScroll();
  }

  void _openDetail(InternProfile intern) {
    _autoScrollTimer?.cancel();

    final page = intern.name == 'Rosalyn Locson'
        ? RosalynProfilePage(intern: intern)
        : intern.name == 'Alex Llanza'
            ? AlexProfilePage(intern: intern)
            : intern.name == 'Airra Lorraine De Castro'
                ? AirraProfilePage(intern: intern)
                : InternDetailPage(intern: intern);

    Navigator.of(context)
        .push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ))
        .then((_) {
      if (mounted) _startAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 550;
        final double targetFraction = isCompact ? 0.75 : 0.35;

        if (targetFraction != _lastTargetFraction) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _rebuildPageController(targetFraction);
              });
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: isCompact
                  // ── Compact: title left, "View All" right, no overlap
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Meet Our Interns',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.topbarText,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const InternDirectoryScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: InternCarouselPalette.accent,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View All'),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12),
                            ],
                          ),
                        ),
                      ],
                    )
                  // ── Wide: UNTOUCHED original layout
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Meet Our Interns',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.topbarText,
                                ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const InternDirectoryScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: InternCarouselPalette.accent,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View All'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _buildCarouselBody(isCompact),
            const SizedBox(height: 16),
            if (!widget.loading && widget.interns.isNotEmpty)
              _buildDotNavigation(isCompact),
          ],
        );
      },
    );
  }

  Widget _buildCarouselBody(bool isCompact) {
    final double computedHeight = isCompact ? 210 : 180;

    if (widget.loading) {
      return SizedBox(
        height: computedHeight,
        child: const Center(
          child: CircularProgressIndicator(
            color: InternCarouselPalette.accent,
          ),
        ),
      );
    }

    if (widget.error != null) {
      final theme = context.internTheme;
      return SizedBox(
        height: computedHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: InternCarouselPalette.accent,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(widget.error!,
                  style: TextStyle(color: theme.topbarMutedText),
                  textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(
                  Icons.refresh,
                  color: InternCarouselPalette.accent,
                ),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: InternCarouselPalette.accent),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.interns.isEmpty) {
      return SizedBox(
        height: computedHeight,
        child: Center(
            child: Text('No interns found.',
                style: TextStyle(
                  color: context.internTheme.topbarMutedText,
                  fontSize: 15,
                ))),
      );
    }

    return SizedBox(
      height: computedHeight,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (context, index) {
          final intern = widget.interns[index % widget.interns.length];
          final isCenter = index == _currentPage;
          return AnimatedScale(
            scale: isCenter ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: isCenter ? 1.0 : 0.45,
              duration: const Duration(milliseconds: 350),
              child: GestureDetector(
                onTap: () => _openDetail(intern),
                child: _InternCardFront(intern: intern, isCompact: isCompact),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDotNavigation(bool isCompact) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ArrowButton(
                  icon: Icons.chevron_left, onTap: _prev, isCompact: isCompact),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.interns.length, (i) {
                  final active = i == (_currentPage % widget.interns.length);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? InternCarouselPalette.dotActive
                          : InternCarouselPalette.dotActive
                              .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 16),
              _ArrowButton(
                  icon: Icons.chevron_right,
                  onTap: _next,
                  isCompact: isCompact),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternCardFront extends StatelessWidget {
  final InternProfile intern;
  final bool isCompact;

  const _InternCardFront({
    required this.intern,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          BorderedAvatar(
            intern: intern,
            size: isCompact ? 55 : 70,
            borderRadius: 18,
            fontSize: isCompact ? 22 : 28,
          ),
          const SizedBox(height: 12),
          Text(
            intern.name,
            style: TextStyle(
              fontSize: isCompact ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: InternCarouselPalette.cardForeground(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            intern.internNumber != 'N/A'
                ? 'Intern #${intern.internNumber}'
                : '',
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: InternCarouselPalette.cardForegroundMuted(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isCompact;

  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.isCompact,
  });

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double buttonSize = widget.isCompact ? 34 : 40;
    final double iconSize = widget.isCompact ? 18 : 22;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: InternCarouselPalette.arrowBackground(
              context,
              hovered: _isHovered,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: InternCarouselPalette.arrowBorder(
                context,
                hovered: _isHovered,
              ),
              width: 0.8,
            ),
          ),
          child: Icon(
            widget.icon,
            color: InternCarouselPalette.arrowIcon(
              context,
              hovered: _isHovered,
            ),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class BorderedAvatar extends StatelessWidget {
  final InternProfile intern;
  final double size;
  final double borderRadius;
  final double fontSize;

  const BorderedAvatar({
    super.key,
    required this.intern,
    required this.size,
    required this.borderRadius,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final initials = intern.name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .where((e) => e.isNotEmpty)
        .take(2)
        .join();

    // Determine final avatar URL, handle relative and absolute paths
    String? finalAvatarUrl;
    if (intern.avatarUrl != null && intern.avatarUrl!.isNotEmpty) {
      final rawUrl = intern.avatarUrl!;
      if (rawUrl.startsWith('http')) {
        finalAvatarUrl = rawUrl;
      } else if (rawUrl.startsWith('/')) {
        finalAvatarUrl = 'http://127.0.0.1:8080$rawUrl';
      } else {
        finalAvatarUrl = 'http://127.0.0.1:8080/$rawUrl';
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        image: finalAvatarUrl != null
            ? DecorationImage(
                image: NetworkImage(finalAvatarUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: finalAvatarUrl == null
          ? Text(
              initials.isNotEmpty ? initials : '??',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5E001F),
              ),
            )
          : null,
    );
  }
}
