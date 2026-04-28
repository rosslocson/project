import 'dart:async';
import 'package:flutter/material.dart';

// Adjust this import path based on where InternProfile and InternDetailPage are located
import '../../screens/intern_widgets.dart'; 
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

  @override
  void initState() {
    super.initState();
    _currentPage = widget.interns.isNotEmpty ? widget.interns.length * 1000 : 0;
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: _currentPage,
    );
    if (!widget.loading && widget.interns.isNotEmpty) {
      _startAutoScroll();
    }
  }

  @override
  void didUpdateWidget(covariant UserInternCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize controller when data arrives so infinite scroll works
    if (widget.interns != oldWidget.interns && widget.interns.isNotEmpty) {
      _currentPage = widget.interns.length * 1000;
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: _viewportFraction,
        initialPage: _currentPage,
      );
      _startAutoScroll();
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InternDetailPage(intern: intern),
      ),
    ).then((_) {
      if (mounted) _startAutoScroll(); // Resume scrolling when returning
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (widget.loading) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white54),
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
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              Text(
                widget.error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text('Retry', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (widget.interns.isEmpty) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: Text(
            'No interns found.',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    // Main Carousel
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final intern = widget.interns[index % widget.interns.length];
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
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
              onPressed: _prev,
            ),
            const SizedBox(width: 20),
            Row(
              children: List.generate(widget.interns.length, (i) {
                final active = i == (_currentPage % widget.interns.length);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF4A5E9A) : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
              onPressed: _next,
            ),
          ],
        ),
      ],
    );
  }
}