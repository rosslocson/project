import 'dart:async';
import 'package:flutter/material.dart';

// Intern profile & detail page models
import '../../screens/intern_widgets.dart';
import '../../screens/intern_directory_screen.dart';
import '../../screens/intern_ross_profile_page.dart';

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

  @override
  void initState() {
    super.initState();
    _currentPage = widget.interns.isNotEmpty ? widget.interns.length * 1000 : 0;
    _pageController =
        PageController(viewportFraction: 0.35, initialPage: _currentPage);
    if (!widget.loading && widget.interns.isNotEmpty) {
      _startAutoScroll();
    }
  }

  @override
  void didUpdateWidget(covariant InternCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interns != oldWidget.interns && widget.interns.isNotEmpty) {
      _currentPage = widget.interns.length * 1000;
      _pageController.dispose();
      _pageController =
          PageController(viewportFraction: 0.35, initialPage: _currentPage);
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

    final page = intern.name == 'Rosalyn Locson'
    ? RosalynProfilePage(intern: intern)
    : InternDetailPage(intern: intern);

    Navigator.of(context)
        .push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => page, // ← USE page HERE
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                  child: SizedBox()), // left spacer keeps title centered
              Text(
                'Meet Our Interns',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                      foregroundColor: const Color(0xFF8A84FF),
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
        const SizedBox(height: 16),
        _buildCarouselBody(),
        const SizedBox(height: 16),
        if (!widget.loading && widget.interns.isNotEmpty) _buildDotNavigation(),
      ],
    );
  }

  Widget _buildCarouselBody() {
    if (widget.loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }

    if (widget.error != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 40),
              const SizedBox(height: 8),
              Text(widget.error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.interns.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
            child: Text('No interns found.',
                style: TextStyle(color: Colors.white54, fontSize: 15))),
      );
    }

    return SizedBox(
      height: 180,
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
                child: _InternCardFront(intern: intern),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDotNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ArrowButton(icon: Icons.chevron_left, onTap: _prev),
        const SizedBox(width: 20),
        Row(
          children: List.generate(widget.interns.length, (i) {
            final active = i == (_currentPage % widget.interns.length);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color.fromARGB(255, 118, 115, 200)
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(width: 20),
        _ArrowButton(icon: Icons.chevron_right, onTap: _next),
      ],
    );
  }
}

class _InternCardFront extends StatelessWidget {
  final InternProfile intern;

  const _InternCardFront({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
          InternAvatar(
              intern: intern, size: 70, borderRadius: 18, fontSize: 28),
          const SizedBox(height: 12),
          Text(
            intern.name,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            intern.internNumber != 'N/A'
                ? 'Intern #${intern.internNumber}'
                : '',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
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
            color: Colors.white.withValues(alpha: _isHovered ? 0.25 : 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: _isHovered ? 0.4 : 0.2),
              width: 0.8,
            ),
          ),
          child: Icon(
            widget.icon,
            color: Colors.white.withValues(alpha: _isHovered ? 1.0 : 0.8),
            size: 22,
          ),
        ),
      ),
    );
  }
}
