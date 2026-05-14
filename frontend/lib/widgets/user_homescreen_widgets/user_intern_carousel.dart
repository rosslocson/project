import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../intern_carousel_palette.dart';

// Adjust this import path based on where InternProfile and InternDetailPage are located
import '../../screens/intern_cards.dart';
import '../../screens/intern_directory_screen.dart';
import 'user_intern_card.dart';

class UserInternCarousel extends StatefulWidget {
  final List<InternProfile> interns;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const UserInternCarousel({
    super.key,
    required this.interns,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  State<UserInternCarousel> createState() => _UserInternCarouselState();
}

class _UserInternCarouselState extends State<UserInternCarousel> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  static const double _viewportFraction = 0.55;

  /// Single source of truth for filtering logic.
  List<InternProfile> get visibleInterns {
    return widget.interns.where((intern) {
      final dyn = intern as dynamic;

      // Spec rule: hide only archived interns.
      // NOTE: InternProfile does NOT have a `status` field, so we must check the actual backend shape.

      // Primary: is_archived / isArchived (only archived should be hidden)
      bool isArchived = false;
      try {
        isArchived = dyn.is_archived == true || dyn.isArchived == true;
      } catch (_) {}

      if (isArchived) return false;

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    final safeList = visibleInterns;
    _currentPage = safeList.isNotEmpty ? safeList.length * 1000 : 0;
    
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: _currentPage,
    );
    
    if (!widget.loading && safeList.isNotEmpty) {
      _startAutoScroll();
    }
  }

  @override
  void didUpdateWidget(covariant UserInternCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final safeList = visibleInterns;
    final listChanged = widget.interns != oldWidget.interns;
    final canScroll = safeList.isNotEmpty;

    if (listChanged && canScroll) {
      _autoScrollTimer?.cancel();

      _currentPage = safeList.length * 1000;

      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: _viewportFraction,
        initialPage: _currentPage,
      );

      if (!widget.loading) {
        _startAutoScroll();
      }
    }

    if ((!canScroll || widget.loading) && _autoScrollTimer != null) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (visibleInterns.isEmpty) return;
    
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
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => InternDetailPage(intern: intern),
      ),
    )
        .then((_) {
      if (mounted) _startAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final safeList = visibleInterns;

    // Loading state
    if (widget.loading) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: CircularProgressIndicator(
            color: InternCarouselPalette.accent,
          ),
        ),
      );
    }

    // Error state
    if (widget.error != null) {
      return SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: InternCarouselPalette.accent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                widget.error!,
                style: TextStyle(color: theme.topbarMutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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

    // Empty state 
    if (safeList.isEmpty) {
      return SizedBox(
        height: 320,
        child: Center(
          child: Text(
            'No interns found.',
            style: TextStyle(color: theme.topbarMutedText, fontSize: 16),
          ),
        ),
      );
    }

    // Main Carousel
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: SizedBox()),
              Text(
                'Meet Our Interns',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.topbarText,
                      fontSize: 24,
                    ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final intern = safeList[index % safeList.length];
              final isCenter = index == _currentPage;

              return AnimatedScale(
                scale: isCenter ? 1.0 : 0.82,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: isCenter ? 1.0 : 0.45,
                  duration: const Duration(milliseconds: 350),
                  child: GestureDetector(
                    onTap: () => _openDetail(intern),
                    child: UserInternCard(intern: intern),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Dot Navigation and Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ArrowButton(icon: Icons.chevron_left, onTap: _prev),
            const SizedBox(width: 20),
            Row(
              children: List.generate(
                safeList.length,
                (i) {
                  final active = i == (_currentPage % safeList.length);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? InternCarouselPalette.dotActive
                          : InternCarouselPalette.dotActive.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            _ArrowButton(icon: Icons.chevron_right, onTap: _next),
          ],
        ),
      ],
    );
  }
}

class _ArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
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
            size: 22,
          ),
        ),
      ),
    );
  }
}